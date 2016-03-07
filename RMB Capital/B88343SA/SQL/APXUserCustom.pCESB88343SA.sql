IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pCESB88343SA]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pCESB88343SA]
GO
 
create procedure [APXUserCustom].[pCESB88343SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,

	-- Optional parameters for sqlrep proc
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@FeeMethod int = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings

	-- Other optional parameters
	@AnnualizeReturns char(1) = null,			-- no Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowIndexes bit = 1 -- default to 1 for for backward-compatibility
as
begin

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()

declare @consolidate bit = 0
select @consolidate = case SUBSTRING(@Portfolios,1,1) when  '@' then 1 when '&' then 1 else 0 end

declare @PerfToDate datetime = APXUser.fGetGenericDate('{edty}',@ToDate)

declare	@L2Y datetime = DATEADD(YYYY,-2, @PerfToDate)
	,@L4Y datetime = DATEADD(YYYY,-4, @PerfToDate)

declare @ExcludeSinceDateIRR bit = 1
if @consolidate = 1
	begin
		declare @Portfolios1 nvarchar(max) 
		set @Portfolios1 = '+' + @Portfolios
		exec APXUser.pPerformanceHistoryPeriodBatch
			-- Required Parameters
			@DataHandle = @DataHandle,
			@DataName = 'Parent1',
			@Portfolios = @Portfolios1,
			@FromDate = @L2Y,
			@ToDate = @PerfToDate,
			@ClassificationID = -9,
			-- Optional Parameters
			@AnnualizeReturns = @AnnualizeReturns,
			@ReportingCurrencyCode = @ReportingCurrencyCode out,
			@FeeMethod = @FeeMethod,
			@AccruePerfFees = @AccruePerfFees,
			@AllocatePerfFees = @AllocatePerfFees,
			@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
			@LocaleID = @LocaleID

		exec APXUser.pPerformanceHistoryPeriodBatch
			-- Required Parameters
			@DataHandle = @DataHandle,
			@DataName = 'Parent2',
			@Portfolios = @Portfolios1,
			@FromDate = @L4Y,
			@ToDate = @PerfToDate,
			@ClassificationID = -9,
			-- Optional Parameters
			@AnnualizeReturns = @AnnualizeReturns,
			@ReportingCurrencyCode = @ReportingCurrencyCode out,
			@FeeMethod = @FeeMethod,
			@AccruePerfFees = @AccruePerfFees,
			@AllocatePerfFees = @AllocatePerfFees,
			@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
			@LocaleID = @LocaleID
	end

exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistory1',
	@Portfolios = @Portfolios,
	@FromDate = @L2Y,
	@ToDate = @PerfToDate,
	@ClassificationID = -9,

	-- Optional Parameters
	@AnnualizeReturns = @AnnualizeReturns,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID

exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistory2',
	@Portfolios = @Portfolios,
	@FromDate = @L4Y,
	@ToDate = @PerfToDate,
	@ClassificationID = -9,

	-- Optional Parameters
	@AnnualizeReturns = @AnnualizeReturns,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 0
declare @ChildData1 varbinary(max)
	,@ChildData2 varbinary(max)

if @consolidate = 1
	begin
		declare @ParentData1 varbinary(max), @ParentData2 varbinary(max)
		exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Parent1', @ReportData = @ParentData1 out
		exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Parent2', @ReportData = @ParentData2 out
	end

exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory1', @ReportData = @ChildData1 out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory2', @ReportData = @ChildData2 out

if @consolidate = 1
	begin
		select
		  ph.PortfolioBaseIDOrder,
		  ph.IsIndex,
		  ph.ClassificationMemberOrder,
		  ph.ClassificationMemberCode,
		  ph.IsHeadOfHousehold,
		  ClassificationMemberName = case
			when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
			else ph.ClassificationMemberName + 
				(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (Short)' end) +
				(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end) end,
		  p.PrefixedPortfolioBaseCode,
		  ph.PortfolioBaseID,

		  -- Latest 1 Year
		  Latest1YearEffectiveTWR = (case
				when @AnnualizeReturns = 'a' then ph.Latest1YearAnnualizedTWR
				else ph.Latest1YearTWR end),
		  Latest1YearHeader = DATEPART(YYYY,ph.Latest1YearPeriodFromDate),

		  -- Latest 2 Years
		  Latest2YearsTWREffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
					then ph.SinceDateAnnualizedTWR
				else ph.SinceDateTWR end),
		  Latest2YearsTWRHeader = DATEPART(YYYY,ph.SinceDateTWRPeriodFromDate),
  
		  -- Latest 3 Years
		  Latest3YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then ph.Latest3YearsAnnualizedTWR
				else ph.Latest3YearsTWR end),
		  Latest3YearsHeader = DATEPART(YYYY,ph.Latest3YearsPeriodFromDate),

		  -- Latest 4 Years
		  Latest4YearsTWREffectiveTWR = (case
				when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
					DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph2.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph2.ThruDate)) < DateDiff(day, ph2.SinceDateTWRPeriodFromDate, ph2.ThruDate))
					then ph2.SinceDateAnnualizedTWR
				else ph2.SinceDateTWR end),
		  Latest4YearsTWRHeader = DATEPART(YYYY,ph2.SinceDateTWRPeriodFromDate),

		  -- Latest 5 Years
		  Latest5YearsEffectiveTWR = (case
				when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then ph.Latest5YearsAnnualizedTWR
				else ph.Latest5YearsTWR end),
		  Latest5YearsHeader = DATEPART(YYYY,ph.Latest5YearsPeriodFromDate),

		  p.LocaleID,		  
		  ph.ThruDate
		from
			( select 0 as IsHeadOfHousehold, ph1.* from APXUser.fPerformanceHistoryPeriod(@ChildData1) ph1
				union all
			  select 1 as IsHeadOfHousehold, ph2.* from APXUser.fPerformanceHistoryPeriod(@ParentData1) ph2
			) ph 
			join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
				p.PortfolioBaseID = ph.PortfolioBaseID
			join ( select 0 as IsHeadOfHousehold, ph3.* from APXUser.fPerformanceHistoryPeriod(@ChildData2) ph3
				union all
			  select 1 as IsHeadOfHousehold, ph4.* from APXUser.fPerformanceHistoryPeriod(@ParentData2) ph4
			) ph2 on ph2.PortfolioBaseID = ph.PortfolioBaseID and ph2.ThruDate = ph.ThruDate and ph.IsIndex = ph2.IsIndex and ph.ClassificationMemberOrder = ph2.ClassificationMemberOrder
				and ph2.ClassificationMemberCode = ph.ClassificationMemberCode and ph2.IsHeadOfHousehold = ph.IsHeadOfHousehold
				and ph2.DayToDatePeriodFromDate = ph.DayToDatePeriodFromDate
		where @ShowIndexes = 1 or ph.IsIndex = 0
		order by
			ph.PortfolioBaseIDOrder, ph.IsIndex, ph.ClassificationMemberOrder
	end
