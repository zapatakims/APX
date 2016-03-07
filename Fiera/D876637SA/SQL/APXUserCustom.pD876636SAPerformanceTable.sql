IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pD876636SA_PerformanceTable]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pD876636SA_PerformanceTable]
GO

create procedure [APXUserCustom].[pD876636SA_PerformanceTable]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	--@Periods nvarchar(max),
	@ClassificationID1 int,
	-- Optional parameters for sqlrep proc
	@ClassificationID2 int,
	@ClassificationID3 int,
	@Periods nvarchar(max),
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
    
	-- Other optional parameters
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null	-- Use Settings
	
as
begin
declare	@AnnualizeReturns char(1) = 'o',
	@ShowIndexes bit = 0

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @PerfSummary1 varbinary(max), @PerfSummary2 varbinary(max), @PerfSummary3 varbinary(max), @PerfSummary4 varbinary(max), @PerfSummary5 varbinary(max), @PerfSummary6 varbinary(max),
	@Cumulative1 varbinary(max), @Cumulative2 varbinary(max), @Cumulative3 varbinary(max), @Holdings varbinary(max)

exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary3 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary4', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary4 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary5', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary5 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary6', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary6 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative3 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Holdings out

exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out

declare @delimitedPeriods nvarchar(max)--, 
	--@Periods nvarchar(max) = 'MTD,YTD,L1Y,L2Y,L3Y,L4Y,ITD'
set @delimitedPeriods = ',' + @Periods + ','

--declare @ClassificationName nstr72 = (select DisplayName from dbo.AoProperty pr where pr.PropertyID = @ClassificationID)
-- Time Period Variables
declare @DTD nvarchar(255) = 'Day VBCRLF To Date'
declare @DTDAnn nvarchar(255) = @DTD
declare @ITD nvarchar(255) = 'Since Inception'
declare @ITDAnn nvarchar(255) = @ITD
declare @L1Y nvarchar(255) = '1-Year'
declare @L1YAnn nvarchar(255) = @L1Y
declare @L2Y nvarchar(255) = '2-Year'
declare @L2YAnn nvarchar(255) = @L2Y
declare @L3Y nvarchar(255) = '3-Year'
declare @L3YAnn nvarchar(255) = @L3Y
declare @L4Y nvarchar(255) = '4-Year'
declare @L4YAnn nvarchar(255) = @L4Y
declare @L5Y nvarchar(255) = '5-Year'
declare @L5YAnn nvarchar(255) = @L5Y
declare @MTD nvarchar(255) = 'Current VBCRLF Month'
declare @MTDAnn nvarchar(255) = @MTD
declare @QTD nvarchar(255) = 'Quarter VBCRLF To Date'
declare @QTDAnn nvarchar(255) = @QTD
declare @WTD nvarchar(255) = 'Week VBCRLF To Date'
declare @WTDAnn nvarchar(255) = @WTD
declare @YTD nvarchar(255) = 'YTD'
declare @YTDAnn nvarchar(255) = @YTD
declare @SSDIRR nvarchar(255) = 'Since IRR'
declare @SSDIRRAnn nvarchar(255) = @SSDIRR
declare @SSDTWR nvarchar(255) = 'Since TWR'
declare @SSDTWRAnn nvarchar(255) = @SSDTWR
-- Get the decoration text into a local table
declare @Decor table(APXLocaleID dtID primary key, ShortText nvarchar(255))
insert into @Decor (APXLocaleID, ShortText)
select q.LocaleID, APXSSRS.fShortSecurityNameDecoration(q.LocaleID)
from (
	select distinct p.LocaleID
	from (select distinct PortfolioBaseID from APXUser.fPerformanceHistoryPeriod(@PerfSummary1)) a
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on p.PortfolioBaseID = a.PortfolioBaseID
	where @LocaleID is null
	union
	select @LocaleID
	where @LocaleID is not null
	) q

declare @Hierarchy table (Classification1DisplayOrder int, Classification1ID int, Classification1MemberID int, Classification1DisplayName nvarchar(max),
	Classification2DisplayOrder int, Classification2ID int, Classification2MemberID int, Classification2DisplayName nvarchar(max),
	Classification3DisplayOrder int, Classification3ID int, Classification3MemberID int, Classification3DisplayName nvarchar(max))
insert @Hierarchy
select distinct 
	-- Classification 1
	[Classification1DisplayOrder] = s1.DisplayOrder,
	[Classification1ID] = @ClassificationID1,
	[Classification1MemberID] = s1.ClassificationMemberID,
	--[Classification1Label] = s1.Label,
	left(s1.Label,len(s1.Label) - patindex('%([0-9])%',s1.Label) + 1),

	-- Classification 2
	[Classification2DisplayOrder] = s2.DisplayOrder,
	[Classification2ID] = @ClassificationID2,
	[Classification2MemberID] = s2.ClassificationMemberID,
	left(s2.Label,len(s2.Label) - patindex('%([0-9])%',s2.Label) + 1),

	-- Classification 3
	[Classification3DisplayOrder] = s3.DisplayOrder,
	[Classification3ID] = @ClassificationID3,
	[Classification3MemberID] = s3.ClassificationMemberID,
	left(s3.Label,len(s3.Label) - patindex('%([0-9])%',s3.Label) + 1)
