IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPerformanceHistoryPeriodHousehold]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportPerformanceHistoryPeriodHousehold]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- $Header: $/APX/Trunk/APX/APXDatabase/APXFirm/sp/SSRSReports/pReportPerformanceHistoryPeriodHousehold.sql  2012-01-05 08:38:42 PST  ADVENT/astanchi $
create procedure [APXUserCustom].[pReportPerformanceHistoryPeriodHousehold]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,
	@ClassificationID int,
	@Periods nvarchar(max),
	-- Optional parameters for sqlrep proc
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@FeeMethod int = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@UseIRRCalc bit = null,
	-- Other optional parameters
	@AnnualizeReturns char(1) = null,			-- no Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@ShowIndexes bit = 1 -- default to 1 for for backward-compatibility
as
begin
-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()
-- Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @consolidate bit = 0
select @consolidate = case SUBSTRING(@Portfolios,1,1) when  '@' then 1 when '&' then 1 else 0 end
declare @ExcludeSinceDateIRR bit = 1
if @consolidate = 1
	begin
		declare @Portfolios1 nvarchar(max) 
		set @Portfolios1 = '+' + @Portfolios
		exec APXUser.pPerformanceHistoryPeriodBatch
			-- Required Parameters
			@DataHandle = @DataHandle,
			@DataName = 'PerformanceHistoryParent',
			@Portfolios = @Portfolios1,
			@FromDate = @FromDate,
			@ToDate = @ToDate,
			@ClassificationID = @ClassificationID,
			-- Optional Parameters
			@ReportingCurrencyCode = @ReportingCurrencyCode out,
			@FeeMethod = @FeeMethod,
			@AccruePerfFees = @AccruePerfFees,
			@AllocatePerfFees = @AllocatePerfFees,
			@UseIRRCalc = @UseIRRCalc,
			@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
			@LocaleID = @LocaleID
	end
exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistory',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@UseIRRCalc = @UseIRRCalc,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID
-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 0
declare @ReportData varbinary(max)
if @consolidate = 1
	begin
	declare @ReportData1 varbinary(max)
	exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistoryParent', @ReportData = @ReportData1 out
	end
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory', @ReportData = @ReportData out
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out
-- 4. Set some miscellaneous working variables
declare @delimitedPeriods nvarchar(max)
set @delimitedPeriods = ',' + @Periods + ','
--declare @timer datetime = getdate()
if @consolidate = 1
	begin
		select
		  ph.ClassificationMemberCode,
		ClassificationMemberName = case
			when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
			else ph.ClassificationMemberName + 
				(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (Short)' end) +
				(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end) end,
		  --ClassificationMemberName = (case ph.ClassificationMemberName
				--when 'Total' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
				--when 'Portfolio' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
				--else  ph.ClassificationMemberName + 
				--	  case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (short)' end +
				--	  case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end 
				--end),
		  ph.ClassificationMemberOrder,
		    
		  -- Day to Date
		  ph.DayToDateBeginningMarketValue,
		  DayToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.DayToDateAnnualizedTWR / 100
				else ph.DayToDateTWR / 100 end),
		  ph.DayToDateEndingMarketValue,
		  ph.DayToDateExternallyPaidFees,
		  ph.DayToDateGainsFees,
		  DayToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Day' + APX.fNewline(1) + 'To Date'
				else 'Day' + APX.fNewline(1) + 'To Date' end),
		  ph.DayToDateNetAdditions,
		  ph.DayToDatePeriodFromDate,
		  DayToDateShowPeriod = convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
		  -- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
		  -- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
		  -- Otherwise zero (0).
		  p.FormatReportingCurrency,
		  ph.IsHeadOfHousehold,
		  -- Inception To Date
		  ph.InceptionToDateBeginningMarketValue,
		  InceptionToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then InceptionToDateAnnualizedTWR / 100
				else InceptionToDateTWR / 100 end),
		  ph.InceptionToDateEndingMarketValue,
		  ph.InceptionToDateExternallyPaidFees,
		  ph.InceptionToDateGainsFees,
		  InceptionToDateHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then 'Annualized' + APX.fNewline(1) + 'Inception' + APX.fNewline(1) + 'To Date'
				else 'Inception' + APX.fNewline(1) + 'To Date' end),
		  ph.InceptionToDateNetAdditions,
		  ph.InceptionToDatePeriodFromDate,
		  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  ph.IsIndex,
		  --ph.IsShortPosition,
		  
		  -- Latest 1 Year
		  ph.Latest1YearBeginningMarketValue,
		  Latest1YearEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then Latest1YearAnnualizedTWR / 100
				else Latest1YearTWR / 100 end),
		  ph.Latest1YearEndingMarketValue,
		  ph.Latest1YearExternallyPaidFees,
		  ph.Latest1YearGainsFees,
		  Latest1YearHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '1 Year'
				else 'Latest' + APX.fNewline(1) + '1 Year' end),
		  ph.Latest1YearNetAdditions,
		  ph.Latest1YearPeriodFromDate,
		  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Months
		  ph.Latest3MonthsBeginningMarketValue,
		  Latest3MonthsEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest3MonthsAnnualizedTWR / 100
				else Latest3MonthsTWR / 100 end),
		  ph.Latest3MonthsEndingMarketValue,
		  ph.Latest3MonthsExternallyPaidFees,
		  ph.Latest3MonthsGainsFees,
		  Latest3MonthsHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '3 Months'
				else 'Latest' + APX.fNewline(1) + '3 Months' end),
		  ph.Latest3MonthsNetAdditions,
		  ph.Latest3MonthsPeriodFromDate,
		  Latest3MonthsShowPeriod = convert(bit, case when charindex( ',L3M,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Years
		  ph.Latest3YearsBeginningMarketValue,
		  Latest3YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then Latest3YearsAnnualizedTWR / 100
				else Latest3YearsTWR / 100 end),
		  ph.Latest3YearsEndingMarketValue,
		  ph.Latest3YearsExternallyPaidFees,
		  ph.Latest3YearsGainsFees,
		  Latest3YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '3 Years'
				else 'Latest' + APX.fNewline(1) + '3 Years' end),
		  ph.Latest3YearsNetAdditions,
		  ph.Latest3YearsPeriodFromDate,
		  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Latest 5 Years
		  ph.Latest5YearsBeginningMarketValue,
		  Latest5YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then Latest5YearsAnnualizedTWR / 100
				else Latest5YearsTWR / 100 end),
		  ph.Latest5YearsEndingMarketValue,
		  ph.Latest5YearsExternallyPaidFees,
		  ph.Latest5YearsGainsFees,
		  Latest5YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '5 Years'
				else 'Latest' + APX.fNewline(1) + '5 Years' end),
		  ph.Latest5YearsNetAdditions,
		  ph.Latest5YearsPeriodFromDate,
		  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.LocaleID,
		  
		  -- Month to Date
		  ph.MonthToDateBeginningMarketValue,
		  MonthToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.MonthToDateAnnualizedTWR / 100
				else ph.MonthToDateTWR / 100 end),
		  ph.MonthToDateEndingMarketValue,
		  ph.MonthToDateExternallyPaidFees,
		  ph.MonthToDateGainsFees,
		  MonthToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Month' + APX.fNewline(1) + 'To Date'
				else 'Month' + APX.fNewline(1) + 'To Date' end),
		  ph.MonthToDateNetAdditions,
		  ph.MonthToDatePeriodFromDate,
		  MonthToDateShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.PrefixedPortfolioBaseCode,
		  ph.PortfolioBaseID,
		  ph.PortfolioBaseIDOrder,
		  
		  -- Quarter to Date
		  ph.QuarterToDateBeginningMarketValue,
		  QuarterToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.QuarterToDateAnnualizedTWR / 100
				else ph.QuarterToDateTWR / 100 end),
		  ph.QuarterToDateEndingMarketValue,
		  ph.QuarterToDateExternallyPaidFees,
		  ph.QuarterToDateGainsFees,
		  QuarterToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Quarter' + APX.fNewline(1) + 'To Date'
				else 'Quarter' + APX.fNewline(1) + 'To Date' end),
		  ph.QuarterToDateNetAdditions,
		  ph.QuarterToDatePeriodFromDate,
		  QuarterToDateShowPeriod = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  --ph.SecTypeCode,
		  --ph.SecurityID,
		  
		  -- Since Date TWR
		  ph.SinceDateBeginningMarketValue,
		  SinceDateTWREffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
					then ph.SinceDateAnnualizedTWR / 100
				else SinceDateTWR / 100 end),
		  ph.SinceDateEndingMarketValue,
		  ph.SinceDateExternallyPaidFees,
		  ph.SinceDateGainsFees,
		  SinceDateTWRHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
					then 'Annualized' + APX.fNewline(1) + 'Since TWR' + APX.fNewline(1)
				else 'Since TWR' + APX.fNewline(1) end),
		  ph.SinceDateNetAdditions,
		  ph.SinceDateTWRPeriodFromDate,
		  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  ph.ThruDate,
		  
		  -- Week To Date
		  ph.WeekToDateBeginningMarketValue,
		  WeekToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.WeekToDateAnnualizedTWR / 100
				else ph.WeekToDateTWR / 100 end),
		  ph.WeekToDateEndingMarketValue,
		  ph.WeekToDateExternallyPaidFees,
		  ph.WeekToDateGainsFees,
		  WeekToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Week' + APX.fNewline(1) + 'To Date'
				else 'Week' + APX.fNewline(1) + 'To Date' end),
		  ph.WeekToDateNetAdditions,
		  ph.WeekToDatePeriodFromDate,
		  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Year To Date      
		  ph.YearToDateBeginningMarketValue,
		  YearToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.YearToDateAnnualizedTWR / 100
				else ph.YearToDateTWR / 100 end),
		  ph.YearToDateEndingMarketValue,
		  ph.YearToDateExternallyPaidFees,
		  ph.YearToDateGainsFees,
		  YearToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Year' + APX.fNewline(1) + 'To Date'
				else 'Year' + APX.fNewline(1) + 'To Date' end),
		  ph.YearToDateNetAdditions,
		  ph.YearToDatePeriodFromDate,
		  YearToDateShowPeriod = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end)
		from
			( select 0 as IsHeadOfHousehold, ph1.* from APXUser.fPerformanceHistoryPeriod(@ReportData) ph1
				union all
			  select 1 as IsHeadOfHousehold, ph2.* from APXUser.fPerformanceHistoryPeriod(@ReportData1) ph2
			) ph 
			join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
				p.PortfolioBaseID = ph.PortfolioBaseID
			--join APXUser.vPortfolioBaseSettingEx portfolioBase on
			--	portfolioBase.PortfolioBaseID = ph.PortfolioBaseID
			--join ApxUser.vCurrency reportingCurrency on
			--	reportingCurrency.CurrencyCode = case @ReportingCurrencyCode
			--	when 'PC' then portfolioBase.ReportingCurrencyCode
			--	else @ReportingCurrencyCode end
		where @ShowIndexes = 1 or ph.IsIndex = 0
