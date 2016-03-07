IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pMDS_ReportPerformancePeriodHousehold]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pMDS_ReportPerformancePeriodHousehold]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pMDS_ReportPerformancePeriodHousehold]    Script Date: 01/17/2014 20:47:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*	Test code
exec [APXUserCustom].[pMDS_ReportPerformancePeriodHousehold]
	-- Required Parameters
	@SessionGuid = null,
	@Portfolios ='@BarnesFamilyHoldings',
	@ToDate = '12/31/08',
	@ClassificationID = -9,
	@OverridePortfolioSettings = 1,
	@AccruedInterestID = null
*/
create procedure [APXUserCustom].[pMDS_ReportPerformancePeriodHousehold]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
--	@FromDate datetime,
	@ToDate datetime,
	@ClassificationID int,
	-- Optional parameters for sqlrep proc
	@OverridePortfolioSettings bit,
	@AccruedInterestID int,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	-- Other optional parameters
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null	-- Use Settings
as
begin
declare @FromDate datetime
select @FromDate = APXUser.fGetGenericDate('{edly}', @ToDate)

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()
-- Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @consolidate bit = 0
select @consolidate = case SUBSTRING(@Portfolios,1,1) when  '@' then 1 when '&' then 1 else 0 end
declare @ExcludeSinceDateIRR bit = 1
	,@Portfolios1 nvarchar(max) 
if @consolidate = 1
	begin
		set @Portfolios1 = '+' + @Portfolios
	end
else
	begin
		set @Portfolios1 = @Portfolios	
	end
exec APXUser.pPerformanceBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Performance',
	@Portfolios = @Portfolios1,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@LocaleID = @LocaleID

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 0
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Performance', @ReportData = @ReportData out
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @ShowFees bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	-- Parameters internal to this proc that are derived from other parameters.
	@ShowFees = @ShowFees out -- A boolean that is derived from @FeeMethod
-- 4. Set some miscellaneous working variables
SELECT 
		p.FormatReportingCurrency,
		p.LocaleID,
		ShowAccruedInterest = APXUser.fShowAccruedInterestOnPerformanceReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID),
		ShowFees = 1,--@ShowFees,
		--UseACB = @UseACB,
		perf.MarketValueDate1,
		perf.AccruedInterestDate1,
		perf.Additions,
		perf.Withdrawals,
		perf.TransfersIn,
		perf.TransfersOut,
		perf.Dividends,
		perf.Interest,
		perf.AccruedInterestDelta,
		perf.RealizedGainLossOnMval,
		perf.UnrealizedGainLossOnMval,
		perf.PriceRealizedGainLossOnMval,
		perf.PriceUnrealizedGainLossOnMval,
		perf.FXRealizedGainLossOnMval,
		perf.FXUnrealizedGainLossOnMval,
		perf.ManagementFees,
		perf.ManagementFeesPaidByClient,
		perf.PortfolioFees,
		perf.PortfolioFeesPaidByClient,
		perf.MarketValueDate2,
		perf.AccruedInterestDate2,
		perf.PortfolioBaseID,
		perf.FromDate,
		perf.ThruDate
	FROM APXUser.fPerformance(@ReportData) perf
		join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
			p.PortfolioBaseID = perf.PortfolioBaseID
	ORDER BY perf.PortfolioBaseIDOrder, perf.ClassificationMemberID, ClassificationMemberName	
end

GO


