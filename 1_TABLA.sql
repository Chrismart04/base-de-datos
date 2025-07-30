CREATE DATABASE PROYECTO_FINAL
USE PROYECTO_FINAL
GO
--TABLAS


--1 Catálogo de tipos de cliente (mayorista, minorista, VIP) - TINYINT optimiza memoria
CREATE TABLE TipoCliente(
    TipoClienteID TINYINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(30) UNIQUE NOT NULL
);
GO

-- 2 Roles de empleados con descripción detallada para permisos específicos
CREATE TABLE Roles(
    RolID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(30) UNIQUE NOT NULL,
    Descripcion NVARCHAR(MAX) NULL
);
GO

-- 3 Sucursales con constraint compuesta para evitar duplicados por nombre-dirección
CREATE TABLE Sucursales(
    SucursalID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(60) NOT NULL,
    Direccion VARCHAR(200) NOT NULL,
    Telefono VARCHAR(20) NULL,
    CONSTRAINT UQ_Sucursales UNIQUE(Nombre, Direccion)
);
GO

-- 4 Categorías de productos para organización y reportes de ventas
CREATE TABLE CategoriasProducto(
    CategoriaID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(60) UNIQUE NOT NULL,
    Descripcion NVARCHAR(MAX) NULL
);
GO

-- 5 Categorías de proveedores para clasificación y gestión de compras
CREATE TABLE CategoriasProveedor(
    CategoriaProvID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(60) UNIQUE NOT NULL
);
GO

-- 6 Clientes con clasificación por tipo para estrategias de precio diferenciadas
CREATE TABLE Clientes(
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    TipoClienteID TINYINT NOT NULL,
    Nombre VARCHAR(60) NOT NULL,
    Apellido VARCHAR(60) NOT NULL,
    Telefono VARCHAR(20) NULL,
    Correo VARCHAR(120) NULL,
    Direccion VARCHAR(200) NULL,
    CONSTRAINT FK_Clientes_TipoCliente FOREIGN KEY (TipoClienteID) REFERENCES TipoCliente(TipoClienteID) ON UPDATE CASCADE
);
GO

-- 7 Empleados con estado activo para histórico sin eliminación física
CREATE TABLE Empleados(
    EmpleadoID INT IDENTITY(1,1) PRIMARY KEY,
    RolID SMALLINT NOT NULL,
    Nombre VARCHAR(60) NOT NULL,
    Apellido VARCHAR(60) NOT NULL,
    Telefono VARCHAR(20) NULL,
    Correo VARCHAR(120) NULL,
    FechaIngreso DATE NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Empleados_Roles FOREIGN KEY (RolID) REFERENCES Roles(RolID) ON UPDATE CASCADE
);
GO

--8 Usuarios del sistema - separados de empleados para seguridad y auditoría
CREATE TABLE Usuarios(
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT UNIQUE NOT NULL,
    Username VARCHAR(40) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL, -- Hash bcrypt para seguridad
    CONSTRAINT FK_Usuarios_Empleado FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

-- 9 Turnos laborales para cálculo automático de planilla
CREATE TABLE Turnos(
    TurnoID SMALLINT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(30) UNIQUE NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL
);
GO

-- 10 Planilla con columna calculada SalarioNeto para consistencia automática
CREATE TABLE Planilla(
    PlanillaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    TurnoID SMALLINT NULL,
    PeriodoInicio DATE NOT NULL,
    PeriodoFin DATE NOT NULL,
    SalarioBruto DECIMAL(10,2) NOT NULL,
    Deducciones DECIMAL(10,2) NOT NULL DEFAULT 0,
    SalarioNeto AS (SalarioBruto - Deducciones) PERSISTED, -- Columna calculada para integridad
    CONSTRAINT FK_Planilla_Empleado FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID) ON UPDATE CASCADE,
    CONSTRAINT FK_Planilla_Turno FOREIGN KEY (TurnoID) REFERENCES Turnos(TurnoID) ON UPDATE CASCADE
);
GO

-- 11 Proveedores con RTN para cumplimiento fiscal hondureño
CREATE TABLE Proveedores(
    ProveedorID INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaProvID SMALLINT NULL,
    NombreEmpresa VARCHAR(100) NOT NULL,
    Contacto VARCHAR(60) NULL,
    Telefono VARCHAR(20) NULL,
    RTN VARCHAR(25) NULL, -- Registro Tributario Nacional Honduras
    Direccion VARCHAR(200) NULL,
    CONSTRAINT FK_Proveedores_Categoria FOREIGN KEY (CategoriaProvID) REFERENCES CategoriasProveedor(CategoriaProvID) ON UPDATE CASCADE
);
GO