--		where
--			(case when @ShowIndexes = 0 and ph.IsIndex = 1 then 0 else 1 end) = 1
		order by
			PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder
	end
else
	begin
	select
		  ph.ClassificationMemberCode,
		ClassificationMemberName = case
			when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
			else ph.ClassificationMemberName + 
				(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (Short)' end) +
				(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end) end,
		  --ClassificationMemberName = (case ph.ClassificationMemberName
				--when 'Total' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
				--when 'Portfolio' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
				--else  ph.ClassificationMemberName + 
				--	  case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (short)' end +
				--	  case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end 
				--end),
		  ph.ClassificationMemberOrder,
		    
		  -- Day to Date
		  ph.DayToDateBeginningMarketValue,
		  DayToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.DayToDateAnnualizedTWR / 100
				else ph.DayToDateTWR / 100 end),
		  ph.DayToDateEndingMarketValue,
		  ph.DayToDateExternallyPaidFees,
		  ph.DayToDateGainsFees,
		  DayToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Day' + APX.fNewline(1) + 'To Date'
				else 'Day' + APX.fNewline(1) + 'To Date' end),
		  ph.DayToDateNetAdditions,
		  ph.DayToDatePeriodFromDate,
		  DayToDateShowPeriod = convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
		  -- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
		  -- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
		  -- Otherwise zero (0).
		  p.FormatReportingCurrency,
		  1 as IsHeadOfHousehold,
		  -- Inception To Date
		  ph.InceptionToDateBeginningMarketValue,
		  InceptionToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then InceptionToDateAnnualizedTWR / 100
				else InceptionToDateTWR / 100 end),
		  ph.InceptionToDateEndingMarketValue,
		  ph.InceptionToDateExternallyPaidFees,
		  ph.InceptionToDateGainsFees,
		  InceptionToDateHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then 'Annualized' + APX.fNewline(1) + 'Inception' + APX.fNewline(1) + 'To Date'
				else 'Inception' + APX.fNewline(1) + 'To Date' end),
		  ph.InceptionToDateNetAdditions,
		  ph.InceptionToDatePeriodFromDate,
		  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  ph.IsIndex,
		  --ph.IsShortPosition,
		  
		  -- Latest 1 Year
		  ph.Latest1YearBeginningMarketValue,
		  Latest1YearEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest1YearAnnualizedTWR / 100
				else Latest1YearTWR / 100 end),
		  ph.Latest1YearEndingMarketValue,
		  ph.Latest1YearExternallyPaidFees,
		  ph.Latest1YearGainsFees,
		  Latest1YearHeader = (case
				when @AnnualizeReturns = 'a'  then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '1 Year'
				else 'Latest' + APX.fNewline(1) + '1 Year' end),
		  ph.Latest1YearNetAdditions,
		  ph.Latest1YearPeriodFromDate,
		  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Months
		  ph.Latest3MonthsBeginningMarketValue,
		  Latest3MonthsEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest3MonthsAnnualizedTWR / 100
				else Latest3MonthsTWR / 100 end),
		  ph.Latest3MonthsEndingMarketValue,
		  ph.Latest3MonthsExternallyPaidFees,
		  ph.Latest3MonthsGainsFees,
		  Latest3MonthsHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '3 Months'
				else 'Latest' + APX.fNewline(1) + '3 Months' end),
		  ph.Latest3MonthsNetAdditions,
		  ph.Latest3MonthsPeriodFromDate,
		  Latest3MonthsShowPeriod = convert(bit, case when charindex( ',L3M,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Years
		  ph.Latest3YearsBeginningMarketValue,
		  Latest3YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then Latest3YearsAnnualizedTWR / 100
				else Latest3YearsTWR / 100 end),
		  ph.Latest3YearsEndingMarketValue,
		  ph.Latest3YearsExternallyPaidFees,
		  ph.Latest3YearsGainsFees,
		  Latest3YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '3 Years'
				else 'Latest' + APX.fNewline(1) + '3 Years' end),
		  ph.Latest3YearsNetAdditions,
		  ph.Latest3YearsPeriodFromDate,
		  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Latest 5 Years
		  ph.Latest5YearsBeginningMarketValue,
		  Latest5YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then Latest5YearsAnnualizedTWR / 100
				else Latest5YearsTWR / 100 end),
		  ph.Latest5YearsEndingMarketValue,
		  ph.Latest5YearsExternallyPaidFees,
		  ph.Latest5YearsGainsFees,
		  Latest5YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then 'Annualized' + APX.fNewline(1) + 'Latest' + APX.fNewline(1) + '5 Years'
				else 'Latest' + APX.fNewline(1) + '5 Years' end),
		  ph.Latest5YearsNetAdditions,
		  ph.Latest5YearsPeriodFromDate,
		  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.LocaleID,
		  
		  -- Month to Date
		  ph.MonthToDateBeginningMarketValue,
		  MonthToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.MonthToDateAnnualizedTWR / 100
				else ph.MonthToDateTWR / 100 end),
		  ph.MonthToDateEndingMarketValue,
		  ph.MonthToDateExternallyPaidFees,
		  ph.MonthToDateGainsFees,
		  MonthToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Month' + APX.fNewline(1) + 'To Date'
				else 'Month' + APX.fNewline(1) + 'To Date' end),
		  ph.MonthToDateNetAdditions,
		  ph.MonthToDatePeriodFromDate,
		  MonthToDateShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.PrefixedPortfolioBaseCode,
		  ph.PortfolioBaseID,
		  ph.PortfolioBaseIDOrder,
		  
		  -- Quarter to Date
		  ph.QuarterToDateBeginningMarketValue,
		  QuarterToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.QuarterToDateAnnualizedTWR / 100
				else ph.QuarterToDateTWR / 100 end),
		  ph.QuarterToDateEndingMarketValue,
		  ph.QuarterToDateExternallyPaidFees,
		  ph.QuarterToDateGainsFees,
		  QuarterToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Quarter' + APX.fNewline(1) + 'To Date'
				else 'Quarter' + APX.fNewline(1) + 'To Date' end),
		  ph.QuarterToDateNetAdditions,
		  ph.QuarterToDatePeriodFromDate,
		  QuarterToDateShowPeriod = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  --ph.SecTypeCode,
		  --ph.SecurityID,
		  
		  -- Since Date TWR
		  ph.SinceDateBeginningMarketValue,
		  SinceDateTWREffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
					then ph.SinceDateAnnualizedTWR / 100
				else SinceDateTWR / 100 end),
		  ph.SinceDateEndingMarketValue,
		  ph.SinceDateExternallyPaidFees,
		  ph.SinceDateGainsFees,
		  SinceDateTWRHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
					then 'Annualized' + APX.fNewline(1) + 'Since TWR' + APX.fNewline(1)
				else 'Since TWR' + APX.fNewline(1) end),
		  ph.SinceDateNetAdditions,
		  ph.SinceDateTWRPeriodFromDate,
		  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  ph.ThruDate,
		  
		  -- Week To Date
		  ph.WeekToDateBeginningMarketValue,
		  WeekToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.WeekToDateAnnualizedTWR / 100
				else ph.WeekToDateTWR / 100 end),
		  ph.WeekToDateEndingMarketValue,
		  ph.WeekToDateExternallyPaidFees,
		  ph.WeekToDateGainsFees,
		  WeekToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Week' + APX.fNewline(1) + 'To Date'
				else 'Week' + APX.fNewline(1) + 'To Date' end),
		  ph.WeekToDateNetAdditions,
		  ph.WeekToDatePeriodFromDate,
		  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Year To Date      
		  ph.YearToDateBeginningMarketValue,
		  YearToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.YearToDateAnnualizedTWR / 100
				else ph.YearToDateTWR / 100 end),
		  ph.YearToDateEndingMarketValue,
		  ph.YearToDateExternallyPaidFees,
		  ph.YearToDateGainsFees,
		  YearToDateHeader = (case
				when @AnnualizeReturns = 'a' then 'Annualized' + APX.fNewline(1) + 'Year' + APX.fNewline(1) + 'To Date'
				else 'Year' + APX.fNewline(1) + 'To Date' end),
		  ph.YearToDateNetAdditions,
		  ph.YearToDatePeriodFromDate,
		  YearToDateShowPeriod = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end)
	from
		APXUser.fPerformanceHistoryPeriod(@ReportData) ph 
		join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
			p.PortfolioBaseID = ph.PortfolioBaseID
		--join APXUser.vPortfolioBaseSettingEx portfolioBase on
		--	portfolioBase.PortfolioBaseID = ph.PortfolioBaseID
		--join ApxUser.vCurrency reportingCurrency on
		--	reportingCurrency.CurrencyCode = case @ReportingCurrencyCode
		--	when 'PC' then portfolioBase.ReportingCurrencyCode
		--	else @ReportingCurrencyCode end
	where @ShowIndexes = 1 or ph.IsIndex = 0
--	where
--		(case when @ShowIndexes = 0 and ph.IsIndex = 1 then 0 else 1 end) = 1
	order by
		PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder
	end
	
--select GETDATE() - @timer	
	
end

GO


