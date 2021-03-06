USE [APXFirm]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPerformanceHistoryPeriodDataHandle_B85383SA]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pReportPerformanceHistoryPeriodDataHandle_B85383SA] 
GO 

create procedure [APXUserCustom].[pReportPerformanceHistoryPeriodDataHandle_B85383SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	@Periods nvarchar(max),
	@Periods_ANN nvarchar(max),

	-- Optional parameters for sqlrep proc
    @ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
    
	-- Other optional parameters
	@AnnualizeReturns bit = null,			-- no Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@ShowIndexes bit = 1, -- Default to 1 just to be backwards-compatible with Angie's old proc
	
	@DataHandleName nvarchar(max) = 'PerformanceHistorySummary'
as

begin


-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

-- Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @ReportData=@ReportData out, @PortfolioBaseID=@PortfolioBaseID
, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder



-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @ConfigurationAnnualizeReturns char(1)
exec APXUser.pGetEffectiveParameter

	-- Parameters internal to this proc that are derived from other parameters.
	@AnnualizeReturns = @ConfigurationAnnualizeReturns out,	-- Just get the configuration value.
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out

--declare @timer datetime = getdate()


-- 4. Set some miscellaneous working variables
declare @annualizeAlways bit = case when  @AnnualizeReturns = 1 and @ConfigurationAnnualizeReturns in('o','a') then 1 else 0 end
declare @newLine char(2) = APX.fNewline(1)
declare @delimitedPeriods nvarchar(max) = ',' + @Periods + ','
-- TODO:  Probably some additional stuff you could do to optimize the select, but it is already fast.
--declare @dayToDateShowPeriod bit = case when charindex( ',ATD,', @delimitedPeriods ) > 0 then 1 else 0 end 
--declare @inceptionToDateShowPeriod bit = case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end



SET @annualizeAlways = 0
declare @delimitedPeriods_ANN nvarchar(max) = ',' + @Periods_ANN + ','


SELECT
	ph.ClassificationMemberCode,
	ClassificationMemberName = case
		when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
		else ph.ClassificationMemberName + 
			(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (Short)' end) +
			(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end) end,
	  -- (case ph.ClassificationMemberName
			--when 'Total' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
			--when 'Portfolio' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
			--else  ph.ClassificationMemberName + 
			--	  case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (short)' end +
			--	  case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end 
			--end),
	  ph.ClassificationMemberOrder,
	    
	  -- Day to Date
	  DayToDateEffectiveTWR = (case
			when @annualizeAlways = 1 then ph.DayToDateAnnualizedTWR
			else ph.DayToDateTWR end),
	  ph.DayToDateEndingMarketValue,
	  DayToDateHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Day' + @newLine + 'To Date'
			else 'Day' + @newLine + 'To Date' end),
	  ph.DayToDatePeriodFromDate,
	  DayToDateShowPeriod = convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
	  -- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
	  -- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
	  -- Otherwise zero (0).
	  --FormatReportingCurrency = 'N' + convert(varchar(3), case @ShowCurrencyFullPrecision
			--	when 1 then reportingCurrency.CurrencyPrecision
			--	else 0 end),
	  FormatReportingCurrency = 'N' + convert(varchar(3), case @ShowCurrencyFullPrecision
				when 1 then p.CurrencyPrecision
				else 0 end),
--	p.FormatReportingCurrency,



	  -- Inception To Date
	  InceptionToDateEffectiveTWR = (case
			when @annualizeAlways = 1 or ((@AnnualizeReturns = 1 or (case when charindex(',ITD,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1) and 
				DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
				then InceptionToDateAnnualizedTWR
			else InceptionToDateTWR end),
	  ph.InceptionToDateEndingMarketValue,
	  InceptionToDateHeader = (case
			when @annualizeAlways = 1 or ((@AnnualizeReturns = 1 or (case when charindex(',ITD,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1) and 
				DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
				then 'Annualized' + @newLine + 'Inception' + @newLine + 'To Date'
			else 'Inception' + @newLine + 'To Date' end),
	  ph.InceptionToDatePeriodFromDate,
	  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
	  



	  ph.IsIndex,
	  --ph.IsShortPosition,
	  
	  -- Latest 1 Year
	  Latest1YearEffectiveTWR = (case
			when @annualizeAlways = 1 then Latest1YearAnnualizedTWR
			else Latest1YearTWR end),
	  ph.Latest1YearEndingMarketValue,
	  Latest1YearHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Latest' + @newLine + '1 Year'
			else 'Latest' + @newLine + '1 Year' end),
	  ph.Latest1YearPeriodFromDate,
	  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
	  
	  -- Latest 3 Months
	  Latest3MonthsEffectiveTWR = (case
			when @annualizeAlways = 1 then Latest3MonthsAnnualizedTWR
			else Latest3MonthsTWR end),
	  ph.Latest3MonthsEndingMarketValue,
	  Latest3MonthsHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Latest' + @newLine + '3 Months'
			else 'Latest' + @newLine + '3 Months' end),
	  ph.Latest3MonthsPeriodFromDate,
	  Latest3MonthsShowPeriod = convert(bit, case when charindex( ',L3M,', @delimitedPeriods ) > 0 then 1 else 0 end),

	  
	  -- Latest 3 Years
	  Latest3YearsEffectiveTWR = (case
			when @annualizeAlways = 1 or @AnnualizeReturns = 1  or (case when charindex(',L3Y,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1    then Latest3YearsAnnualizedTWR
			else Latest3YearsTWR end),
	  ph.Latest3YearsEndingMarketValue,
	  Latest3YearsHeader = (case
			when @annualizeAlways = 1 or @AnnualizeReturns = 1 or (case when charindex(',L3Y,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1 then 'Annualized' + @newLine + 'Latest' + @newLine + '3 Years'
			else 'Latest' + @newLine + '3 Years' end),
	  ph.Latest3YearsPeriodFromDate,
	  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),



	  -- Latest 5 Years
	  Latest5YearsEffectiveTWR = (case
			when @annualizeAlways = 1 or @AnnualizeReturns = 1 or (case when charindex(',L5Y,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1 then Latest5YearsAnnualizedTWR
			else Latest5YearsTWR end),
      ph.Latest5YearsEndingMarketValue,
	  Latest5YearsHeader = (case
			when @annualizeAlways = 1 or @AnnualizeReturns = 1 or (case when charindex(',L5Y,', @delimitedPeriods_ANN) > 0 then 1 else 0 end)=1 then 'Annualized' + @newLine + 'Latest' + @newLine + '5 Years'
			else 'Latest' + @newLine + '5 Years' end),
	  ph.Latest5YearsPeriodFromDate,
	  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

	  p.LocaleID, -- = isnull(@LocaleID, portfolioBase.LocaleID),
	  
	  -- Month to Date
	  MonthToDateEffectiveTWR = (case
			when @annualizeAlways = 1 then ph.MonthToDateAnnualizedTWR
			else ph.MonthToDateTWR end),
	  ph.MonthToDateEndingMarketValue,
	  MonthToDateHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Month' + @newLine + 'To Date'
			else 'Month' + @newLine + 'To Date' end),
	  ph.MonthToDatePeriodFromDate,
	  MonthToDatesShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
	  p.PrefixedPortfolioBaseCode,
	  ph.PortfolioBaseID,
	  ph.PortfolioBaseIDOrder,
	  
	  -- Quarter to Date
	  QuarterToDateEffectiveTWR = (case
			when @annualizeAlways = 1 then ph.QuarterToDateAnnualizedTWR
			else ph.QuarterToDateTWR end),
	  ph.QuarterToDateEndingMarketValue,
	  QuarterToDateHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Quarter' + @newLine + 'To Date'
			else 'Quarter' + @newLine + 'To Date' end),
	  ph.QuarterToDatePeriodFromDate,
	  QuarterToDateShowPeriod = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

	  --ph.SecTypeCode,
	  --ph.SecurityID,
	  
	  ph.SinceDateEndingMarketValue,

	  -- Since Date TWR
	  SinceDateTWREffectiveTWR = (case
			when @annualizeAlways = 1 or (@AnnualizeReturns = 1 and 
				DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
				then ph.SinceDateAnnualizedTWR
			else SinceDateTWR end),
	  SinceDateTWRHeader = (case
			when @annualizeAlways = 1 or (@AnnualizeReturns = 1 and
				DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
				then 'Annualized' + @newLine + 'Since TWR' + @newLine
			else 'Since TWR' + @newLine end),
	  ph.SinceDateTWRPeriodFromDate,
	  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

	  ph.ThruDate,
	  
	  -- Week To Date
	  WeekToDateEffectiveTWR = (case
			when @annualizeAlways = 1 then ph.WeekToDateAnnualizedTWR
			else ph.WeekToDateTWR end),
	  ph.WeekToDateEndingMarketValue,
	  WeekToDateHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Week' + @newLine + 'To Date'
			else 'Week' + @newLine + 'To Date' end),
	  ph.WeekToDatePeriodFromDate,
	  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

	  -- Year To Date        
	  YearToDateEffectiveTWR = (case
			when @annualizeAlways = 1 then ph.YearToDateAnnualizedTWR
			else ph.YearToDateTWR end),
	  ph.YearToDateEndingMarketValue,
	  YearToDateHeader = (case
			when @annualizeAlways = 1 then 'Annualized' + @newLine + 'Year' + @newLine + 'To Date'
			else 'Year' + @newLine + 'To Date' end),
	  ph.YearToDatePeriodFromDate,
	  YearToDateShowPeriod = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end)

from APXUser.fPerformanceHistoryPeriod(@ReportData)
--, @PortfolioBaseID, @PortfolioBaseIDOrder)
 ph 
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = ph.PortfolioBaseID
where @ShowIndexes = 1 or ph.IsIndex = 0 and
	ph.PortfolioBaseID = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder

end


