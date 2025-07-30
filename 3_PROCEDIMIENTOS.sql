--------------------------------------------------------------
--//////////////////////////////////////////////////////////////////////////////////////////////--
--PROCEDIMIENTOS 
--//////////////////////////////////////////////////////////////////////////////////////////////////--
CREATE OR ALTER PROCEDURE sp_CrearSucursal
    @NombreSucursal NVARCHAR(100),
	@DIRECCION NVARCHAR (100)
AS
BEGIN
    INSERT INTO Sucursales (Nombre,Direccion)
    VALUES (@NombreSucursal,@DIRECCION);
END;
----------------------------------------------------
--PROCEDIMIENTO ALMACENADO CREAR SUCURSALES
GO
CREATE PROCEDURE sp_CrearSucursal
    @NombreSucursal NVARCHAR(100)
AS
BEGIN
    INSERT INTO Sucursales (NombreSucursal)
    VALUES (@NombreSucursal);
END;

---------------------------------------------------
--ejemplos procedimientos anterior
EXEC sp_CrearSucursal @NombreSucursal = N'Sucursal norte',@DIRECCION ='ZONA NORTE DE LA CIUDAD';
EXEC sp_CrearSucursal @NombreSucursal = N'Sucursal sur',@DIRECCION ='ZONA SUR DE LA CIUDAD';
EXEC sp_CrearSucursal @NombreSucursal = N'Sucursal Centro',@DIRECCION ='ZONA CENTRO DE LA CIUDAD';
EXEC sp_CrearSucursal @NombreSucursal = N'Sucursal PRINCIPAL',@DIRECCION ='EDIFICIO PRINCIPAL';

SELECT *
FROM Sucursales
--YA
---------------------------------------------------
--PROCEDIMIENTO PARA CREAR USUARIO PARA EMPLEADO
GO
CREATE PROCEDURE sp_CrearUsuarioParaEmpleado
    @EmpleadoID INT,
    @NombreUsuario NVARCHAR(50),
    @Contrasenia NVARCHAR(100)
AS
BEGIN
    INSERT INTO Usuarios (EmpleadoID, Username, PasswordHash)
    VALUES (@EmpleadoID, @NombreUsuario, @Contrasenia);
END;
-----------------------------------------------------------
--PRUEBA
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 1,  @NombreUsuario = N'clopez',    @Contrasenia = N'Clave#123';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 2,  @NombreUsuario = N'mfernandez',@Contrasenia = N'Password456';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 3,  @NombreUsuario = N'jramirez',  @Contrasenia = N'Segura789';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 4,  @NombreUsuario = N'agomez',    @Contrasenia = N'Ana2023!';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 5,  @NombreUsuario = N'lmartinez', @Contrasenia = N'MtzClave22';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 6,  @NombreUsuario = N'dcruz',     @Contrasenia = N'Bienvenida1';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 7,  @NombreUsuario = N'fortega',   @Contrasenia = N'Acceso88!';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 8,  @NombreUsuario = N'lmejia',    @Contrasenia = N'MejiaPass';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 9,  @NombreUsuario = N'rperez',    @Contrasenia = N'Hola1234';
EXEC sp_CrearUsuarioParaEmpleado @EmpleadoID = 10, @NombreUsuario = N'vrios',     @Contrasenia = N'Valeria2024';

SELECT *
FROM Empleados

SELECT*
FROM Usuarios
--------------------------------------------------------------
--INGRESAR EMPLEADOS
INSERT INTO Empleados (RolID, Nombre, Apellido, Telefono, Correo, FechaIngreso, Activo)
VALUES
(1, 'Carlos',   'López',     '(9988-3423)', 'carlos.lopez@empresa.com',   '2024-02-15', 1),
(2, 'María',    'Fernández', '(3332-0520)', 'maria.fernandez@empresa.com','2023-11-10', 1),
(1, 'Jorge',    'Ramírez',   '(7722-8811)', 'jorge.ramirez@empresa.com',  '2024-01-20', 1),
(1, 'Ana',      'Gómez',     '(6112-3456)', 'ana.gomez@empresa.com',      '2022-07-05', 1),
(2, 'Luis',     'Martínez',  '(7445-7788)', 'luis.martinez@empresa.com',  '2023-09-30', 1),
(1, 'Diana',    'Cruz',      '(8123-5678)', 'diana.cruz@empresa.com',     '2024-04-10', 1),
(2, 'Fernando', 'Ortega',    '(9654-2231)', 'fernando.ortega@empresa.com','2022-12-01', 1),
(2, 'Laura',    'Mejía',     '(7000-0001)', 'laura.mejia@empresa.com',    '2023-03-14', 1),
(1, 'Ricardo',  'Pérez',     '(8899-1122)', 'ricardo.perez@empresa.com',  '2024-05-01', 1),
(2, 'Valeria',  'Ríos',      '(5566-7788)', 'valeria.rios@empresa.com',   '2023-08-19', 1);