-- 12 Productos con stock global para control centralizado de inventario
CREATE TABLE Productos(
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaID SMALLINT NOT NULL,
    ProveedorID INT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(MAX) NULL,
    PrecioVenta DECIMAL(10,2) NOT NULL,
    StockGlobal INT NOT NULL DEFAULT 0, -- Stock total en todas las sucursales
    CONSTRAINT FK_Productos_Categoria FOREIGN KEY (CategoriaID) REFERENCES CategoriasProducto(CategoriaID) ON UPDATE CASCADE,
    CONSTRAINT FK_Productos_Proveedor FOREIGN KEY (ProveedorID) REFERENCES Proveedores(ProveedorID) ON UPDATE CASCADE
);
GO

-- 13 Inventario por sucursal - clave compuesta para distribución específica
CREATE TABLE Inventario(
    SucursalID SMALLINT NOT NULL,
    ProductoID INT NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Inventario PRIMARY KEY(SucursalID, ProductoID),
    CONSTRAINT FK_Inventario_Sucursal FOREIGN KEY (SucursalID) REFERENCES Sucursales(SucursalID) ON UPDATE CASCADE,
    CONSTRAINT FK_Inventario_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID) ON UPDATE CASCADE
);
GO

--14 Compras con DATETIME2 para precisión en timestamps de transacciones
CREATE TABLE Compras(
    CompraID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    ProveedorID INT NOT NULL,
    SucursalID SMALLINT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CostoTotal DECIMAL(12,2) NULL, -- Calculado desde DetalleCompras
    CONSTRAINT FK_Compras_Empleado FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID) ON UPDATE CASCADE,
    CONSTRAINT FK_Compras_Proveedor FOREIGN KEY (ProveedorID) REFERENCES Proveedores(ProveedorID) ON UPDATE CASCADE,
    CONSTRAINT FK_Compras_Sucursal FOREIGN KEY (SucursalID) REFERENCES Sucursales(SucursalID) ON UPDATE CASCADE
);
GO

--15 Detalle de compras con CASCADE DELETE para integridad transaccional
CREATE TABLE DetalleCompras(
    DetalleCompraID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CompraID BIGINT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    CostoUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_DetalleCompras_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID) ON UPDATE CASCADE
);
GO

--16-----------------------------------------
CREATE TABLE Ventas(
    VentaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    ClienteID INT NOT NULL,
    SucursalID SMALLINT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Total DECIMAL(12,2) NULL, -- Calculado desde DetalleVentas
    CONSTRAINT FK_Ventas_Empleado FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID) ON UPDATE CASCADE,
    CONSTRAINT FK_Ventas_Cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID) ON UPDATE CASCADE,
    CONSTRAINT FK_Ventas_Sucursal FOREIGN KEY (SucursalID) REFERENCES Sucursales(SucursalID) ON UPDATE CASCADE
);
GO
--17-----------------------------------------
CREATE TABLE DetalleVentas(
    DetalleID BIGINT IDENTITY(1,1) PRIMARY KEY,
    VentaID BIGINT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_DetalleVentas_Venta FOREIGN KEY (VentaID) REFERENCES Ventas(VentaID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_DetalleVentas_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID) ON UPDATE CASCADE
);
GO
--18-----------------------------------------
CREATE TABLE Facturas(
    FacturaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    VentaID BIGINT UNIQUE NOT NULL,
    NumeroFiscal VARCHAR(45) NOT NULL,
    FechaEmision DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Facturas_Venta FOREIGN KEY (VentaID) REFERENCES Ventas(VentaID) ON DELETE CASCADE ON UPDATE CASCADE
);
GO

CREATE INDEX IX_Ventas_FechaHora ON Ventas(FechaHora);
CREATE INDEX IX_Compras_FechaHora ON Compras(FechaHora);
CREATE INDEX IX_DetalleVentas_ProductoID ON DetalleVentas(ProductoID);
CREATE INDEX IX_DetalleCompras_ProductoID ON DetalleCompras(ProductoID);
GO

