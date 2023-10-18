USE ComedorBD
GO

--EXEC PROC_statsPaises;
--GO

--EXEC PROC_statsCondicion;
--GO

--EXEC PROC_contarPersonasSinHogarMexicanas;
--GO

--EXEC PROC_ordenMejoresComedores '10','2022';
--GO

--EXEC PROC_buscarFamiliares '1001';
--GO

--EXEC PROC_listaComedores;
--GO

--SELECT* FROM Calificaciones;
--GO

--SELECT* FROM Nacionalidad;
--GO

--SELECT* FROM Condicion;
--GO

--DECLARE @TotalGanancias INT
--EXEC PROC_gananciasHoy '1', '2023-04-13', @TotalGanancias OUTPUT;
--SELECT @TotalGanancias AS TotalGananciasHoy
--GO

--EXEC PROC_gananciasFechas '1','2023-03-12','2023-04-13';
--GO

--EXEC PROC_listaGananciasPorComedor '2023-01-01', '2023-12-24';
--GO

--EXEC PROC_sumarAsistentes '2023-04-13', '1';
--GO

--SELECT* FROM Usuario
--SELECT* FROM Condicion

--DECLARE @Success AS BIT
--SELECT* FROM Administrador
--EXEC PROC_logInAdmin '100','angelito123', @Success OUTPUT;
--SELECT @Success AS Success
--GO

--DECLARE @Success AS BIT
--SELECT* FROM Comedor
--EXEC PROC_logInComedor 'Com01','DIFATCOM01', @Success OUTPUT;
--SELECT @Success AS Success
--GO

--DECLARE @Success AS BIT
--EXEC PROC_altaUsuario 'Jimena','Campos','Escamilla','JCE234JDH6789GK594','México','F','2001-04-14','No aplica','5577889876','jim2t@tec.mx',@Success OUTPUT;
--SELECT @Success AS Success
--SELECT * FROM Usuario
--GO

--DECLARE @Success AS BIT
--EXEC PROC_altaUsuario 'Aldo','Gonzales','Espinoza','ALGOE6758JHGF89TR6','Mexico','N','2001-05-16','No aplica','5573389876','aldogon@tec.mx',@Success OUTPUT;
--SELECT @Success AS Success
--SELECT * FROM Usuario
--GO

--EXEC PROC_comedorDelMes '10','2022';
--GO

--EXEC PROC_reportesCompletados;
--GO

--EXEC PROC_reportesNoCompletados;
--GO