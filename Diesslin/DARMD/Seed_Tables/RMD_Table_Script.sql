USE APXFirm
GO

IF OBJECT_ID('APXUsercustom.RMD10Yr', 'U') IS NOT NULL
DROP TABLE APXUserCustom.RMD10Yr
GO

IF OBJECT_ID('APXUsercustom.RMDNormal', 'U') IS NOT NULL
DROP TABLE APXUserCustom.RMDNormal
GO

IF OBJECT_ID('APXUsercustom.RMDInherited', 'U') IS NOT NULL
DROP TABLE APXUserCustom.RMDInherited
GO

CREATE TABLE APXUserCustom.RMD10Yr (
OwnerAge smallint,
SpouseAge smallint,
LifeExpectancy float)
GO

BULK
INSERT APXUserCustom.RMD10Yr
FROM 'c:\temp\rmd10yr.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
)
GO

-- trim the table
DELETE FROM APXUserCustom.RMD10Yr
WHERE LifeExpectancy IS NULL
GO

CREATE TABLE APXUserCustom.RMDNormal (
Age smallint,
LifeExpectancy float,
Value float)
GO

BULK
INSERT APXUserCustom.RMDNormal
FROM 'c:\temp\rmdnormal.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
)
GO

CREATE TABLE APXUserCustom.RMDInherited (
Age smallint,
LifeExpectancy float,
Value float)
GO

BULK
INSERT APXUserCustom.RMDInherited
FROM 'c:\temp\rmdinherited.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
)
GO