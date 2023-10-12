USE MASTER;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = 'ComedorBD')
BEGIN
    ALTER DATABASE ComedorBD SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ComedorBD;
    --Sólo si la base de datos marca error porque está siendo ocupada
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
DROP TABLE IF EXISTS Despensa;
DROP TABLE IF EXISTS Estado;
DROP TABLE IF EXISTS Condicion;
DROP TABLE IF EXISTS Nacionalidad;
DROP TABLE IF EXISTS Calificaciones;

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
	Usuario VARCHAR(10) NOT NULL, 
	ContraComedor VARCHAR(80) NOT NULL,
	Estado INT NOT NULL
		CONSTRAINT FK_Comedor_Estado FOREIGN KEY (Estado)
		REFERENCES Estado(IDEstado)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
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
	Cel VARCHAR(15),
	Correo VARCHAR(30)
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
	Donacion CHAR NOT NULL,
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

CREATE TABLE Despensa(
	FechaIng DATE NOT NULL,
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
	CalAtencion INT NOT NULL
);

USE ComedorBD;
GO

--trigger para contraseñas Admin
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

--trigger para contraseñas comedor
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

--procedure para alta de un usuario
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
@Success AS BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @IDCondicion AS INT;
		SELECT @IDCondicion = (SELECT IDCondicion FROM Condicion WHERE Cond LIKE @Condicion);

		DECLARE @IDNacionalidad AS INT;
		SELECT @IDNacionalidad = (SELECT IDNacionalidad FROM Nacionalidad WHERE Nac LIKE @Nacionalidad);

		INSERT INTO Usuario(Nombre, Apellido1, Apellido2, CURP, Nacionalidad, Sexo, FechaNac, Condicion, Cel, Correo) 
		VALUES (@Nombre, @Apellido1, @Apellido2, @CURP, @IDNacionalidad, @Sexo, @FechaNac, @IDCondicion, @Cel, @Correo);
		SET @Success = 1;
	END TRY
	BEGIN CATCH
		SET @Success = 0;
	END CATCH
	RETURN @Success
END;
GO

--procedure para insertar una calificación
CREATE OR ALTER PROCEDURE PROC_calificar
@IDUsuario INT,
@FolioComedor INT,
@Fecha DATE,
@CalLimpieza INT,
@CalComida INT,
@CalAtencion INT,
@Success AS BIT OUTPUT
AS
BEGIN 
	BEGIN TRY
        INSERT INTO Calificaciones(IDUsuario, FolioComedor,Fecha, CalLimpieza, CalComida, CalAtencion)
		VALUES (@IDUsuario, @FolioComedor,@Fecha, @CalLimpieza, @CalComida, @CalAtencion);
        SET @Success = 1;
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

--procedure para cambiar condición de un usuario
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

--procedure para cambiar o actualiza número de teléfono
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

--procedure para cambiar o actualizar correo electrónico
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

--procedure para cambiar contraseña Admin
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

--procedure para verificar inicio de sesión del Administrador
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

--procedure para cambiar contraseña Comedor
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

--procedure para verificar inicio de sesión del Comedor
CREATE OR ALTER PROCEDURE PROC_logInComedor
@FolioComedor INT,
@Contrasena VARCHAR(80),
@Success BIT OUTPUT
AS
BEGIN
	BEGIN TRY
		DECLARE @StoredPassword VARCHAR(80);
		SELECT @StoredPassword = (SELECT ContraComedor FROM Comedor WHERE FolioComedor = FolioComedor)

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

CREATE PROCEDURE PROC_comedorDelMes
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
    SELECT TOP 3 FolioComedor, PromedioLimpieza, PromedioComida, PromedioAtencion
    FROM PromedioCategorias
    ORDER BY (PromedioLimpieza + PromedioComida + PromedioAtencion) DESC;
END;
GO








USE ComedorBD;
GO

INSERT INTO Estado(Estado) VALUES ('Activo');
INSERT INTO Estado(Estado) VALUES ('Cerrado');
INSERT INTO Estado(Estado) VALUES ('Suspendido');
GO