SELECT *
FROM Usuarios

SELECT *
FROM AuditoriaGeneral
----------------------------------------------------------------

--PROCEDIMIENTO PARA ASIGNAR ROL AL EMPLEADO
GO
CREATE PROCEDURE sp_AsignarRolAEmpleado
    @EmpleadoID INT,
    @RolID SMALLINT
AS
BEGIN
    UPDATE Empleados
    SET RolID = @RolID
    WHERE EmpleadoID = @EmpleadoID;
END;
------------------------------------------------------------------
--prueba
EXEC sp_AsignarRolAEmpleado @EmpleadoID = 12, @RolID = 1;


EXEC sp_AsignarRolAEmpleado @EmpleadoID = 11, @RolID = 3;


EXEC sp_AsignarRolAEmpleado @EmpleadoID = 2, @RolID = 3;

select *
from Roles

-------------------------------------------------------------------
--ingresar roles
INSERT INTO Roles ( Nombre,Descripcion) VALUES
('Administrador','acceso total a'),
('Gerente','acceso total a'),
( 'Analista','acceso total a'),
( 'Soporte','acceso total a');


--------------------------------------------------------------------
--PROCEDIMIENTO PARA ACTUALIZAR EL TIPO DE CLIENTE
GO
CREATE PROCEDURE sp_ActualizarTipoCliente
    @ClienteID INT,
    @NuevoTipoClienteID TINYINT
AS
BEGIN
    UPDATE Clientes
    SET TipoClienteID = @NuevoTipoClienteID
    WHERE ClienteID = @ClienteID;
END;
----------------------------------------------------------------------------------------------
--prueba
EXEC sp_ActualizarTipoCliente @ClienteID = 1, @NuevoTipoClienteID = 3;


EXEC sp_ActualizarTipoCliente @ClienteID = 2, @NuevoTipoClienteID = 4;


EXEC sp_ActualizarTipoCliente @ClienteID = 3, @NuevoTipoClienteID = 2;


EXEC sp_ActualizarTipoCliente @ClienteID = 4, @NuevoTipoClienteID = 1;


EXEC sp_ActualizarTipoCliente @ClienteID = 5, @NuevoTipoClienteID = 3;
-----------------------------------------------------------------------------------------------
--insertar tipo de cliente 
INSERT INTO TipoCliente( Nombre) VALUES
('Regular'),
( 'Preferente'),
( 'VIP'),
( 'Corporativo');

SELECT *
FROM TipoCliente
-----------------------------------------------------------------------------------------------
--PROCEDIMIENTO PARA LISTAR USUARIOS CON ROL
GO
CREATE PROCEDURE sp_ListarUsuariosConRol
AS
BEGIN
    SELECT U.UsuarioID, U.Username, E.EmpleadoID, R.RolID, R.RolID
    FROM Usuarios U
    INNER JOIN Empleados E ON U.EmpleadoID = E.EmpleadoID
    INNER JOIN Roles R ON E.RolID = R.RolID;
END;

GO
-----------------------------------------------------------------------
--PRUEBA
EXEC sp_ListarUsuariosConRol

