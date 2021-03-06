USE [APXFirm]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPortfolioOverview_D85383SA]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pReportPortfolioOverview_D85383SA] 
GO 

create procedure [APXUserCustom].[pReportPortfolioOverview_D85383SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,
	@ReportingCurrencyCode dtCurrencyCode,
	
	-- Optional parameters
	@FiscalYearStartDate datetime = null,
	@IncludeClosedPortfolios bit = null,
	@IncludeUnsupervisedAssets bit = null,

	@FeeMethod int = null,
	@UseACB bit = null,						-- Use Settings
	@UseIRRCalc bit = null,
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@AnnualizeReturns bit = null,			-- no Use Settings
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

-- ***************  Appraisal  ***************
declare @CompositeFromDate datetime = @FromDate
declare @CompositeToDate datetime = @ToDate

exec APXUser.pAppraisalBatch
    
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @ToDate,
    
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@CompositeFromDate = @CompositeFromDate,
	@CompositeToDate = @CompositeToDate,
	@FiscalYearStartDate = @FiscalYearStartDate,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = 1,
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
	set @InceptionToDate1 = case @Period1 when 'ITD' then 1 else 0 end
	end

exec APXUser.pPerformanceBatch
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
	@UseACB = @UseACB out,
	@AccruePerfFees = @AccruePerfFees out,
	@AllocatePerfFees = @AllocatePerfFees,
	@InceptionToDate = @InceptionToDate1,
	@AccruedInterestID = @AccruedInterestID,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@OverridePortfolioSettings = @OverridePortfolioSettings

-- ***************  Performance Period 2 ***************
declare @InceptionToDate2 bit = 0
declare @PerfFromDate2 datetime = @FromDate
if @Period2 is not null
	begin
	set @PerfFromDate2 = APXSSRS.fFromDate(@PerfFromDate2, @ToDate, @Period2)
	set @InceptionToDate2 = case @Period2 when 'ITD' then 1 else 0 end
	end

exec APXUser.pPerformanceBatch
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
	@UseACB = @UseACB out,
	@AccruePerfFees = @AccruePerfFees out,
	@AllocatePerfFees = @AllocatePerfFees,
	@InceptionToDate = @InceptionToDate2,
	@AccruedInterestID = @AccruedInterestID,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@OverridePortfolioSettings = @OverridePortfolioSettings

-- ***************  Appraisal Period 1 ***************
exec APXUser.pAppraisalBatch
    
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal1',
	@Portfolios = @Portfolios,
	@Date = @PerfFromDate1,
    
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@CompositeFromDate = @CompositeFromDate,
	@CompositeToDate = @CompositeToDate,
	@FiscalYearStartDate = @FiscalYearStartDate,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = 1,
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

-- ***************	Transactions Period 1	****************
declare @TranFromDate1 datetime = @PerfFromDate1
if @InceptionToDate1 = 1
begin
set @TranFromDate1 = '01/01/1904'
end

exec APXUser.pTransactionActivityBatch
	@DataHandle = @DataHandle,
	@DataName = 'Transaction1',
	@Portfolios = @Portfolios,
	@FromDate = @TranFromDate1,
	@ToDate = @ToDate,
	@ReportingCurrencyCode = @ReportingCurrencyCode,
	@IncludeUnsupervisedAssets = 1,
	@UseSettlementDate = @UseSettlementDate,
	@PriceTypeID = @PriceTypeID,
	@LocaleID = @LocaleID

-- ***************	Realized Gain Loss Period 1	****************
exec APXUser.pRealizedGainLossBatch
	@DataHandle = @DataHandle,
	@DataName = 'RealizedGainLoss1',
	@Portfolios = @Portfolios,
	@FromDate = @TranFromDate1,
	@ToDate = @ToDate,
	
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@IncludeUnsupervisedAssets = 1,
	@BondCostBasisID = @BondCostBasisID,
	@UseSettlementDate = @UseSettlementDate,
	@PriceTypeID = @PriceTypeID,
	@LocaleID = @LocaleID

if @Period2 is not null
begin
	-- ***************  Appraisal Period 2 ***************
	exec APXUser.pAppraisalBatch
	    
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'Appraisal2',
		@Portfolios = @Portfolios,
		@Date = @PerfFromDate2,
	    
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@CompositeFromDate = @CompositeFromDate,
		@CompositeToDate = @CompositeToDate,
		@FiscalYearStartDate = @FiscalYearStartDate,
		@IncludeClosedPortfolios = @IncludeClosedPortfolios,
		@IncludeUnsupervisedAssets = 1,
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

	-- ***************	Transactions Period 2	****************
declare @TranFromDate2 datetime = @PerfFromDate2
	if @InceptionToDate2 = 1
	begin
	set @TranFromDate2 = '01/01/1904'
	end
	exec APXUser.pTransactionActivityBatch
		@DataHandle = @DataHandle,
		@DataName = 'Transaction2',
		@Portfolios = @Portfolios,
		@FromDate = @TranFromDate2,
		@ToDate = @ToDate,
		@ReportingCurrencyCode = @ReportingCurrencyCode,
		@IncludeUnsupervisedAssets = 1,
		@UseSettlementDate = @UseSettlementDate,
		@PriceTypeID = @PriceTypeID,
		@LocaleID = @LocaleID

	-- ***************	Realized Gain Loss Period 2	****************
	exec APXUser.pRealizedGainLossBatch
		@DataHandle = @DataHandle,
		@DataName = 'RealizedGainLoss2',
		@Portfolios = @Portfolios,
		@FromDate = @TranFromDate2,
		@ToDate = @ToDate,
		
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@IncludeUnsupervisedAssets = 1,
		@BondCostBasisID = @BondCostBasisID,
		@UseSettlementDate = @UseSettlementDate,
		@PriceTypeID = @PriceTypeID,
		@LocaleID = @LocaleID
end

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

-- ***************  Performance History Summary ***************
declare @ExcludeSinceDateIRR bit = 1
SELECT @FromDate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@ToDate),0))
exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistorySummary',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = @AnnualizeReturns,
	@UseIRRCalc = @UseIRRCalc,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=1 --	2014.01.24 AZK this needs to be set to 1 for this to work properly

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
	UseSettlementDate = @UseSettlementDate,
	p.PrefixedPortfolioBaseCode
FROM APXUser.fReportDataIndex(@ReportPOData) a
join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder
end
