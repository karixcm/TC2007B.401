USE MASTER;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'ComedorBD')
BEGIN
    ALTER DATABASE ComedorBD SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ComedorBD;
    --S�lo si la base de datos marca error porque est� siendo ocupada
END;


--DROP DATABASE IF EXISTS NombreBD;
CREATE DATABASE ComedorBD;
GO

USE ComedorBD;
GO

DROP TABLE IF EXISTS Administrador;
DROP TABLE IF EXISTS Comedor;
DROP TABLE IF EXISTS Asistencia;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Pariente;
DROP TABLE IF EXISTS Inventario;
DROP TABLE IF EXISTS Estado;
DROP TABLE IF EXISTS Condicion;
DROP TABLE IF EXISTS Nacionalidad;
DROP TABLE IF EXISTS Calificaciones;
DROP TABLE IF EXISTS Apertura;
DROP TABLE IF EXISTS Reportes;
DROP TABLE IF EXISTS TipoReporte;
DROP TABLE IF EXISTS Urgencia;

CREATE TABLE Administrador(
	IDAdmin INT PRIMARY KEY IDENTITY(100,1),
	Nombre VARCHAR(50) NOT NULL,
	Apellido1 VARCHAR(50) NOT NULL,
	Apellido2 VARCHAR(50) NOT NULL,
	ContrasenaAdmin VARCHAR(80) NOT NULL
);

--comedor abierto o cerrado
CREATE TABLE Estado(
	IDEstado INT PRIMARY KEY IDENTITY(200,1),
	Estado VARCHAR(15)
);

CREATE TABLE Nacionalidad(
	IDNacionalidad INT PRIMARY KEY IDENTITY(300,1),
	Nac VARCHAR(30)
);

CREATE TABLE Comedor(
	FolioComedor INT PRIMARY KEY,
	Nombre VARCHAR(50) NOT NULL,
	Ubicacion VARCHAR(80) NOT NULL,
	Apertura DATE NOT NULL,
	Usuario VARCHAR(10) NOT NULL UNIQUE, 
	ContraComedor VARCHAR(80) NOT NULL,
	Estado INT NOT NULL
		CONSTRAINT FK_Comedor_Estado FOREIGN KEY (Estado)
		REFERENCES Estado(IDEstado)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

CREATE TABLE Apertura(
	FolioComedor INT NOT NULL
		CONSTRAINT FK_Apertura_Comedor FOREIGN KEY (FolioComedor)
		REFERENCES Comedor(FolioComedor)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	Fecha DATE NOT NULL,
	HoraApertura TIME NOT NULL,
	HoraCierre TIME
);

CREATE TABLE Condicion(
	IDCondicion INT PRIMARY KEY IDENTITY(250,1),
	Cond VARCHAR(50)
);

CREATE TABLE Usuario(
	IDUsuario INT PRIMARY KEY IDENTITY(1000,1),
	Nombre VARCHAR(50) NOT NULL,
	Apellido1 VARCHAR(50) NOT NULL,
	Apellido2 VARCHAR(50) NOT NULL,
	CURP CHAR(18) NOT NULL UNIQUE,
	Nacionalidad INT NOT NULL
		CONSTRAINT FK_Usuario_Nacionalidad FOREIGN KEY (Nacionalidad)
		REFERENCES Nacionalidad(IDNacionalidad)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	Sexo CHAR NOT NULL,
	FechaNac DATE NOT NULL,
	Condicion INT NOT NULL
		CONSTRAINT FK_Usuario_Condicion FOREIGN KEY (Condicion)
		REFERENCES Condicion(IDCondicion)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	Cel VARCHAR(15) UNIQUE,
	Correo VARCHAR(30) UNIQUE
);

CREATE TABLE Pariente(
	Pariente1 INT NOT NULL
		CONSTRAINT FK_Pariente1_Usuario FOREIGN KEY (Pariente1)
		REFERENCES Usuario(IDUsuario)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	Pariente2 INT NOT NULL
		CONSTRAINT FK_Pariente2_Usuario FOREIGN KEY (Pariente2)
		REFERENCES Usuario(IDUsuario)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

CREATE TABLE Asistencia(
	Fecha DATE NOT NULL,
	Donacion INT NOT NULL,
	IDUsuario INT NOT NULL
		CONSTRAINT FK_Asistencia_Usuario FOREIGN KEY (IDUsuario)
		REFERENCES Usuario(IDUsuario)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	FolioComedor INT NOT NULL
		CONSTRAINT FK_Asistencia_Comedor FOREIGN KEY (FolioComedor)
		REFERENCES Comedor(FolioComedor)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

CREATE TABLE Inventario(
	FechaCad DATE NOT NULL,
	Nombre VARCHAR(50) NOT NULL,
	Cantidad INT NOT NULL,
	Presentacion VARCHAR(50) NOT NULL,
	FolioComedor INT NOT NULL
		CONSTRAINT FK_Despensa_Comedor FOREIGN KEY (FolioComedor)
		REFERENCES Comedor(FolioComedor)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

CREATE TABLE Calificaciones(
	IDUsuario INT NOT NULL
		CONSTRAINT FK_Calificaciones_Usuario FOREIGN KEY (IDUsuario)
		REFERENCES Usuario(IDUsuario)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	FolioComedor INT NOT NULL
		CONSTRAINT FK_Calificaciones_Comedor FOREIGN KEY (FolioComedor)
		REFERENCES Comedor(FolioComedor)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	Fecha DATE NOT NULL,
	CalLimpieza INT NOT NULL,
	CalComida INT NOT NULL,
	CalAtencion INT NOT NULL,
	Comentario VARCHAR(150) NOT NULL
);

CREATE TABLE TipoReporte(
	IDReporte INT PRIMARY KEY IDENTITY(210,1),
	Nombre VARCHAR(30)
);

CREATE TABLE Urgencia(
	IDUrgencia INT PRIMARY KEY IDENTITY(220,1),
	Nombre VARCHAR(25)
);

CREATE TABLE Reportes(
	FolioReporte INT PRIMARY KEY IDENTITY(100000, 1),
	FolioComedor INT NOT NULL
		CONSTRAINT FK_Reportes_Comedor FOREIGN KEY (FolioComedor)
		REFERENCES Comedor(FolioComedor)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	Fecha DATE NOT NULL,
	Tipo INT NOT NULL
		CONSTRAINT FK_Reportes_TipoReporte FOREIGN KEY (Tipo)
		REFERENCES TipoReporte(IDReporte)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	Descripcion VARCHAR(250) NOT NULL,
	UrgenciaSol INT NOT NULL
		CONSTRAINT FK_Reportes_Urgencia FOREIGN KEY (UrgenciaSol)
		REFERENCES Urgencia(IDUrgencia)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	Estado INT NOT NULL
);

USE ComedorBD;
GO

--trigger para contrase�as Admin
CREATE OR ALTER TRIGGER TRG_Admin_INSERT
ON Administrador
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @Nombre AS VARCHAR(50);
	DECLARE @Apellido1 AS VARCHAR(50);
	DECLARE @Apellido2 AS VARCHAR(50);
	DECLARE @ContrasenaAdmin AS VARCHAR(64);

	SELECT @Nombre = (SELECT Nombre FROM inserted);
	SELECT @Apellido1 = (SELECT Apellido1 FROM inserted);
	SELECT @Apellido2 = (SELECT Apellido2 FROM inserted);
	SELECT @ContrasenaAdmin = (SELECT ContrasenaAdmin FROM inserted);

	DECLARE @Salt AS VARCHAR(16);
	SELECT @Salt = CONVERT(VARCHAR(16), CRYPT_GEN_RANDOM(8), 2);

	--el select genera el password ya codificado
	DECLARE @HashedPassword AS VARCHAR(80);
	SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt + @ContrasenaAdmin)), 2);
	
	INSERT INTO Administrador(Nombre, Apellido1, Apellido2, ContrasenaAdmin) 
	VALUES (@Nombre, @Apellido1, @Apellido2, @HashedPassword);
END;
GO

--trigger para contrase�as comedor
CREATE OR ALTER TRIGGER TRG_Comedor_INSERT
ON Comedor
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @FolioComedor AS INT;
	DECLARE @Nombre AS VARCHAR(50);
	DECLARE @Ubicacion AS VARCHAR(80);
	DECLARE @Apertura AS DATE;
	DECLARE @Usuario AS VARCHAR(10);
	DECLARE @ContraComedor AS VARCHAR(64);
	DECLARE @Estado AS INT;

	SELECT @FolioComedor = (SELECT FolioComedor FROM inserted);
	SELECT @Nombre = (SELECT Nombre FROM inserted);
	SELECT @Ubicacion = (SELECT Ubicacion FROM inserted);
	SELECT @Apertura = (SELECT Apertura FROM inserted);
	SELECT @Usuario = (SELECT Usuario FROM inserted);
	SELECT @ContraComedor = (SELECT ContraComedor FROM inserted);
	SELECT @Estado = (SELECT Estado FROM inserted);

	DECLARE @Salt AS VARCHAR(16);
	SELECT @Salt = CONVERT(VARCHAR(16), CRYPT_GEN_RANDOM(8), 2);

	--el select genera el password ya codificado
	DECLARE @HashedPassword AS VARCHAR(80);
	SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt + @ContraComedor)), 2);
	
	INSERT INTO Comedor(FolioComedor, Nombre, Ubicacion, Apertura, Usuario, ContraComedor, Estado) 
	VALUES (@FolioComedor, @Nombre, @Ubicacion, @Apertura, @Usuario, @HashedPassword, @Estado);
