if object_id('[APXUserCustom].[pPerformanceHistoryPeriod]') is not null
	drop procedure [APXUserCustom].[pPerformanceHistoryPeriod]
go

-- exec [APXUserCustom].[pPerformanceHistoryPeriod] null, '@Fidelity', '03/31/14', 'MTD,QTD,YTD'

create procedure [APXUserCustom].[pPerformanceHistoryPeriod]
	@SessionGuid nvarchar(max),
	@Portfolios nvarchar(32),
	@ToDate datetime,
	@Periods nvarchar(max),

	-- Optional parameters for sqlrep proc
    @AccruePerfFees bit = null,
    @AllocatePerfFees bit = null,
	@FeeMethod int = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings

	-- Other optional parameters
	@AnnualizeReturns char(1) = null,			-- no Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null	-- Use Settings
as begin

declare @PerformanceHistoryPeriod varbinary(max)
	--,@PerformanceHistoryDetail varbinary(max)
	--,@PerformanceHistory varbinary(max)
	--,@DataHandle uniqueidentifier
	,@ShowIndexes bit = 0

--select @DataHandle = newid()

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @delimitedPeriods nvarchar(max)
set @delimitedPeriods = ',' + @Periods + ','

exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	-- Parameters internal to this proc that are derived from other parameters.
	@FeeMethod = @FeeMethod, -- Need for determining @ShowFees.
	@ReportingCurrencyCode = @ReportingCurrencyCode out

exec APXUser.pPerformanceHistoryPeriod @ReportData = @PerformanceHistoryPeriod out
	,@Portfolios = @Portfolios
	,@FromDate = @ToDate
	,@ToDate = @ToDate
	,@ClassificationID = -9
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@FeeMethod = @FeeMethod
	,@AccruePerfFees = @AccruePerfFees
	,@AllocatePerfFees = @AllocatePerfFees
	,@AnnualizeReturns = @AnnualizeReturns
	,@LocaleID = @LocaleID

--exec APXUser.pPerformanceHistoryBatch
--	@DataHandle = @DataHandle
--	,@DataName = 'PerformanceHistory'
--	,@Portfolios = @Portfolios
--	,@FromDate = @ToDate
--	,@ToDate = @ToDate
--	,@ClassificationID = -9
--	,@InceptionToDate = 1
--	,@ReportingCurrencyCode = @ReportingCurrencyCode out
--	,@IntervalLength = 1
--	,@LocaleID = @LocaleID

--exec APXUser.pReportBatchExecute @DataHandle = @DataHandle, @ExplodeData = 0

--exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistoryPeriod', @ReportData = @PerformanceHistoryPeriod out
--exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory', @ReportData = @PerformanceHistory out


