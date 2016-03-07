IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fPortfolioBase]'))
DROP FUNCTION [APXUserCustom].[fPortfolioBase]
GO

create function [APXUserCustom].[fPortfolioBase](
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
		FormatReportingCurrency = case @ShowCurrencyFullPrecision
			when 1 then (case rc.CurrencyPrecision when 0 then '#,0' else '#,0.' + REPLICATE('0', rc.CurrencyPrecision) end)
			else '#,0' end,
		LocaleID = coalesce(@LocaleID, prt.LocaleID, usr.LocaleID, glb.LocaleID), -- $locale
		PrefixedPortfolioBaseCode = (case pbo.ClassID when 88 then '+@' when 94 then '+&' else '' end) + pbo.Name,
		PortfolioBaseCode = pbo.Name,
		ReportHeading1 = isnull(nullif(pbo.DisplayName, ''), '?'), -- $name
		ReportHeading2 = nullif(prt.ReportHeading2, ''), -- $name2
		ReportHeading3 = nullif(prt.ReportHeading3, ''), -- $name3
		ReportingCurrencyCode = rc.CurrencyCode, -- $fx
		ReportingCurrencyName = rc.CurrencyName,
		ReportingCurrencySymbol = rc.CurrencySymbol
	from dbo.AdvPortfolioBase prt
	join dbo.AoObject pbo on
		pbo.ObjectID = prt.PortfolioBaseID
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