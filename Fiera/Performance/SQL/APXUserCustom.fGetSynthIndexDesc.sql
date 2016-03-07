/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSynthIndexDesc]    Script Date: 08/22/2013 16:37:38 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetSynthIndexDesc]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetSynthIndexDesc]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSynthIndexDesc]    Script Date: 08/22/2013 16:37:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE Function [APXUserCustom].[fGetSynthIndexDesc](@PortfolioBaseID int)
returns varchar(max)
with execute as self
begin
return (SELECT SyntheticIndexDesc FROM AdvPortfolioBase where Portfoliobaseid = @PortfolioBaseID)
end





GO