from APXUserCustom.AssetClassHierarchy a
left join APXUser.vSecClassMember s1 on 
	s1.ClassificationID = @ClassificationID1 and
	s1.Label = a.AssetClass1 
left join APXUser.vSecClassMember s2 on 
	s2.ClassificationID = @ClassificationID2 and
	s2.Label = a.AssetClass2
left join APXUser.vSecClassMember s3 on 
	s3.ClassificationID = @ClassificationID3 and
	s3.Label = a.AssetClass3

declare @PerformanceTable1 table (ClassificationID int, ClassificationMemberID int, ClassificationMemberCode nvarchar(72), ClassificationMemberName nvarchar(max)
	,ClassificationMemberOrder int, DayToDateEffectiveTWR float, DayToDatePeriodFromDate datetime
	,EndingMarketValue float, InceptionToDateEffectiveTWR float, InceptionToDatePeriodFromDate datetime
	,IsIndex bit, Latest1YearEffectiveTWR float, Latest1YearPeriodFromDate datetime
	,Latest2YearsEffectiveTWR float, Latest2YearsPeriodFromDate datetime, Latest3YearsEffectiveTWR float, Latest3YearsPeriodFromDate datetime
	,Latest4YearsEffectiveTWR float, Latest4YearsPeriodFromDate datetime, Latest5YearsEffectiveTWR float, Latest5YearsPeriodFromDate datetime
	,MonthToDateEffectiveTWR float, MonthToDatePeriodFromDate datetime, PortfolioBaseID int, PortfolioBaseIDOrder int, QuarterToDateEffectiveTWR float
	,QuarterToDatePeriodFromDate datetime, ThruDate datetime, WeekToDateEffectiveTWR float, WeekToDatePeriodFromDate datetime, YearToDateEffectiveTWR float
	,YearToDatePeriodFromDate datetime, IsShortPosition bit, BondDescription nvarchar(max))
declare @PerformanceTable2 table (ClassificationID int, ClassificationMemberID int, ClassificationMemberCode nvarchar(72), ClassificationMemberName nvarchar(max)
	,ClassificationMemberOrder int, DayToDateEffectiveTWR float, DayToDatePeriodFromDate datetime
	,EndingMarketValue float, InceptionToDateEffectiveTWR float, InceptionToDatePeriodFromDate datetime
	,IsIndex bit, Latest1YearEffectiveTWR float, Latest1YearPeriodFromDate datetime
	,Latest2YearsEffectiveTWR float, Latest2YearsPeriodFromDate datetime, Latest3YearsEffectiveTWR float, Latest3YearsPeriodFromDate datetime
	,Latest4YearsEffectiveTWR float, Latest4YearsPeriodFromDate datetime, Latest5YearsEffectiveTWR float, Latest5YearsPeriodFromDate datetime
	,MonthToDateEffectiveTWR float, MonthToDatePeriodFromDate datetime, PortfolioBaseID int, PortfolioBaseIDOrder int, QuarterToDateEffectiveTWR float
	,QuarterToDatePeriodFromDate datetime, ThruDate datetime, WeekToDateEffectiveTWR float, WeekToDatePeriodFromDate datetime, YearToDateEffectiveTWR float
	,YearToDatePeriodFromDate datetime, IsShortPosition bit, BondDescription nvarchar(max))
declare @PerformanceTable3 table (ClassificationID int, ClassificationMemberID int, ClassificationMemberCode nvarchar(72), ClassificationMemberName nvarchar(max)
	,ClassificationMemberOrder int, DayToDateEffectiveTWR float, DayToDatePeriodFromDate datetime
	,EndingMarketValue float, InceptionToDateEffectiveTWR float, InceptionToDatePeriodFromDate datetime
	,IsIndex bit, Latest1YearEffectiveTWR float, Latest1YearPeriodFromDate datetime
	,Latest2YearsEffectiveTWR float, Latest2YearsPeriodFromDate datetime, Latest3YearsEffectiveTWR float, Latest3YearsPeriodFromDate datetime
	,Latest4YearsEffectiveTWR float, Latest4YearsPeriodFromDate datetime, Latest5YearsEffectiveTWR float, Latest5YearsPeriodFromDate datetime
	,MonthToDateEffectiveTWR float, MonthToDatePeriodFromDate datetime, PortfolioBaseID int, PortfolioBaseIDOrder int, QuarterToDateEffectiveTWR float
	,QuarterToDatePeriodFromDate datetime, ThruDate datetime, WeekToDateEffectiveTWR float, WeekToDatePeriodFromDate datetime, YearToDateEffectiveTWR float
	,YearToDatePeriodFromDate datetime, IsShortPosition bit, BondDescription nvarchar(max))

