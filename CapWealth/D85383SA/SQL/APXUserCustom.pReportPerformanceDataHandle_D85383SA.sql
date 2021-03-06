IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportPerformanceDataHandle_D85383SA]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pReportPerformanceDataHandle_D85383SA] 
GO 

create procedure [APXUserCustom].[pReportPerformanceDataHandle_D85383SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	
	-- Optional parameters for sqlrep proc
	@FeeMethod int = null,
	@AnnualizeReturns char(1) = null,			-- no Use Settings
	@Period char(3) = null,
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AccruedInterestID smallint = null,		-- Use Settings
	@ShowMultiCurrency bit = null,			-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@OverridePortfolioSettings bit = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@UseACB bit = null,						-- Use Settings
	@DataHandleName nvarchar(max) = 'Performance'
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@ReportData out
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @ShowFees bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	-- Parameters internal to this proc that are derived from other parameters.
	@FeeMethod = @FeeMethod, -- Need for determining @ShowFees.
	@ShowFees = @ShowFees out -- A boolean that is derived from @FeeMethod.
-- 4. Select the columns for the report.
select
	
	-- Indicates if the return should be annualized.
	-- If @ConfigurationAnnualizeReturns and @AnnualizeReturns (from user), then always annualize, regardless of TimePeriod.
	-- If @AnnualizeReturns (from user) and TimePeriod > 1 year, then annualize.
	-- Otherwise do not annualize.
 	AnnualizeReturn = convert(bit, case
		when @AnnualizeReturns = 'a'  then 1
		when @AnnualizeReturns = 'o' and 366 <= datediff(day, perf.FromDate, perf.ThruDate) then 1
		else 0 end),
	p.FormatReportingCurrency,
	p.LegacyLocaleID,
	p.LocaleID,
	p.PrefixedPortfolioBaseCode,
  
	-- Indicates if Accrued Interest should be shown.
	-- If @OverridePortfolioSettings, then use the effective value of @AccruedInterestID.
	-- Otherwise use  the portfolio AccruedInterestID.
	ShowAccruedInterest = APXUser.fShowAccruedInterestOnPerformanceReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID),
	-- Indicates if fees should be shown.
	-- Based on @FeeMethod.
	ShowFees = @ShowFees,
	
	-- The effective value of @ShowMultiCurrency.
	-- If @ShowMultiCurrency is specified (but not null), then @ShowMultiCurrency.
	-- Otherwise Configuration.ShowMultiCurrency.
	ShowMultiCurrency = @ShowMultiCurrency,
	
	-- The effective value of @UseACB
	-- If @UseACB is specified (but not null), then @UseACB.
	-- Otherwise Configuration.UseACB.
	UseACB = @UseACB,
	Period = @Period,
	perf.*
from APXUser.fPerformance(@ReportData) perf
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
	p.PortfolioBaseID = perf.PortfolioBaseID
where perf.PortfolioBaseID = @PortfolioBaseID and
	perf.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by perf.PortfolioBaseIDOrder, perf.ClassificationMemberID, ClassificationMemberName
end
