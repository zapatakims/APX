if object_id('[APXUserCustom].[pReportPerformanceHistoryPeriodDataHandle]') is not null
	drop procedure [APXUserCustom].[pReportPerformanceHistoryPeriodDataHandle]
go

-- 1. The unique key is IsIndex, PortfolioBaseIDOrder, ClassificationMemberOrder, PeriodThruDate
create procedure [APXuserCustom].[pReportPerformanceHistoryPeriodDataHandle]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	@IndexArray nvarchar(max) = null,
	@Periods nvarchar(max),
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
    
	-- Other optional parameters
	@AnnualizeReturns char(1) = null,			-- no Use Settings
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

declare @maxCount int
select @maxCount = COUNT(name) from APXUserCustom.CSVToTable(@IndexArray)

declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@ReportData out
-- Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
-- Also calculate some new variables that are internal to this proc.
exec APXUser.pGetEffectiveParameter
	-- Parameters internal to this proc that are derived from other parameters.
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out
-- Set some miscellaneous working variables
declare @delimitedPeriods nvarchar(max)
set @delimitedPeriods = ',' + @Periods + ','
declare @temp table ([ID] int identity, PortfolioBaseID int, 
	DTDTWR float, DTDHeader nvarchar(72), DTDShow bit, 
	WTDTWR float, WTDHeader nvarchar(72), WTDShow bit,
	MTDTWR float, MTDHeader nvarchar(72), MTDShow bit,
	QTDTWR float, QTDHeader nvarchar(72), QTDShow bit,
	YTDTWR Float, YTDHeader nvarchar(72), YTDShow bit,
	L1YTWR float, L1YHeader nvarchar(72), L1YShow bit,
	L3YTWR float, L3YHeader nvarchar(72), L3YShow bit,
	L5YTWR float, L5YHeader nvarchar(72), L5YShow bit,
	ITDTWR float, ITDHeader nvarchar(72), ITDShow bit, 
	IsIndex Bit)
insert @temp
-- Select the columns for the report.
select 
  ph.PortfolioBaseID,
  -- Day to Date
  ph.DayToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' then 'Annualized Day To Date' else 'Day To Date' end,
  convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
  -- Week To Date
  ph.WeekToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' then 'Annualized Week To Date' else 'Week To Date' end,
  convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Month to Date
  ph.MonthToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' then 'Annualized Month To Date' else 'Month To Date' end,
  convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Quarter to Date
  ph.QuarterToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' then 'Annualized Quarter To Date' else 'Quarter To Date' end,
  convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Year To Date        
  ph.YearToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' then 'Annualized Year To Date' else 'Year To Date' end,
  convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 1 Year
  ph.Latest1YearAnnualizedTWR,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest1YearPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 1 Year' else 'Latest 1 Year' end,
  convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 3 Years
  ph.Latest3YearsAnnualizedTWR,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest3YearsPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 3 Years' else 'Latest 3 Years' end,
  convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 5 Years
  ph.Latest5YearsAnnualizedTWR,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest5YearsPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 5 Years' else 'Latest 5 Years' end,
  convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Inception To Date
  ph.InceptionToDateAnnualizedTWR,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate)) then 'Annualized Inception To Date' else 'Inception To Date' end,
  convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  ph.IsIndex
from APXUser.fPerformanceHistoryPeriod(@ReportData) ph 
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  	p.PortfolioBaseID = ph.PortfolioBaseID
where ph.IsIndex = 0 and
	ph.PortfolioBaseID = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder

insert into @temp
select 
  ph.PortfolioBaseID,
  -- Day to Date
  case when @AnnualizeReturns = 'a' 
	then APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.DayToDatePeriodFromDate, ph.ThruDate),ph.DayToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.DayToDatePeriodFromDate, ph.ThruDate) end,
  case when @AnnualizeReturns = 'a' then 'Annualized Day To Date' else 'Day To Date' end,
  convert(bit, case when charindex(',ATD,', @delimitedPeriods) > 0 then 1 else 0 end),
  -- Week To Date
  case when @AnnualizeReturns = 'a' 
	then APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.WeekToDatePeriodFromDate, ph.ThruDate),ph.WeekToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.WeekToDatePeriodFromDate, ph.ThruDate) end,
  case when @AnnualizeReturns = 'a' then 'Annualized Week To Date' else 'Week To Date' end,
  convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Month to Date
  case when @AnnualizeReturns = 'a' 
	then APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.MonthToDatePeriodFromDate, ph.ThruDate),ph.MonthToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.MonthToDatePeriodFromDate, ph.ThruDate) end,
  case when @AnnualizeReturns = 'a' then 'Annualized Month To Date' else 'Month To Date' end,
  convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Quarter to Date
  case when @AnnualizeReturns = 'a' 
	then APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.QuarterToDatePeriodFromDate, ph.ThruDate),ph.QuarterToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.QuarterToDatePeriodFromDate, ph.ThruDate) end,
  case when @AnnualizeReturns = 'a' then 'Annualized Quarter To Date' else 'Quarter To Date' end,
  convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Year To Date        
  case when @AnnualizeReturns = 'a' 
	then APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.YearToDatePeriodFromDate, ph.ThruDate),ph.YearToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.YearToDatePeriodFromDate, ph.ThruDate) end,
  case when @AnnualizeReturns = 'a' then 'Annualized Year To Date' else 'Year To Date' end,
  convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 1 Year
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest1YearPeriodFromDate, ph.ThruDate)) then 
	APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest1YearPeriodFromDate, ph.ThruDate),ph.Latest1YearPeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest1YearPeriodFromDate, ph.ThruDate)
	end,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest1YearPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 1 Year' else 'Latest 1 Year' end,
  convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 3 Years
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest3YearsPeriodFromDate, ph.ThruDate)) then 
	APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest3YearsPeriodFromDate, ph.ThruDate),ph.Latest3YearsPeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest3YearsPeriodFromDate, ph.ThruDate)
	end,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest3YearsPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 3 Years' else 'Latest 3 Years' end,
  convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Latest 5 Years
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest5YearsPeriodFromDate, ph.ThruDate)) then 
	APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest5YearsPeriodFromDate, ph.ThruDate),ph.Latest5YearsPeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.Latest5YearsPeriodFromDate, ph.ThruDate)
	end,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.Latest5YearsPeriodFromDate, ph.ThruDate)) then 'Annualized Latest 5 Years' else 'Latest 5 Years' end,
  convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),
  -- Inception To Date
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate)) then 
	APXUserCustom.fGetAnnualizedReturn(APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.InceptionToDatePeriodFromDate, ph.ThruDate),ph.InceptionToDatePeriodFromDate,ph.ThruDate)
	else APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, i.IndexID, @ReportingCurrencyCode, ph.InceptionToDatePeriodFromDate, ph.ThruDate)
	end,
  case when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ph.InceptionToDatePeriodFromDate, ph.ThruDate)) then 'Annualized Inception To Date' else 'Inception To Date' end,
  convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),
  1
from APXUser.fPerformanceHistoryPeriod(@ReportData) ph
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = ph.PortfolioBaseID
join APXUserCustom.CSVToTable(@IndexArray) ia on 1 = 1
join APXUser.vMarketIndex i on i.IndexID = ia.name
where ph.IsIndex = 0
order by PortfolioBaseIDOrder, IsIndex, ClassificationMemberOrder

select ID, PortfolioBaseID,	DTDHeader [Period],	DTDTWR [Return],DTDShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	WTDHeader [Period],	WTDTWR [Return],WTDShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	MTDHeader [Period],	MTDTWR [Return],MTDShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	QTDHeader [Period],	QTDTWR [Return],QTDShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	YTDHeader [Period],	YTDTWR [Return],YTDShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	L1YHeader [Period],	L1YTWR [Return],L1YShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	L3YHeader [Period],	L3YTWR [Return],L3YShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	L5YHeader [Period],	L5YTWR [Return],L5YShow [Show],	IsIndex from @temp
union all
select ID, PortfolioBaseID,	ITDHeader [Period],	ITDTWR [Return],ITDShow [Show],	IsIndex from @temp
end
