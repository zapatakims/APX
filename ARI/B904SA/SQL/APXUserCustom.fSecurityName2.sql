USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fSecurityName2]    Script Date: 12/01/2013 18:41:06 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fSecurityName2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fSecurityName2]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fSecurityName2]    Script Date: 12/01/2013 18:41:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--	$Header: $/APX/Trunk/APX/APXDatabase/APXFirm/Function/APXSSRS/fSecurityName2.sql  2012-01-05 08:38:42 PST  ADVENT/astanchi $
create function [APXUserCustom].[fSecurityName2](@BondDescription nstr255, @MutualFund nstr255, @MFBasisIncludeReinvest bit, @IncludeNewLine bit)
returns nstr255
as
begin
declare @securityName2 nstr255
set @securityName2 = isnull(nullif(@BondDescription, ''), case when isnull(@MFBasisIncludeReinvest, 0) = 0 then @MutualFund else null end)
if (@IncludeNewLine = 1)
begin
if (isnull(@securityName2, '') = '')
set @securityName2 = ''
else
set @securityName2 = APX.fNewLine(1) + @securityName2
end

return @securityName2
end


GO


