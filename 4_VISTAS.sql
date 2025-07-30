---------------------------------------------------
-- 1‑5: VISTAS DE CLIENTES Y TIPOS DE CLIENTE
---------------------------------------------------
CREATE VIEW vw_Clientes_Completo AS
SELECT c.ClienteID, c.Nombre, c.Apellido, tc.Nombre AS TipoCliente, c.Telefono, c.Correo, c.Direccion
FROM Clientes c
JOIN TipoCliente tc ON c.TipoClienteID = tc.TipoClienteID;
GO

CREATE VIEW vw_Clientes_Contactos AS
SELECT cc.ContactoID, cc.ClienteID, c.Nombre + ' ' + c.Apellido AS Cliente,
       cc.NombreContacto, cc.Telefono, cc.Correo, cc.Relacion
FROM ContactosClientes cc
JOIN Clientes c ON cc.ClienteID = c.ClienteID;
GO

-- Vista de clientes VIP
CREATE VIEW vw_Clientes_VIP AS
SELECT * FROM vw_Clientes_Completo WHERE TipoCliente = 'VIP';
GO

-- Conteo de clientes por tipo
CREATE VIEW vw_Count_Clientes_Por_Tipo AS
SELECT tc.Nombre AS TipoCliente, COUNT(*) AS CantidadClientes
FROM Clientes c
JOIN TipoCliente tc ON c.TipoClienteID = tc.TipoClienteID
GROUP BY tc.Nombre;
GO

-- Clientes con columna de nombres completos
CREATE VIEW vw_Clientes_FullName AS
SELECT ClienteID, Nombre + ' ' + Apellido AS NombreCompleto, Telefono, Correo
FROM Clientes;
GO

---------------------------------------------------
-- 6‑10: VENTAS Y FACTURAS
---------------------------------------------------
CREATE VIEW vw_Ventas_Detalle AS
SELECT v.VentaID, v.FechaHora, e.Nombre + ' ' + e.Apellido AS Vendedor,
       c.Nombre + ' ' + c.Apellido AS Cliente, v.SucursalID, v.Total
FROM Ventas v
JOIN Empleados e ON v.EmpleadoID = e.EmpleadoID
JOIN Clientes c ON v.ClienteID = c.ClienteID;
GO

CREATE VIEW vw_Ventas_Productos AS
SELECT dv.VentaID, p.Nombre AS Producto, dv.Cantidad, dv.PrecioUnitario, (dv.Cantidad * dv.PrecioUnitario) AS Subtotal
FROM DetalleVentas dv
JOIN Productos p ON dv.ProductoID = p.ProductoID;
GO

CREATE VIEW vw_Ventas_Completo AS
SELECT vd.*, vp.Producto, vp.Cantidad, vp.PrecioUnitario, vp.Subtotal
FROM vw_Ventas_Detalle vd
JOIN vw_Ventas_Productos vp ON vd.VentaID = vp.VentaID;
GO

-- Ventas por sucursal
CREATE VIEW vw_Ventas_Por_Sucursal AS
SELECT SucursalID, COUNT(*) AS NumeroVentas, SUM(Total) AS TotalVentas
FROM Ventas
GROUP BY SucursalID;
GO

-- Ventas por cliente
CREATE VIEW vw_Ventas_Por_Cliente AS
SELECT ClienteID, COUNT(*) AS NumeroCompras, SUM(Total) AS TotalGastado
FROM Ventas
GROUP BY ClienteID;
GO

---------------------------------------------------
-- 11‑15: COMPRAS Y PROVEEDORES
---------------------------------------------------
CREATE VIEW vw_Compras_Detalle AS
SELECT c.CompraID, c.FechaHora, e.Nombre + ' ' + e.Apellido AS Comprador,
       pr.NombreEmpresa AS Proveedor, c.SucursalID, c.CostoTotal
FROM Compras c
JOIN Empleados e ON c.EmpleadoID = e.EmpleadoID
JOIN Proveedores pr ON c.ProveedorID = pr.ProveedorID;
GO

CREATE VIEW vw_Compras_Productos AS
SELECT dc.CompraID, p.Nombre AS Producto, dc.Cantidad, dc.CostoUnitario, (dc.Cantidad * dc.CostoUnitario) AS Subtotal
FROM DetalleCompras dc
JOIN Productos p ON dc.ProductoID = p.ProductoID;
GO