insert @PerformanceTable1
select
  @ClassificationID1,
  ph.ClassificationMemberID,
  ph.ClassificationMemberCode,
  ph.ClassificationMemberName,
	  case when ph.ClassificationMemberCode = 'totport' then ph.ClassificationMemberOrder * -1
	  else ph.ClassificationMemberOrder end,
  -- Day to Date
  DayToDateEffectiveTWR = ph.DayToDateAnnualizedTWR,
  ph.DayToDatePeriodFromDate,

  EndingMarketValue = ph.InceptionToDateEndingMarketValue,

  -- Inception To Date
  InceptionToDateEffectiveTWR = ph.InceptionToDateAnnualizedTWR,
  ph.InceptionToDatePeriodFromDate,

  ph.IsIndex,

  -- Latest 1 Year
  Latest1YearEffectiveTWR = ph.Latest1YearAnnualizedTWR,
  ph.Latest1YearPeriodFromDate,

  -- Latest 2 Years
  Latest2YearsEffectiveTWR = ph.SinceDateAnnualizedTWR,
  Latest2YearsPeriodFromDate = ph.SinceDateTWRPeriodFromDate,
  
  -- Latest 3 Years
  Latest3YearsEffectiveTWR = ph.Latest3YearsAnnualizedTWR,
  ph.Latest3YearsPeriodFromDate,

  -- Latest 4 Years
  Latest4YearsEffectiveTWR = ph2.SinceDateAnnualizedTWR,
  Latest4YearsPeriodFromDate = ph2.SinceDateTWRPeriodFromDate,

  -- Latest 5 Years
  Latest5YearsEffectiveTWR = ph.Latest5YearsAnnualizedTWR,
  ph.Latest5YearsPeriodFromDate,
  
  -- Month to Date
  MonthToDateEffectiveTWR = ph.MonthToDateAnnualizedTWR,
  ph.MonthToDatePeriodFromDate,

  ph.PortfolioBaseID,
  ph.PortfolioBaseIDOrder,
  
  -- Quarter to Date
  QuarterToDateEffectiveTWR = ph.QuarterToDateAnnualizedTWR,
  ph.QuarterToDatePeriodFromDate,

  ph.ThruDate,
  
  -- Week To Date
  WeekToDateEffectiveTWR = ph.WeekToDateAnnualizedTWR,
  ph.WeekToDatePeriodFromDate,

  -- Year To Date        
  YearToDateEffectiveTWR = ph.YearToDateAnnualizedTWR,
  ph.YearToDatePeriodFromDate,

  ph.IsShortPosition,
  ph.BondDescription
from APXUser.fPerformanceHistoryPeriod(@PerfSummary1) ph
join APXUser.fPerformanceHistoryPeriod(@PerfSummary2) ph2 on
	ph2.PortfolioBaseID = ph.PortfolioBaseID and
	ph2.IsIndex = ph.IsIndex and
	ph2.ClassificationMemberCode = ph.ClassificationMemberCode
where @ShowIndexes = 1 or ph.IsIndex = 0 and
	ph.PortfolioBaseID = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder

insert @PerformanceTable2
select
  @ClassificationID2,
  ph.ClassificationMemberID,
  ph.ClassificationMemberCode,
  ph.ClassificationMemberName,
	  case when ph.ClassificationMemberCode = 'totport' then ph.ClassificationMemberOrder * -1
	  else ph.ClassificationMemberOrder end,
  -- Day to Date
  DayToDateEffectiveTWR = ph.DayToDateAnnualizedTWR,
  ph.DayToDatePeriodFromDate,

  EndingMarketValue = ph.InceptionToDateEndingMarketValue,

  -- Inception To Date
  InceptionToDateEffectiveTWR = ph.InceptionToDateAnnualizedTWR,
  ph.InceptionToDatePeriodFromDate,

  ph.IsIndex,

  -- Latest 1 Year
  Latest1YearEffectiveTWR = ph.Latest1YearAnnualizedTWR,
  ph.Latest1YearPeriodFromDate,

  -- Latest 2 Years
  Latest2YearsEffectiveTWR = ph.SinceDateAnnualizedTWR,
  Latest2YearsPeriodFromDate = ph.SinceDateTWRPeriodFromDate,
  
  -- Latest 3 Years
  Latest3YearsEffectiveTWR = ph.Latest3YearsAnnualizedTWR,
  ph.Latest3YearsPeriodFromDate,

  -- Latest 4 Years
  Latest4YearsEffectiveTWR = ph2.SinceDateAnnualizedTWR,
  Latest4YearsPeriodFromDate = ph2.SinceDateTWRPeriodFromDate,

  -- Latest 5 Years
  Latest5YearsEffectiveTWR = ph.Latest5YearsAnnualizedTWR,
  ph.Latest5YearsPeriodFromDate,
  
  -- Month to Date
  MonthToDateEffectiveTWR = ph.MonthToDateAnnualizedTWR,
  ph.MonthToDatePeriodFromDate,

  ph.PortfolioBaseID,
  ph.PortfolioBaseIDOrder,
  
  -- Quarter to Date
  QuarterToDateEffectiveTWR = ph.QuarterToDateAnnualizedTWR,
  ph.QuarterToDatePeriodFromDate,

  ph.ThruDate,
  
  -- Week To Date
  WeekToDateEffectiveTWR = ph.WeekToDateAnnualizedTWR,
  ph.WeekToDatePeriodFromDate,

  -- Year To Date        
  YearToDateEffectiveTWR = ph.YearToDateAnnualizedTWR,
  ph.YearToDatePeriodFromDate,

  ph.IsShortPosition,
  ph.BondDescription