INSERT INTO Nacionalidad(Nac) VALUES ('Mexico');
INSERT INTO Nacionalidad(Nac) VALUES ('Guatemala');
INSERT INTO Nacionalidad(Nac) VALUES ('El Salvador');
INSERT INTO Nacionalidad(Nac) VALUES ('Chile');
INSERT INTO Nacionalidad(Nac) VALUES ('Brasil');
INSERT INTO Nacionalidad(Nac) VALUES ('Perú');
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

INSERT INTO Condicion(Cond) VALUES ('Persona mayor de 60 años');
INSERT INTO Condicion(Cond) VALUES ('Menor de edad');
INSERT INTO Condicion(Cond) VALUES ('Persona indígena');
INSERT INTO Condicion(Cond) VALUES ('Persona con discapacidad');
INSERT INTO Condicion(Cond) VALUES ('Persona perteneciente al colectivo LGBTQ+');
INSERT INTO Condicion(Cond) VALUES ('Migrante o desplazado por conflictos');
INSERT INTO Condicion(Cond) VALUES ('Persona en condición de calle');
INSERT INTO Condicion(Cond) VALUES ('Mujer embarazada');
INSERT INTO Condicion(Cond) VALUES ('Trabajador/a informal');
INSERT INTO Condicion(Cond) VALUES ('Otra condición');
INSERT INTO Condicion(Cond) VALUES ('No aplica');
--SELECT* FROM Condicion
GO



--SELECT* FROM Usuario
DECLARE @Success AS BIT
EXEC PROC_altaUsuario 'Karla','Cruz','Muñiz','CUMK030414MDFRXRA9','Mexico','F','2003-04-14','No aplica','5567866976','karla.cruzmz@gmail.com', @Success OUTPUT;
EXEC PROC_altaUsuario 'Leonel','Cruz','Alcántara','CUAL021125HVERXRA9','Guatemala','M','2002-11-25','No aplica','5532544142','leonelcalc@gmail.com', @Success OUTPUT;
EXEC PROC_altaUsuario 'Erik','Soto','Cano','CUDKE85H4NME96HJF9', 'Mexico','M','2003-04-25','Persona perteneciente al colectivo LGBTQ+','5567890987','erik@mail.com', @Success OUTPUT;
EXEC PROC_altaUsuario 'Brisa','Estrada','Ortiz','EAOBRUEIT854HFMD38','El Salvador','F','2003-05-28','Mujer embarazada','5589723423','brisa@mail.com', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Usuario
GO

DECLARE @Success AS BIT
EXEC PROC_altaUsuario 'Juan','Carlo','Carro','JCS234HDGS6789JDH7','Mexico','M','2002-06-12','No aplica','5567890987','juanca@gmail.com',@Success OUTPUT;
--SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_altaUsuario 'Pepe','Luis','Moreno','HSJDKSEWUTYFHD7856','Mexico','M','2002-07-12','No aplica','5585463275','pepeca@gmail.com',@Success OUTPUT;
--SELECT @Success AS Success
GO

--SELECT* FROM Usuario
DECLARE @Success AS BIT
EXEC PROC_actualizarCelular '1000','5567861076',@Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Usuario
GO

DECLARE @Success AS BIT
EXEC PROC_actualizarCorreo '1005','pepeluism@hotmail.com',@Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Usuario
GO

DECLARE @Success AS BIT
EXEC PROC_altaPariente '1000', '1001', @Success OUTPUT;
EXEC PROC_altaPariente '1002', '1003', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Pariente
GO

DECLARE @Success AS BIT
EXEC PROC_cambioCond '1002','Menor de edad', @Success OUTPUT;
EXEC PROC_cambioCond '1000','No aplica', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Usuario
GO

