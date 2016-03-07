IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPerformanceHistoryPeriodHousehold]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportPerformanceHistoryPeriodHousehold]
GO

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

declare @PerfFromDate datetime
select @PerfFromDate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,DATEADD(year,-2,@ToDate))+1,0))

if @consolidate = 1
	begin
		declare @Portfolios1 nvarchar(max) 
		set @Portfolios1 = '+' + @Portfolios
		exec APXUser.pPerformanceHistoryPeriodBatch
			-- Required Parameters
			@DataHandle = @DataHandle,
			@DataName = 'PerformanceHistoryParent',
			@Portfolios = @Portfolios1,
			@FromDate = @PerfFromDate,
			@ToDate = @ToDate,
			@ClassificationID = @ClassificationID,
			-- Optional Parameters
			@AnnualizeReturns = @AnnualizeReturns,
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
	@FromDate = @PerfFromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@AnnualizeReturns = @AnnualizeReturns,
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
-- Get the decoration text into a local table
declare @Decor table(APXLocaleID dtID primary key, ShortText nvarchar(255))
insert into @Decor (APXLocaleID, ShortText)
select q.LocaleID, APXSSRS.fShortSecurityNameDecoration(q.LocaleID)
from (
	select distinct p.LocaleID
	from ( 
		select distinct PortfolioBaseID from APXUser.fPerformanceHistoryPeriod(@ReportData)
		union
		select distinct PortfolioBaseID from APXUser.fPerformanceHistoryPeriod(@ReportData1) where @consolidate = 1
		) a
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on 
		p.PortfolioBaseID = a.PortfolioBaseID
	where @LocaleID is null
	union
	select @LocaleID
	where @LocaleID is not null
	) q
