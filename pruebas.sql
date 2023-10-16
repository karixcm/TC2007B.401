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