from APXUser.fPerformanceHistoryPeriod(@PerfSummary3) ph
join APXUser.fPerformanceHistoryPeriod(@PerfSummary4) ph2 on
	ph2.PortfolioBaseID = ph.PortfolioBaseID and
	ph2.IsIndex = ph.IsIndex and
	ph2.ClassificationMemberCode = ph.ClassificationMemberCode
where @ShowIndexes = 1 or ph.IsIndex = 0 and
	ph.PortfolioBaseID = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder

insert @PerformanceTable3
select
  @ClassificationID3,
  ph.ClassificationMemberID,
  ph.ClassificationMemberCode,
  ph.ClassificationMemberName,
	  case when ph.ClassificationMemberCode = 'totport' then ph.ClassificationMemberOrder * -1
	  else ph.ClassificationMemberOrder end,
  -- Day to Date
  DayToDateEffectiveTWR = ph.DayToDateAnnualizedTWR,
  ph.DayToDatePeriodFromDate,

  EndingMarketValue = ph.InceptionToDateEndingMarketValue,

  -- Inception To Date
  InceptionToDateEffectiveTWR = ph.InceptionToDateAnnualizedTWR,
  ph.InceptionToDatePeriodFromDate,

  ph.IsIndex,

  -- Latest 1 Year
  Latest1YearEffectiveTWR = ph.Latest1YearAnnualizedTWR,
  ph.Latest1YearPeriodFromDate,

  -- Latest 2 Years
  Latest2YearsEffectiveTWR = ph.SinceDateAnnualizedTWR,
  Latest2YearsPeriodFromDate = ph.SinceDateTWRPeriodFromDate,
  
  -- Latest 3 Years
  Latest3YearsEffectiveTWR = ph.Latest3YearsAnnualizedTWR,
  ph.Latest3YearsPeriodFromDate,

  -- Latest 4 Years
  Latest4YearsEffectiveTWR = ph2.SinceDateAnnualizedTWR,
  Latest4YearsPeriodFromDate = ph2.SinceDateTWRPeriodFromDate,

  -- Latest 5 Years
  Latest5YearsEffectiveTWR = ph.Latest5YearsAnnualizedTWR,
  ph.Latest5YearsPeriodFromDate,
  
  -- Month to Date
  MonthToDateEffectiveTWR = ph.MonthToDateAnnualizedTWR,
  ph.MonthToDatePeriodFromDate,

  ph.PortfolioBaseID,
  ph.PortfolioBaseIDOrder,
  
  -- Quarter to Date
  QuarterToDateEffectiveTWR = ph.QuarterToDateAnnualizedTWR,
  ph.QuarterToDatePeriodFromDate,

  ph.ThruDate,
  
  -- Week To Date
  WeekToDateEffectiveTWR = ph.WeekToDateAnnualizedTWR,
  ph.WeekToDatePeriodFromDate,

  -- Year To Date        
  YearToDateEffectiveTWR = ph.YearToDateAnnualizedTWR,
  ph.YearToDatePeriodFromDate,

  ph.IsShortPosition,
  ph.BondDescription
from APXUser.fPerformanceHistoryPeriod(@PerfSummary5) ph
join APXUser.fPerformanceHistoryPeriod(@PerfSummary6) ph2 on
	ph2.PortfolioBaseID = ph.PortfolioBaseID and
	ph2.IsIndex = ph.IsIndex and
	ph2.ClassificationMemberCode = ph.ClassificationMemberCode
where @ShowIndexes = 1 or ph.IsIndex = 0 and
	ph.PortfolioBaseID = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder

declare @TotMV float
select @TotMV = EndingMarketValue from @PerformanceTable1 where ClassificationMemberCode = 'totport'

--	2015-05-05 AZK Adding filter table for 'Fund' CSP set to 'y'.
declare @KeyString char(1) = 'y', @ClassificationName nvarchar(255) = 'Fund'
declare @filter table (ClassificationID int, ClassificationMemberID int, ClassificationDisplayName nvarchar(255), ClassificationMemberCode nvarchar(255))
insert @filter
select distinct
	[ClassificationID] = assetClass3.PropertyID,
	[ClassificationMemberID] = assetClass3.PropertyLookupID,
	[ClassificationDisplayName] = assetClass3.DisplayName,
	[ClassificationMemberCode] = isnull(ls.DisplayName,'n')
from APXUser.vSecurityPropertyLookupLS ls
join APXUser.vSecClass sc on
	sc.ClassificationID = ls.PropertyID and
	ls.IsShort = 0