END;
GO

--trigger para borrado de un usuario
CREATE OR ALTER TRIGGER TRG_Usuario_DELETE
ON Usuario
INSTEAD OF DELETE
AS BEGIN
	BEGIN TRANSACTION;
	DECLARE @IDUsuario AS INT;
	SELECT @IDUsuario = (SELECT IDUsuario FROM deleted);
	DELETE FROM Asistencia WHERE IDUsuario = @IDUsuario;
	DELETE FROM Pariente WHERE Pariente1 = @IDUsuario;
	DELETE FROM Pariente WHERE Pariente2 = @IDUsuario;
	DELETE FROM Usuario WHERE IDUsuario = @IDUsuario;
END;
GO

--trigger para borrado de un comedor
CREATE OR ALTER TRIGGER TRG_Comedor_DELETE
ON Comedor
INSTEAD OF DELETE
AS BEGIN
	BEGIN TRANSACTION;
	DECLARE @FolioComedor AS INT;
	SELECT @FolioComedor = (SELECT FolioComedor FROM deleted);
	DELETE FROM Asistencia WHERE FolioComedor = @FolioComedor;
	DELETE FROM Comedor WHERE FolioComedor = @FolioComedor;
END;
GO

--procedure para alta de un administrador
CREATE OR ALTER PROCEDURE PROC_altaAdmin
	@Nombre VARCHAR(50),
	@Apellido1 VARCHAR(50),
	@Apellido2 VARCHAR(50),
	@ContrasenaAdmin VARCHAR(15),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
        INSERT INTO Administrador(Nombre, Apellido1, Apellido2, ContrasenaAdmin)
		VALUES (@Nombre, @Apellido1, @Apellido2, @ContrasenaAdmin);
        SET @Success = 1;
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH
	RETURN @Success
END;
GO

-- Procedure para alta de un usuario
CREATE OR ALTER PROCEDURE PROC_altaUsuario
    @Nombre VARCHAR(50),
    @Apellido1 VARCHAR(50),
    @Apellido2 VARCHAR(50),
    @CURP CHAR(18),
    @Nacionalidad VARCHAR(30),
    @Sexo CHAR,
    @FechaNac DATE,
    @Condicion VARCHAR(50),
    @Cel VARCHAR(15),
    @Correo VARCHAR(30),
    @NuevoIDUsuario INT OUTPUT,  -- Agregamos un par�metro de salida para el nuevo ID
    @Success BIT OUTPUT
AS
BEGIN
    DECLARE @NacionalidadID INT;
    DECLARE @CondicionID INT;
    
    -- Variable para almacenar el nuevo ID
    DECLARE @IDNuevo INT;

    BEGIN TRY
        SELECT @NacionalidadID = IDNacionalidad FROM Nacionalidad WHERE Nac = @Nacionalidad;
        SELECT @CondicionID = IDCondicion FROM Condicion WHERE Cond = @Condicion;
        IF @NacionalidadID IS NULL OR @CondicionID IS NULL
        BEGIN
            SET @Success = 0;
        END
        ELSE
        BEGIN
            INSERT INTO Usuario(Nombre, Apellido1, Apellido2, CURP, Nacionalidad, Sexo, FechaNac, Condicion, Cel, Correo) 
            VALUES (@Nombre, @Apellido1, @Apellido2, @CURP, @NacionalidadID, @Sexo, @FechaNac, @CondicionID, @Cel, @Correo);

            -- Obtenemos el nuevo ID
            SET @IDNuevo = SCOPE_IDENTITY();
            SET @Success = 1;

            -- Devolver el nuevo ID como una tabla
            SELECT @IDNuevo AS IDUsuario;
        END
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH

    -- No es necesario devolver el nuevo ID aqu�, ya se devuelve dentro del procedimiento
    -- SET @NuevoIDUsuario = @IDNuevo;
    
    RETURN @Success;
END;
GO

--procedure para insertar una calificaci�n
CREATE OR ALTER PROCEDURE PROC_calificar
	@IDUsuario INT,
	@NombreComedor VARCHAR(50),
	@Fecha DATE,
	@CalLimpieza INT,
	@CalComida INT,
	@CalAtencion INT,
	@Comentario VARCHAR(150),
	@Success AS BIT OUTPUT
AS
BEGIN 
	BEGIN TRY
		DECLARE @FolioComedor INT;
		SELECT @FolioComedor = (SELECT FolioComedor FROM Comedor WHERE Nombre LIKE @NombreComedor);
		IF (@Comentario IS NULL)
			BEGIN
				DECLARE @ComentarioVacio AS VARCHAR(15)
				SELECT @ComentarioVacio = 'Sin comentario'
				INSERT INTO Calificaciones(IDUsuario, FolioComedor,Fecha, CalLimpieza, CalComida, CalAtencion, Comentario)
				VALUES (@IDUsuario, @FolioComedor,@Fecha, @CalLimpieza, @CalComida, @CalAtencion, @ComentarioVacio);
				SET @Success = 1;
			END
		ELSE
			BEGIN
				INSERT INTO Calificaciones(IDUsuario, FolioComedor,Fecha, CalLimpieza, CalComida, CalAtencion, Comentario)
				VALUES (@IDUsuario, @FolioComedor,@Fecha, @CalLimpieza, @CalComida, @CalAtencion, @Comentario);
				SET @Success = 1;
			END
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH
	RETURN @Success
END;
GO

--procedure alta comedor
CREATE OR ALTER PROCEDURE PROC_altaComedor
	@FolioComedor INT,
	@Nombre VARCHAR(50),
	@Ubicacion VARCHAR(80),
	@Apertura DATE,
	@Usuario VARCHAR(10),
	@ContraComedor VARCHAR(15),
	@Estado INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		INSERT INTO Comedor(FolioComedor, Nombre, Ubicacion, Apertura, Usuario, ContraComedor, Estado)
		VALUES (@FolioComedor, @Nombre, @Ubicacion, @Apertura, @Usuario, @ContraComedor, @Estado)
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure baja de un comedor
CREATE OR ALTER PROCEDURE PROC_bajaComedor
	@FolioComedor INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @EstadoActual AS INT;
		SELECT @EstadoActual = (SELECT Estado FROM Comedor WHERE FolioComedor LIKE @FolioComedor);
		IF (@EstadoActual = '200')
			BEGIN
				UPDATE Comedor 
				SET Estado = '201' WHERE FolioComedor LIKE @FolioComedor;
				SET @Success = 1;
			END
		ELSE
			BEGIN
				SET @Success = 0;
			END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar condici�n de un usuario
CREATE OR ALTER PROCEDURE PROC_cambioCond
	@FolioUsuario INT,
	@NuevaCond AS VARCHAR(50),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @IDNuevaCond AS INT;
		SELECT @IDNuevaCond = (SELECT IDCondicion FROM Condicion WHERE Cond LIKE @NuevaCond);

		DECLARE @CondActual AS INT;
		SELECT @CondActual = (SELECT Condicion FROM Usuario WHERE IDUsuario LIKE @FolioUsuario);
		IF (@CondActual != @IDNuevaCond)
			BEGIN
				UPDATE Usuario
				SET Condicion = @IDNuevaCond WHERE IDUsuario LIKE @FolioUsuario
				SET @Success = 1;
			END
		ELSE 
			BEGIN
				SET @Success = 0;
			END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure baja de un administrador
CREATE OR ALTER PROCEDURE PROC_bajaAdmin
	@FolioAdmin INT,
	@Success AS BIT OUTPUT
AS 
BEGIN
	BEGIN TRY
		DElETE FROM Administrador WHERE IDAdmin Like @FolioAdmin;
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET	@Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure alta Pariente
CREATE OR ALTER PROCEDURE PROC_altaPariente
	@Pariente1 INT,
	@Pariente2 INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
        INSERT INTO Pariente(Pariente1, Pariente2) VALUES (@Pariente1, @Pariente2);
        SET @Success = 1; 
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH
	RETURN @Success
END;
GO

