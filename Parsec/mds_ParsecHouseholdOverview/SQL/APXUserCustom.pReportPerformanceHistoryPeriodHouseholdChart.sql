IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPerformanceHistoryPeriodHouseholdChart]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportPerformanceHistoryPeriodHouseholdChart]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*
exec [APXUserCustom].[pReportPerformanceHistoryPeriodHouseholdChart]
	-- Required Parameters
	@SessionGuid = null,
	@Portfolios = '@casetrade',
	@ToDate = '03/31/2014',
    @FromDate = '12/31/80',
	@ClassificationID = -9,
	@Consolidate = 1,
	@Cap10Years = 0
*/
create procedure [APXUserCustom].[pReportPerformanceHistoryPeriodHouseholdChart]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@ToDate datetime,
    @FromDate datetime,
	@ClassificationID int,
    
	-- Optional parameters for sqlrep proc
	@AccruePerfFees bit = null,
    @AllocatePerfFees bit = null,
	@FeeMethod int = null,
	@UseIRRCalc bit = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@LocaleID int = null, 					-- Use Portfolio Settings
	@IntervalLength int = null,
	@Consolidate bit = 0,
	@Cap10Years bit = 1,	--	New parameter to cap 10 years.
    
	-- Other optional parameters
	@IncludeBeginningZeroRows bit = null,	-- For 'Growth Of A Dollar' charts.
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@ShowIndexes bit = 1, -- default to 1 for for backward-compatibility
	@Period nvarchar(max) = null -- Valid Values: ATD, WTD, MTD, QTD, YTD, L1Y, L3Y, L5Y, ITD, DTD
	
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Set @FromDate and @InceptionToDate based on @Period and @ToDate.
set @FromDate = APXSSRS.fFromDate(@FromDate, @ToDate, @Period)
declare @InceptionToDate bit = case @Period when 'ITD' then 1 else null end
--declare @IsGroup bit = case when SUBSTRING(@Portfolios,1,1) in ('@','&') then 1 else 0 end
--if @IsGroup = 1 and @Consolidate = 1 and SUBSTRING(@Portfolios,1,1) in ('@','&')
if @Consolidate = 1 and SUBSTRING(@Portfolios,1,1) in ('@','&')
	set @Portfolios = '+' + @Portfolios
-- 3. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pPerformanceHistory
	-- Required Parameters
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees =@AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@UseIRRCalc = @UseIRRCalc,
    @InceptionToDate = @InceptionToDate,
    @LocaleID = @LocaleID,
    @IntervalLength = @IntervalLength
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out
/*
2014/04/09 AZK Modified to cap the performance period to 10 years. If the difference beween @ToDate and @InceptionDate exceeds 3650 days,
rerun the PerformanceHistory Accounting Function with the new @FromDate definition.
*/
declare @InceptionDate datetime
	,@PerfStartDate datetime
select top 1 @InceptionDate = InceptionDate from APXUser.fPerformanceHistory (@ReportData)
select @PerfStartDate = dateadd(year,-10,@ToDate)
if (datediff(day,@InceptionDate,@ToDate) > 3650 and @Cap10Years = 1)
begin
	exec APXUser.pPerformanceHistory
		-- Required Parameters
		@ReportData = @ReportData out,
		@Portfolios = @Portfolios,
		@FromDate = @PerfStartDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees =@AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@UseIRRCalc = @UseIRRCalc,
		@InceptionToDate = 0,
		@LocaleID = @LocaleID,
		@IntervalLength = @IntervalLength
end
select
	ClassificationMemberName = case
		when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
		else ph.ClassificationMemberName end,
	---- A descriptive name of the row.
	--ClassificationMemberName = (case ph.ClassificationMemberName
	--	when 'Total' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
	--	when 'Portfolio' then isnull(portfolioBase.ReportHeading1, portfolioBase.PortfolioBaseCode)
	--	else ph.ClassificationMemberName end),
	ph.ClassificationMemberOrder,
	ph.CumulativeTWR,
	ph.CumulativeTWRAnnualized,
	CurrencySymbol = p.ReportingCurrencySymbol,
	-- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
	-- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
	-- Otherwise zero (0).
	p.FormatReportingCurrency,
	ph.FromDate,
	ph.InceptionDate,
	ph.IsIndex,
				
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID,
	ph.PeriodThruDate,
	p.PrefixedPortfolioBaseCode,
	ph.PortfolioBaseIDOrder,
	ph.TWR
-- 4a) Select the result set.
from (
		-- This query creates a beginning 'dummy zero' record at the minimum of PeriodThruDate.
		-- It finds the minimum PeriodThruDate of all rows, and then selects each row that has that minimum PeriodThruDate.
		-- Some portfolios will have rows, and other ones (without a row at min(PeriodThruDate)) will not have rows.
		-- These rows are used when plotting 'Growth of a Dollar' charts when you want the y-intercept to be 0.
		select 
			IsIndex,
			PortfolioBaseId,
			PortfolioBaseIDOrder,
			ClassificationMemberName,
			ClassificationMemberOrder,
			InceptionDate,
			TWR = 0,
			CumulativeTWR = 0,
			CumulativeTWRAnnualized = 0,
			FromDate,
			PeriodThruDate = PeriodFromDate
		from APXUser.fPerformanceHistory(@ReportData)
		where @IncludeBeginningZeroRows = 1 and
			 PeriodThruDate = (select min(PeriodThruDate) from APXUser.fPerformanceHistory(@ReportData))
		union
		-- This query selects the actual performance rows, one row for each performance period.
		select 
			IsIndex,
			PortfolioBaseId,
			PortfolioBaseIDOrder,
			ClassificationMemberName,
			ClassificationMemberOrder,
			InceptionDate,
			TWR,
			CumulativeTWR,
			CumulativeTWRAnnualized,
			FromDate,
			PeriodThruDate 
		from APXUser.fPerformanceHistory(@ReportData) 
) ph 
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = ph.PortfolioBaseID
where @ShowIndexes = 1 or ph.IsIndex = 0
order by PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder, PeriodThruDate
--select GETDATE() - @timer
end

GO