--SELECT* FROM Administrador
DECLARE @Success AS BIT
EXEC PROC_altaAdmin 'Ángel','Schiaffini','Rodríguez','angelito123', @Success OUTPUT;
EXEC PROC_altaAdmin 'Stefania','Cruz','Muñiz','karicitabonita', @Success OUTPUT;
EXEC PROC_altaAdmin 'Maximiliano','Lecona','Nieves','maxi345', @Success OUTPUT;
EXEC PROC_altaAdmin 'Joahan','García','Fernandez','joahancin', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Administrador
GO

--DECLARE @Success AS BIT
--EXEC PROC_bajaAdmin '103', @Success OUTPUT;
--SELECT* FROM Administrador
--SELECT @Success AS Success
--GO

--SELECT* FROM Comedor
DECLARE @Success AS BIT
EXEC PROC_altaComedor '01','Cinco de Mayo','Calle Porfirio Diaz #25 Col. 5 de Mayo','2022-08-23','Com01','DIFATCOM01','200', @Success OUTPUT;
EXEC PROC_altaComedor '02','México 86','Calle Italia #53 Col. México','2023-08-23','Com02','DIFATCOM02','200', @Success OUTPUT;
EXEC PROC_altaComedor '03','Cardenas del Rio','Calle Gral. Cárdenas del Río Mz 14 Lt 10','2022-08-23','Com03','DIFATCOM03','201', @Success OUTPUT;
EXEC PROC_altaComedor '04','Monte María','Calle Monte Real Mz 406 Lt 11 Col. Lomas del Monte Maria','2022-08-23','Com04','DIFATCOM04','200', @Success OUTPUT;
EXEC PROC_altaComedor '05','Margarita Maza','Calle Francisco Javier Mina #12, Col. Margarita Maza dde Juárez','2022-08-23','Com05','DIFATCOM05','200', @Success OUTPUT;
EXEC PROC_altaComedor '06','Cerro Grande','Calle Teotihuacan #15 Col. Cerro Grande','2023-01-30','Com06','DIFATCOM06','200', @Success OUTPUT;
EXEC PROC_altaComedor '07','Amp Peñitas','Cda Gardenias #3 Col. Amp Peñitas','2022-08-30','Com07','DIFATCOM07','200', @Success OUTPUT;
EXEC PROC_altaComedor '08','San Jose Jaral 2','Calle Jazmín #22 Col. San Jose el Jaral','2022-08-30','Com08','DIFATCOM08','200', @Success OUTPUT;
EXEC PROC_altaComedor '09','San Jose Jaral 1','Calle Clavelinas #24 Col. San Jose el Jaral','2022-08-30','Com09','DIFATCOM09','201', @Success OUTPUT;
EXEC PROC_altaComedor '10','Amp. Emiliana Zapata','Av. Ejército Mexicano s/n, Col. Ampl. Emiliano Zapata','2022-08-30','Com10','DIFATCOM10','200', @Success OUTPUT;
EXEC PROC_altaComedor '11','DIF Central','Av. Ruiz Cortines esq. Acambay Lomas de Atizapán','2022-09-08','Com11','DIFATCOM11','200', @Success OUTPUT;
EXEC PROC_altaComedor '12','Los Olivos','Av Jalisco s/n Casa de la Juventud','2022-09-09','Com12','DIFATCOM12','201', @Success OUTPUT;
EXEC PROC_altaComedor '13','Adolfo Lopez Mateos','Adolfo Lopez Mateos, Privada Zacatecas no.6','2022-09-08','Com13','DIFATCOM13','200', @Success OUTPUT;
EXEC PROC_altaComedor '14','Hogares','Retorno de la Tranquilidad no.8A, Hogares de Atizapán','2022-09-12','Com14','DIFATCOM14','200', @Success OUTPUT;
EXEC PROC_altaComedor '15','Rinconada Bonfil','Rinconada Bonfil Calle Rosas Mz 4 Lt 15','2022-06-09','Com15','DIFATCOM15','200', @Success OUTPUT;
EXEC PROC_altaComedor '16','San juan Bosco','San Juan Bosco, Calle Profesor Roberto Barrio no.2','2022-09-23','Com16','DIFATCOM16','200', @Success OUTPUT;
EXEC PROC_altaComedor '17','Mexico Nuevo','Pioneros de Rochandell esquina con calle Veracruz S/N Col. Mexico Nuevo (Deportivo)','2022-09-26','Com17','DIFATCOM17','201', @Success OUTPUT;
EXEC PROC_altaComedor '18','Las Peñitas','Peñitas. Mirador # 100 Col. Las Peñitas','2022-09-26','Com18','DIFATCOM18','200', @Success OUTPUT;
EXEC PROC_altaComedor '19','Rancho Castro','Rancho Castro, Calle del Puerto s/n Rancho salón de usos múltiplos','2022-09-23','Com19','DIFATCOM19','200', @Success OUTPUT;
EXEC PROC_altaComedor '20','Villas de las Palmas','Villas de las palmas Calle avena Mz. 5 Lt. 12 col. Amp villa de las Palmas','2022-09-23','Com20','DIFATCOM20','200', @Success OUTPUT;
EXEC PROC_altaComedor '21','UAM','Calle Ingenieria Industrial Mz 24 Lt 45 Col. UAM','2022-10-04','Com21','DIFATCOM21','200', @Success OUTPUT;
EXEC PROC_altaComedor '22','Bosques de Ixtacala','Cerrada Sauces Mz 12 Lt 13- C #6 col.Bosques de Ixtacala','2022-10-05','Com22','DIFATCOM22','200', @Success OUTPUT;
EXEC PROC_altaComedor '23','Lomas de Tepalcapa','Calle seis #14 Colonia Lomas de Tepalcapa','2022-10-17','Com23','DIFATCOM23','200', @Success OUTPUT;
EXEC PROC_altaComedor '24','Villa de las Torres','Calle Villa Alba Mza. 17 lote 9, esquina Bicentenario, Col. Villa de las Torres','2022-10-18','Com24','DIFATCOM24','200', @Success OUTPUT;
EXEC PROC_altaComedor '25','Cristobal Higuera','Cristobal Higuera - Calle Sandía # 24. Col. Prof. Cristobal Higuera','2022-10-18','Com25','DIFATCOM25','200', @Success OUTPUT;
EXEC PROC_altaComedor '26','Lomas de Guadalupe','Lomas de Guadalupe - Calle Vicente Guerrero Número 2, Colonia Lomas de Guadalupe','2022-10-19','Com26','DIFATCOM26','200', @Success OUTPUT;
EXEC PROC_altaComedor '27','Lazara Cardenas','Lázaro Cardenas - Calle Chihuahua 151-A Col. Lázaro Cardenas','2022-10-21','Com27','DIFATCOM27','200', @Success OUTPUT;
EXEC PROC_altaComedor '28','El Chaparral','El Chaparral - Calle Túcan # 48. Colonia el Chaparral','2022-10-21','Com28','DIFATCOM28','200', @Success OUTPUT;
EXEC PROC_altaComedor '29','Primero de Septiembre','Primero de Septiembre - Calle Belisario Dominguez Colonia 44 Primero de Septiembre','2022-11-17','Com29','DIFATCOM29','200', @Success OUTPUT;
EXEC PROC_altaComedor '30','Las Aguilas','Las Aguilas - Pavo Real # 18 Colonia de las Aguilas','2022-11-25','Com30','DIFATCOM30','200', @Success OUTPUT;
EXEC PROC_altaComedor '31','El Cerrito','El Cerrito. Paseo Buenavista # 1Col. El Cerrito','2022-11-23','Com31','DIFATCOM31','200', @Success OUTPUT;
EXEC PROC_altaComedor '32','Villas de la Hacienda','Calle de las Chaparreras #5 Col. Villas de la Hacienda','2023-09-01','Com32','DIFATCOM32','200', @Success OUTPUT;
EXEC PROC_altaComedor '33','Seguridad Publica','Seguridad Publica','2023-09-03','Com33','DIFATCOM33','200', @Success OUTPUT;
EXEC PROC_altaComedor '34','San Juan Ixtacala Plano Norte 1','Loma San Juan 194.San Juan Ixtacala Plano Norte','2023-03-14','Com34','DIFATCOM34','200', @Success OUTPUT;
EXEC PROC_altaComedor '35','Prados de Ixtacala 2DA SECC.','Clavel no. 13 mz13 lt 17 Prados Ixtacala 2da. secc.','2023-03-14','Com18','DIFATCOM18','200', @Success OUTPUT;
EXEC PROC_altaComedor '36','Villa Jardin','Villa Jardin. Cda. Francisco Villa S/N. Col. Villa Jardin','2023-03-24','Com36','DIFATCOM36','200', @Success OUTPUT;
EXEC PROC_altaComedor '37','AMP. Cristobal Higuera','Calle Aldama #17 Col Amp Cristobal Higuera','2023-03-27','Com37','DIFATCOM37','200', @Success OUTPUT;
EXEC PROC_altaComedor '38','CAMP. Adolfo Lopez Mateos','Calle Leon #1 esquina Coatzacoalcos Col Amp. Adolfo López Mateos','2023-03-28','Com38','DIFATCOM38','200', @Success OUTPUT;
EXEC PROC_altaComedor '39','Lomas de San Miguel','Jacarandas #5 Col. Lomas de San Miguel','2023-04-17','Com39','DIFATCOM39','200', @Success OUTPUT;
EXEC PROC_altaComedor '40','San Juan Ixtacala Plano Norte 2','Boulevar Ignacio Zaragoza, Loma Alta #82. Col San Juan Ixtacala Plano Norte','2023-04-17','Com40','DIFATCOM40','200', @Success OUTPUT;
EXEC PROC_altaComedor '41','Los Olivios 2','Calle Mérida numero 10, colonia los Olivos','2023-05-09','Com41','DIFATCOM41','200', @Success OUTPUT;
EXEC PROC_altaComedor '42','Tierra de en Medio','Hacienda de la Flor #14 Col. Tierra de en medio','2023-05-29','Com42','DIFATCOM42','200', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Comedor
GO

