USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fPortfolioBase]    Script Date: 12/01/2013 18:42:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fPortfolioBase]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fPortfolioBase]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fPortfolioBase]    Script Date: 12/01/2013 18:42:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--	$Header: $/APX/Trunk/APX/APXDatabase/APXFirm/Function/APXSSRS/fPortfolioBase.sql  2012-01-05 08:38:42 PST  ADVENT/astanchi $
CREATE function [APXUserCustom].[fPortfolioBase](
	@LocaleID dtID,
	@ReportingCurrencyCode dtCurrencyCode,
	@ShowCurrencyFullPrecision dtBoolean
	)
returns table
as
return
	select
		prt.PortfolioBaseID,
		AccruedInterestID = coalesce(nullif(prt.AccruedInterestID, 0), nullif(usr.AccruedInterestID, 0), glb.AccruedInterestID),
		rc.CurrencyPrecision,
		-- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
		-- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
		-- Otherwise zero decimals
		FormatReportingCurrency = case @ShowCurrencyFullPrecision
			when 1 then (case rc.CurrencyPrecision when 0 then '#,0' else '#,0.' + REPLICATE('0', rc.CurrencyPrecision) end)
			else '#,0' end,
		LocaleID = coalesce(@LocaleID, prt.LocaleID, usr.LocaleID, glb.LocaleID), -- $locale
		PrefixedPortfolioBaseCode = (case pbo.ClassID when 88 then '+@' when 94 then '+&' else '' end) + pbo.Name,
		PortfolioBaseCode = pbo.Name,
		ReportHeading1 = isnull(nullif(pbo.DisplayName, ''), '?'), -- $name
		-- CoverPage uses '', not null for the next 2
		ReportHeading2 = nullif(prt.ReportHeading2, ''), -- $name2
		ReportHeading3 = nullif(prt.ReportHeading3, ''), -- $name3
		ReportingCurrencyCode = rc.CurrencyCode, -- $fx
		ReportingCurrencyName = rc.CurrencyName,
		ReportingCurrencySymbol = rc.CurrencySymbol
	from dbo.AdvPortfolioBase prt
	join dbo.AoObject pbo on
		pbo.ObjectID = prt.PortfolioBaseID
--	join dbo.AoUser on AoUser.UserID = APX.fGetApxUserRunAsUserID()
--	join dbo.AdvPortfolioBase usr on usr.PortfolioBaseID = AoUser.DefaultConfigurationID
	join dbo.AdvPortfolioBase usr on
		usr.PortfolioBaseID = APX.fGetApxUserConfigurationID()
	join dbo.AdvPortfolioBase glb on
		glb.PortfolioBaseID = dbo.fQbGetNetwideID()
	join APX.PortfolioSetting glbs on
		glb.PortfolioBaseID = glbs.PortfolioSettingID
	join dbo.AdvCurrency rc on
		rc.CurrencyCode = case @ReportingCurrencyCode
			when 'PC' then coalesce(prt.ReportingCurrencyCode, usr.ReportingCurrencyCode, glb.ReportingCurrencyCode, glbs.DefaultSettlementCurrencyCode)
			else @ReportingCurrencyCode end
/* This makes pReportChangeInPortfolioChartNew REALLY SLOW
	-- find FirmLogo
	left join advapp.vPortfolioBaseLabels prtl on
		prtl.PortfolioBaseID = prt.PortfolioBaseID and
		prtl.Label = '$flogo'
	left join advapp.vPortfolioBaseLabels usrl on
		usrl.PortfolioBaseID = usr.PortfolioBaseID and
		usrl.Label = '$flogo'
	left join advapp.vPortfolioBaseLabels glbl on
		glbl.PortfolioBaseID = glb.PortfolioBaseID and
		glbl.Label = '$flogo'
*/



GO