--procedure baja Pariente
CREATE OR ALTER PROCEDURE PROC_bajaPariente
	@Pariente1 INT,
	@Pariente2 INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
        DELETE FROM Pariente 
        WHERE Pariente1 = @Pariente1 AND Pariente2 = @Pariente2;
        SET @Success = 1;
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar o actualiza n�mero de tel�fono
CREATE OR ALTER PROCEDURE PROC_actualizarCelular
	@IDUsuario INT,
	@NuevoCelular VARCHAR(15),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		UPDATE Usuario SET Cel = @NuevoCelular WHERE IDUsuario LIKE @IDUsuario;
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar o actualizar correo electr�nico
CREATE OR ALTER PROCEDURE PROC_actualizarCorreo
	@IDUsuario INT,
	@NuevoCorreo VARCHAR(30),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		UPDATE Usuario SET Correo = @NuevoCorreo WHERE IDUsuario LIKE @IDUsuario;
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar contrase�a Admin
CREATE OR ALTER PROCEDURE PROC_cambioContraAdmin
	@IDAdmin INT,
	@ContraNueva VARCHAR(64),
	@RepContraNueva VARCHAR(64),
	@Success BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		IF (@ContraNueva != @RepContraNueva)
			BEGIN
				SET @Success = 0;
			END
		ELSE
			BEGIN
				DECLARE @StoredPassword VARCHAR(80);
				SELECT @StoredPassword = (SELECT ContrasenaAdmin FROM Administrador WHERE IDAdmin = @IDAdmin)

				DECLARE @Salt AS VARCHAR(16);
				SELECT @Salt = SUBSTRING(@StoredPassword, 1, 16);

				DECLARE @HashedPassword AS VARCHAR(80);
				SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt+@ContraNueva)), 2);

				IF (@HashedPassword != @StoredPassword)
					BEGIN
						DECLARE @SaltN AS VARCHAR(16);
						SELECT @SaltN = CONVERT(VARCHAR(16), CRYPT_GEN_RANDOM(8), 2);

						--el select genera el password ya codificado
						DECLARE @HashedPasswordN AS VARCHAR(80);
						SELECT @HashedPasswordN = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt + @ContraNueva)), 2);

						UPDATE Administrador SET ContrasenaAdmin = @HashedPasswordN WHERE IDAdmin LIKE @IDAdmin;
						SET @Success = 1;
					END
				ELSE
					BEGIN
						SET @Success = 0;
					END
			END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para verificar inicio de sesi�n del Administrador
CREATE OR ALTER PROCEDURE PROC_logInAdmin
	@IDAdmin INT,
	@Contrasena VARCHAR(80),
	@Success BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @StoredPassword VARCHAR(80);
		SELECT @StoredPassword = (SELECT ContrasenaAdmin FROM Administrador WHERE IDAdmin = @IDAdmin)

		DECLARE @Salt AS VARCHAR(16);
		SELECT @Salt = SUBSTRING(@StoredPassword, 1, 16);

		DECLARE @HashedPassword AS VARCHAR(80);
		SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt+@Contrasena)), 2);

		IF (@HashedPassword = @StoredPassword)
			BEGIN
				SET @Success = 1;
			END
		ELSE
			BEGIN
				SET @Success = 0;
			END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar contrase�a Comedor
CREATE OR ALTER PROCEDURE PROC_cambioContraComedor
	@FolioComedor INT,
	@ContraNueva VARCHAR(64),
	@RepContraNueva VARCHAR(64),
	@Success BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		IF (@ContraNueva != @RepContraNueva)
			BEGIN
				SET @Success = 0;
			END
		ELSE
			BEGIN
				DECLARE @StoredPassword VARCHAR(80);
				SELECT @StoredPassword = (SELECT ContraComedor FROM Comedor WHERE FolioComedor = @FolioComedor)

				DECLARE @Salt AS VARCHAR(16);
				SELECT @Salt = SUBSTRING(@StoredPassword, 1, 16);

				DECLARE @HashedPassword AS VARCHAR(80);
				SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt+@ContraNueva)), 2);

				IF (@HashedPassword != @StoredPassword)
					BEGIN
						DECLARE @SaltN AS VARCHAR(16);
						SELECT @SaltN = CONVERT(VARCHAR(16), CRYPT_GEN_RANDOM(8), 2);

						--el select genera el password ya codificado
						DECLARE @HashedPasswordN AS VARCHAR(80);
						SELECT @HashedPasswordN = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt + @ContraNueva)), 2);

						UPDATE Comedor SET ContraComedor = @HashedPasswordN WHERE FolioComedor LIKE @FolioComedor;
						SET @Success = 1;
					END
				ELSE
					BEGIN
						SET @Success = 0;
					END
			END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para verificar inicio de sesi�n del Comedor
CREATE OR ALTER PROCEDURE PROC_logInComedor
	@Usuario VARCHAR(10),
	@Contrasena VARCHAR(80),
	@Success BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @StoredPassword VARCHAR(80);
		SELECT @StoredPassword = (SELECT ContraComedor FROM Comedor WHERE Usuario = @Usuario)

		DECLARE @Salt AS VARCHAR(16);
		SELECT @Salt = SUBSTRING(@StoredPassword, 1, 16);

		DECLARE @HashedPassword AS VARCHAR(80);
		SELECT @HashedPassword = @Salt + CONVERT(VARCHAR(64), (HASHBYTES('SHA2_256', @Salt+@Contrasena)), 2);

		IF (@HashedPassword = @StoredPassword)
			BEGIN
				SET @Success = 1;
			END
		ELSE
			BEGIN
				SET @Success = 0;
			END
		SELECT FolioComedor, Nombre FROM Comedor WHERE Usuario LIKE @Usuario;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure que genera el comedor del mes
CREATE OR ALTER PROCEDURE PROC_comedorDelMes
    @mes INT,
    @anio INT
AS
BEGIN
    WITH PromedioCategorias AS (
        SELECT C.FolioComedor,
               AVG(C.CalLimpieza) AS PromedioLimpieza,
               AVG(C.CalComida) AS PromedioComida,
               AVG(C.CalAtencion) AS PromedioAtencion
        FROM Calificaciones AS C
        WHERE MONTH(C.Fecha) = @mes AND YEAR(C.Fecha) = @anio
        GROUP BY C.FolioComedor
    )
    SELECT TOP 1 FolioComedor, PromedioLimpieza, PromedioComida, PromedioAtencion
    FROM PromedioCategorias
    ORDER BY (PromedioLimpieza + PromedioComida + PromedioAtencion) DESC;
END;
GO

--procedure que regresa una lista ordenada de mejor a peor calificados los comedores
CREATE OR ALTER PROCEDURE PROC_ordenMejoresComedores
    @mes INT,
    @anio INT
AS
BEGIN
    WITH PromedioCategorias AS (
        SELECT C.FolioComedor,
               AVG(C.CalLimpieza) AS PromedioLimpieza,
               AVG(C.CalComida) AS PromedioComida,
               AVG(C.CalAtencion) AS PromedioAtencion
        FROM Calificaciones AS C
        WHERE MONTH(C.Fecha) = @mes AND YEAR(C.Fecha) = @anio
        GROUP BY C.FolioComedor
    )
    SELECT C.Nombre AS NombreComedor
    FROM PromedioCategorias AS PC
    INNER JOIN Comedor AS C ON PC.FolioComedor = C.FolioComedor
    ORDER BY (PC.PromedioLimpieza + PC.PromedioComida + PC.PromedioAtencion) DESC;
END;
GO



--procedure para ingresar un nuevo alimento
CREATE OR ALTER PROCEDURE PROC_agregarInventario
	@FechaCad DATE,
	@Nombre VARCHAR(50),
	@Cantidad INT,
	@Presentacion VARCHAR(50),
	@FolioComedor INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		INSERT INTO Inventario(FechaCad, Nombre, Cantidad, Presentacion, FolioComedor)
		VALUES (@FechaCad, @Nombre, @Cantidad, @Presentacion, @FolioComedor);
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para cambiar cantidad de algo en el inventario
CREATE OR ALTER PROCEDURE PROC_actualizarInventario
	@FechaCad DATE,
	@Nombre VARCHAR(50),
	@NuevaCant INT,
	@FolioComedor INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		UPDATE Inventario
		SET Cantidad = @NuevaCant 
		WHERE FolioComedor LIKE @FolioComedor AND FechaCad LIKE @FechaCad AND Nombre LIKE @Nombre;
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure login usuario con el ID
CREATE OR ALTER PROCEDURE PROC_loginUsuarioID
	@IDUsuario INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @UserCount INT
		SELECT @UserCount = COUNT(*) FROM Usuario WHERE IDUsuario = @IDUsuario

		IF @UserCount > 0
		BEGIN
			SET @Success = 1;
			SELECT U.IDUsuario, U.Nombre, U.Apellido1, U.Apellido2, U.CURP, 
				N.Nac AS Nacionalidad, U.Sexo, U.FechaNac, C.Cond AS Condicion, 
				U.Cel, U.Correo
			FROM Usuario U
			LEFT JOIN Nacionalidad N ON U.Nacionalidad = N.IDNacionalidad
			LEFT JOIN Condicion C ON U.Condicion = C.IDCondicion
			WHERE U.IDUsuario = @IDUsuario;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0
	END CATCH
	RETURN @Success
END;
GO

--procedure login usuario con el CURP
CREATE OR ALTER PROCEDURE PROC_loginUsuarioCURP
	@CURP CHAR(18),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @UserCount INT
		SELECT @UserCount = COUNT(*) FROM Usuario WHERE CURP = @CURP

		IF @UserCount > 0
		BEGIN
			SET @Success = 1;
			SELECT U.IDUsuario, U.Nombre, U.Apellido1, U.Apellido2, U.CURP, 
				N.Nac AS Nacionalidad, U.Sexo, U.FechaNac, C.Cond AS Condicion, 
				U.Cel, U.Correo
			FROM Usuario U
			LEFT JOIN Nacionalidad N ON U.Nacionalidad = N.IDNacionalidad
			LEFT JOIN Condicion C ON U.Condicion = C.IDCondicion
			WHERE U.CURP = @CURP;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0
	END CATCH
	RETURN @Success