else
	begin
		select
			  ph.PortfolioBaseIDOrder,
			  ph.IsIndex,
			  ph.ClassificationMemberOrder,
			  ph.ClassificationMemberCode,
			  IsHeadOfHousehold = 0,
			  ClassificationMemberName = case
				when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
				else ph.ClassificationMemberName + 
					(case when ph.IsShortPosition = 0 or ph.IsShortPosition is null then '' else ' (Short)' end) +
					(case when ph.BondDescription is null then '' else APX.fNewLine(1) + ph.BondDescription end) end,
			  ph.ClassificationMemberOrder,
			  ph.IsIndex,
		  
			  -- Latest 1 Year
			  Latest1YearEffectiveTWR = (case
					when @AnnualizeReturns = 'a' then ph.Latest1YearAnnualizedTWR
					else ph.Latest1YearTWR end),
			  Latest1YearHeader = DATEPART(YYYY,ph.Latest1YearPeriodFromDate),

			  -- Latest 2 Years
			  Latest2YearsTWREffectiveTWR = (case
					when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
						DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph.ThruDate)) < DateDiff(day, ph.SinceDateTWRPeriodFromDate, ph.ThruDate))
						then ph.SinceDateAnnualizedTWR
					else ph.SinceDateTWR end),
			  Latest2YearsTWRHeader = DATEPART(YYYY,ph.SinceDateTWRPeriodFromDate),
  
			  -- Latest 3 Years
			  Latest3YearsEffectiveTWR = (case
					when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o' then ph.Latest3YearsAnnualizedTWR
					else ph.Latest3YearsTWR end),
			  Latest3YearsHeader = DATEPART(YYYY,ph.Latest3YearsPeriodFromDate),

			  -- Latest 4 Years
			  Latest4YearsTWREffectiveTWR = (case
					when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 
						DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-12,ph2.ThruDate)),APXUser.fGetGenericDate('{edtm}',ph2.ThruDate)) < DateDiff(day, ph2.SinceDateTWRPeriodFromDate, ph2.ThruDate))
						then ph2.SinceDateAnnualizedTWR
					else ph2.SinceDateTWR end),
			  Latest4YearsTWRHeader = DATEPART(YYYY,ph2.SinceDateTWRPeriodFromDate),

			  -- Latest 5 Years
			  Latest5YearsEffectiveTWR = (case
					when @AnnualizeReturns = 'a' or @AnnualizeReturns = 'o'  then ph.Latest5YearsAnnualizedTWR
					else ph.Latest5YearsTWR end),
			  Latest5YearsHeader = DATEPART(YYYY,ph.Latest5YearsPeriodFromDate),

			  p.LocaleID,		  
			  ph.ThruDate
		from
			APXUser.fPerformanceHistoryPeriod(@ChildData1) ph 
			join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
				p.PortfolioBaseID = ph.PortfolioBaseID
			join ( select * from APXUser.fPerformanceHistoryPeriod(@ChildData2)	) ph2 on 
					ph2.PortfolioBaseID = ph.PortfolioBaseID and 
					ph2.ThruDate = ph.ThruDate and 
					ph.IsIndex = ph2.IsIndex and 
					ph.ClassificationMemberOrder = ph2.ClassificationMemberOrder and
					ph2.ClassificationMemberCode = ph.ClassificationMemberCode and
					ph2.DayToDatePeriodFromDate = ph.DayToDatePeriodFromDate
			where @ShowIndexes = 1 or ph.IsIndex = 0
		order by
			ph.PortfolioBaseIDOrder, ph.IsIndex, ph.ClassificationMemberOrder
	end
end