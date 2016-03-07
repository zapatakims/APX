IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pMDSARIReport]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pMDSARIReport]
GO
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = '@casetrade'
	,@FromDate datetime = '12/31/08'
	,@ToDate datetime = '12/31/09'
	,@ClassificationID int = -9
	,@ReportingCurrencyCode char(2) = 'us'
	,@FeeMethod int
	,@AccruePerfFees bit
	,@AllocatePerfFees bit
	,@AnnualizeReturns char(1) = 'o'
	,@UseIRRCalc bit
	,@LocaleID int
exec APXUserCustom.pMDSARIReport @SessionGuid, @Portfolios, @FromDate, @ToDate, @ClassificationID, 
@ReportingCurrencyCode, @FeeMethod, @AccruePerfFees, @AllocatePerfFees, @AnnualizeReturns, @UseIRRCalc, @LocaleID
*/
create procedure [APXUserCustom].[pMDSARIReport]
	@SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32)
	,@FromDate datetime
	,@ToDate datetime
	,@ClassificationID int
	,@ReportingCurrencyCode char(2)
	,@FeeMethod int
	,@AccruePerfFees bit
	,@AllocatePerfFees bit
	,@AnnualizeReturns char(1)
	,@UseIRRCalc bit
	,@LocaleID int

as begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid


-- 2. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pPerformanceHistoryPeriod

  -- Required Parameters
  @ReportData = @ReportData out,
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
  @LocaleID = @LocaleID

-- 4. Select the columns for the report.
--	Portfolio returns
select

-- fPerformanceHistoryPeriod
	ph.ClassificationID,
	ph.ClassificationMemberCode,
	ph.ClassificationMemberName,
	ph.ClassificationMemberOrder,

	ph.DayToDateTWR / 100 [DayToDateTWR],
	case when @AnnualizeReturns = 'a' then
		APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.DayToDatePeriodFromDate,ph.ThruDate) / 100,ph.DayToDatePeriodFromDate, ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.DayToDatePeriodFromDate,ph.ThruDate) / 100 end [DayToDateTWRIndex],
	ph.DayToDatePeriodFromDate,

	ph.InceptionToDateTWR / 100 [InceptionToDateTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100
		when @AnnualizeReturns = 'o' and datediff(DAY,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100>365 then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.InceptionToDatePeriodFromDate,ph.ThruDate) / 100 end [InceptionToDateTWRIndex],
	ph.InceptionToDatePeriodFromDate,

	ph.Latest1YearTWR / 100 [Latest1YearTWR],
	APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest1YearPeriodFromDate,ph.ThruDate) / 100,ph.Latest1YearPeriodFromDate,ph.ThruDate) / 100 [Latest1YearTWRIndex],
	ph.Latest1YearPeriodFromDate,

	ph.Latest3MonthsTWR / 100 [Latest3MonthsTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest3MonthsPeriodFromDate,ph.ThruDate) / 100,ph.Latest3YearsPeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest3MonthsPeriodFromDate,ph.ThruDate) / 100 end [Latest3MonthsTWRIndex],
	ph.Latest3MonthsPeriodFromDate,

	ph.Latest3YearsTWR / 100 [Latest3YearsTWR],
	case when @AnnualizeReturns <> 'n' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest3YearsPeriodFromDate,ph.ThruDate) / 100,ph.Latest3YearsPeriodFromDate, ph.ThruDate)
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest3YearsPeriodFromDate,ph.ThruDate) / 100 end [Latest3YearsTWRIndex],
	ph.Latest3YearsPeriodFromDate,

	ph.Latest5YearsTWR / 100 [Latest5YearsTWR],
	case when @AnnualizeReturns <> 'n' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest5YearsPeriodFromDate,ph.ThruDate) / 100,ph.Latest5YearsPeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.Latest5YearsPeriodFromDate,ph.ThruDate) / 100 end [Latest5YearsTWRIndex],
	ph.Latest5YearsPeriodFromDate,

	ph.MonthToDateTWR / 100 [MonthToDateTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.MonthToDatePeriodFromDate,ph.ThruDate) / 100,ph.MonthToDatePeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.MonthToDatePeriodFromDate,ph.ThruDate) / 100 end [MonthToDateTWRIndex],
	ph.MonthToDatePeriodFromDate,

	ph.PortfolioBaseID,
	ph.PortfolioBaseIDOrder,

	ph.QuarterToDateTWR / 100 [QuarterToDateTWR],
	case when @AnnualizeReturns = 'a' then
		APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.QuarterToDatePeriodFromDate,ph.ThruDate) / 100,ph.QuarterToDatePeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.QuarterToDatePeriodFromDate,ph.ThruDate) / 100 end [QuarterToDateTWRIndex],
	ph.QuarterToDatePeriodFromDate,

	ph.SinceDateTWR / 100 [SinceDateTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100
		when @AnnualizeReturns = 'o' and DATEDIFF(DAY,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100>365 then 
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.SinceDateTWRPeriodFromDate,ph.ThruDate) / 100 end [SinceDateTWRIndex],
	ph.SinceDateTWRPeriodFromDate,

	ph.ThruDate,
	ph.WeekToDateTWR / 100 [WeekToDateTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.WeekToDatePeriodFromDate,ph.ThruDate) / 100,ph.WeekToDatePeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.WeekToDatePeriodFromDate,ph.ThruDate) / 100 end [WeekToDateTWRIndex],
	ph.WeekToDatePeriodFromDate,

	ph.YearToDateTWR / 100 [YearToDateTWR],
	case when @AnnualizeReturns = 'a' then
			APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.YearToDatePeriodFromDate,ph.ThruDate) / 100,ph.YearToDatePeriodFromDate,ph.ThruDate) / 100
		else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.YearToDatePeriodFromDate,ph.ThruDate) / 100 end [YearToDateTWRIndex],
	ph.YearToDatePeriodFromDate,

--	index
	m.IndexName,
	case when m.IndexName = 'Blend' then APXUserCustom.fGetSynthIndexDesc(ph.PortfolioBaseID) else m.IndexDesc end [IndexDescription],

-- Portfolio	
	b.PrefixedPortfolioBaseCode,
	b.PortfolioBaseCode,
	isnull(l.Value, b.ReportHeading1) [ReportHeading1],
	b.ReportHeading2,
	b.ReportHeading3,

-- Effective Parameter
  LocaleID = isnull(@LocaleID, b.LocaleID)

-- 5. Join to additional views
from APXUser.fPerformanceHistoryPeriod(@ReportData) ph 
join APXUser.vPortfolioBaseSettingEx b on b.PortfolioBaseID = ph.PortfolioBaseID
left join APXUser.vPortfolioBaseCustomLabels l on l.PortfolioBaseID = ph.PortfolioBaseID
	and l.Label = '$pname'
left join APXUser.vPortfolioBaseCustomLabels s on s.PortfolioBaseID = ph.PortfolioBaseID
	and s.Label = '$sindex'
left join APXUser.vMarketIndex m on m.IndexName = s.Value
where ph.IsIndex = 0
end