join APXUser.vSecurityPropertyLookupLS assetClass3 on
	assetClass3.PropertyID = @ClassificationID3 and
	assetClass3.SecurityID = ls.SecurityID and
	assetClass3.IsShort = 0
where sc.ClassificationName = @ClassificationName and
	isnull(ls.DisplayName,'n') = @KeyString

declare @PortfolioInceptionDate datetime
select @PortfolioInceptionDate = InceptionToDatePeriodFromDate from APXUser.fPerformanceHistoryPeriod(@PerfSummary1)

create table #InceptionDates_Sub (RowID int identity, ClassificationID int, ClassificationMemberID int, InceptionDate datetime)

declare @temp table (OrderID int, ClassificationID int, ClassificationMemberID int, Classification1MemberOrder int, Classification2MemberOrder int, InceptionDate datetime)
declare @footerstring nvarchar(max)
--insert @temp
--select 1, @ClassificationID1, ph.ClassificationMemberID, ph.ClassificationMemberOrder, MIN(ph.PeriodFromDate)
--from APXUser.fPerformanceHistory(@Cumulative1) ph
--where ph.ClassificationMemberID is not null 
--	and ph.IsIndex = 0
--group by ph.ClassificationMemberID, ph.ClassificationMemberOrder
--order by ph.ClassificationMemberOrder

insert @temp
select 2, @ClassificationID2, ph.ClassificationMemberID, ph.ClassificationMemberOrder, 0, MIN(ph.PeriodFromDate)
from APXUser.fPerformanceHistory(@Cumulative2) ph
where ph.ClassificationMemberID is not null 
	and ph.IsIndex = 0
group by ph.ClassificationMemberID, ph.ClassificationMemberOrder

insert @temp
select 3, @ClassificationID3, ph.ClassificationMemberID, h.Classification2DisplayOrder, ph.ClassificationMemberOrder, MIN(ph.PeriodFromDate)
from APXUser.fPerformanceHistory(@Cumulative3) ph
join @filter filter on
	filter.ClassificationMemberID = ph.ClassificationMemberID and
	filter.ClassificationID = @ClassificationID3
join @Hierarchy h on 
	h.Classification3ID = @ClassificationID3 and
	h.Classification3MemberID = ph.ClassificationMemberID
where ph.ClassificationMemberID is not null 
	and ph.IsIndex = 0
	and filter.ClassificationMemberCode = 'y'
group by ph.ClassificationMemberID, ph.ClassificationMemberOrder, h.Classification2DisplayOrder

insert #InceptionDates_Sub
select ClassificationID, ClassificationMemberID, InceptionDate from @temp 
where InceptionDate > @PortfolioInceptionDate
order by Classification1MemberOrder, Classification2MemberOrder asc
--select * from @temp
--select * from #InceptionDates_Sub
--select @footerstring = STUFF((
--	select ', ' + convert(nvarchar(32),RowID) + ' - ' + 'since ' + convert(nvarchar(32),InceptionDate,101)
--	from #InceptionDates_Sub
--	for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

select
  p.PrefixedPortfolioBaseCode,
  p1.PortfolioBaseID,
  p1.PortfolioBaseIDOrder,
  p.LegacyLocaleID,
  p.LocaleID,
  p.FormatReportingCurrency,

  p1.IsIndex,
  [IsTotal] = case when p1.ClassificationMemberCode = 'totport' then 1 else 0 end,

--	Hierarchy info
	h.*,
	
	[ShowClassification3] = 'y',

--	Header info
	DayToDateHeader = (case when @AnnualizeReturns = 'a' then @DTDAnn else @DTD end),
	MonthToDateHeader = (case	when @AnnualizeReturns = 'a' then @MTDAnn else @MTD end),
	QuarterToDateHeader = (case when @AnnualizeReturns = 'a' then @QTDAnn else @QTD end),
	InceptionToDateHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.InceptionToDatePeriodFromDate, p1.ThruDate)) then @ITDAnn
		else @ITD end),
	Latest1YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest1YearPeriodFromDate, p1.ThruDate)) then @L1YAnn
		else @L1Y end),
	Latest2YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest1YearPeriodFromDate, p1.ThruDate)) then @L2YAnn
		else @L2Y end),
	Latest3YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest3YearsPeriodFromDate, p1.ThruDate)) then @L3YAnn
		else @L3Y end),
	Latest4YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest4YearsPeriodFromDate, p1.ThruDate)) then @L4YAnn
		else @L4Y end),
	Latest5YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest5YearsPeriodFromDate, p1.ThruDate)) then @L5YAnn
		else @L5Y end),
	WeekToDateHeader = (case 	when @AnnualizeReturns = 'a' then @WTDAnn else @WTD end),
	YearToDateHeader = (case when @AnnualizeReturns = 'a' then @YTDAnn else @YTD end),
	CumulativeHeader = (case 	when @AnnualizeReturns = 'a' then @ITDAnn else @ITD end),

	[ActualAllocation] = 1,
	[TotalMarketValue] = @TotMV,
	[EndingMarketValue1] = p1.EndingMarketValue,
	[EndingMarketValue2] = null,
	[EndingMarketValue3] = null,