CREATE VIEW vw_Compras_Completo AS
SELECT cd.*, cp.Producto, cp.Cantidad, cp.CostoUnitario, cp.Subtotal
FROM vw_Compras_Detalle cd
JOIN vw_Compras_Productos cp ON cd.CompraID = cp.CompraID;
GO

-- Gastos totales por proveedor
CREATE VIEW vw_Gastos_Por_Proveedor AS
SELECT ProveedorID, SUM(CostoTotal) AS TotalComprado, COUNT(*) AS NumeroCompras
FROM Compras
GROUP BY ProveedorID;
GO

-- Compras por sucursal
CREATE VIEW vw_Compras_Por_Sucursal AS
SELECT SucursalID, COUNT(*) AS NumeroCompras, SUM(CostoTotal) AS TotalCompras
FROM Compras
GROUP BY SucursalID;
GO

---------------------------------------------------
-- 16‑20: INVENTARIO
---------------------------------------------------
CREATE VIEW vw_Inventario_Sucursal AS
SELECT i.SucursalID, p.ProductoID, p.Nombre AS Producto, i.Stock
FROM Inventario i
JOIN Productos p ON i.ProductoID = p.ProductoID;
GO

CREATE VIEW vw_Inventario_Global AS
SELECT ProductoID, Nombre, StockGlobal
FROM Productos;
GO

-- Stock total y por sucursal
CREATE VIEW vw_Stock_Por_Producto AS
SELECT p.ProductoID, p.Nombre,
       p.StockGlobal, ISNULL(SUM(i.Stock),0) AS StockDistribuido
FROM Productos p
LEFT JOIN Inventario i ON p.ProductoID = i.ProductoID
GROUP BY p.ProductoID, p.Nombre, p.StockGlobal;
GO

-- Productos con bajo stock (umbral configurable)
CREATE VIEW vw_Stock_Bajo AS
SELECT ProductoID, Nombre, StockGlobal
FROM Productos
WHERE StockGlobal < 10;
GO

-- Stock por categoría
CREATE VIEW vw_Stock_Por_Categoria AS
SELECT cp.Nombre AS Categoria, COUNT(*) AS NumeroProductos, SUM(p.StockGlobal) AS StockTotal
FROM Productos p
JOIN CategoriasProducto cp ON p.CategoriaID = cp.CategoriaID
GROUP BY cp.Nombre;
GO

---------------------------------------------------
-- 21‑25: AUDITORÍA, ERRORES Y ACCESOS
---------------------------------------------------
CREATE VIEW vw_Auditoria_General AS
SELECT AuditoriaID, NombreTabla, Operacion, UsuarioSistema, UsuarioApp, FechaHora, RegistroID
FROM AuditoriaGeneral;
GO

CREATE VIEW vw_LogErrores_Reciente AS
SELECT TOP 50 ErrorID, FechaHora, MensajeError, Procedimiento, Linea, UsuarioSistema, AppOrigen
FROM LogErroresSistema
ORDER BY FechaHora DESC;
GO

-- Accesos por usuario
CREATE VIEW vw_Bitacora_Accesos AS
SELECT ba.UsuarioID, u.Username, ba.FechaHora, ba.TipoAcceso, ba.IP_Acceso, ba.Dispositivo
FROM BitacoraAccesos ba
JOIN Usuarios u ON ba.UsuarioID = u.UsuarioID;
GO

-- Frecuencia de inicios de sesión
CREATE VIEW vw_LoginCount_Per_Usuario AS
SELECT UsuarioID, COUNT(*) AS TotalAccesos
FROM BitacoraAccesos
WHERE TipoAcceso = 'LOGIN'
GROUP BY UsuarioID;
GO

-- Consultas SQL por usuario
CREATE VIEW vw_LogsConsultasSQL AS
SELECT LogID, UsuarioID, FechaHora, Origen, SUBSTRING(ConsultaSQL,1,200) AS ConsultaPreview
FROM LogsConsultasSQL;
GO

---------------------------------------------------
-- 26‑30: PRECIOS, HISTÓRICOS Y PROMOCIONES
---------------------------------------------------
CREATE VIEW vw_HistorialPrecios_Reciente AS
SELECT HistorialID, ProductoID, PrecioAnterior, PrecioNuevo, FechaCambio, UsuarioCambio
FROM HistorialPrecios
ORDER BY FechaCambio DESC;
GO

