if object_id('[APXUserCustom].[pMDS_ParsecPortfolioSummaryReport]') is not null
	drop procedure [APXUserCustom].[pMDS_ParsecPortfolioSummaryReport]
go

CREATE procedure [APXUserCustom].[pMDS_ParsecPortfolioSummaryReport]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@Date datetime,
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@IncludeClosedPortfolios bit = null,
	@IncludeUnsupervisedAssets bit = null,
--	@AccruedInterestID int = null,			-- Use Settings (0)
	@UseSettlementDate bit = null,			-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@YieldOptionID int = null,				-- Use Settings (0)
	@OverridePortfolioSettings bit = null
	
as
begin
-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@YieldOptionID = @YieldOptionID, -- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out -- A boolean that is derived from multi-valued @YieldOptionID.
-- 4. Select the columns for the report.

declare @DataHandle as uniqueidentifier = newid()
-- Execute the sqlrep proc that will fill the @ReportData
-- To get the effective value for 'Use Settings' parameters, specify 'out'
exec APXUser.pAppraisalBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @Date,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@YieldOptionID = @YieldOptionID,
	@OverridePortfolioSettings = @OverridePortfolioSettings

exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData= 1

declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Appraisal', @ReportData = @ReportData out
-- Select the columns for the report
SELECT 
	DataHandle = @DataHandle,
	FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
	p.LocaleID,
	p.PrefixedPortfolioBaseCode,
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	a.ReportDate,
	p.ReportHeading1,	
	p.ReportHeading2,
	p.ReportHeading3,
	Custom.compos [compos],
	Custom.cgtot [cgtot],
	Custom.egtot [egtot],
	Custom.fgtot [fgtot],
	p.ReportingCurrencyCode,
    p.ReportingCurrencyName,
	-- The effective value of @UseSettlementDate.
	-- If @UseSettlementDate is specified (but not null), then @UseSettlementDate.
	-- Otherwise Configuration.UseSettlementDate.
	UseSettlementDate = @UseSettlementDate
FROM APXUser.fReportDataIndex(@ReportData) a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
join APXUser.vPortfolioBaseCustom Custom on 
	Custom.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder
end

GO


