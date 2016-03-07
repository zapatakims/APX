USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetIndexReturn]    Script Date: 06/02/2014 14:23:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetIndexReturn]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetIndexReturn]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetIndexReturn]    Script Date: 06/02/2014 14:23:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE Function [APXUserCustom].[fGetIndexReturn](@PortfolioID int, @IndexID int, @ReportingCurrencyCode varchar(2), @StartDate datetime, @EndDate datetime)
returns float
with execute as caller
begin

return (SELECT DISTINCT
CASE WHEN IndexName = 'Blend'
then
APXUserCustom.fGetSynthIndexReturn(@PortfolioID, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=@PortfolioID) ELSE @ReportingCurrencyCode END, @StartDate, @EndDate)
ELSE
(((er.Rate * APXUserCustom.fGetFXRate(m.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=@PortfolioID) ELSE @ReportingCurrencyCode END, @EndDate)) - (sr.Rate * APXUserCustom.fGetFXRate(m.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=@PortfolioID) ELSE @ReportingCurrencyCode END, @StartDate)))/ (sr.Rate * APXUserCustom.fGetFXRate(m.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=@PortfolioID) ELSE @ReportingCurrencyCode END, @StartDate)) )* 100
end
FROM
APXUser.vMarketIndex m
LEFT OUTER JOIN APXUser.vMarketIndexRate sr on m.IndexID = sr.IndexID and sr.AsOfDate = @StartDate
LEFT OUTER JOIN APXUser.vMarketIndexRate er on m.IndexID = er.IndexID and er.AsOfDate = @EndDate
where m.IndexID = @IndexID
)
end






GO