-------------------------------------------------------------------------
----------------------------------------------------------------------
-- PROCEDIMIENTO: Registra una compra con sus detalles y actualiza totales mediante el trigger
IF OBJECT_ID('dbo.usp_RegistrarCompra','P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RegistrarCompra;
GO
CREATE PROCEDURE dbo.usp_RegistrarCompra
    @EmpleadoID  INT,
    @ProveedorID INT,
    @SucursalID  SMALLINT,
    @Detalles    dbo.TipoDetalleCompra READONLY
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM @Detalles)
    BEGIN
        RAISERROR('Debe enviar detalles.',16,1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM @Detalles d
        LEFT JOIN Productos p ON p.ProductoID = d.ProductoID
        WHERE p.ProductoID IS NULL OR p.Activo = 0
    )
    BEGIN
        RAISERROR('Producto inexistente o inactivo.',16,1);
        RETURN;
    END

    BEGIN TRAN;
    BEGIN TRY
        INSERT INTO Compras(EmpleadoID, ProveedorID, SucursalID, CostoTotal)
        VALUES(@EmpleadoID, @ProveedorID, @SucursalID, 0);

        DECLARE @CompraID BIGINT = SCOPE_IDENTITY();

        INSERT INTO DetalleCompras(CompraID, ProductoID, Cantidad, CostoUnitario)
        SELECT @CompraID, ProductoID, Cantidad, CostoUnitario
        FROM @Detalles;

        SELECT CompraID, CostoTotal
        FROM Compras
        WHERE CompraID = @CompraID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(),16,1);
    END CATCH