END;
GO

--procedure login usuario con el celular
CREATE OR ALTER PROCEDURE PROC_loginUsuarioCelular
	@Celular VARCHAR(15),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @UserCount INT
		SELECT @UserCount = COUNT(*) FROM Usuario WHERE Cel = @Celular

		IF @UserCount > 0
		BEGIN
			SET @Success = 1;
			SELECT U.IDUsuario, U.Nombre, U.Apellido1, U.Apellido2, U.CURP, 
				N.Nac AS Nacionalidad, U.Sexo, U.FechaNac, C.Cond AS Condicion, 
				U.Cel, U.Correo
			FROM Usuario U
			LEFT JOIN Nacionalidad N ON U.Nacionalidad = N.IDNacionalidad
			LEFT JOIN Condicion C ON U.Condicion = C.IDCondicion
			WHERE U.Cel = @Celular;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0
	END CATCH
	RETURN @Success
END;
GO

--procedure login usuario con el correo
CREATE OR ALTER PROCEDURE PROC_loginUsuarioCorreo
	@Correo VARCHAR(30),
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @UserCount INT
		SELECT @UserCount = COUNT(*) FROM Usuario WHERE Correo = @Correo

		IF @UserCount > 0
		BEGIN
			SET @Success = 1;
			SELECT U.IDUsuario, U.Nombre, U.Apellido1, U.Apellido2, U.CURP, 
				N.Nac AS Nacionalidad, U.Sexo, U.FechaNac, C.Cond AS Condicion, 
				U.Cel, U.Correo
			FROM Usuario U
			LEFT JOIN Nacionalidad N ON U.Nacionalidad = N.IDNacionalidad
			LEFT JOIN Condicion C ON U.Condicion = C.IDCondicion
			WHERE U.Correo = @Correo;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0
	END CATCH
	RETURN @Success
END;
GO

--procedure que genera la tabla con la cuenta de usuarios por pa�s al que pertenecen
CREATE OR ALTER PROCEDURE PROC_statsPaises
AS
BEGIN
    CREATE TABLE #TablaCuentaPorNacionalidad (
        Nacionalidad VARCHAR(50),
        Usuarios INT
    )

    INSERT INTO #TablaCuentaPorNacionalidad (Nacionalidad, Usuarios)
    SELECT
        N.Nac AS Nacionalidad,
        COUNT(U.IDUsuario) AS Cuenta
    FROM
        Nacionalidad N
    INNER JOIN
        Usuario U ON N.IDNacionalidad = U.Nacionalidad
    GROUP BY
        N.Nac

    SELECT * FROM #TablaCuentaPorNacionalidad
    DROP TABLE #TablaCuentaPorNacionalidad
END;
GO

--procedure que genera la tabla con la cuenta de usuarios por condici�n
CREATE OR ALTER PROCEDURE PROC_statsCondicion
AS
BEGIN
    CREATE TABLE #TablaCuentaPorCondicion (
        Condicion VARCHAR(100),
        Usuarios INT
    )

    INSERT INTO #TablaCuentaPorCondicion (Condicion, Usuarios)
    SELECT
        C.Cond AS Condicion,
        COUNT(U.IDUsuario) AS Cuenta
    FROM
        Condicion C
    INNER JOIN
        Usuario U ON C.IDCondicion = U.Condicion
    GROUP BY
        C.Cond

    SELECT * FROM #TablaCuentaPorCondicion
    DROP TABLE #TablaCuentaPorCondicion
END;
GO

--Procedure que cuenta a las personas registradas en el comedor que est�n en situaci�n de calle y sean mexicanas
CREATE OR ALTER PROCEDURE PROC_contarPersonasSinHogarMexicanas
AS
BEGIN
    DECLARE @Cuenta INT
    SELECT @Cuenta = COUNT(U.IDUsuario)
    FROM Usuario U
    WHERE U.Condicion = (SELECT IDCondicion FROM Condicion WHERE Cond = 'Persona en condici�n de calle')
    AND U.Nacionalidad = (SELECT IDNacionalidad FROM Nacionalidad WHERE Nac = 'M�xico')
    PRINT 'N�mero de personas en situaci�n de calle de nacionalidad mexicana: ' + CAST(@Cuenta AS VARCHAR)
END;
GO

--procedure para obtener todos familiares de un usuario
CREATE OR ALTER PROCEDURE PROC_buscarFamiliares
    @Pariente1 INT
AS
BEGIN
    SELECT U.IDUsuario, U.Nombre, U.Apellido1, U.Apellido2
    FROM Usuario AS U
    INNER JOIN Pariente AS P ON U.IDUsuario = P.Pariente2
    WHERE P.Pariente1 = @Pariente1;
END;
GO

--procedure para registrar asistencia
CREATE OR ALTER PROCEDURE PROC_registrarAsistencia
	@Fecha DATE,
	@Donacion INT,
	@IDUsuario INT,
	@FolioComedor INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		INSERT INTO Asistencia(Fecha, Donacion, IDUsuario, FolioComedor)
		VALUES (@Fecha, @Donacion, @IDUsuario, @FolioComedor)
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success;
END;
GO

--procedure para sumar los asistentes en un comedor en un d�a
CREATE OR ALTER PROCEDURE PROC_sumarAsistentes
    @Fecha DATE,
    @FolioComedor INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS TotalAsistentesEnComedor
    FROM Asistencia
    WHERE Fecha = @Fecha AND FolioComedor = @FolioComedor;
END;
GO


--procedure que genera la lista de todos los comedores activos
CREATE OR ALTER PROCEDURE PROC_listaComedores
AS
BEGIN
	SELECT Nombre FROM Comedor WHERE Estado LIKE 200
END;
GO

--procedure para sacar promedio de calificaciones semanal de un comedor
CREATE OR ALTER PROCEDURE PROC_promedioCalSemanal
	@FolioComedor INT,
	@FechaInicio DATE,
	@FechaFin DATE
AS
BEGIN
	SELECT
		AVG(CalLimpieza) AS PromedioLimpieza,
		AVG(CalComida) AS PromedioComida,
		AVG(CalAtencion) AS PromedioAtencion
	FROM Calificaciones
	WHERE FolioComedor = @FolioComedor
	AND Fecha BETWEEN @FechaInicio AND @FechaFin;
END;
GO

--procedure para sumar las ganancias de un comedor en un d�a
CREATE OR ALTER PROCEDURE PROC_gananciasHoy
	@FolioComedor INT,
	@Fecha DATE,
	@TotalGanancias INT OUTPUT
AS
BEGIN
	DECLARE @GananciaHoy AS INT
	SELECT @GananciaHoy = COUNT(*) FROM Asistencia WHERE FolioComedor = @FolioComedor AND Fecha = @Fecha AND Donacion = '0';
	DECLARE @Total AS INT;
	SELECT @Total = (@GananciaHoy * 13);
	SET @TotalGanancias = @Total;
	SELECT @TotalGanancias AS GananciasHoy
	PRINT @Total;
END;
GO

--procedure para sumar las ganancias de un comedor en un mes
CREATE OR ALTER PROCEDURE PROC_gananciasFechas
	@FolioComedor INT,
	@FechaInicio DATE,
	@FechaFin DATE,
	@TotalGananciasPeriodo INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TotalA AS INT
	SELECT @TotalA = COUNT(*) FROM Asistencia WHERE FolioComedor = @FolioComedor AND Fecha BETWEEN @FechaInicio AND @FechaFin AND Donacion = '0';
	DECLARE @TotalGanancias AS INT;
	SELECT @TotalGanancias = (@TotalA * 13);
	SET @TotalGananciasPeriodo = @TotalGanancias
	PRINT @TotalGanancias;
END;
GO

--procedure para generar una lista de ganancias semanales de los comedores
CREATE OR ALTER PROCEDURE PROC_listaGananciasPorComedor
	@FechaInicio DATE,
	@FechaFin DATE
AS
BEGIN
	SET NOCOUNT ON;

	SELECT FolioComedor, SUM(13) AS GananciaTotal
	FROM Asistencia
	WHERE Fecha BETWEEN @FechaInicio AND @FechaFin
	      AND Donacion = '0'
	GROUP BY FolioComedor
	HAVING SUM(13) IS NOT NULL
	ORDER BY FolioComedor;
END;
GO

--procedure para generar la hora de apertura
CREATE OR ALTER PROCEDURE PROC_apertura
	@FolioComedor INT,
	@Fecha DATE,
	@HoraApertura TIME,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		INSERT INTO Apertura(FolioComedor, Fecha, HoraApertura, HoraCierre)
		VALUES (@FolioComedor, @Fecha, @HoraApertura, NULL);
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
END;
GO

--procedure para generar la hora de cierre
CREATE OR ALTER PROCEDURE PROC_cierre
	@FolioComedor INT,
	@Fecha DATE,
	@HoraCierre TIME,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		UPDATE Apertura
		SET HoraCierre = @HoraCierre
		WHERE FolioComedor = @FolioComedor AND Fecha = @Fecha;
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
END;
GO