--select * from @Decor
-- Time Period Variables
declare @DTD nvarchar(255) = 'Day VBCRLF To Date'
declare @DTDAnn nvarchar(255) = 'Annualized VBCRLF Day VBCRLF To Date'
declare @ITD nvarchar(255) = 'Inception VBCRLF To Date'
declare @ITDAnn nvarchar(255) = 'Annualized VBCRLF Inception VBCRLF To Date'
declare @L3M nvarchar(255) = 'Latest VBCRLF 3 Months'
declare @L3MAnn nvarchar(255) = 'Annualized VBCRLF Latest VBCRLF 3 Months'
declare @L1Y nvarchar(255) = 'Latest VBCRLF 1 Year'
declare @L1YAnn nvarchar(255) = 'Annualized VBCRLF Latest VBCRLF 1 Year'
declare @L2Y nvarchar(255) = 'Latest VBCRLF 2 Years'
declare @L2YAnn nvarchar(255) = 'Annualized VBCRLF Latest VBCRLF 2 Years'
declare @L3Y nvarchar(255) = 'Latest VBCRLF 3 Years'
declare @L3YAnn nvarchar(255) = 'Annualized VBCRLF Latest VBCRLF 3 Years'
declare @L5Y nvarchar(255) = 'Latest VBCRLF 5 Years'
declare @L5YAnn nvarchar(255) = 'Annualized VBCRLF Latest VBCRLF 5 Years'
declare @MTD nvarchar(255) = 'Month VBCRLF To Date'
declare @MTDAnn nvarchar(255) = 'Annualized VBCRLF Month VBCRLF To Date'
declare @QTD nvarchar(255) = 'Quarter VBCRLF To Date'
declare @QTDAnn nvarchar(255) = 'Annualized VBCRLF Quarter VBCRLF To Date'
declare @WTD nvarchar(255) = 'Week VBCRLF To Date'
declare @WTDAnn nvarchar(255) = 'Annualized VBCRLF Week VBCRLF To Date'
declare @YTD nvarchar(255) = 'Year VBCRLF To Date'
declare @YTDAnn nvarchar(255) = 'Annualized VBCRLF Year VBCRLF To Date'
declare @SSDTWR nvarchar(255) = 'Since TWR'
declare @SSDTWRAnn nvarchar(255) = 'Annualized VBCRLF Since TWR'
if @consolidate = 1
	begin
		select
		  ph.ClassificationMemberCode,
		  ClassificationMemberName = case
			when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
			when @ClassificationID = -8 then IsNull(sec.FullName, ph.ClassificationMemberName) + 
				(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else decor.ShortText end) +
				(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end)
			else IsNull(l.LookupLabel, ph.ClassificationMemberName) 
			end,
		  ph.ClassificationMemberOrder,
		    
		  -- Day to Date
		  ph.DayToDateBeginningMarketValue,
		  DayToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.DayToDateAnnualizedTWR
				else ph.DayToDateTWR end),
		  ph.DayToDateEndingMarketValue,
		  ph.DayToDateExternallyPaidFees,
		  ph.DayToDateGainsFees,
		  DayToDateHeader = (case when @AnnualizeReturns = 'a' then @DTDAnn else @DTD end),
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
					then InceptionToDateAnnualizedTWR
				else InceptionToDateTWR end),
		  ph.InceptionToDateEndingMarketValue,
		  ph.InceptionToDateExternallyPaidFees,
		  ph.InceptionToDateGainsFees,
		  InceptionToDateHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then @ITDAnn
				else @ITD end),
		  ph.InceptionToDateNetAdditions,
		  ph.InceptionToDatePeriodFromDate,
		  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  ph.IsIndex,
		  --ph.IsShortPosition,
		  
		  -- Latest 1 Year
		  ph.Latest1YearBeginningMarketValue,
		  Latest1YearEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then Latest1YearAnnualizedTWR
				else Latest1YearTWR end),
		  ph.Latest1YearEndingMarketValue,
		  ph.Latest1YearExternallyPaidFees,
		  ph.Latest1YearGainsFees,
		  Latest1YearHeader = (case	when @AnnualizeReturns = 'a' then @L1YAnn else @L1Y end),
		  ph.Latest1YearNetAdditions,
		  ph.Latest1YearPeriodFromDate,
		  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Months
		  ph.Latest3MonthsBeginningMarketValue,
		  Latest3MonthsEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest3MonthsAnnualizedTWR
				else Latest3MonthsTWR end),
		  ph.Latest3MonthsEndingMarketValue,
		  ph.Latest3MonthsExternallyPaidFees,
		  ph.Latest3MonthsGainsFees,
		  Latest3MonthsHeader = (case when @AnnualizeReturns = 'a' then @L3MAnn else @L3M end),
		  ph.Latest3MonthsNetAdditions,
		  ph.Latest3MonthsPeriodFromDate,
		  Latest3MonthsShowPeriod = convert(bit, case when charindex( ',L3M,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Years
		  ph.Latest3YearsBeginningMarketValue,
		  Latest3YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then Latest3YearsAnnualizedTWR
				else Latest3YearsTWR end),
		  ph.Latest3YearsEndingMarketValue,
		  ph.Latest3YearsExternallyPaidFees,
		  ph.Latest3YearsGainsFees,
		  Latest3YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then @L3YAnn else @L3Y end),
		  ph.Latest3YearsNetAdditions,
		  ph.Latest3YearsPeriodFromDate,
		  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Latest 5 Years
		  ph.Latest5YearsBeginningMarketValue,
		  Latest5YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then Latest5YearsAnnualizedTWR
				else Latest5YearsTWR end),
		  ph.Latest5YearsEndingMarketValue,
		  ph.Latest5YearsExternallyPaidFees,
		  ph.Latest5YearsGainsFees,
		  Latest5YearsHeader = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then @L5YAnn else @L5Y end),
		  ph.Latest5YearsNetAdditions,
		  ph.Latest5YearsPeriodFromDate,
		  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.LegacyLocaleID,
		  p.LocaleID,
		  
		  -- Month to Date
		  ph.MonthToDateBeginningMarketValue,
		  MonthToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.MonthToDateAnnualizedTWR
				else ph.MonthToDateTWR end),
		  ph.MonthToDateEndingMarketValue,
		  ph.MonthToDateExternallyPaidFees,
		  ph.MonthToDateGainsFees,
		  MonthToDateHeader = (case
				when @AnnualizeReturns = 'a' then @MTDAnn else @MTD end),
		  ph.MonthToDateNetAdditions,
		  ph.MonthToDatePeriodFromDate,
		  MonthToDateShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.PrefixedPortfolioBaseCode,
		  ph.PortfolioBaseID,
		  ph.PortfolioBaseIDOrder,
		  
		  -- Quarter to Date
		  ph.QuarterToDateBeginningMarketValue,
		  QuarterToDateEffectiveTWR = (case	when @AnnualizeReturns = 'a' then ph.QuarterToDateAnnualizedTWR	else ph.QuarterToDateTWR end),
		  ph.QuarterToDateEndingMarketValue,
		  ph.QuarterToDateExternallyPaidFees,
		  ph.QuarterToDateGainsFees,
		  QuarterToDateHeader = (case when @AnnualizeReturns = 'a' then @QTDAnn else @QTD end),
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
					then ph.SinceDateAnnualizedTWR
				else SinceDateTWR end),
		  ph.SinceDateEndingMarketValue,
		  ph.SinceDateExternallyPaidFees,
		  ph.SinceDateGainsFees,
		  --SinceDateTWRHeader = (case
				--when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
				--	DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
				--	then @SSDTWRAnn
				--else @SSDTWR end),
		  SinceDateTWRHeader = (case
				when @AnnualizeReturns = 'a' then @L2YAnn else @L2Y end),
		  ph.SinceDateNetAdditions,
		  ph.SinceDateTWRPeriodFromDate,
		  --SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',L2Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  ph.ThruDate,
		  
		  -- Week To Date
		  ph.WeekToDateBeginningMarketValue,
		  WeekToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.WeekToDateAnnualizedTWR
				else ph.WeekToDateTWR end),
		  ph.WeekToDateEndingMarketValue,
		  ph.WeekToDateExternallyPaidFees,
		  ph.WeekToDateGainsFees,
		  WeekToDateHeader = (case when @AnnualizeReturns = 'a' then @WTDAnn else @WTD end),
		  ph.WeekToDateNetAdditions,
		  ph.WeekToDatePeriodFromDate,
		  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Year To Date      
		  ph.YearToDateBeginningMarketValue,
		  YearToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.YearToDateAnnualizedTWR
				else ph.YearToDateTWR end),
		  ph.YearToDateEndingMarketValue,
		  ph.YearToDateExternallyPaidFees,
		  ph.YearToDateGainsFees,
		  YearToDateHeader = (case when @AnnualizeReturns = 'a' then @YTDAnn else @YTD end),
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
			left join dbo.vAoPropertyLookupLangPerLocale l on 
				l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID and l.PropertyLookupID = ph.ClassificationMemberID
		   	left join dbo.AdvSecurityLang sec on
				sec.APXLocaleID = p.LocaleID and @ClassificationID = -8 and sec.SecurityID = ph.ClassificationMemberID
			join @Decor decor on decor.APXLocaleID = p.LocaleID
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
			when @ClassificationID = -8 then IsNull(sec.FullName, ph.ClassificationMemberName) + 
				(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else decor.ShortText end) +
				(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end)
			else IsNull(l.LookupLabel, ph.ClassificationMemberName) 
			end,
		  ph.ClassificationMemberOrder,
		    
		  -- Day to Date
		  ph.DayToDateBeginningMarketValue,
		  DayToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.DayToDateAnnualizedTWR
				else ph.DayToDateTWR end),
		  ph.DayToDateEndingMarketValue,
		  ph.DayToDateExternallyPaidFees,
		  ph.DayToDateGainsFees,
		  DayToDateHeader = (case when @AnnualizeReturns = 'a' then @DTDAnn else @DTD end),
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
					then InceptionToDateAnnualizedTWR
				else InceptionToDateTWR end),
		  ph.InceptionToDateEndingMarketValue,
		  ph.InceptionToDateExternallyPaidFees,
		  ph.InceptionToDateGainsFees,
		  InceptionToDateHeader = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate))
					then @ITDAnn
				else @ITD end),
		  ph.InceptionToDateNetAdditions,
		  ph.InceptionToDatePeriodFromDate,
		  InceptionToDateShowPeriod = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  ph.IsIndex,
		  --ph.IsShortPosition,
		  
		  -- Latest 1 Year
		  ph.Latest1YearBeginningMarketValue,
		  Latest1YearEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest1YearAnnualizedTWR
				else Latest1YearTWR end),
		  ph.Latest1YearEndingMarketValue,
		  ph.Latest1YearExternallyPaidFees,
		  ph.Latest1YearGainsFees,
		  Latest1YearHeader = (case	when @AnnualizeReturns = 'a'  then @L1YAnn else @L1Y end),
		  ph.Latest1YearNetAdditions,
		  ph.Latest1YearPeriodFromDate,
		  Latest1YearShowPeriod = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Months
		  ph.Latest3MonthsBeginningMarketValue,
		  Latest3MonthsEffectiveTWR = (case
				when @AnnualizeReturns = 'a'  then Latest3MonthsAnnualizedTWR
				else Latest3MonthsTWR end),
		  ph.Latest3MonthsEndingMarketValue,
		  ph.Latest3MonthsExternallyPaidFees,
		  ph.Latest3MonthsGainsFees,
		  Latest3MonthsHeader = (case when @AnnualizeReturns = 'a' then @L3MAnn else @L3M end),
		  ph.Latest3MonthsNetAdditions,
		  ph.Latest3MonthsPeriodFromDate,
		  Latest3MonthsShowPeriod = convert(bit, case when charindex( ',L3M,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  
		  -- Latest 3 Years
		  ph.Latest3YearsBeginningMarketValue,
		  Latest3YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then Latest3YearsAnnualizedTWR
				else Latest3YearsTWR end),
		  ph.Latest3YearsEndingMarketValue,
		  ph.Latest3YearsExternallyPaidFees,
		  ph.Latest3YearsGainsFees,
		  Latest3YearsHeader = (case when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then @L3YAnn else @L3Y end),
		  ph.Latest3YearsNetAdditions,
		  ph.Latest3YearsPeriodFromDate,
		  Latest3YearsShowPeriod = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Latest 5 Years
		  ph.Latest5YearsBeginningMarketValue,
		  Latest5YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then Latest5YearsAnnualizedTWR
				else Latest5YearsTWR end),
		  ph.Latest5YearsEndingMarketValue,
		  ph.Latest5YearsExternallyPaidFees,
		  ph.Latest5YearsGainsFees,
		  Latest5YearsHeader = (case when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then @L5YAnn else @L5Y end),
		  ph.Latest5YearsNetAdditions,
		  ph.Latest5YearsPeriodFromDate,
		  Latest5YearsShowPeriod = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.LegacyLocaleID,
		  p.LocaleID,
		  
		  -- Month to Date
		  ph.MonthToDateBeginningMarketValue,
		  MonthToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.MonthToDateAnnualizedTWR
				else ph.MonthToDateTWR end),
		  ph.MonthToDateEndingMarketValue,
		  ph.MonthToDateExternallyPaidFees,
		  ph.MonthToDateGainsFees,
		  MonthToDateHeader = (case when @AnnualizeReturns = 'a' then @MTDAnn else @MTD end),
		  ph.MonthToDateNetAdditions,
		  ph.MonthToDatePeriodFromDate,
		  MonthToDateShowPeriod = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  p.PrefixedPortfolioBaseCode,
		  ph.PortfolioBaseID,
		  ph.PortfolioBaseIDOrder,
		  
		  -- Quarter to Date
		  ph.QuarterToDateBeginningMarketValue,
		  QuarterToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.QuarterToDateAnnualizedTWR
				else ph.QuarterToDateTWR end),
		  ph.QuarterToDateEndingMarketValue,
		  ph.QuarterToDateExternallyPaidFees,
		  ph.QuarterToDateGainsFees,
		  QuarterToDateHeader = (case when @AnnualizeReturns = 'a' then @QTDAnn else @QTD end),
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
					then ph.SinceDateAnnualizedTWR
				else SinceDateTWR end),
		  ph.SinceDateEndingMarketValue,
		  ph.SinceDateExternallyPaidFees,
		  ph.SinceDateGainsFees,
		  --SinceDateTWRHeader = (case
				--when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
				--	DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
				--	then @SSDTWRAnn
				--else @SSDTWR end),
		  SinceDateTWRHeader = (case
				when @AnnualizeReturns = 'a' then @L2YAnn else @L2Y end),
		  ph.SinceDateNetAdditions,
		  ph.SinceDateTWRPeriodFromDate,
		  --SinceDateTWRShowPeriod = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  SinceDateTWRShowPeriod = convert(bit, case when charindex( ',L2Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  ph.ThruDate,
		  
		  -- Week To Date
		  ph.WeekToDateBeginningMarketValue,
		  WeekToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.WeekToDateAnnualizedTWR
				else ph.WeekToDateTWR end),
		  ph.WeekToDateEndingMarketValue,
		  ph.WeekToDateExternallyPaidFees,
		  ph.WeekToDateGainsFees,
		  WeekToDateHeader = (case when @AnnualizeReturns = 'a' then @WTDAnn else @WTD end),
		  ph.WeekToDateNetAdditions,
		  ph.WeekToDatePeriodFromDate,
		  WeekToDateShowPeriod = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
		  -- Year To Date      
		  ph.YearToDateBeginningMarketValue,
		  YearToDateEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.YearToDateAnnualizedTWR
				else ph.YearToDateTWR end),
		  ph.YearToDateEndingMarketValue,
		  ph.YearToDateExternallyPaidFees,
		  ph.YearToDateGainsFees,
		  YearToDateHeader = (case when @AnnualizeReturns = 'a' then @YTDAnn else @YTD end),
		  ph.YearToDateNetAdditions,
		  ph.YearToDatePeriodFromDate,
		  YearToDateShowPeriod = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end)
	from
		APXUser.fPerformanceHistoryPeriod(@ReportData) ph 
		join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
			p.PortfolioBaseID = ph.PortfolioBaseID
		left join dbo.vAoPropertyLookupLangPerLocale l on 
			l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID and l.PropertyLookupID = ph.ClassificationMemberID
	   	left join dbo.AdvSecurityLang sec on
			sec.APXLocaleID = p.LocaleID and @ClassificationID = -8 and sec.SecurityID = ph.ClassificationMemberID
		join @Decor decor on decor.APXLocaleID = p.LocaleID
	where @ShowIndexes = 1 or ph.IsIndex = 0
	order by
		PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder
	end
	
--select GETDATE() - @timer	
	
end

GO


