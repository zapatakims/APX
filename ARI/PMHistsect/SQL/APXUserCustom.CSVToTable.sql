IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[CSVToTable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')) 
DROP FUNCTION [APXUserCustom].[CSVToTable] 
GO 
  
SET ANSI_NULLS ON
GO 
  
SET QUOTED_IDENTIFIER ON
GO 

CREATE FUNCTION [APXUserCustom].[CSVToTable] (@InStr VARCHAR(MAX))
RETURNS @TempTab TABLE
   ([ID] int identity, name nvarchar(32) not null)
AS
BEGIN
    ;-- Ensure input ends with comma
	SET @InStr = REPLACE(@InStr + ',', ',,', ',')
	DECLARE @SP INT
DECLARE @VALUE VARCHAR(1000)
WHILE PATINDEX('%,%', @INSTR ) <> 0 
BEGIN
   SELECT  @SP = PATINDEX('%,%',@INSTR)
   SELECT  @VALUE = LEFT(@INSTR , @SP - 1)
   SELECT  @INSTR = STUFF(@INSTR, 1, @SP, '')
   INSERT INTO @TempTab(name) VALUES (@VALUE)
END
	RETURN
END
GO