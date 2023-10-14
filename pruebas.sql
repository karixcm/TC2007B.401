USE ComedorBD
GO

EXEC PROC_statsPaises;
GO

EXEC PROC_statsCondicion;
GO

EXEC PROC_contarPersonasSinHogarMexicanas;
GO

EXEC PROC_ordenMejoresComedores '10','2022';
GO

EXEC PROC_buscarFamiliares '1001';
GO