--	Day to Date Returns
	[DayToDateEffectiveTWR1] = p1.DayToDateEffectiveTWR,
	[DayToDateEffectiveTWR2] = null,
	[DayToDateEffectiveTWR3] = null,
	[DayToDateShowPeriod] = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Week to Date Returns
	[WeekToDateEffectiveTWR1] = p1.WeekToDateEffectiveTWR,
	[WeekToDateEffectiveTWR2] = null,
	[WeekToDateEffectiveTWR3] = null,
	[WeekToDateShowPeriod] = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Month to Date Returns
	[MonthToDateEffectiveTWR1] = p1.MonthToDateEffectiveTWR,
	[MonthToDateEffectiveTWR2] = null,
	[MonthToDateEffectiveTWR3] = null,
	[MonthToDateShowPeriod] = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Quarter to Date Returns
	[QuarterToDateEffectiveTWR1] = p1.QuarterToDateEffectiveTWR,
	[QuarterToDateEffectiveTWR2] = null,
	[QuarterToDateEffectiveTWR3] = null,
	[QuarterToDateShowPeriod] = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Inception to Date Returns
	[InceptionToDateEffectiveTWR1] = p1.InceptionToDateEffectiveTWR,
	[InceptionToDateEffectiveTWR2] = null,
	[InceptionToDateEffectiveTWR3] = null,
	[InceptionToDateShowPeriod] = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Year to Date Returns
	[YearToDateEffectiveTWR1] = p1.YearToDateEffectiveTWR,
	[YearToDateEffectiveTWR2] = null,
	[YearToDateEffectiveTWR3] = null,
	[YearToDateShowPeriod] = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 1 Year Returns
	[Latest1YearEffectiveTWR1] = p1.Latest1YearEffectiveTWR,
	[Latest1YearEffectiveTWR2] = null,
	[Latest1YearEffectiveTWR3] = null,
	[Latest1YearShowPeriod] = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 2 Year Returns
	[Latest2YearsEffectiveTWR1] = p1.Latest2YearsEffectiveTWR,
	[Latest2YearsEffectiveTWR2] = null,
	[Latest2YearsEffectiveTWR3] = null,
	[Latest2YearsShowPeriod] = convert(bit, case when charindex( ',L2Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 3 Year Returns
	[Latest3YearsEffectiveTWR1] = p1.Latest3YearsEffectiveTWR,
	[Latest3YearsEffectiveTWR2] = null,
	[Latest3YearsEffectiveTWR3] = null,
	[Latest3YearsShowPeriod] = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 4 Year Returns
	[Latest4YearsEffectiveTWR1] = p1.Latest4YearsEffectiveTWR,
	[Latest4YearsEffectiveTWR2] = null,
	[Latest4YearsEffectiveTWR3] = null,
	[Latest4YearsShowPeriod] = convert(bit, case when charindex( ',L4Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 5 Year Returns
	[Latest5YearsEffectiveTWR1] = p1.Latest5YearsEffectiveTWR,
	[Latest5YearsEffectiveTWR2] = null,
	[Latest5YearsEffectiveTWR3] = null,
	[Latest5YearsShowPeriod] = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Cumulative
	CumulativeEffectiveTWR1 = c1.CumulativeTWRAnnualized,
	CumulativeEffectiveTWR2 = null,
	CumulativeEffectiveTWR3 = null,
	p1.InceptionToDatePeriodFromDate,
	
	[DateFooterID1] = null,
	[DateFooterID2] = null,
	[DateFooterID3] = null,
	
	[FooterText] = @footerstring
from @PerformanceTable1 p1
left join @Hierarchy h on 
	h.Classification1ID = p1.ClassificationID and
	h.Classification1MemberID = p1.ClassificationMemberID
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  	p.PortfolioBaseID = p1.PortfolioBaseID
join @Decor decor on decor.APXLocaleID = p.LocaleID
join dbo.vAoPropertyLangPerLocale pl on
	pl.APXLocaleID = p.LocaleID and pl.PropertyID = @ClassificationID1
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID1 and l.PropertyLookupID = p1.ClassificationMemberID
left join dbo.AdvSecurityLang sec on
	sec.APXLocaleID = p.LocaleID and @ClassificationID1 = -8 and sec.SecurityID = p1.ClassificationMemberID
join APXUser.fPerformanceHistory(@Cumulative1) c1 on
	p1.PortfolioBaseID = c1.PortfolioBaseID and
	p1.ClassificationMemberCode = c1.ClassificationMemberCode and
	c1.PeriodThruDate = p1.ThruDate
where @ShowIndexes = 1 or p1.IsIndex = 0 and
	p1.PortfolioBaseID = @PortfolioBaseID and
	p1.PortfolioBaseIDOrder = @PortfolioBaseIDOrder and
	p1.ClassificationMemberCode = 'totport'
union
select 
  p.PrefixedPortfolioBaseCode,
  p1.PortfolioBaseID,
  p1.PortfolioBaseIDOrder,
  p.LegacyLocaleID,
  p.LocaleID,
  p.FormatReportingCurrency,

  p1.IsIndex,
  [IsTotal] = case when p1.ClassificationMemberCode = 'totport' then 1 else 0 end,

--	Hierarchy info
	h.*,
	
	[ShowClassification3] = ISNULL(fund.ClassificationMemberCode,'n'),

--	Header info
	DayToDateHeader = (case when @AnnualizeReturns = 'a' then @DTDAnn else @DTD end),
	MonthToDateHeader = (case	when @AnnualizeReturns = 'a' then @MTDAnn else @MTD end),
	QuarterToDateHeader = (case when @AnnualizeReturns = 'a' then @QTDAnn else @QTD end),
	InceptionToDateHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.InceptionToDatePeriodFromDate, p1.ThruDate)) then @ITDAnn
		else @ITD end),
	Latest1YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest1YearPeriodFromDate, p1.ThruDate)) then @L1YAnn
		else @L1Y end),
	Latest2YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest1YearPeriodFromDate, p1.ThruDate)) then @L2YAnn
		else @L2Y end),
	Latest3YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest3YearsPeriodFromDate, p1.ThruDate)) then @L3YAnn
		else @L3Y end),
	Latest4YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest4YearsPeriodFromDate, p1.ThruDate)) then @L4YAnn
		else @L4Y end),
	Latest5YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest5YearsPeriodFromDate, p1.ThruDate)) then @L5YAnn
		else @L5Y end),
	WeekToDateHeader = (case 	when @AnnualizeReturns = 'a' then @WTDAnn else @WTD end),
	YearToDateHeader = (case when @AnnualizeReturns = 'a' then @YTDAnn else @YTD end),
	CumulativeHeader = (case 	when @AnnualizeReturns = 'a' then @ITDAnn else @ITD end),

	[ActualAllocation] = coalesce(p3.EndingMarketValue, p2.EndingMarketValue, p1.EndingMarketValue) / @TotMV,
	[TotalMarketValue] = @TotMV,
	[EndingMarketValue1] = p1.EndingMarketValue,
	[EndingMarketValue2] = p2.EndingMarketValue,
	[EndingMarketValue3] = p3.EndingMarketValue,