DECLARE @Success AS BIT
EXEC PROC_bajaComedor '01', @Success OUTPUT;
--SELECT @Success AS Success
--SELECT* FROM Comedor
GO

SELECT* FROM Administrador
DECLARE @Success AS BIT
EXEC PROC_cambioContraAdmin '101','hola','hola', @Success OUTPUT;
SELECT @Success AS Success
SELECT* FROM Administrador
GO

DECLARE @Success AS BIT
EXEC PROC_logInAdmin '101','holas',@Success OUTPUT;
SELECT @Success AS Success
GO

DECLARE @Success AS BIT
EXEC PROC_calificar '1000','1','2022-10-12','4','5','3', @Success OUTPUT;
EXEC PROC_calificar '1001','2','2022-10-12','5','2','1', @Success OUTPUT;
EXEC PROC_calificar '1002','3','2022-10-12','5','5','4', @Success OUTPUT;
EXEC PROC_calificar '1003','2','2022-10-12','4','4','3', @Success OUTPUT;
EXEC PROC_calificar '1004','1','2022-10-12','3','5','3', @Success OUTPUT;
EXEC PROC_calificar '1005','2','2022-10-12','3','4','4', @Success OUTPUT;
EXEC PROC_calificar '1000','3','2022-10-12','2','5','2', @Success OUTPUT;
EXEC PROC_calificar '1001','1','2022-10-12','4','5','3', @Success OUTPUT;
EXEC PROC_calificar '1002','2','2022-10-12','1','2','5', @Success OUTPUT;
EXEC PROC_calificar '1003','2','2022-10-12','5','4','1', @Success OUTPUT;
EXEC PROC_calificar '1004','3','2022-10-12','4','3','3', @Success OUTPUT;
EXEC PROC_calificar '1005','1','2022-10-12','3','3','2', @Success OUTPUT;
SELECT @Success AS Success
GO

EXEC PROC_comedorDelMes '10','2022';
GO
