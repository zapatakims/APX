USE APXFirm
GO

IF OBJECT_ID('APXUsercustom.InvestmentGuidelines', 'U') IS NOT NULL
DROP TABLE [APXUserCustom].[InvestmentGuidelines]
GO

CREATE TABLE [APXUserCustom].[InvestmentGuidelines] (
	[AccountCode] nvarchar(72),
	[AssetClass] nvarchar(255),
	[Min] float,
	[Bench] float,
	[Max] float
)
GO


DECLARE @filePath nvarchar(255) = 'C:\temp\',	--	!!IMPORTANT -- Change this to the correct path on the SQL database server where you saved the Fiera_Investment_Guidelines.csv file!!
	@sql varchar(max)	

SET @sql = 'BULK INSERT [APXUserCustom].[InvestmentGuidelines] FROM ''' + @filePath + 'Fiera_Investment_Guidelines.csv'' WITH (FIELDTERMINATOR = '','',ROWTERMINATOR = ''\n'')'

EXEC (@sql)
GO