select
  ph.PortfolioBaseIDOrder,
  ph.PortfolioBaseID,
  p.PortfolioBaseCode,
  p.ReportHeading1,
  p.ReportHeading2,
  p.ReportHeading3,
  ph.ClassificationMemberCode,
  ClassificationMemberName = (case 
		when ph.ClassificationMemberName = 'Total' then isnull(p.ReportHeading1, p.PortfolioBaseCode)
		when ph.ClassificationMemberName = 'Portfolio' then isnull(p.ReportHeading1, p.PortfolioBaseCode)
		end),
  ph.ClassificationMemberOrder,
    
  -- Day to Date
  DayToDateEffectiveTWR = ph.DayToDateAnnualizedTWR,
  DayToDateHeader = (case
		when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Day' + APX.fNewline(1) + 'To Date'
		else 'Day' + APX.fNewline(1) + 'To Date' end),
  ph.DayToDatePeriodFromDate,
  DayToDateShowPeriod = convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
  -- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
  -- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
  -- Otherwise zero decimals
  p.FormatReportingCurrency,
  -- Inception To Date
  InceptionToDateEffectiveTWR = ph.InceptionToDateAnnualizedTWR,
  InceptionToDateHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Inception' + APX.fNewline(1) + 'To Date'
		else 'Inception' + APX.fNewline(1) + 'To Date' end),
  ph.InceptionToDatePeriodFromDate,
  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  
  ph.IsIndex,
  --ph.IsShortPosition,
  
  -- Latest 1 Year
  Latest1YearEffectiveTWR = ph.Latest1YearAnnualizedTWR,
  Latest1YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest1YearPeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '1 Year'
		else 'Latest' + APX.fNewline(1) + '1 Year' end),
  ph.Latest1YearPeriodFromDate,
  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  
  -- Latest 3 Years
  Latest3YearsEffectiveTWR = ph.Latest3YearsAnnualizedTWR,
  Latest3YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest3YearsPeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '3 Years'
		else 'Latest' + APX.fNewline(1) + '3 Years' end),
  ph.Latest3YearsPeriodFromDate,
  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 5 Years
  Latest5YearsEffectiveTWR = ph.Latest5YearsAnnualizedTWR,
  Latest5YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest5YearsPeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '5 Years'
		else 'Latest' + APX.fNewline(1) + '5 Years' end),
  ph.Latest5YearsPeriodFromDate,
  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  p.LocaleID,
  
  -- Month to Date
  MonthToDateEffectiveTWR = ph.MonthToDateAnnualizedTWR,
  MonthToDateHeader = (case
		when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Month' + APX.fNewline(1) + 'To Date'
		else 'Month' + APX.fNewline(1) + 'To Date' end),
  ph.MonthToDatePeriodFromDate,
  MonthToDatesShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  
  -- Quarter to Date
  QuarterToDateEffectiveTWR = ph.QuarterToDateAnnualizedTWR,
  QuarterToDateHeader = (case
		when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Quarter' + APX.fNewline(1) + 'To Date'
		else 'Quarter' + APX.fNewline(1) + 'To Date' end),
  ph.QuarterToDatePeriodFromDate,
  QuarterToDateShowPeriod = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  --ph.SecTypeCode,
  --ph.SecurityID,
  
  -- Since Date IRR
  SinceDateIRREffectiveTWR = ph.SinceDateAnnualizedIRR,
  SinceDateIRRHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.SinceDateIRRPeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Since IRR' + APX.fNewline(1)
		else 'Since IRR' + APX.fNewline(1) end),
  ph.SinceDateIRRPeriodFromDate,
  SinceDateIRRShowPeriod = convert(bit, case when charindex( ',DTDIRR,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Since Date TWR
  SinceDateTWREffectiveTWR = ph.SinceDateAnnualizedTWR,
  SinceDateTWRHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate)) then 'Annualized' + APX.fNewline(1) + 'Since TWR' + APX.fNewline(1)
		else 'Since TWR' + APX.fNewline(1) end),
  ph.SinceDateTWRPeriodFromDate,
  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  ph.ThruDate,
  
  -- Week To Date
  WeekToDateEffectiveTWR = ph.WeekToDateAnnualizedTWR,
  WeekToDateHeader = (case
		when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Week' + APX.fNewline(1) + 'To Date'
		else 'Week' + APX.fNewline(1) + 'To Date' end),
  ph.WeekToDatePeriodFromDate,
  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Year To Date        
  YearToDateEffectiveTWR = ph.YearToDateAnnualizedTWR,
  YearToDateHeader = (case
		when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Year' + APX.fNewline(1) + 'To Date'
		else 'Year' + APX.fNewline(1) + 'To Date' end),
  ph.YearToDatePeriodFromDate,
  YearToDateShowPeriod = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  ph.DayToDateBeginningMarketValue [DTDBeginningMarketValue],
  ph.WeekToDateBeginningMarketValue [WTDBeginningMarketValue],
  ph.MonthToDateBeginningMarketValue [MTDBeginningMarketValue],
  ph.QuarterToDateBeginningMarketValue [QTDBeginningMarketValue],
  ph.YearToDateBeginningMarketValue [YTDBeginningMarketValue],
  ph.Latest1YearBeginningMarketValue [L1YBeginningMarketValue],
  ph.Latest3YearsBeginningMarketValue [L3YBeginningMarketValue],
  ph.Latest5YearsBeginningMarketValue [L5YBeginningMarketValue],
  ph.InceptionToDateBeginningMarketValue [ITDBeginningMarketValue] 
from
	APXUser.fPerformanceHistoryPeriod(@PerformanceHistoryPeriod) ph 
	--join APXUser.vPortfolioBaseSettingEx portfolioBase on
	--	portfolioBase.PortfolioBaseID = ph.PortfolioBaseID
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  		p.PortfolioBaseID = ph.PortfolioBaseID
	--join ApxUser.vCurrency reportingCurrency on
	--	reportingCurrency.CurrencyCode = @ReportingCurrencyCode	
where
	(case when @ShowIndexes = 0 and ph.IsIndex = 1 then 0 else 1 end) = 1
order by
	ph.PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder
end