--19-----------------------------------------
CREATE TABLE AuditoriaGeneral(
    AuditoriaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    NombreTabla VARCHAR(50) NOT NULL,
    Operacion VARCHAR(10) NOT NULL CHECK (Operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    UsuarioSistema VARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
    UsuarioApp VARCHAR(40) NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    HostName VARCHAR(128) NULL DEFAULT HOST_NAME(),
    AppName VARCHAR(128) NULL DEFAULT APP_NAME(),
    RegistroID VARCHAR(50) NOT NULL,
    ValoresAnteriores NVARCHAR(MAX) NULL,
    ValoresNuevos NVARCHAR(MAX) NULL,
    Observaciones NVARCHAR(500) NULL
);
GO

CREATE INDEX IX_Auditoria_Tabla_Fecha ON AuditoriaGeneral(NombreTabla, FechaHora);
CREATE INDEX IX_Auditoria_Usuario_Fecha ON AuditoriaGeneral(UsuarioSistema, FechaHora);
GO

ALTER TABLE Sucursales
ADD NombreSucursal NVARCHAR(100);

ALTER TABLE Usuarios
ADD NombreUsuario NVARCHAR(50),
    Contrasenia NVARCHAR(100);

ALTER TABLE Roles
ADD NombreRol NVARCHAR(50);

--20. HistorialPrecios

CREATE TABLE HistorialPrecios(
    HistorialID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    PrecioAnterior DECIMAL(10,2) NOT NULL,
    PrecioNuevo DECIMAL(10,2) NOT NULL,
    FechaCambio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioCambio VARCHAR(40) NULL,
    CONSTRAINT FK_HistorialPrecios_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);
GO
--21. DescuentosPromociones
CREATE TABLE DescuentosPromociones(
    DescuentoID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    PorcentajeDescuento DECIMAL(5,2) CHECK (PorcentajeDescuento BETWEEN 0 AND 100),
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    CONSTRAINT FK_Descuentos_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);
GO
--22. DevolucionesVentas

CREATE TABLE DevolucionesVentas(
    DevolucionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    VentaID BIGINT NOT NULL,
    FechaDevolucion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo NVARCHAR(300) NULL,
    CONSTRAINT FK_Devoluciones_Venta FOREIGN KEY (VentaID) REFERENCES Ventas(VentaID)
);
GO
--23. BitacoraAccesos

CREATE TABLE BitacoraAccesos(
    AccesoID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    TipoAcceso VARCHAR(10) CHECK (TipoAcceso IN ('LOGIN','LOGOUT')) NOT NULL,
    IP_Acceso VARCHAR(45) NULL,
    Dispositivo VARCHAR(100) NULL,
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);
GO
--24. ContactosClientes

CREATE TABLE ContactosClientes(
    ContactoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    NombreContacto VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20) NULL,
    Correo VARCHAR(100) NULL,
    Relacion VARCHAR(50) NULL,
    CONSTRAINT FK_Contacto_Cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);
GO
--25. DocumentosAdjuntos

CREATE TABLE DocumentosAdjuntos(
    DocumentoID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TablaReferencia VARCHAR(50) NOT NULL, -- ej: 'Ventas', 'Compras'
    RegistroID VARCHAR(50) NOT NULL,
    NombreArchivo NVARCHAR(100),
    RutaArchivo NVARCHAR(500),
    FechaCarga DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioCarga VARCHAR(40) NULL
);
GO
--26. ConfiguracionSistema

CREATE TABLE ConfiguracionSistema(
    ParametroID INT IDENTITY(1,1) PRIMARY KEY,
    NombreParametro VARCHAR(50) UNIQUE NOT NULL,
    ValorParametro NVARCHAR(300) NOT NULL,
    Descripcion NVARCHAR(500) NULL
);

-- ========================================
-- TABLA 27: LogErroresSistema
-- Registro de errores técnicos del sistema
-- ========================================
CREATE TABLE LogErroresSistema(
    ErrorID BIGINT IDENTITY(1,1) PRIMARY KEY,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MensajeError NVARCHAR(MAX) NOT NULL,
    Procedimiento NVARCHAR(200) NULL,
    Linea INT NULL,
    UsuarioSistema VARCHAR(128) NULL DEFAULT SUSER_SNAME(),
    AppOrigen NVARCHAR(100) NULL
);
GO

-- ========================================
-- TABLA 28: TareasProgramadas
-- Gestión de tareas automáticas del sistema
-- ========================================
CREATE TABLE TareasProgramadas(
    TareaID INT IDENTITY(1,1) PRIMARY KEY,
    NombreTarea NVARCHAR(100) NOT NULL,
    Frecuencia VARCHAR(20) NOT NULL, -- Ej: 'Diaria', 'Semanal'
    HoraEjecucion TIME NOT NULL,
    UltimaEjecucion DATETIME2 NULL,
    Activa BIT NOT NULL DEFAULT 1,
    Descripcion NVARCHAR(500) NULL
);
GO

-- ========================================
-- TABLA 29: NotificacionesSistema
-- Registro de notificaciones enviadas (correo, app, SMS)
-- ========================================
CREATE TABLE NotificacionesSistema(
    NotificacionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NULL,
    ClienteID INT NULL,
    Titulo NVARCHAR(100) NOT NULL,
    Mensaje NVARCHAR(MAX) NOT NULL,
    FechaEnvio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MedioEnvio VARCHAR(30) CHECK (MedioEnvio IN ('Correo', 'App', 'SMS')) NOT NULL,
    CONSTRAINT FK_Notif_Usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID),
    CONSTRAINT FK_Notif_Cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);
GO

-- ========================================
-- TABLA 30: LogsConsultasSQL
-- Auditoría de consultas SQL ejecutadas en el sistema
-- ========================================
CREATE TABLE LogsConsultasSQL(
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NULL,
    ConsultaSQL NVARCHAR(MAX) NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Origen VARCHAR(50) NULL, -- Ej: 'App', 'SSMS'
    CONSTRAINT FK_LogSQL_Usuario FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);
GO

ALTER TABLE Planilla
ADD Periodo NVARCHAR(20),
    Monto DECIMAL(10,2);

ALTER TABLE Turnos ADD Activo BIT DEFAULT 1;