END;
GO
--REPARAR
-----------------------------------
-- PROCEDIMIENTO: Anula (soft) una compra restando stock y marcando la compra como Anulada
IF OBJECT_ID('dbo.usp_AnularCompra','P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AnularCompra;
GO
CREATE PROCEDURE dbo.usp_AnularCompra
    @CompraID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Compras WHERE CompraID=@CompraID)
    BEGIN
        RAISERROR('Compra no existe.',16,1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Compras WHERE CompraID=@CompraID AND Anulada=1)
    BEGIN
        RAISERROR('Compra ya anulada.',16,1);
        RETURN;
    END

    BEGIN TRAN;
    BEGIN TRY
        DECLARE @SucursalID SMALLINT;
        SELECT @SucursalID = SucursalID FROM Compras WHERE CompraID=@CompraID;

        DECLARE curDet CURSOR LOCAL FAST_FORWARD FOR
            SELECT ProductoID, Cantidad
            FROM DetalleCompras
            WHERE CompraID=@CompraID;

        DECLARE @ProdID INT, @Cant INT;
        OPEN curDet;
        FETCH NEXT FROM curDet INTO @ProdID, @Cant;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE Inventario
               SET Stock = Stock - @Cant
             WHERE SucursalID=@SucursalID AND ProductoID=@ProdID;

            UPDATE Productos
               SET StockGlobal = StockGlobal - @Cant
             WHERE ProductoID=@ProdID;

            FETCH NEXT FROM curDet INTO @ProdID, @Cant;
        END
        CLOSE curDet; DEALLOCATE curDet;

        IF EXISTS(SELECT 1 FROM Inventario WHERE Stock < 0) OR
           EXISTS(SELECT 1 FROM Productos WHERE StockGlobal < 0)
        BEGIN
            RAISERROR('No se puede anular: stock negativo.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Compras
           SET Anulada = 1,
               CostoTotal = 0
         WHERE CompraID=@CompraID;

        COMMIT TRAN;

        SELECT CompraID=@CompraID, Anulada=1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRAN;
        RAISERROR(ERROR_MESSAGE(),16,1);
    END CATCH
END;
GO
--REPARAR
-----------------------------------------
--PROCEDIMIENTOS ALMACENADOS



--PROCEDIMIENTO PARA INSERTAR UN NUEVO EMPLEADO
GO
CREATE PROCEDURE sp_RegistrarEmpleado
    @RolID SMALLINT = NULL
AS
BEGIN
    INSERT INTO Empleados (RolID, Activo)
    VALUES (@RolID, 1);
END;

--PROCEDIMIENTO PARA LISTAR EMPLEADOS SEGUN SU ROL
GO
CREATE PROCEDURE sp_ListarEmpleadosPorRol
    @RolID SMALLINT
AS
BEGIN
    SELECT E.EmpleadoID, E.RolID
    FROM Empleados E
    WHERE E.RolID = @RolID AND E.Activo = 1;
END;

--PROCEDIMIENTO PARA CALCULAR PLANILLA POR PERIODO
GO
CREATE PROCEDURE sp_CalcularPlanillaPorPeriodo
    @Periodo NVARCHAR(20)
AS
BEGIN
    SELECT P.EmpleadoID, SUM(P.Monto) AS TotalPagado
    FROM Planilla P
    WHERE P.Periodo = @Periodo
    GROUP BY P.EmpleadoID;
END;

--PROCEDIMIENTO PARA LISTAR TURNOS ACTIVOS
GO
CREATE PROCEDURE sp_ListarTurnosActivos
AS
BEGIN
    SELECT * FROM Turnos WHERE Activo = 1;
END;

--PROCEDIMIENTO PARA CAMBIAR ESTADO DE USUARIO ACTIVAR O DESACTIVAR
GO
CREATE PROCEDURE sp_CambiarEstadoEmpleado
    @EmpleadoID INT,
    @NuevoEstado BIT
AS
BEGIN
    UPDATE Empleados
    SET Activo = @NuevoEstado
    WHERE EmpleadoID = @EmpleadoID;
END;

--PROCEDIMIENTO PARA LISTAR TODOS LOS EMPLEADOS ACTIVOS
GO
CREATE PROCEDURE sp_ListarEmpleadosActivos
AS
BEGIN
    SELECT EmpleadoID, RolID
    FROM Empleados
    WHERE Activo = 1;
END;

--PROCEDIMIENTO PARA ASIGNAR TURNO A EMPLEADO
GO
CREATE PROCEDURE sp_AsignarTurnoAEmpleado
    @EmpleadoID INT,
    @TurnoID SMALLINT,
    @Periodo NVARCHAR(20),
    @Monto DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Planilla (EmpleadoID, TurnoID, Periodo, Monto)
    VALUES (@EmpleadoID, @TurnoID, @Periodo, @Monto);
END;

--PROCEDIMIENTO LISTA PLANILLA POR EMPLEADO
GO
CREATE PROCEDURE sp_ListarPlanillaPorEmpleado
    @EmpleadoID INT
AS
BEGIN
    SELECT PlanillaID, TurnoID, Periodo, Monto
    FROM Planilla
    WHERE EmpleadoID = @EmpleadoID;
END;

--ACTUALIZAR ROL EMPLEADO
GO
CREATE PROCEDURE sp_ActualizarRolEmpleado
    @EmpleadoID INT,
    @NuevoRolID SMALLINT
AS
BEGIN
    UPDATE Empleados
    SET RolID = @NuevoRolID
    WHERE EmpleadoID = @EmpleadoID;
END;
-- Listar cambios por tabla
CREATE OR ALTER PROCEDURE sp_ListarCambiosPorTabla
  @NombreTabla VARCHAR(50)
AS
BEGIN
    SELECT *
    FROM AuditoriaGeneral
    WHERE NombreTabla = @NombreTabla
    ORDER BY FechaHora DESC;
END
GO

-- Listar cambios por usuario
CREATE OR ALTER PROCEDURE sp_ListarCambiosPorUsuario
  @UsuarioSistema VARCHAR(128)
AS
BEGIN
    SELECT *
    FROM AuditoriaGeneral
    WHERE UsuarioSistema = @UsuarioSistema
    ORDER BY FechaHora DESC;
END
GO

-- Resumen por fecha
CREATE OR ALTER PROCEDURE sp_ResumenAuditoriaPorFecha
AS
BEGIN
    SELECT CONVERT(DATE, FechaHora) AS Fecha, NombreTabla, Operacion, COUNT(*) AS Total
    FROM AuditoriaGeneral
    GROUP BY CONVERT(DATE, FechaHora), NombreTabla, Operacion
    ORDER BY Fecha;
END
GO

-- Obtener detalle de cambio por ID
CREATE OR ALTER PROCEDURE sp_ObtenerDetalleCambio
  @AuditoriaID INT
AS
BEGIN
    SELECT *
    FROM AuditoriaGeneral
    WHERE AuditoriaID = @AuditoriaID;
END
GO
