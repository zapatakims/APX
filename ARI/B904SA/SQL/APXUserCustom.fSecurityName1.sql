USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fSecurityName1]    Script Date: 12/01/2013 18:40:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fSecurityName1]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fSecurityName1]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fSecurityName1]    Script Date: 12/01/2013 18:40:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--	$Header: $/APX/Trunk/APX/APXDatabase/APXFirm/Function/APXSSRS/fSecurityName1.sql  2012-02-27 11:46:13 PST  ADVENT/PJC $
create function [APXUserCustom].[fSecurityName1](@SecurityName name72, @ISOCode nvarchar(3), @MaturityDate datetime, @LocaleID int, @IsFFX bit, @IsShort bit)
returns nstr128
as
begin
declare @baseSecurityName nstr128
if (@IsFFX = 1 and ISNULL(@SecurityName, '') = '')
begin
declare @datePattern nstr50
select @datePattern = LongDateFormatString from dbo.AoLocale where LocaleID = @LocaleID
if (@datePattern = '')
set @datePattern = APXSys.fLongDatePattern(@LocaleID);
set @baseSecurityName = @ISOCode + ' Forward ' + APXSys.fDateToString(@MaturityDate, @DatePattern)
end
else
begin
set @baseSecurityName = @SecurityName
end
return (case @IsShort when 1 then @baseSecurityName + ' (Short)' else @baseSecurityName end)
end


GO