-- Promociones activas
CREATE VIEW vw_Promociones_Activas AS
SELECT DescuentoID, ProductoID, PorcentajeDescuento, FechaInicio, FechaFin
FROM DescuentosPromociones
WHERE FechaInicio <= GETDATE() AND FechaFin >= GETDATE();
GO

-- Promociones por producto
CREATE VIEW vw_Promociones_Por_Producto AS
SELECT p.Nombre AS Producto, dp.PorcentajeDescuento, dp.FechaInicio, dp.FechaFin
FROM DescuentosPromociones dp
JOIN Productos p ON dp.ProductoID = p.ProductoID;
GO

-- Cambios de precio por usuario
CREATE VIEW vw_CambiosPrecio_Usuario AS
SELECT hp.UsuarioCambio, COUNT(*) AS CambiosRealizados, MIN(FechaCambio) AS PrimeraFecha, MAX(FechaCambio) AS UltimaFecha
FROM HistorialPrecios hp
GROUP BY UsuarioCambio;
GO

---------------------------------------------------
-- 31‑34: EMPLEADOS Y TURNOS
---------------------------------------------------
CREATE VIEW vw_Empleados_Completo AS
SELECT e.EmpleadoID, e.Nombre + ' ' + e.Apellido AS Empleado, r.Nombre AS Rol, e.FechaIngreso, e.Activo
FROM Empleados e
JOIN Roles r ON e.RolID = r.RolID;
GO

CREATE VIEW vw_Turnos_Disponibles AS
SELECT TurnoID, Nombre, HoraInicio, HoraFin FROM Turnos;
GO

-- Planilla consolidada por empleado y período
CREATE VIEW vw_Planilla_Resumen AS
SELECT pl.EmpleadoID, e.Nombre + ' ' + e.Apellido AS Empleado,
       pl.PeriodoInicio, pl.PeriodoFin,
       SUM(pl.SalarioBruto) AS TotalBruto, SUM(pl.Deducciones) AS TotalDeducciones,
       SUM(pl.SalarioNeto) AS TotalNeto
FROM Planilla pl
JOIN Empleados e ON pl.EmpleadoID = e.EmpleadoID
GROUP BY pl.EmpleadoID, e.Nombre, e.Apellido, pl.PeriodoInicio, pl.PeriodoFin;
GO

-- Empleados activos con rol
CREATE VIEW vw_Empleados_Activos AS
SELECT EmpleadoID, Nombre + ' ' + Apellido AS NombreCompleto, Rol,
       FechaIngreso
FROM vw_Empleados_Completo
WHERE Activo = 1;
GO

---------------------------------------------------
-- 35‑40: NOTIFICACIONES, DOCUMENTOS Y CONFIGURACIÓN
---------------------------------------------------
CREATE VIEW vw_Notificaciones_Recientes AS
SELECT NotificacionID, Titulo, Mensaje, FechaEnvio, MedioEnvio, UsuarioID, ClienteID
FROM NotificacionesSistema
WHERE FechaEnvio >= DATEADD(day,-30,GETDATE());
GO

-- Notificaciones por medio
CREATE VIEW vw_Notificaciones_Por_Medio AS
SELECT MedioEnvio, COUNT(*) AS Total
FROM NotificacionesSistema
GROUP BY MedioEnvio;
GO

-- Documentos adjuntos por tabla de referencia
CREATE VIEW vw_Documentos_Por_Tabla AS
SELECT TablaReferencia, COUNT(*) AS TotalDocumentos
FROM DocumentosAdjuntos
GROUP BY TablaReferencia;
GO

-- Archivos recientes
CREATE VIEW vw_Documentos_Recientes AS
SELECT DocumentoID, TablaReferencia, RegistroID, NombreArchivo, FechaCarga, UsuarioCarga
FROM DocumentosAdjuntos
WHERE FechaCarga >= DATEADD(day,-30,GETDATE());
GO

-- Parámetros de configuración activos
CREATE VIEW vw_ConfiguracionSistema AS
SELECT NombreParametro, ValorParametro, Descripcion
FROM ConfiguracionSistema;
GO