--procedure para generar un reporte
CREATE OR ALTER PROCEDURE PROC_generarReporte
	@FolioComedor INT,
	@Fecha DATE,
	@Tipo VARCHAR(30),
	@Descripcion VARCHAR(250),
	@Urgencia VARCHAR(25),
	@Estado INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @IDTipo INT;
		SELECT @IDTipo = (SELECT IDReporte FROM TipoReporte WHERE Nombre LIKE @Tipo);
		DECLARE @IDUrgencia INT;
		SELECT @IDUrgencia = (SELECT IDUrgencia FROM Urgencia WHERE Nombre LIKE @Urgencia);
		INSERT INTO Reportes(FolioComedor, Fecha, Tipo, Descripcion, UrgenciaSol, Estado)
		VALUES (@FolioComedor, @Fecha, @IDTipo, @Descripcion, @IDUrgencia, @Estado);
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO


--procedure para marcar reporte como completado
CREATE OR ALTER PROCEDURE PROC_marcarReporteCompletado
	@FolioReporte INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @EstadoActual INT;
		SELECT @EstadoActual = (SELECT Estado FROM Reportes WHERE FolioReporte LIKE @FolioReporte);
		IF (@EstadoActual != 1)
		BEGIN
			UPDATE Reportes
			SET Estado = '1'
			WHERE FolioReporte LIKE @FolioReporte;
			SET @Success = 1;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para marcar reporte como no completado
CREATE OR ALTER PROCEDURE PROC_marcarReporteNoCompletado
	@FolioReporte INT,
	@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @EstadoActual INT;
		SELECT @EstadoActual = (SELECT Estado FROM Reportes WHERE FolioReporte LIKE @FolioReporte);
		IF (@EstadoActual != 0)
		BEGIN
			UPDATE Reportes
			SET Estado = '0'
			WHERE FolioReporte LIKE @FolioReporte;
			SET @Success = 1;
		END
		ELSE
		BEGIN
			SET @Success = 0;
		END
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para filtrar reportes completados
CREATE OR ALTER PROCEDURE PROC_reportesCompletados
AS
BEGIN
	SELECT* FROM Reportes WHERE Estado LIKE '1';
END;
GO

--procedure para filtrar reportes no completados
CREATE OR ALTER PROCEDURE PROC_reportesNoCompletados
AS
BEGIN
	SELECT* FROM Reportes WHERE Estado LIKE '0';
END;
GO

--procedure para obtener el id de usuario a partir del curp
CREATE OR ALTER PROCEDURE PROC_obtenerIDcCURP
	@CURP CHAR(18)
AS
BEGIN
	SELECT IDUsuario FROM Usuario WHERE CURP LIKE @CURP;
END;
GO

--procedure para obtener el id de usuario a partir del cel
CREATE OR ALTER PROCEDURE PROC_obtenerIDcCel
	@Cel VARCHAR(15)
AS
BEGIN
	SELECT IDUsuario FROM Usuario WHERE Cel LIKE @Cel;
END;
GO

--procedure para obtener el id de usuario a partir del correo
CREATE OR ALTER PROCEDURE PROC_obtenerIDcCorreo
	@Correo VARCHAR(30)
AS
BEGIN
	SELECT IDUsuario FROM Usuario WHERE Correo LIKE @Correo;
END;
GO

--procedure para generar el inventario de un comedor
CREATE OR ALTER PROCEDURE PROC_inventarioCom
	@FolioComedor INT
AS
BEGIN
	SELECT Cantidad, Nombre, Presentacion, FechaCad FROM Inventario WHERE FolioComedor LIKE @FolioComedor;
END;
GO

USE ComedorBD
GO

INSERT INTO Estado(Estado) VALUES ('Activo');
INSERT INTO Estado(Estado) VALUES ('Cerrado');
INSERT INTO Estado(Estado) VALUES ('Suspendido');
GO

INSERT INTO Nacionalidad(Nac) VALUES ('M�xico');
INSERT INTO Nacionalidad(Nac) VALUES ('Guatemala');
INSERT INTO Nacionalidad(Nac) VALUES ('El Salvador');
INSERT INTO Nacionalidad(Nac) VALUES ('Chile');
INSERT INTO Nacionalidad(Nac) VALUES ('Brasil');
INSERT INTO Nacionalidad(Nac) VALUES ('Per�');
INSERT INTO Nacionalidad(Nac) VALUES ('Honduras');
INSERT INTO Nacionalidad(Nac) VALUES ('Bolivia');
INSERT INTO Nacionalidad(Nac) VALUES ('Venezuela');
INSERT INTO Nacionalidad(Nac) VALUES ('Ecuador');
INSERT INTO Nacionalidad(Nac) VALUES ('Cuba');
INSERT INTO Nacionalidad(Nac) VALUES ('Belice');
INSERT INTO Nacionalidad(Nac) VALUES ('Uruguay');
INSERT INTO Nacionalidad(Nac) VALUES ('Argentina');
INSERT INTO Nacionalidad(Nac) VALUES ('Republica Dominicana');
INSERT INTO Nacionalidad(Nac) VALUES ('Nicaragua');
INSERT INTO Nacionalidad(Nac) VALUES ('Costa Rica');
GO

INSERT INTO Condicion(Cond) VALUES ('Persona mayor de 60 a�os');
INSERT INTO Condicion(Cond) VALUES ('Menor de edad');
INSERT INTO Condicion(Cond) VALUES ('Persona ind�gena');
INSERT INTO Condicion(Cond) VALUES ('Persona con discapacidad');
INSERT INTO Condicion(Cond) VALUES ('Persona perteneciente al colectivo LGBTQ+');
INSERT INTO Condicion(Cond) VALUES ('Migrante o desplazado por conflictos');
INSERT INTO Condicion(Cond) VALUES ('Persona en condici�n de calle');
INSERT INTO Condicion(Cond) VALUES ('Mujer embarazada');
INSERT INTO Condicion(Cond) VALUES ('Trabajador/a informal');
INSERT INTO Condicion(Cond) VALUES ('Otra condici�n');
INSERT INTO Condicion(Cond) VALUES ('No aplica');
--SELECT* FROM Condicion
GO

INSERT INTO TipoReporte(Nombre) VALUES ('Reporte de seguridad');
INSERT INTO TipoReporte(Nombre) VALUES ('Reporte de salud e higiene');
INSERT INTO TipoReporte(Nombre) VALUES ('Reporte de incidentes');
INSERT INTO TipoReporte(Nombre) VALUES ('Reporte de mantenimiento');
INSERT INTO TipoReporte(Nombre) VALUES ('Otro');
GO

INSERT INTO Urgencia(Nombre) VALUES ('Inmediato');
INSERT INTO Urgencia(Nombre) VALUES ('Menos de 30 minutos');
INSERT INTO Urgencia(Nombre) VALUES ('Menos de 2 horas');
INSERT INTO Urgencia(Nombre) VALUES ('Antes de 24 horas');
INSERT INTO Urgencia(Nombre) VALUES ('Antes de 72 horas');
INSERT INTO Urgencia(Nombre) VALUES ('Sin rango asignado');
GO

