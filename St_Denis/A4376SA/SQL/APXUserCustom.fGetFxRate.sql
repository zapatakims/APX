USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetFxRate]    Script Date: 06/02/2014 14:23:24 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetFxRate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetFxRate]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetFxRate]    Script Date: 06/02/2014 14:23:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE Function [APXUserCustom].[fGetFxRate](@FromCurrencyCode varchar(2), @ToCurrencyCode varchar(2), @Date datetime)
returns float
with execute as caller
begin
return
(
Select
Case When @FromCurrencyCode = @ToCurrencyCode
Then 1
Else
(Select
SpotRate
From APXUser.vFXRate
where AsOfDate = @Date
and DenominatorCurrencyCode = @FromCurrencyCode
and NumeratorCurrencyCode = @ToCurrencyCode)
End as ExchangeRate
)
end





GO

