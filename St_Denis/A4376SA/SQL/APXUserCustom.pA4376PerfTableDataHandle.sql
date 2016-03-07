USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pA4376PerfTableDataHandle]    Script Date: 2/24/2015 9:04:27 AM ******/
DROP PROCEDURE [APXUserCustom].[pA4376PerfTableDataHandle]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pA4376PerfTableDataHandle]    Script Date: 2/24/2015 9:04:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [APXUserCustom].[pA4376PerfTableDataHandle]
@SessionGuid nvarchar(48),
@Portfolios nvarchar(max),
@FromDate datetime,
@ToDate datetime,
@ReportingCurrencyCode dtCurrencyCode,
@customClassification int,  --for the performance reporting, inclusion of clasifications

-- Optional parameters
@FiscalYearStartDate datetime = null,
@IncludeClosedPortfolios bit = null,
@IncludeUnsupervisedAssets bit = null,
@FeeMethod int = null,
@UseACB bit = null,						-- Use Settings
@AccruePerfFees bit = null,
@AllocatePerfFees bit = null,
@AnnualizeReturns char(1) = null,			-- no Use Settings
@Period1 char(3) = null,
@Period2 char(3) = null,

@ShowTaxLotsLumped bit = null,			-- Use Settings
@AccruedInterestID int = null,			-- Use Settings (0)
@YieldOptionID int = null,				-- Use Settings (0)
@BondCostBasisID int = null,			-- Use Settings (0)
@MFBasisIncludeReinvest bit = null,		-- Use Settings
@ShowMultiCurrency bit = null,			-- Use Settings
@UseSettlementDate bit = null,			-- Use Settings
@ShowCurrentMBSFace bit = null,			-- Use Settings
@ShowCurrentTIPSFace bit = null,		-- Use Settings
@LocaleID int = null,					-- Use Portfolio Settings
@PriceTypeID int = null,
@OverridePortfolioSettings bit = null
as
begin
/*
Changelog
01212015 request to add 10 year returns to performance history period.  Will implement this using SinceDate by running proc with FromDate = @ToDate - 10 years.
Then updating ApxUserCustom.pA4376PerfTableDataHandle to override the SinceDateTWR if InceptionDate > 10 year date.  This is because
pPerformanceHistoryPeriod returns a TWR instead of null and annualizes it to the 10 year period whichis not correct behavior for client request.--MWB
*/

-- Set the Session Guid and Data Handle
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()
declare @ClassificationID int = -9 -- PortPerf
-- Get the effective parameter values for parameters that are not passed to pAppraisal.
declare @ShowFees bit
EXEC APXUser.pGetEffectiveParameter
@FeeMethod = @FeeMethod,   -- input for @ShowFees
@ShowFees = @ShowFees out,
@UseSettlementDate = @UseSettlementDate out,
@ShowMultiCurrency = @ShowMultiCurrency out
-- ***************  Appraisal ***************
declare @Date datetime = @ToDate
declare @CompositeFromDate datetime = @FromDate
declare @CompositeToDate datetime = @ToDate
exec APXUser.pAppraisalBatch

-- Required Parameters
@DataHandle = @DataHandle,
@DataName = 'Appraisal',
@Portfolios = @Portfolios,
@Date = @Date,

-- Optional Parameters
@ReportingCurrencyCode = @ReportingCurrencyCode out,
@CompositeFromDate = @CompositeFromDate,
@CompositeToDate = @CompositeToDate,
@FiscalYearStartDate = @FiscalYearStartDate,
@IncludeClosedPortfolios = @IncludeClosedPortfolios,
@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
@ShowTaxLotsLumped = @ShowTaxLotsLumped out,
@AccruedInterestID = @AccruedInterestID,
@YieldOptionID = @YieldOptionID out,
@BondCostBasisID  = @BondCostBasisID out,			-- Use Settings (0)
@MFBasisIncludeReinvest = @MFBasisIncludeReinvest out,
@UseSettlementDate = @UseSettlementDate out,
@ShowCurrentMBSFace  = @ShowCurrentMBSFace out,			-- Use Settings
@ShowCurrentTIPSFace  = @ShowCurrentTIPSFace out,		-- Use Settings
@LocaleID = @LocaleID,
@PriceTypeID = @PriceTypeID,
@OverridePortfolioSettings = @OverridePortfolioSettings
-- ***************  Performance Period 1 ***************
declare @InceptionToDate1 bit = 0
declare @PerfFromDate1 datetime = @FromDate
if @Period1 is not null
	begin
	set @PerfFromDate1 = APXSSRS.fFromDate(@PerfFromDate1, @ToDate, @Period1)
	if @Period1 in ('ITD','SSD') set @PerfFromDate1 = @FromDate
	--set @InceptionToDate1 = case @Period1 when 'ITD' then 1 else 0 end
	end
exec APXUser.pPerformanceHistoryDetailBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformancePeriod1',
	@Portfolios = @Portfolios,
	@FromDate = @PerfFromDate1,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	--@UseACB = @UseACB out,
	@AccruePerfFees = @AccruePerfFees out,
	@AllocatePerfFees = @AllocatePerfFees,
	@InceptionToDate = @InceptionToDate1,
	--@AccruedInterestID = @AccruedInterestID,
	@LocaleID = @LocaleID
	--@PriceTypeID = @PriceTypeID,
	--@OverridePortfolioSettings = @OverridePortfolioSettings
-- ***************  Performance Period 2 ***************
declare @InceptionToDate2 bit = 0
declare @PerfFromDate2 datetime = @FromDate
if @Period2 is not null
	begin
	set @PerfFromDate2 = APXSSRS.fFromDate(@PerfFromDate2, @ToDate, @Period2)
	if @Period2 in ('ITD','SSD') set @PerfFromDate2 = @FromDate
	--set @InceptionToDate2 = case @Period2 when 'ITD' then 1 else 0 end
	end
exec APXUser.pPerformanceHistoryDetailBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformancePeriod2',
	@Portfolios = @Portfolios,
	@FromDate = @PerfFromDate2,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	--@UseACB = @UseACB out,
	@AccruePerfFees = @AccruePerfFees out,
	@AllocatePerfFees = @AllocatePerfFees,
	@InceptionToDate = @InceptionToDate2,
	--@AccruedInterestID = @AccruedInterestID,
	@LocaleID = @LocaleID
	--@PriceTypeID = @PriceTypeID,
	--@OverridePortfolioSettings = @OverridePortfolioSettings
-- ***************  Performance History Detail ***************
exec APXUser.pPerformanceHistoryDetailBatch
-- Required Parameters
@DataHandle = @DataHandle,
@DataName = 'PerformanceHistoryDetail',
@Portfolios = @Portfolios,
@FromDate = @FromDate,
@ToDate = @ToDate,
@ClassificationID = @ClassificationID,
-- Optional Parameters
@ReportingCurrencyCode = @ReportingCurrencyCode out,
@FeeMethod = @FeeMethod,
@AccruePerfFees = @AccruePerfFees,
@AllocatePerfFees = @AllocatePerfFees,
@LocaleID = @LocaleID
-- ***************  Performance History Summary***************
declare @PerfHistPeriodFromDate datetime
set @PerfHistPeriodFromDate = CASE WHEN MONTH(@ToDate) = 2 AND Day(@ToDate) = 29 THEN ApxUser.fGetGenericDate('{edtm}', DATEADD(year, -10, @ToDate)) ELSE DATEADD(year, -10, @ToDate) END --MWB 01212015
exec APXUser.pPerformanceHistoryPeriodBatch
-- Required Parameters
@DataHandle = @DataHandle,
@DataName = 'PerformanceHistorySummary',
@Portfolios = @Portfolios,
@FromDate = @PerfHistPeriodFromDate,
@ToDate = @ToDate,
@ClassificationID = @customClassification,
-- Optional Parameters
@ReportingCurrencyCode = @ReportingCurrencyCode out,
@FeeMethod = @FeeMethod,
@AccruePerfFees = @AccruePerfFees,
@AllocatePerfFees = @AllocatePerfFees,
@AnnualizeReturns = @AnnualizeReturns,
@LocaleID = @LocaleID
-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=1
-- ***************  Get Portfolio Overview Portfolio List ***************
declare @ReportPOData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistoryDetail', @ReportData = @ReportPOData out
SELECT
DataHandle = @DataHandle,
FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
a.FromDate,
p.LegacyLocaleID,
p.LocaleID,
a.PortfolioBaseID,
a.PortfolioBaseIDOrder,
p.ReportHeading1,
p.ReportHeading2,
p.ReportHeading3,
p.ReportingCurrencyCode,
p.ReportingCurrencyName,
a.ThruDate,
ShowMultiCurrency = @ShowMultiCurrency,
UseSettlementDate = @UseSettlementDate
FROM APXUser.fReportDataIndex(@ReportPOData) a
join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, 0) p on
p.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder
end

GO