--	Day to Date Returns
	[DayToDateEffectiveTWR1] = p1.DayToDateEffectiveTWR,
	[DayToDateEffectiveTWR2] = p2.DayToDateEffectiveTWR,
	[DayToDateEffectiveTWR3] = p3.DayToDateEffectiveTWR,
	[DayToDateShowPeriod] = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Week to Date Returns
	[WeekToDateEffectiveTWR1] = p1.WeekToDateEffectiveTWR,
	[WeekToDateEffectiveTWR2] = p2.WeekToDateEffectiveTWR,
	[WeekToDateEffectiveTWR3] = p3.WeekToDateEffectiveTWR,
	[WeekToDateShowPeriod] = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Month to Date Returns
	[MonthToDateEffectiveTWR1] = p1.MonthToDateEffectiveTWR,
	[MonthToDateEffectiveTWR2] = p2.MonthToDateEffectiveTWR,
	[MonthToDateEffectiveTWR3] = p3.MonthToDateEffectiveTWR,
	[MonthToDateShowPeriod] = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Quarter to Date Returns
	[QuarterToDateEffectiveTWR1] = p1.QuarterToDateEffectiveTWR,
	[QuarterToDateEffectiveTWR2] = p2.QuarterToDateEffectiveTWR,
	[QuarterToDateEffectiveTWR3] = p3.QuarterToDateEffectiveTWR,
	[QuarterToDateShowPeriod] = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Inception to Date Returns
	[InceptionToDateEffectiveTWR1] = p1.InceptionToDateEffectiveTWR,
	[InceptionToDateEffectiveTWR2] = p2.InceptionToDateEffectiveTWR,
	[InceptionToDateEffectiveTWR3] = p3.InceptionToDateEffectiveTWR,
	[InceptionToDateShowPeriod] = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Year to Date Returns
	[YearToDateEffectiveTWR1] = p1.YearToDateEffectiveTWR,
	[YearToDateEffectiveTWR2] = p2.YearToDateEffectiveTWR,
	[YearToDateEffectiveTWR3] = p3.YearToDateEffectiveTWR,
	[YearToDateShowPeriod] = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 1 Year Returns
	[Latest1YearEffectiveTWR1] = p1.Latest1YearEffectiveTWR,
	[Latest1YearEffectiveTWR2] = p2.Latest1YearEffectiveTWR,
	[Latest1YearEffectiveTWR3] = p3.Latest1YearEffectiveTWR,
	[Latest1YearShowPeriod] = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 2 Year Returns
	[Latest2YearsEffectiveTWR1] = p1.Latest2YearsEffectiveTWR,
	[Latest2YearsEffectiveTWR2] = p2.Latest2YearsEffectiveTWR,
	[Latest2YearsEffectiveTWR3] = p3.Latest2YearsEffectiveTWR,
	[Latest2YearsShowPeriod] = convert(bit, case when charindex( ',L2Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 3 Year Returns
	[Latest3YearsEffectiveTWR1] = p1.Latest3YearsEffectiveTWR,
	[Latest3YearsEffectiveTWR2] = p2.Latest3YearsEffectiveTWR,
	[Latest3YearsEffectiveTWR3] = p3.Latest3YearsEffectiveTWR,
	[Latest3YearsShowPeriod] = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 4 Year Returns
	[Latest4YearsEffectiveTWR1] = p1.Latest4YearsEffectiveTWR,
	[Latest4YearsEffectiveTWR2] = p2.Latest4YearsEffectiveTWR,
	[Latest4YearsEffectiveTWR3] = p3.Latest4YearsEffectiveTWR,
	[Latest4YearsShowPeriod] = convert(bit, case when charindex( ',L4Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 5 Year Returns
	[Latest5YearsEffectiveTWR1] = p1.Latest5YearsEffectiveTWR,
	[Latest5YearsEffectiveTWR2] = p2.Latest5YearsEffectiveTWR,
	[Latest5YearsEffectiveTWR3] = p3.Latest5YearsEffectiveTWR,
	[Latest5YearsShowPeriod] = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Cumulative
	CumulativeEffectiveTWR1 = c1.CumulativeTWRAnnualized,
	CumulativeEffectiveTWR2 = c2.CumulativeTWRAnnualized,
	CumulativeEffectiveTWR3 = c3.CumulativeTWRAnnualized,

	p1.InceptionToDatePeriodFromDate,
	
	date1.RowID,
	date2.RowID,
	date3.RowID,

	[FooterText] = @footerstring
from @PerformanceTable1 p1
left join @Hierarchy h on 
	h.Classification1ID = p1.ClassificationID and
	h.Classification1MemberID = p1.ClassificationMemberID
left join @PerformanceTable2 p2 on
	p2.ClassificationID = h.Classification2ID and
	p2.ClassificationMemberID = h.Classification2MemberID and
	p2.ThruDate = p1.ThruDate
join @PerformanceTable3 p3 on
	p3.ClassificationID = h.Classification3ID and
	p3.ClassificationMemberID = h.Classification3MemberID and
	p3.ThruDate = p1.ThruDate
left join @filter fund on
	fund.ClassificationID = h.Classification3ID and
	fund.ClassificationMemberID = h.Classification3MemberID
left join #InceptionDates_Sub date1 on
	date1.ClassificationID = h.Classification1ID and
	date1.ClassificationMemberID = h.Classification1MemberID
left join #InceptionDates_Sub date2 on
	date2.ClassificationID = h.Classification2ID and
	date2.ClassificationMemberID = h.Classification2MemberID
left join #InceptionDates_Sub date3 on
	date3.ClassificationID = h.Classification3ID and
	date3.ClassificationMemberID = h.Classification3MemberID
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  	p.PortfolioBaseID = p1.PortfolioBaseID
join @Decor decor on decor.APXLocaleID = p.LocaleID
join dbo.vAoPropertyLangPerLocale pl on
	pl.APXLocaleID = p.LocaleID and pl.PropertyID = @ClassificationID1
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID1 and l.PropertyLookupID = p1.ClassificationMemberID
left join dbo.AdvSecurityLang sec on
	sec.APXLocaleID = p.LocaleID and @ClassificationID1 = -8 and sec.SecurityID = p1.ClassificationMemberID
left join APXUser.fPerformanceHistory(@Cumulative1) c on
	p1.PortfolioBaseID = c.PortfolioBaseID and
	p1.ClassificationMemberCode = c.ClassificationMemberCode and
	c.PeriodThruDate = p1.ThruDate
left join APXUser.fPerformanceHistory(@Cumulative1) c1 on
	p1.PortfolioBaseID = c1.PortfolioBaseID and
	p1.ClassificationMemberCode = c1.ClassificationMemberCode and
	c1.PeriodThruDate = p1.ThruDate
left join APXUser.fPerformanceHistory(@Cumulative2) c2 on
	p2.PortfolioBaseID = c2.PortfolioBaseID and
	p2.ClassificationMemberCode = c2.ClassificationMemberCode and
	c2.PeriodThruDate = p2.ThruDate
left join APXUser.fPerformanceHistory(@Cumulative3) c3 on
	p3.PortfolioBaseID = c3.PortfolioBaseID and
	p3.ClassificationMemberCode = c3.ClassificationMemberCode and
	c3.PeriodThruDate = p3.ThruDate
where @ShowIndexes = 1 or p1.IsIndex = 0 and
	p1.PortfolioBaseID = @PortfolioBaseID and
	p1.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by h.Classification1DisplayOrder, h.Classification2DisplayOrder, h.Classification3DisplayOrder asc

drop table #InceptionDates_Sub
	
end
GO