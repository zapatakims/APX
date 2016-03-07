USE APXFirm
GO

IF OBJECT_ID('APXUsercustom.AssetClassHierarchy', 'U') IS NOT NULL
DROP TABLE [APXUserCustom].[AssetClassHierarchy]
GO

CREATE TABLE [APXUserCustom].[AssetClassHierarchy] (
	[AssetClass1] nvarchar(255),
	[AssetClass2] nvarchar(255),
	[AssetClass3] nvarchar(255)
)
GO


DECLARE @filePath nvarchar(255) = 'C:\temp\',	--	!!IMPORTANT -- Change this to the correct path on the SQL database server where you saved the Fiera_Investment_Guidelines.csv file!!
	@sql varchar(max)	

SET @sql = 'BULK INSERT [APXUserCustom].[AssetClassHierarchy] FROM ''' + @filePath + 'AssetClass.csv'' WITH (FIELDTERMINATOR = '','',ROWTERMINATOR = ''\n'')'

EXEC (@sql)
GO