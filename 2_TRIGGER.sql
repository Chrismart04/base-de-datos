--///////////////////////////////////////////////////////////////////////////////////////////////
--TRIGGERS
--///////////////////////////////////////////////////////////////////////////////////////////////////
CREATE TRIGGER tgr_AuditarUpdateClientes
ON Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditoriaGeneral ( NombreTabla,Operacion,UsuarioSistema,UsuarioApp,
						FechaHora,HostName,AppName,RegistroID,ValoresAnteriores,ValoresNuevos,
						Observaciones)
    SELECT 'Clientes','UPDATE',SUSER_SNAME(),NULL, SYSDATETIME(),                       
			  HOST_NAME(),APP_NAME(),CAST(i.ClienteID AS VARCHAR),        
        (
            SELECT * 
            FROM deleted d 
            WHERE d.ClienteID = i.ClienteID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,
        (
            SELECT * 
            FROM inserted i2 
            WHERE i2.ClienteID = i.ClienteID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos,
        'Actualización de cliente desde trigger automático' -- Observaciones
    FROM inserted i;
END;
-----------------------------------------------------------------

-- TRIGGER PARA AUDITORIA DE CAMBIO DE SUCURSALES
CREATE TRIGGER tgr_AuditarUpdateSucursales
ON Sucursales
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditoriaGeneral (NombreTabla,Operacion,UsuarioSistema,UsuarioApp,
								FechaHora,HostName,AppName,RegistroID,ValoresAnteriores,
								ValoresNuevos,Observaciones)
    SELECT 'Sucursales', 'UPDATE',SUSER_SNAME(),NULL,SYSDATETIME(),HOST_NAME(),APP_NAME(),
	       CAST(i.SucursalID AS VARCHAR),
		(   
            SELECT * 
            FROM deleted d 
            WHERE d.SucursalID = i.SucursalID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,
        (
            SELECT * 
            FROM inserted i2 
            WHERE i2.SucursalID = i.SucursalID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos,
        'Actualización de sucursal desde trigger automático' -- Observaciones
    FROM inserted i;
END;
-------------------------------------------------



--TRIGGER PARA MANTENER INVENTARIO EN 0 AL ELIMINAR PRODUCTO
CREATE TRIGGER tgr_BorrarProductoInventario
ON Productos
AFTER DELETE
AS
BEGIN
    DELETE FROM Inventario
    WHERE ProductoID IN (SELECT ProductoID FROM deleted);
END;
GO

--------------------------------------------------------------

--TRIGGER PARA AUDITORIA ACTUALIZAR EN CLIENTES
CREATE TRIGGER tgr_AuditarActualizarClientes
ON Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditoriaGeneral (NombreTabla,Operacion,UsuarioSistema,UsuarioApp,FechaHora,
									HostName,AppName,RegistroID,ValoresAnteriores,ValoresNuevos,
									Observaciones)
    SELECT 
        'Clientes','UPDATE',SUSER_SNAME(),NULL,SYSDATETIME(),HOST_NAME(),APP_NAME(),CAST(i.ClienteID AS VARCHAR),
		   (
            SELECT * FROM deleted d 
            WHERE d.ClienteID = i.ClienteID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,
        (
            SELECT * FROM inserted i2 
            WHERE i2.ClienteID = i.ClienteID 
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos,
        'Actualización de datos del cliente'
    FROM inserted i;
END;
---------------------------------------------------------------------

-- TRIGGER: Actualiza stock por sucursal, stock global y costo total cuando cambian líneas de compra
IF OBJECT_ID('dbo.TR_DetalleCompras_StockYCosto','TR') IS NOT NULL
    DROP TRIGGER dbo.TR_DetalleCompras_StockYCosto;
GO
CREATE TRIGGER dbo.TR_DetalleCompras_StockYCosto
ON dbo.DetalleCompras
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Deltas TABLE(
        CompraID   BIGINT,
        ProductoID INT,
        DeltaCant  INT
    );

    INSERT INTO @Deltas(CompraID, ProductoID, DeltaCant)
    SELECT i.CompraID, i.ProductoID, i.Cantidad
    FROM inserted i;

    INSERT INTO @Deltas(CompraID, ProductoID, DeltaCant)
    SELECT d.CompraID, d.ProductoID, -d.Cantidad
    FROM deleted d;

    SELECT CompraID, ProductoID, DeltaCant = SUM(DeltaCant)
    INTO #DeltaAgr
    FROM @Deltas
    GROUP BY CompraID, ProductoID
    HAVING SUM(DeltaCant) <> 0;

    IF NOT EXISTS (SELECT 1 FROM #DeltaAgr) RETURN;

    SELECT c.SucursalID, d.ProductoID, DeltaCant = SUM(d.DeltaCant)
    INTO #DeltaInv
    FROM #DeltaAgr d
    JOIN Compras c ON c.CompraID = d.CompraID
    GROUP BY c.SucursalID, d.ProductoID;

    UPDATE inv
       SET Stock = inv.Stock + x.DeltaCant
    FROM Inventario inv
    JOIN #DeltaInv x
      ON inv.SucursalID = x.SucursalID
     AND inv.ProductoID = x.ProductoID;

    INSERT INTO Inventario(SucursalID, ProductoID, Stock)
    SELECT x.SucursalID, x.ProductoID, x.DeltaCant
    FROM #DeltaInv x
    LEFT JOIN Inventario inv
           ON inv.SucursalID = x.SucursalID
          AND inv.ProductoID = x.ProductoID
    WHERE inv.ProductoID IS NULL;

    SELECT ProductoID, DeltaCant = SUM(DeltaCant)
    INTO #DeltaProd
    FROM #DeltaAgr
    GROUP BY ProductoID;

    UPDATE p
       SET StockGlobal = p.StockGlobal + dp.DeltaCant
    FROM Productos p
    JOIN #DeltaProd dp ON dp.ProductoID = p.ProductoID;

    UPDATE c
       SET CostoTotal = ISNULL(t.Suma,0)
    FROM Compras c
    JOIN (SELECT DISTINCT CompraID FROM #DeltaAgr) a ON a.CompraID = c.CompraID
    OUTER APPLY (
        SELECT SUM(d.Cantidad * d.CostoUnitario) AS Suma
        FROM DetalleCompras d
        WHERE d.CompraID = c.CompraID
    ) t;

    IF EXISTS (SELECT 1 FROM Inventario WHERE Stock < 0)
       OR EXISTS (SELECT 1 FROM Productos WHERE StockGlobal < 0)
    BEGIN
        RAISERROR('Operacion invalida: stock negativo.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- TRIGGER (opcional): Impide agregar productos inactivos a nuevas líneas de compra
IF OBJECT_ID('dbo.TR_DetalleCompras_BloquearInactivos','TR') IS NOT NULL
    DROP TRIGGER dbo.TR_DetalleCompras_BloquearInactivos;
GO
CREATE TRIGGER dbo.TR_DetalleCompras_BloquearInactivos
ON dbo.DetalleCompras
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(
        SELECT 1
        FROM inserted i
        JOIN Productos p ON p.ProductoID = i.ProductoID
        WHERE P. = 0 -------FALTA REPARAR Y AGREGAR EL ELIMINADO SUAVE
    )
    BEGIN
        RAISERROR('Producto inactivo no se puede comprar.',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
-----------------------------------------------------------------------------------------

--TRIGGER PARA AGREGAR USUARIO
CREATE TRIGGER tgr_AfterInsert_Empleados_AgregarUsuario
ON Empleados
AFTER INSERT
AS
BEGIN
    INSERT INTO Usuarios (EmpleadoID)
    SELECT EmpleadoID FROM inserted;
END;
----------------------------------------------------------------------------
--TRIGGER PARA ACTUALIZAR EMPLEADOS EN AUDITORIA GENRAL
CREATE TRIGGER tgr_AfterUpdate_Empleados_Auditoria
ON Empleados
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditoriaGeneral (Descripcion)
    SELECT CONCAT('Se actualizo el empleado ID ', inserted.EmpleadoID)
    FROM inserted;
END;
--REPARAR
-----------------------------------------------------------------
--TRIGGER ELIMNADO LOGICO
CREATE TRIGGER tgr_AfterDeleteLogico_Empleados
ON Empleados
INSTEAD OF DELETE
AS
BEGIN
    UPDATE Empleados
    SET Activo = 0
    WHERE EmpleadoID IN (SELECT EmpleadoID FROM deleted);
END;
------------------------------------------------------------------

--TRIGGER PARA AUDITAR CADA INSERCION DE PAGO
CREATE TRIGGER tgr_AuditarInsertPlanilla
ON Planilla
AFTER INSERT
AS
BEGIN
    INSERT INTO AuditoriaGeneral (Descripcion)
    SELECT CONCAT('Se registrO planilla para EmpleadoID ', inserted.EmpleadoID)
    FROM inserted;
END;
--REPARAR
-------------------------------------------------------------------

--TRIGGER AL ACTUALIZAR ROLES
CREATE TRIGGER tgr_AuditarUpdateRoles
ON Roles
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditoriaGeneral (Descripcion)
    SELECT CONCAT('Se actualizO el rol con RolID ', inserted.RolID)
    FROM inserted;
END;
--REPARAR
--------------------------------------------------------------------------

--TRIGGER PARA EVITAR ELIMINACION DIRECTA SI UN ROL ESTA EN USO
CREATE TRIGGER tgr_PreventDeleteRolEnUso
ON Roles
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Empleados
        WHERE RolID IN (SELECT RolID FROM deleted)
    )
    BEGIN
        RAISERROR('No se puede eliminar un rol que estO asignado a un empleado.', 16, 1);
    END
    ELSE
    BEGIN
        DELETE FROM Roles WHERE RolID IN (SELECT RolID FROM deleted);
    END
END;
GO
-------------------------------------------------------------------------
-- Clientes
CREATE OR ALTER TRIGGER trg_Auditoria_Clientes
ON Clientes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operacion VARCHAR(10);

    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'DELETE';

    INSERT INTO AuditoriaGeneral (NombreTabla, Operacion, RegistroID, ValoresAnteriores, ValoresNuevos)
    SELECT
        'Clientes',
        @Operacion,
        CAST(ISNULL(i.ClienteID, d.ClienteID) AS VARCHAR),
        CONCAT('Nombre: ', d.Nombre, ' ', d.Apellido),
        CONCAT('Nombre: ', i.Nombre, ' ', i.Apellido)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.ClienteID = d.ClienteID;
END
GO
--------------------------------------------------------------------
-- Productos
CREATE OR ALTER TRIGGER trg_Auditoria_Productos
ON Productos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operacion VARCHAR(10);

    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'DELETE';

    INSERT INTO AuditoriaGeneral (NombreTabla, Operacion, RegistroID, ValoresAnteriores, ValoresNuevos)
    SELECT
        'Productos',
        @Operacion,
        CAST(ISNULL(i.ProductoID, d.ProductoID) AS VARCHAR),
        CONCAT('Nombre: ', d.Nombre, ', Precio: ', d.PrecioVenta),
        CONCAT('Nombre: ', i.Nombre, ', Precio: ', i.PrecioVenta)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.ProductoID = d.ProductoID;
END
GO
-------------------------------------------------------------------------------------
-- Empleados
CREATE OR ALTER TRIGGER trg_Auditoria_Empleados
ON Empleados
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operacion VARCHAR(10);

    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'DELETE';

    INSERT INTO AuditoriaGeneral (NombreTabla, Operacion, RegistroID, ValoresAnteriores, ValoresNuevos)
    SELECT
        'Empleados',
        @Operacion,
        CAST(ISNULL(i.EmpleadoID, d.EmpleadoID) AS VARCHAR),
        CONCAT('Nombre: ', d.Nombre, ' ', d.Apellido),
        CONCAT('Nombre: ', i.Nombre, ' ', i.Apellido)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.EmpleadoID = d.EmpleadoID;
END
GO
----------------------------------------------------------------------------

-- Compras
CREATE OR ALTER TRIGGER trg_Auditoria_Compras
ON Compras
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operacion VARCHAR(10);

    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'DELETE';

    INSERT INTO AuditoriaGeneral (NombreTabla, Operacion, RegistroID, ValoresAnteriores, ValoresNuevos)
    SELECT
        'Compras',
        @Operacion,
        CAST(ISNULL(i.CompraID, d.CompraID) AS VARCHAR),
        CONCAT('Total: ', d.CostoTotal),
        CONCAT('Total: ', i.CostoTotal)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.CompraID = d.CompraID;
END
GO
--------------------------------------------------------------------------

-- Ventas
CREATE OR ALTER TRIGGER trg_Auditoria_Ventas
ON Ventas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operacion VARCHAR(10);

    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operacion = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
        SET @Operacion = 'DELETE';

    INSERT INTO AuditoriaGeneral (NombreTabla, Operacion, RegistroID, ValoresAnteriores, ValoresNuevos)
    SELECT
        'Ventas',
        @Operacion,
        CAST(ISNULL(i.VentaID, d.VentaID) AS VARCHAR),
        CONCAT('Total: ', d.Total),
        CONCAT('Total: ', i.Total)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.VentaID = d.VentaID;
END
GO