--SELECT* FROM Usuario
DECLARE @NuevoIDUsuario INT
DECLARE @Success AS BIT
EXEC PROC_altaUsuario 'Karla','Cruz','Mu�iz','CUMK030414MDFRXRA9','M�xico','F','1990-04-14','No aplica','5567866976','karla.cruzmz@gmail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Leonel','Cruz','Alc�ntara','CUAL021125HVERXRA9','Guatemala','F','1982-11-25','No aplica','5532544142','leonelcalc@gmail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Erik','Soto','Cano','CUDKE85H4NME96HJF9', 'Argentina','F','1991-04-25','Persona perteneciente al colectivo LGBTQ+','5567890987','erik@mail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Brisa','Estrada','Ortiz','EAOBRUEIT854HFMD38','El Salvador','F','1975-05-28','Mujer embarazada','5589723423','brisa@mail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Juan','Carlo','Carro','JCS234HDGS6789JDH7','Argentina','F','1980-06-12','Persona en condici�n de calle','5567890987','juanca@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Pepe','Luis','Moreno','HSJDKSEWUTYFHD7856','Cuba','M','1960-07-12','No aplica','5585463275','pepeca@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Patricio','Gonzales','Romo','M6GDSTEXUASYWE7856','M�xico','F','1950-07-13','Persona en condici�n de calle','5657863426','pattgonro@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Lorena','Delgado','Mendonza','LDMREHDUS85746FHC7','Guatemala','F','1982-08-10','Trabajador/a informal','5576859403','lorenitadm1404@hotmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Lauren','Soria','Castro','HIJDJSNE38475HFJD9','Republica Dominicana','F','2001-03-14','Menor de edad','5674839203','lauso@mail.mx',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Santiago','Mondragon','Sanchez','SANTHI67DH47FH28EK','El Salvador','M','2001-10-19','Persona ind�gena','5647890987','santimond@yahoo.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Carla','Jimena','Ximena','CAJIXI345627DIKJ87','Guatemala','F','1998-06-02','Migrante o desplazado por conflictos','5512312345','carlajimxim@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Estefania','Luz','Miranda','KSJDHFY78473JFUR89','Bolivia','F','1968-09-08','Otra condici�n','5584569867','estf@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Karla','Cruz','Mu�iz','CUMK030124MDFRXRA9','M�xico','F','1953-04-14','No aplica','55678669743','karla.cruzm@gmail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Leonel','Cruz','Alc�ntara','CUAL012125HVERXRA9','Guatemala','M','1945-11-25','No aplica','5232544142','leoelcalc@gmail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Erik','Soto','Cano','CUDKE85H4NME34HJF9', 'M�xico','M','1997-04-25','Persona perteneciente al colectivo LGBTQ+','5567330987','eri@mail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Brisa','Estrada','Ortiz','EAOBRUEIT654HFMD38','El Salvador','F','1982-05-28','Mujer embarazada','558972223','bris@mail.com', @NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Juan','Carlo','Carro','JCS234HDGS6723JDH7','Nicaragua','M','1965-06-12','Persona en condici�n de calle','5167890987','juanc@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Pepe','Luis','Moreno','HSJDKSEWUTYFHD1256','M�xico','M','1970-07-12','No aplica','5585343275','pepec@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Patricio','Gonzales','Romo','M6GDSTEXUASYWE3356','Brasil','M','1983-07-13','Persona en condici�n de calle','5655663426','pattgonr@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Lorena','Delgado','Mendonza','LDMREHDUS85446FHC7','Guatemala','F','1990-08-10','Trabajador/a informal','5576859783','lorenitad1404@hotmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Lauren','Soria','Castro','HIJDJSNE38475HFJt9','Republica Dominicana','F','1993-03-14','Menor de edad','5674839234','laus@mail.mx',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Santiago','Mondragon','Sanchez','SANTHI672347FH28EK','El Salvador','M','1960-10-19','Persona ind�gena','5647890217','santimnd@yahoo.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
EXEC PROC_altaUsuario 'Carla','Jimena','Ximena','CAJIXI345627DIKJ17','Guatemala','F','1978-06-02','Migrante o desplazado por conflictos','5512329345','carlajmxim@gmail.com',@NuevoIDUsuario OUTPUT, @Success OUTPUT;
--SELECT @NuevoIDUsuario AS IDUsuario
SELECT @Success AS Success
--SELECT* FROM Usuario
GO

DECLARE @Success AS BIT
EXEC PROC_altaPariente '1000', '1001', @Success OUTPUT;
EXEC PROC_altaPariente '1002', '1003', @Success OUTPUT;
EXEC PROC_altaPariente '1000', '1002', @Success OUTPUT;
EXEC PROC_altaPariente '1000', '1003', @Success OUTPUT;
EXEC PROC_altaPariente '1000', '1004', @Success OUTPUT;
EXEC PROC_altaPariente '1000', '1005', @Success OUTPUT;
EXEC PROC_altaPariente '1001', '1007', @Success OUTPUT;
EXEC PROC_altaPariente '1001', '1002', @Success OUTPUT;
EXEC PROC_altaPariente '1001', '1003', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Pariente
GO

--SELECT* FROM Administrador
DECLARE @Success AS BIT
EXEC PROC_altaAdmin '�ngel','Schiaffini','Rodr�guez','angelito123', @Success OUTPUT;
EXEC PROC_altaAdmin 'Stefania','Cruz','Mu�iz','karicitabonita', @Success OUTPUT;
EXEC PROC_altaAdmin 'Maximiliano','Lecona','Nieves','maxi345', @Success OUTPUT;
EXEC PROC_altaAdmin 'Joahan','Garc�a','Fernandez','joahancin', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Administrador
GO

--SELECT* FROM Comedor
DECLARE @Success AS BIT
EXEC PROC_altaComedor '01','Cinco de Mayo','Calle Porfirio Diaz #25 Col. 5 de Mayo','2022-08-23','Com01','DIFATCOM01','200', @Success OUTPUT;
EXEC PROC_altaComedor '02','M�xico 86','Calle Italia #53 Col. M�xico','2023-08-23','Com02','DIFATCOM02','200', @Success OUTPUT;
EXEC PROC_altaComedor '03','Cardenas del Rio','Calle Gral. C�rdenas del R�o Mz 14 Lt 10','2022-08-23','Com03','DIFATCOM03','201', @Success OUTPUT;
EXEC PROC_altaComedor '04','Monte Mar�a','Calle Monte Real Mz 406 Lt 11 Col. Lomas del Monte Maria','2022-08-23','Com04','DIFATCOM04','200', @Success OUTPUT;
EXEC PROC_altaComedor '05','Margarita Maza','Calle Francisco Javier Mina #12, Col. Margarita Maza dde Ju�rez','2022-08-23','Com05','DIFATCOM05','200', @Success OUTPUT;
EXEC PROC_altaComedor '06','Cerro Grande','Calle Teotihuacan #15 Col. Cerro Grande','2023-01-30','Com06','DIFATCOM06','200', @Success OUTPUT;
EXEC PROC_altaComedor '07','Amp Pe�itas','Cda Gardenias #3 Col. Amp Pe�itas','2022-08-30','Com07','DIFATCOM07','200', @Success OUTPUT;
EXEC PROC_altaComedor '08','San Jose Jaral 2','Calle Jazm�n #22 Col. San Jose el Jaral','2022-08-30','Com08','DIFATCOM08','200', @Success OUTPUT;
EXEC PROC_altaComedor '09','San Jose Jaral 1','Calle Clavelinas #24 Col. San Jose el Jaral','2022-08-30','Com09','DIFATCOM09','201', @Success OUTPUT;
EXEC PROC_altaComedor '10','Amp. Emiliana Zapata','Av. Ej�rcito Mexicano s/n, Col. Ampl. Emiliano Zapata','2022-08-30','Com10','DIFATCOM10','200', @Success OUTPUT;
EXEC PROC_altaComedor '11','DIF Central','Av. Ruiz Cortines esq. Acambay Lomas de Atizap�n','2022-09-08','Com11','DIFATCOM11','200', @Success OUTPUT;
EXEC PROC_altaComedor '12','Los Olivos','Av Jalisco s/n Casa de la Juventud','2022-09-09','Com12','DIFATCOM12','201', @Success OUTPUT;
EXEC PROC_altaComedor '13','Adolfo Lopez Mateos','Adolfo Lopez Mateos, Privada Zacatecas no.6','2022-09-08','Com13','DIFATCOM13','200', @Success OUTPUT;
EXEC PROC_altaComedor '14','Hogares','Retorno de la Tranquilidad no.8A, Hogares de Atizap�n','2022-09-12','Com14','DIFATCOM14','200', @Success OUTPUT;
EXEC PROC_altaComedor '15','Rinconada Bonfil','Rinconada Bonfil Calle Rosas Mz 4 Lt 15','2022-06-09','Com15','DIFATCOM15','200', @Success OUTPUT;
EXEC PROC_altaComedor '16','San juan Bosco','San Juan Bosco, Calle Profesor Roberto Barrio no.2','2022-09-23','Com16','DIFATCOM16','200', @Success OUTPUT;
EXEC PROC_altaComedor '17','Mexico Nuevo','Pioneros de Rochandell esquina con calle Veracruz S/N Col. Mexico Nuevo (Deportivo)','2022-09-26','Com17','DIFATCOM17','201', @Success OUTPUT;
EXEC PROC_altaComedor '18','Las Pe�itas','Pe�itas. Mirador # 100 Col. Las Pe�itas','2022-09-26','Com18','DIFATCOM18','200', @Success OUTPUT;
EXEC PROC_altaComedor '19','Rancho Castro','Rancho Castro, Calle del Puerto s/n Rancho sal�n de usos m�ltiplos','2022-09-23','Com19','DIFATCOM19','200', @Success OUTPUT;
EXEC PROC_altaComedor '20','Villas de las Palmas','Villas de las palmas Calle avena Mz. 5 Lt. 12 col. Amp villa de las Palmas','2022-09-23','Com20','DIFATCOM20','200', @Success OUTPUT;
EXEC PROC_altaComedor '21','UAM','Calle Ingenieria Industrial Mz 24 Lt 45 Col. UAM','2022-10-04','Com21','DIFATCOM21','200', @Success OUTPUT;
EXEC PROC_altaComedor '22','Bosques de Ixtacala','Cerrada Sauces Mz 12 Lt 13- C #6 col.Bosques de Ixtacala','2022-10-05','Com22','DIFATCOM22','200', @Success OUTPUT;
EXEC PROC_altaComedor '23','Lomas de Tepalcapa','Calle seis #14 Colonia Lomas de Tepalcapa','2022-10-17','Com23','DIFATCOM23','200', @Success OUTPUT;
EXEC PROC_altaComedor '24','Villa de las Torres','Calle Villa Alba Mza. 17 lote 9, esquina Bicentenario, Col. Villa de las Torres','2022-10-18','Com24','DIFATCOM24','200', @Success OUTPUT;
EXEC PROC_altaComedor '25','Cristobal Higuera','Cristobal Higuera - Calle Sand�a # 24. Col. Prof. Cristobal Higuera','2022-10-18','Com25','DIFATCOM25','200', @Success OUTPUT;
EXEC PROC_altaComedor '26','Lomas de Guadalupe','Lomas de Guadalupe - Calle Vicente Guerrero N�mero 2, Colonia Lomas de Guadalupe','2022-10-19','Com26','DIFATCOM26','200', @Success OUTPUT;
EXEC PROC_altaComedor '27','Lazara Cardenas','L�zaro Cardenas - Calle Chihuahua 151-A Col. L�zaro Cardenas','2022-10-21','Com27','DIFATCOM27','200', @Success OUTPUT;
EXEC PROC_altaComedor '28','El Chaparral','El Chaparral - Calle T�can # 48. Colonia el Chaparral','2022-10-21','Com28','DIFATCOM28','200', @Success OUTPUT;
EXEC PROC_altaComedor '29','Primero de Septiembre','Primero de Septiembre - Calle Belisario Dominguez Colonia 44 Primero de Septiembre','2022-11-17','Com29','DIFATCOM29','200', @Success OUTPUT;
EXEC PROC_altaComedor '30','Las Aguilas','Las Aguilas - Pavo Real # 18 Colonia de las Aguilas','2022-11-25','Com30','DIFATCOM30','200', @Success OUTPUT;
EXEC PROC_altaComedor '31','El Cerrito','El Cerrito. Paseo Buenavista # 1Col. El Cerrito','2022-11-23','Com31','DIFATCOM31','200', @Success OUTPUT;
EXEC PROC_altaComedor '32','Villas de la Hacienda','Calle de las Chaparreras #5 Col. Villas de la Hacienda','2023-09-01','Com32','DIFATCOM32','200', @Success OUTPUT;
EXEC PROC_altaComedor '33','Seguridad Publica','Seguridad Publica','2023-09-03','Com33','DIFATCOM33','200', @Success OUTPUT;
EXEC PROC_altaComedor '34','San Juan Ixtacala Plano Norte 1','Loma San Juan 194.San Juan Ixtacala Plano Norte','2023-03-14','Com34','DIFATCOM34','200', @Success OUTPUT;
EXEC PROC_altaComedor '35','Prados de Ixtacala 2DA SECC.','Clavel no. 13 mz13 lt 17 Prados Ixtacala 2da. secc.','2023-03-14','Com18','DIFATCOM18','200', @Success OUTPUT;
EXEC PROC_altaComedor '36','Villa Jardin','Villa Jardin. Cda. Francisco Villa S/N. Col. Villa Jardin','2023-03-24','Com36','DIFATCOM36','200', @Success OUTPUT;
EXEC PROC_altaComedor '37','AMP. Cristobal Higuera','Calle Aldama #17 Col Amp Cristobal Higuera','2023-03-27','Com37','DIFATCOM37','200', @Success OUTPUT;
EXEC PROC_altaComedor '38','CAMP. Adolfo Lopez Mateos','Calle Leon #1 esquina Coatzacoalcos Col Amp. Adolfo L�pez Mateos','2023-03-28','Com38','DIFATCOM38','200', @Success OUTPUT;
EXEC PROC_altaComedor '39','Lomas de San Miguel','Jacarandas #5 Col. Lomas de San Miguel','2023-04-17','Com39','DIFATCOM39','200', @Success OUTPUT;
EXEC PROC_altaComedor '40','San Juan Ixtacala Plano Norte 2','Boulevar Ignacio Zaragoza, Loma Alta #82. Col San Juan Ixtacala Plano Norte','2023-04-17','Com40','DIFATCOM40','200', @Success OUTPUT;
EXEC PROC_altaComedor '41','Los Olivios 2','Calle M�rida numero 10, colonia los Olivos','2023-05-09','Com41','DIFATCOM41','200', @Success OUTPUT;
EXEC PROC_altaComedor '42','Tierra de en Medio','Hacienda de la Flor #14 Col. Tierra de en medio','2023-05-29','Com42','DIFATCOM42','200', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Comedor
GO

DECLARE @Success AS BIT
EXEC PROC_calificar '1000','Cinco de Mayo','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1001','Amp Pe�itas','2023-10-12','5','2','1','Muy horrible comida', @Success OUTPUT;
EXEC PROC_calificar '1002','Cardenas del Rio','2023-10-12','5','5','4','Excelente servicio', @Success OUTPUT;
EXEC PROC_calificar '1003','M�xico 86','2023-10-12','4','4','3','Muy limpio el lugar, me quedaron a deber con la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Amp Pe�itas','2023-10-12','3','5','3','Estaba sucio, pero la comida estaba rica', @Success OUTPUT;
EXEC PROC_calificar '1005','Monte Mar�a','2023-10-12','3','4','4','Deben limpiar m�s seguido', @Success OUTPUT;
EXEC PROC_calificar '1003','Monte Mar�a','2023-10-12','2','4','2','Buena comida', @Success OUTPUT;
EXEC PROC_calificar '1000','Cardenas del Rio','2023-10-12','2','5','2','Deliciosa comida, pero falt� atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1001','Cinco de Mayo','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1002','M�xico 86','2023-10-12','1','2','5','P�simo, sucio muy sucio pero me dieron buena atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1003','M�xico 86','2023-10-12','5','4','1','Bonito lugar y rica comida, pero fue mala la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Cardenas del Rio','2023-10-12','4','3','3','En general bien', @Success OUTPUT;
EXEC PROC_calificar '1005','Margarita Maza','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Margarita Maza','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Cerro Grande','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Cinco de Mayo','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Cerro Grande','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1000','Cerro Grande','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1001','M�xico 86','2023-10-12','5','2','1','Muy horrible comida', @Success OUTPUT;
EXEC PROC_calificar '1002','Cardenas del Rio','2023-10-12','5','5','4','Excelente servicio', @Success OUTPUT;
EXEC PROC_calificar '1003','M�xico 86','2023-10-12','4','4','3','Muy limpio el lugar, me quedaron a deber con la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','San Jose Jaral 2','2023-10-12','3','5','3','Estaba sucio, pero la comida estaba rica', @Success OUTPUT;
EXEC PROC_calificar '1005','San Jose Jaral 2','2023-10-12','3','4','4','Deben limpiar m�s seguido', @Success OUTPUT;
EXEC PROC_calificar '1001','San Jose Jaral 1','2023-10-12','2','4','2','Buena comida', @Success OUTPUT;
EXEC PROC_calificar '1000','San Jose Jaral 1','2023-10-12','2','5','2','Deliciosa comida, pero falt� atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1001','Amp. Emiliana Zapata','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1002','Amp. Emiliana Zapata','2023-10-12','1','2','5','P�simo, sucio muy sucio pero me dieron buena atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1003','DIF Central','2023-10-12','5','4','1','Bonito lugar y rica comida, pero fue mala la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Cardenas del Rio','2023-10-12','4','3','3','En general bien', @Success OUTPUT;
EXEC PROC_calificar '1005','Cinco de Mayo','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','DIF Central','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','DIF Central','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Los Olivos','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Los Olivos','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Los Olivos','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Adolfo Lopez Mateos','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Cinco de Mayo','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Los Olivos','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Hogares','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Hogares','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Adolfo Lopez Mateos','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Hogares','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Adolfo Lopez Mateos','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Rinconada Bonfil','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Adolfo Lopez Mateos','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Hogares','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Rinconada Bonfil','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Hogares','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','San juan Bosco','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Mexico Nuevo','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Las Pe�itas','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Mexico Nuevo','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Hogares','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Mexico Nuevo','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Rinconada Bonfil','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Las Pe�itas','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Rancho Castro','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Las Pe�itas','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Rancho Castro','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Las Pe�itas','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Rancho Castro','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Rancho Castro','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','San juan Bosco','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Villas de las Palmas','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','UAM','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Villas de las Palmas','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Villas de las Palmas','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','UAM','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Villas de las Palmas','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Rancho Castro','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','UAM','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','UAM','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Bosques de Ixtacala','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Bosques de Ixtacala','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1000','Lomas de Tepalcapa','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1001','Lomas de Tepalcapa','2023-10-12','5','2','1','Muy horrible comida', @Success OUTPUT;
EXEC PROC_calificar '1002','Villa de las Torres','2023-10-12','5','5','4','Excelente servicio', @Success OUTPUT;
EXEC PROC_calificar '1003','Lomas de Tepalcapa','2023-10-12','4','4','3','Muy limpio el lugar, me quedaron a deber con la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Villa de las Torres','2023-10-12','3','5','3','Estaba sucio, pero la comida estaba rica', @Success OUTPUT;
EXEC PROC_calificar '1005','Villa de las Torres','2023-10-12','3','4','4','Deben limpiar m�s seguido', @Success OUTPUT;
EXEC PROC_calificar '1001','Cristobal Higuera','2023-10-12','2','4','2','Buena comida', @Success OUTPUT;
EXEC PROC_calificar '1000','Lomas de Guadalupe','2023-10-12','2','5','2','Deliciosa comida, pero falt� atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1001','Lomas de Guadalupe','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1002','Lomas de Guadalupe','2023-10-12','1','2','5','P�simo, sucio muy sucio pero me dieron buena atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1003','Lazara Cardenas','2023-10-12','5','4','1','Bonito lugar y rica comida, pero fue mala la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Lazara Cardenas','2023-10-12','4','3','3','En general bien', @Success OUTPUT;
EXEC PROC_calificar '1005','Cinco de Mayo','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','El Chaparral','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','El Chaparral','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','El Chaparral','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','El Chaparral','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Primero de Septiembre','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Las Aguilas','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Primero de Septiembre','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Tierra de en Medio','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Seguridad Publica','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Seguridad Publica','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1000','Tierra de en Medio Plano Norte 1','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1001','Prados de Ixtacala 2DA SECC.','2023-10-12','5','2','1','Muy horrible comida', @Success OUTPUT;
EXEC PROC_calificar '1002','Tierra de en Medio','2023-10-12','5','5','4','Excelente servicio', @Success OUTPUT;
EXEC PROC_calificar '1003','Prados de Ixtacala 2DA SECC.','2023-10-12','4','4','3','Muy limpio el lugar, me quedaron a deber con la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1005','Las Aguilas','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Las Pe�itas','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Primero de Septiembre','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Las Aguilas','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Primero de Septiembre','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','El Cerrito','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Villas de la Hacienda','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Villas de las Palmas','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','El Cerrito','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Villas de la Hacienda','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Villas de la Hacienda','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Seguridad Publica','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Villas de la Hacienda','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Villas de la Hacienda','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Seguridad Publica','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Seguridad Publica','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1000','San Juan Ixtacala Plano Norte 1','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1001','Prados de Ixtacala 2DA SECC.','2023-10-12','5','2','1','Muy horrible comida', @Success OUTPUT;
EXEC PROC_calificar '1002','Prados de Ixtacala 2DA SECC.','2023-10-12','5','5','4','Excelente servicio', @Success OUTPUT;
EXEC PROC_calificar '1003','Prados de Ixtacala 2DA SECC.','2023-10-12','4','4','3','Muy limpio el lugar, me quedaron a deber con la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','Prados de Ixtacala 2DA SECC.','2023-10-12','3','5','3','Estaba sucio, pero la comida estaba rica', @Success OUTPUT;
EXEC PROC_calificar '1005','Villa Jardin','2023-10-12','3','4','4','Deben limpiar m�s seguido', @Success OUTPUT;
EXEC PROC_calificar '1001','Villa Jardin','2023-10-12','2','4','2','Buena comida', @Success OUTPUT;
EXEC PROC_calificar '1000','AMP. Cristobal Higuera','2023-10-12','2','5','2','Deliciosa comida, pero falt� atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1001','Villa Jardin','2023-10-12','4','5','3',null, @Success OUTPUT;
EXEC PROC_calificar '1002','AMP. Cristobal Higuera','2023-10-12','1','2','5','P�simo, sucio muy sucio pero me dieron buena atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1003','Lazara Cardenas','2023-10-12','5','4','1','Bonito lugar y rica comida, pero fue mala la atenci�n', @Success OUTPUT;
EXEC PROC_calificar '1004','CAMP. Adolfo Lopez Mateos','2023-10-12','4','3','3','En general bien', @Success OUTPUT;
EXEC PROC_calificar '1005','CAMP. Adolfo Lopez Mateos','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Lomas de San Miguel','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
EXEC PROC_calificar '1001','Lomas de San Miguel','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','San Juan Ixtacala Plano Norte 2','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','San Juan Ixtacala Plano Norte 2','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1002','Los Olivios 2','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Los Olivios 2','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1001','Los Olivios 2','2023-10-11','4','3','5','Hay que mejorar la comida',@Success OUTPUT;
EXEC PROC_calificar '1002','Los Olivios 2','2023-10-17','5','5','5','Hoy fue perfecto',@Success OUTPUT;
EXEC PROC_calificar '1003','Villas de la Hacienda','2023-10-16','3','2','1','No me gust�',@Success OUTPUT;
EXEC PROC_calificar '1005','Seguridad Publica','2023-10-12','3','3','2',null, @Success OUTPUT;
EXEC PROC_calificar '1000','Villas de la Hacienda','2023-10-10','5','4','4','Muy buen servicio',@Success OUTPUT;
--EXEC PROC_calificar '','','','','','','',@Success OUTPUT;
--EXEC PROC_calificar '','','','','','','',@Success OUTPUT;
--SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_registrarAsistencia '2023-10-17','0','1003','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-17','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-13','1','1002','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-13','1','1004','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-03-12','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-03','1','1012','3',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-23','1','1010','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-24','1','1008','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-30','0','1007','42',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-14','1','1005','33',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-11','1','1003','12',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-13','1','1000','3',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-01','1','1004','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-01','1','1002','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-13','0','1010','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-03','1','1009','23',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-17','1','1003','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-17','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-13','1','1002','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-13','1','1004','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-12','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-03','0','1012','3',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-23','1','1010','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-24','0','1008','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-30','1','1007','42',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-14','0','1005','33',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-11','1','1003','12',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-13','1','1000','3',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-01','1','1004','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-01','1','1002','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-03-13','1','1010','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-03','0','1009','23',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-17','0','1003','2',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-17','1','1001','3',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-13','1','1002','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-13','1','1004','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-03-12','1','1001','6',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-03','0','1012','7',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-23','1','1010','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-24','0','1008','9',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-30','1','1007','43',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-14','0','1005','35',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-11','1','1003','11',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-13','1','1000','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-01','1','1004','2',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-01','1','1002','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-13','1','1010','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-03','0','1009','13',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-17','0','1003','4',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-17','1','1001','5',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-13','1','1002','6',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-13','1','1004','7',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-12','1','1001','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-03','1','1012','32',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-23','1','1010','12',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-01-24','0','1008','12',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-30','1','1007','43',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-14','0','1005','31',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-11','1','1003','11',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-13','1','1000','9',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-01','1','1004','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-02-01','1','1002','7',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-03-13','1','1010','12',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-03','0','1009','29',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-17','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-13','1','1002','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-13','1','1004','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-12','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-07-03','0','1012','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-23','1','1010','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-24','0','1008','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-30','1','1007','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-14','0','1005','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-11','1','1003','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-17','0','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-13','1','1002','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-10-13','1','1004','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-12','1','1001','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-11-03','0','1012','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-23','1','1010','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-24','0','1008','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-30','1','1007','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-14','0','1005','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-12-11','1','1003','1',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-03-13','1','1000','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-01','1','1004','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-01','1','1002','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-04-13','1','1010','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-05-03','0','1009','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-13','1','1000','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-06-01','1','1004','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-01','1','1002','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-08-13','1','1010','8',@Success OUTPUT;
EXEC PROC_registrarAsistencia '2023-09-03','0','1009','8',@Success OUTPUT;
--EXEC PROC_registrarAsistencia '','','','',@Success OUTPUT;
--SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_apertura '1','2023-10-15','12:30:02',@Success OUTPUT;
--SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_cierre '1','2023-10-15','16:02:15',@Success OUTPUT;
--SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_generarReporte '1','2023-10-17','Reporte de seguridad','Se metieron a robar','Sin rango asignado','0', @Success OUTPUT;
EXEC PROC_generarReporte '2','2023-10-16','Reporte de salud e higiene','Hay chinches','Antes de 72 horas','0', @Success OUTPUT;
EXEC PROC_generarReporte '3','2023-09-15','Reporte de incidentes','La cocinera se enferm�','Antes de 24 horas','0', @Success OUTPUT;
EXEC PROC_generarReporte '1','2023-08-16','Reporte de mantenimiento','Hay una fuga de gas','Inmediato','0', @Success OUTPUT;
EXEC PROC_generarReporte '4','2023-09-10','Reporte de salud e higiene','Tenemos un foco de infecci�n de gripa','Sin rango asignado','0', @Success OUTPUT;
EXEC PROC_generarReporte '3','2023-10-17','Reporte de seguridad','Hay una pandilla por el barrio','Antes de 72 horas','0', @Success OUTPUT;
EXEC PROC_generarReporte '2','2023-10-02','Reporte de incidentes','Hubo una disputa entre clientes que termin� en una ri�a','Sin rango asignado','0', @Success OUTPUT;
EXEC PROC_generarReporte '5','2023-06-12','Otro','Tenemos falta de personal, no podemos atender a tantos asistentes','Antes de 72 horas','0', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Reportes;
GO

DECLARE @Success AS BIT
EXEC PROC_marcarReporteCompletado '100002', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Reportes;
GO

DECLARE @Success AS BIT
EXEC PROC_agregarInventario '2023-10-20','Frijoles','50','Bolsa de 100 gramos','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-30','Manzanas','5','Piezas de manzana','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-11-01','Arroz','1','Bolsa de 1k','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-12','Tomates','10','Piezas de tomate','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-23','Cebolla','4','Piezas de cebolla','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-26','Spaghetti','250','Gramos','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-28','Champi�ones','3','Latas','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-10-29','Avena','500','gramos','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-11-02','Sand�a','1','Pieza','1',@Success OUTPUT;
EXEC PROC_agregarInventario '2023-11-05','Huevo','18','Pieza','2',@Success OUTPUT;
--SELECT @Success AS Success
--EXEC PROC_inventarioCom '2';
GO