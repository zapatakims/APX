USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pD876636SA_PerformanceTable]    Script Date: 01/05/2016 13:15:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pD876636SA_PerformanceTable]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pD876636SA_PerformanceTable]
GO

USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pD876636SA_PerformanceTable]    Script Date: 01/05/2016 13:15:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
EXEC [APXUserCustom].[pD876636SA_PerformanceTable]
	-- Required Parameters
	@SessionGuid = null,
	@PortfolioBaseID = 16207,
	@PortfolioBaseIDOrder = 1,
	@DataHandle = '4B43B15D-40B2-4C97-867C-6CA3CD8DEB4A',
	@ClassificationID1 = 261,
	-- Optional parameters for sqlrep procem
	@ClassificationID2 = 258,
	@ClassificationID3 = 257,
	@Periods = 'QTD,YTD,ITD',
	@ReportingCurrencyCode = 'ca',
	@AnnualizeReturns = 'n',
	@FeeMethod = 2
*/

CREATE procedure [APXUserCustom].[pD876636SA_PerformanceTable]
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
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AnnualizeReturns char(1) = 'o',
	@FeeMethod int = null
as
begin
--declare	@AnnualizeReturns char(1) = 'o',
declare @ShowIndexes bit = 0
declare @NetGross char

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @PerfHistory varbinary(max), @PerfSummary1 varbinary(max), @PerfSummary2 varbinary(max), @PerfSummary3 varbinary(max), @PerfSummary4 varbinary(max), @PerfSummary5 varbinary(max), @PerfSummary6 varbinary(max),
	@Cumulative1 varbinary(max), @Cumulative2 varbinary(max), @Cumulative3 varbinary(max), @Holdings varbinary(max),
	@Detail1 varbinary(max), @Detail2 varbinary(max), @Detail3 varbinary(max),
	@totport varbinary(max), @totport2 varbinary(max), @totport4 varbinary(max)

exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistory', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfHistory out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary3 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary4', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary4 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary5', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary5 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary6', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary6 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative3 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'totport', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @totport out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'totport2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @totport2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'totport4', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @totport4 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Detail1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Detail1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Detail2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Detail2 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Detail3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Detail3 out
	

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Holdings out

exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@FeeMethod = @FeeMethod out

set @NetGross = CASE 
					WHEN @FeeMethod = 1 THEN 'n' 
					ELSE 'g' 
				END

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
	Classification3DisplayOrder int, Classification3ID int, Classification3MemberID int, Classification3DisplayName nvarchar(max),
	AssetClass int)
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
		left(s3.Label,len(s3.Label) - patindex('%([0-9])%',s3.Label) + 1),
		AssetClass = CASE 
					WHEN s3.DisplayOrder IS NULL 
						AND s2.DisplayOrder IS NULL
						AND s1.DisplayOrder IS NOT NULL
					THEN 1
					WHEN s3.DisplayOrder IS NULL 
						AND s2.DisplayOrder IS NOT NULL
						AND s1.DisplayOrder IS NOT NULL
					THEN 2
					ELSE 3
				END
	from APXUserCustom.AssetClassHierarchy a
	left join APXUser.vSecClassMember s1 on 
		s1.ClassificationID = @ClassificationID1 and
		s1.Label = a.AssetClass1 and
		s1.Label <> ''
	left join APXUser.vSecClassMember s2 on 
		s2.ClassificationID = @ClassificationID2 and
		s2.Label = a.AssetClass2 and
		s2.Label <> ''
	left join APXUser.vSecClassMember s3 on 
		s3.ClassificationID = @ClassificationID3 and
		s3.Label = a.AssetClass3 and
		s3.Label <> ''
		
--SELECT * INTO ##hier FROM @Hierarchy

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

BEGIN --Calculate InceptionToDate TWR custom
	declare @FlyByTWR table (ClassLevel int, ClassificationMemberCode nvarchar(max), CumulativeTWR float)
	declare @InceptionDates table (row int identity, ClassLevel int, ClassificationMemberCode nvarchar(max), InceptionDate datetime)
	declare @localFromDate datetime, @localClassification int
	declare @ToDate datetime = (SELECT top 1 ThruDate FROM APXUser.fPerformanceHistoryPeriod(@PerfSummary5))
	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = (SELECT top 1 ThruDate FROM APXUser.fPerformanceHistoryPeriod(@PerfSummary3))
	END
	--SELECT * INTO ##perftemp FROM APXUser.fPerformanceHistoryPeriod(@PerfSummary5)
	--DROP TABLE ##perftemp
	--SELECT * FROM ##perftemp

	declare @ReportDataFlyByTWR varbinary(max), @count int = 1
	declare @ConsPortfolio nvarchar(max) = '+@' + (SELECT PortfolioBaseCode FROM APXUser.vPortfolioBase WHERE PortfolioBaseID = @PortfolioBaseID)
	Print @ConsPortfolio
	insert into @InceptionDates
	SELECT 2, ClassificationMemberCode, InceptionDate FROM APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail2)
	insert into @InceptionDates
	SELECT 3, ClassificationMemberCode, InceptionDate FROM APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail3)
	--select * from @InceptionDates

	while @count < (SELECT COUNT(ClassificationMemberCode) FROM @InceptionDates) + 1
	BEGIN
	set @localFromDate = (SELECT InceptionDate FROM @InceptionDates WHERE row = @count)
	set @localClassification = case when (SELECT ClassLevel FROM @InceptionDates WHERE row = @count) = 2
									then @ClassificationID2 else @ClassificationID3 end
	IF @ToDate IS NOT NULL
	BEGIN
	EXEC APXUser.pPerformanceHistoryPeriod
		@ReportData = @ReportDataFlyByTWR out,
		@Portfolios = @ConsPortfolio,
		@FromDate = @localFromDate,
		@ToDate = @ToDate,
		@ClassificationID = @localClassification,
		@ReportingCurrencyCode = @ReportingCurrencyCode
		
		INSERT INTO @FlyByTWR
		SELECT @localClassification, ClassificationMemberCode, SinceDateTWR FROM APXUser.fPerformanceHistoryPeriod(@ReportDataFlyByTWR)
		WHERE ClassificationMemberCode = (SELECT a.ClassificationMemberCode FROM @InceptionDates a WHERE row = @count)

	END
		set @count = @count + 1	

	END
END

--select * from @FlyByTWR

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
	  --InceptionToDateEffectiveTWR = APXUserCustom.fGetAnnualizedReturn((EXP(SUM(LOG( 1 + ph3.TWR /100))) -1) * 100, i1.InceptionDate, ph3.ThruDate),
	  --i1.InceptionDate,

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
	--TestCode
	LEFT JOIN APXUser.fPerformanceHistory(@PerfHistory) ph3
		ON ph.ClassificationMemberCode = ph3.ClassificationMemberCode
	LEFT JOIN APXUserCustom.fGetClassificationInceptionDates(@PerfHistory) i1
		ON ph3.ClassificationMemberID = i1.ClassificationMemberID
	--TestCode
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
	  --InceptionToDateEffectiveTWR = ph.InceptionToDateAnnualizedTWR,
	  InceptionToDateEffectiveTWR = (case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ISNULL(i1.InceptionDate, ph.InceptionToDatePeriodFromDate), ph.ThruDate)) 
			then APXUserCustom.fGetAnnualizedReturn(f.CumulativeTWR, ISNULL(i1.InceptionDate, ph.InceptionToDatePeriodFromDate), ph.ThruDate)
			else f.CumulativeTWR 
		end),
	  --ph.InceptionToDatePeriodFromDate,
	  i1.InceptionDate,

	  ph.IsIndex,

	  -- Latest 1 Year
	  Latest1YearEffectiveTWR = case when i1.InceptionDate > ph.Latest1YearPeriodFromDate then NULL else ph.Latest1YearAnnualizedTWR end,
	  ph.Latest1YearPeriodFromDate,

	  -- Latest 2 Years
	  Latest2YearsEffectiveTWR = case when i1.InceptionDate > ph.SinceDateTWRPeriodFromDate then NULL else ph.SinceDateAnnualizedTWR end,
	  Latest2YearsPeriodFromDate = ph.SinceDateTWRPeriodFromDate,
	  
	  -- Latest 3 Years
	  Latest3YearsEffectiveTWR = case when i1.InceptionDate > ph.Latest3YearsPeriodFromDate then NULL else ph.Latest3YearsAnnualizedTWR end,
	  ph.Latest3YearsPeriodFromDate,

	  -- Latest 4 Years
	  Latest4YearsEffectiveTWR = case when i1.InceptionDate > ph2.SinceDateTWRPeriodFromDate then NULL else ph2.SinceDateAnnualizedTWR end,
	  Latest4YearsPeriodFromDate = ph2.SinceDateTWRPeriodFromDate,

	  -- Latest 5 Years
	  Latest5YearsEffectiveTWR = case when i1.InceptionDate > ph.Latest5YearsPeriodFromDate then NULL else ph.Latest5YearsAnnualizedTWR end,
	  ph.Latest5YearsPeriodFromDate,
	  
	  -- Month to Date
	  MonthToDateEffectiveTWR = case when i1.InceptionDate > ph.MonthToDatePeriodFromDate then NULL else ph.MonthToDateAnnualizedTWR end,
	  ph.MonthToDatePeriodFromDate,

	  ph.PortfolioBaseID,
	  ph.PortfolioBaseIDOrder,
	  
	  -- Quarter to Date
	  QuarterToDateEffectiveTWR = case when i1.InceptionDate > ph.QuarterToDatePeriodFromDate then NULL else ph.QuarterToDateAnnualizedTWR end,
	  ph.QuarterToDatePeriodFromDate,

	  ph.ThruDate,
	  
	  -- Week To Date
	  WeekToDateEffectiveTWR = case when i1.InceptionDate > ph.WeekToDatePeriodFromDate then NULL else ph.WeekToDateAnnualizedTWR end,
	  ph.WeekToDatePeriodFromDate,

	  -- Year To Date        
	  YearToDateEffectiveTWR = case when i1.InceptionDate > ph.YearToDatePeriodFromDate then NULL else ph.YearToDateAnnualizedTWR end,
	  ph.YearToDatePeriodFromDate,

	  ph.IsShortPosition,
	  ph.BondDescription
	from APXUser.fPerformanceHistoryPeriod(@PerfSummary3) ph
	join APXUser.fPerformanceHistoryPeriod(@PerfSummary4) ph2 on
		ph2.PortfolioBaseID = ph.PortfolioBaseID and
		ph2.IsIndex = ph.IsIndex and
		ph2.ClassificationMemberID = ph.ClassificationMemberID
	LEFT JOIN @FlyByTWR f
		ON ph.ClassificationMemberCode = f.ClassificationMemberCode
			AND f.ClassLevel = @ClassificationID2
	--TestCode
	LEFT JOIN APXUser.fPerformanceHistory(@PerfHistory) ph3
		ON ph.ClassificationMemberCode = ph3.ClassificationMemberCode
	LEFT JOIN APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail2) i1
		ON ph.ClassificationMemberID = i1.ClassificationMemberID
	--TestCode
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
	  --InceptionToDateEffectiveTWR = ph.InceptionToDateTWR,
	  --ph.InceptionToDatePeriodFromDate,
	  InceptionToDateEffectiveTWR = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, ISNULL(i1.InceptionDate, ph.InceptionToDatePeriodFromDate), ph.ThruDate)) then 
		APXUserCustom.fGetAnnualizedReturn(f.CumulativeTWR, ISNULL(i1.InceptionDate, ph.InceptionToDatePeriodFromDate), ph.ThruDate)
		else f.CumulativeTWR end),
	  i1.InceptionDate,

	  ph.IsIndex,

	  -- Latest 1 Year
	  Latest1YearEffectiveTWR = case when i1.InceptionDate > ph.Latest1YearPeriodFromDate then NULL else ph.Latest1YearAnnualizedTWR end,
	  ph.Latest1YearPeriodFromDate,

	  -- Latest 2 Years
	  Latest2YearsEffectiveTWR = case when i1.InceptionDate > ph.SinceDateTWRPeriodFromDate then NULL else ph.SinceDateAnnualizedTWR end,
	  Latest2YearsPeriodFromDate = ph.SinceDateTWRPeriodFromDate,
	  
	  -- Latest 3 Years
	  Latest3YearsEffectiveTWR = case when i1.InceptionDate > ph.Latest3YearsPeriodFromDate then NULL else ph.Latest3YearsAnnualizedTWR end,
	  ph.Latest3YearsPeriodFromDate,

	  -- Latest 4 Years
	  Latest4YearsEffectiveTWR = case when i1.InceptionDate > ph2.SinceDateTWRPeriodFromDate then NULL else ph2.SinceDateAnnualizedTWR end,
	  Latest4YearsPeriodFromDate = ph2.SinceDateTWRPeriodFromDate,

	  -- Latest 5 Years
	  Latest5YearsEffectiveTWR = case when i1.InceptionDate > ph.Latest5YearsPeriodFromDate then NULL else ph.Latest5YearsAnnualizedTWR end,
	  ph.Latest5YearsPeriodFromDate,
	  
	  -- Month to Date
	  MonthToDateEffectiveTWR = case when i1.InceptionDate > ph.MonthToDatePeriodFromDate then NULL else ph.MonthToDateAnnualizedTWR end,
	  ph.MonthToDatePeriodFromDate,

	  ph.PortfolioBaseID,
	  ph.PortfolioBaseIDOrder,
	  
	  -- Quarter to Date
	  QuarterToDateEffectiveTWR = case when i1.InceptionDate > ph.QuarterToDatePeriodFromDate then NULL else ph.QuarterToDateAnnualizedTWR end,
	  ph.QuarterToDatePeriodFromDate,

	  ph.ThruDate,
	  
	  -- Week To Date
	  WeekToDateEffectiveTWR = case when i1.InceptionDate > ph.WeekToDatePeriodFromDate then NULL else ph.WeekToDateAnnualizedTWR end,
	  ph.WeekToDatePeriodFromDate,

	  -- Year To Date        
	  YearToDateEffectiveTWR = case when i1.InceptionDate > ph.YearToDatePeriodFromDate then NULL else ph.YearToDateAnnualizedTWR end,
	  ph.YearToDatePeriodFromDate,

	  ph.IsShortPosition,
	  ph.BondDescription
	from APXUser.fPerformanceHistoryPeriod(@PerfSummary5) ph
	join APXUser.fPerformanceHistoryPeriod(@PerfSummary6) ph2 on
		ph2.PortfolioBaseID = ph.PortfolioBaseID and
		ph2.IsIndex = ph.IsIndex and
		ph2.ClassificationMemberCode = ph.ClassificationMemberCode
	--TestCode
	LEFT JOIN APXUser.fPerformanceHistory(@PerfHistory) ph3
		ON ph.ClassificationMemberCode = ph3.ClassificationMemberCode
	LEFT JOIN APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail3) i1
		ON ph.ClassificationMemberID = i1.ClassificationMemberID
	LEFT JOIN @FlyByTWR f
		ON ph.ClassificationMemberCode = f.ClassificationMemberCode
			AND f.ClassLevel = @ClassificationID3
	--TestCode
	where @ShowIndexes = 1 or ph.IsIndex = 0 and
		ph.PortfolioBaseID = @PortfolioBaseID and
		ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
--select * from @PerformanceTable3 WHERE ClassificationMemberCode = 'FLSE'
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
set @PortfolioInceptionDate = (SELECT MIN(PerfDate) FROM AdvApp.vPerformance WHERE RowTypeCode='s' AND PortfolioBaseID = @PortfolioBaseID AND NetOrGrossCode = @NetGross and CurrencyCode = @ReportingCurrencyCode)

declare @CumulativeThruDate datetime
SET @CumulativeThruDate = (SELECT MAX(PeriodThruDate) FROM APXUser.fPerformanceHistory(@Cumulative2))

create table #InceptionDates_Sub (RowID int, ClassificationID int, ClassificationMemberID int, InceptionDate datetime)

declare @distinctnotes table (RowID int identity, InceptionDate datetime)
declare @temp table (OrderID int, ClassificationID int, ClassificationMemberID int, Classification1MemberOrder int, Classification2MemberOrder int, InceptionDate datetime)
--declare @temp3 table (OrderID int, ClassificationID int, ClassificationMemberID int, Classification1MemberOrder int, Classification2MemberOrder int, InceptionDate datetime)
declare @footerstring nvarchar(max)
--insert @temp
--select 1, @ClassificationID1, ph.ClassificationMemberID, ph.ClassificationMemberOrder, MIN(ph.PeriodFromDate)
--from APXUser.fPerformanceHistory(@Cumulative1) ph
--where ph.ClassificationMemberID is not null 
--	and ph.IsIndex = 0
--group by ph.ClassificationMemberID, ph.ClassificationMemberOrder
--order by ph.ClassificationMemberOrder

insert @temp
	select 2, @ClassificationID2, ph.ClassificationMemberID, ph.ClassificationMemberOrder, 0, c.InceptionDate --MIN(ph.PeriodFromDate)
	from APXUser.fPerformanceHistoryPeriod(@PerfSummary4) ph
	JOIN APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail2) c
	ON ph.ClassificationMemberID = c.ClassificationMemberID
	where ph.ClassificationMemberID is not null 
		and ph.IsIndex = 0
		and ph.InceptionToDateTWR IS NOT NULL
		and (ph.InceptionToDateEndingMarketValue IS NOT NULL
		--AND ph.InceptionToDateEndingMarketValue/@TotMV >= .001
		)
		AND Not(ph.ClassificationMemberName Like '%Cash%')
	group by ph.ClassificationMemberID, ph.ClassificationMemberOrder, c.InceptionDate
/*
SELECT ph.InceptionToDateEndingMarketValue, ph.InceptionToDateEndingMarketValue/@TotMV as alloc, ph.ClassificationMemberName 
INTO ##perf FROM 
	APXUser.fPerformanceHistoryPeriod(@PerfSummary4) ph
	JOIN APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail2) c
	ON ph.ClassificationMemberID = c.ClassificationMemberID
	where ph.ClassificationMemberID is not null 
		and ph.IsIndex = 0
		and ph.InceptionToDateTWR IS NOT NULL
		and (ph.InceptionToDateEndingMarketValue IS NOT NULL
		AND ph.InceptionToDateEndingMarketValue/@TotMV > .001)
		AND Not(ph.ClassificationMemberName Like '%Cash%')
	group by ph.ClassificationMemberID, ph.InceptionToDateEndingMarketValue, ph.ClassificationMemberName, ph.ClassificationMemberOrder, c.InceptionDate
*/
--SELECT * FROM ##perf

insert @temp
	select 3, @ClassificationID3, ph.ClassificationMemberID, h.Classification2DisplayOrder, ph.ClassificationMemberOrder, c.InceptionDate --MIN(ph.PeriodFromDate)
	from APXUser.fPerformanceHistoryPeriod(@PerfSummary6) ph
	JOIN APXUserCustom.fGetClassificationInceptionDatesDetail(@Detail3) c
	ON ph.ClassificationMemberID = c.ClassificationMemberID
	join @filter filter on
		filter.ClassificationMemberID = ph.ClassificationMemberID and
		filter.ClassificationID = @ClassificationID3
	join @Hierarchy h on 
		h.Classification3ID = @ClassificationID3 and
		h.Classification3MemberID = ph.ClassificationMemberID --and
		--'Fiera ' + h.Classification2DisplayName = h.Classification3DisplayName
	CROSS APPLY
		(
			SELECT MAX(ThruDate)[maxTDate] FROM APXUser.fPerformanceHistoryPeriod(@PerfSummary5) phm
			WHERE phm.ClassificationMemberID = ph.ClassificationMemberID 	
		) maxP
	where ph.ClassificationMemberID is not null 
		and ph.IsIndex = 0
		and filter.ClassificationMemberCode = 'y'
		and ph.InceptionToDateTWR IS NOT NULL
		AND ph.InceptionToDateEndingMarketValue IS NOT NULL
		AND ph.ThruDate = maxP.maxTDate
		AND ph.InceptionToDateEndingMarketValue/@TotMV >= 0.001
	group by ph.ClassificationMemberID, ph.ClassificationMemberOrder, h.Classification2DisplayOrder, c.InceptionDate

--SELECT * FROM @temp
--SELECT * FROM APXUser.fPerformanceHistory(@Cumulative3) ph
declare @tDistinctNotes table (id int IDENTITY, IndeptionDate datetime, Classification1MemberOrder int, Classification2MemberOrder int)
/*INSERT INTO @tDistinctNotes
	SELECT InceptionDate, Classification1MemberOrder, Classification2MemberOrder
			FROM @temp
		ORDER BY Classification1MemberOrder, Classification2MemberOrder ASC

--Select * from @tDistinctNotes t
INSERT INTO @distinctnotes
	select --ROW_NUMBER() OVER(order by Min(t.id)),
	 t.IndeptionDate from @tDistinctNotes t
	group by t.IndeptionDate
	order by MIN(t.id)

--insert @distinctnotes

--SELECT DISTINCT(InceptionDate)
--FROM (
--	SELECT InceptionDate, Classification1MemberOrder, Classification2MemberOrder
--		FROM @temp
--	ORDER BY Classification1MemberOrder, Classification2MemberOrder ASC
--	) A

--select * from @distinctnotes

--select * from @temp
--select * from @Hierarchy

--insert #InceptionDates_Sub
-- SELECT  t.OrderID, ClassificationID, ClassificationMemberID, InceptionDate from @temp t
--order by Classification1MemberOrder, Classification2MemberOrder asc


insert #InceptionDates_Sub
	SELECT [RowID], [ClassificationID], [ClassificationMemberID], [InceptionDate] 
	FROM(
		SELECT d.RowID, t.[ClassificationID], t.[ClassificationMemberID], t.[InceptionDate], t.[Classification1MemberOrder], t.[Classification2MemberOrder]
			FROM @temp t
		JOIN
			@distinctnotes d
			ON d.InceptionDate = t.InceptionDate
--where InceptionDate > @PortfolioInceptionDate
		) A
		ORDER BY A.Classification1MemberOrder, A.Classification2MemberOrder asc

--select * from @temp
--select * from #InceptionDates_Sub

select @footerstring = STUFF((
	select ', ' + convert(nvarchar(32),RowID) + ' - ' + 'since ' + (SELECT DATENAME(MONTH, InceptionDate) + RIGHT(convert(nvarchar(32),InceptionDate,107), 9) AS [Month, DD, YYYY])
	from @distinctnotes
	for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
--select * from #InceptionDates_Sub
*/

DECLARE @Output table (
	[PrefixedPortfolioBaseCode] [nvarchar](34) NOT NULL,
	[PortfolioBaseID] [int] NULL,
	[PortfolioBaseIDOrder] [int] NULL,
	[LegacyLocaleID] [int] NULL,
	[LocaleID] [dbo].[dtID] NULL,
	[FormatReportingCurrency] [varchar](8000) NULL,
	[IsIndex] [bit] NULL,
	[IsTotal] [int] NOT NULL,
	[Classification1DisplayOrder] [int] NULL,
	[Classification1ID] [int] NULL,
	[Classification1MemberID] [int] NULL,
	[Classification1DisplayName] [nvarchar](max) NULL,
	[Classification2DisplayOrder] [int] NULL,
	[Classification2ID] [int] NULL,
	[Classification2MemberID] [int] NULL,
	[Classification2DisplayName] [nvarchar](max) NULL,
	[Classification3DisplayOrder] [int] NULL,
	[Classification3ID] [int] NULL,
	[Classification3MemberID] [int] NULL,
	[Classification3DisplayName] [nvarchar](max) NULL,
	[AssetClass] [int] NULL,
	[ShowClassification3] [nvarchar](255) NOT NULL,
	[DayToDateHeader] [nvarchar](255) NULL,
	[MonthToDateHeader] [nvarchar](255) NULL,
	[QuarterToDateHeader] [nvarchar](255) NULL,
	[InceptionToDateHeader] [nvarchar](255) NULL,
	[Latest1YearHeader] [nvarchar](255) NULL,
	[Latest2YearHeader] [nvarchar](255) NULL,
	[Latest3YearsHeader] [nvarchar](255) NULL,
	[Latest4YearsHeader] [nvarchar](255) NULL,
	[Latest5YearsHeader] [nvarchar](255) NULL,
	[WeekToDateHeader] [nvarchar](255) NULL,
	[YearToDateHeader] [nvarchar](255) NULL,
	[CumulativeHeader] [nvarchar](255) NULL,
	[ActualAllocation] [float] NULL,
	[TotalMarketValue] [float] NULL,
	[EndingMarketValue1] [float] NULL,
	[EndingMarketValue2] [float] NULL,
	[EndingMarketValue3] [float] NULL,
	[DayToDateEffectiveTWR1] [float] NULL,
	[DayToDateEffectiveTWR2] [float] NULL,
	[DayToDateEffectiveTWR3] [float] NULL,
	[DayToDateShowPeriod] [bit] NULL,
	[WeekToDateEffectiveTWR1] [float] NULL,
	[WeekToDateEffectiveTWR2] [float] NULL,
	[WeekToDateEffectiveTWR3] [float] NULL,
	[WeekToDateShowPeriod] [bit] NULL,
	[MonthToDateEffectiveTWR1] [float] NULL,
	[MonthToDateEffectiveTWR2] [float] NULL,
	[MonthToDateEffectiveTWR3] [float] NULL,
	[MonthToDateShowPeriod] [bit] NULL,
	[QuarterToDateEffectiveTWR1] [float] NULL,
	[QuarterToDateEffectiveTWR2] [float] NULL,
	[QuarterToDateEffectiveTWR3] [float] NULL,
	[QuarterToDateShowPeriod] [bit] NULL,
	[InceptionToDateEffectiveTWR1] [float] NULL,
	[InceptionToDateEffectiveTWR2] [float] NULL,
	[InceptionToDateEffectiveTWR3] [float] NULL,
	[InceptionToDateShowPeriod] [bit] NULL,
	[YearToDateEffectiveTWR1] [float] NULL,
	[YearToDateEffectiveTWR2] [float] NULL,
	[YearToDateEffectiveTWR3] [float] NULL,
	[YearToDateShowPeriod] [bit] NULL,
	[Latest1YearEffectiveTWR1] [float] NULL,
	[Latest1YearEffectiveTWR2] [float] NULL,
	[Latest1YearEffectiveTWR3] [float] NULL,
	[Latest1YearShowPeriod] [bit] NULL,
	[Latest2YearsEffectiveTWR1] [float] NULL,
	[Latest2YearsEffectiveTWR2] [float] NULL,
	[Latest2YearsEffectiveTWR3] [float] NULL,
	[Latest2YearsShowPeriod] [bit] NULL,
	[Latest3YearsEffectiveTWR1] [float] NULL,
	[Latest3YearsEffectiveTWR2] [float] NULL,
	[Latest3YearsEffectiveTWR3] [float] NULL,
	[Latest3YearsShowPeriod] [bit] NULL,
	[Latest4YearsEffectiveTWR1] [float] NULL,
	[Latest4YearsEffectiveTWR2] [float] NULL,
	[Latest4YearsEffectiveTWR3] [float] NULL,
	[Latest4YearsShowPeriod] [bit] NULL,
	[Latest5YearsEffectiveTWR1] [float] NULL,
	[Latest5YearsEffectiveTWR2] [float] NULL,
	[Latest5YearsEffectiveTWR3] [float] NULL,
	[Latest5YearsShowPeriod] [bit] NULL,
	[CumulativeEffectiveTWR1] [float] NULL,
	[CumulativeEffectiveTWR2] [float] NULL,
	[CumulativeEffectiveTWR3] [float] NULL,
	[InceptionToDatePeriodFromDate] [datetime] NULL,
	[DateFooterID1] nvarchar(max) NULL,
	[DateFooterID2] nvarchar(max) NULL,
	[DateFooterID3] nvarchar(max) NULL,
	[FooterText] [nvarchar](max) NULL
)

INSERT INTO @Output
select
  p.PrefixedPortfolioBaseCode,
  t2.PortfolioBaseID,
  t2.PortfolioBaseIDOrder,
  p.LegacyLocaleID,
  p.LocaleID,
  p.FormatReportingCurrency,

  t2.IsIndex,
  [IsTotal] = case when t2.ClassificationMemberCode = 'totport' then 1 else 0 end,

--	Hierarchy info
	h.*,
	
	[ShowClassification3] = 'y',

--	Header info
	DayToDateHeader = (case when @AnnualizeReturns = 'a' then @DTDAnn else @DTD end),
	MonthToDateHeader = (case	when @AnnualizeReturns = 'a' then @MTDAnn else @MTD end),
	QuarterToDateHeader = (case when @AnnualizeReturns = 'a' then @QTDAnn else @QTD end),
	InceptionToDateHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t2.InceptionToDatePeriodFromDate, t2.ThruDate)) then @ITDAnn
		else @ITD end),
	Latest1YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t2.Latest1YearPeriodFromDate, t2.ThruDate)) then @L1YAnn
		else @L1Y end),
	Latest2YearHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t2.SinceDateTWRPeriodFromDate, t2.ThruDate)) then @L2YAnn
		else @L2Y end),
	Latest3YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t2.Latest3YearsPeriodFromDate, t2.ThruDate)) then @L3YAnn
		else @L3Y end),
	Latest4YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t4.SinceDateTWRPeriodFromDate, t2.ThruDate)) then @L4YAnn
		else @L4Y end),
	Latest5YearsHeader = (case
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, t2.Latest5YearsPeriodFromDate, t2.ThruDate)) then @L5YAnn
		else @L5Y end),
	WeekToDateHeader = (case 	when @AnnualizeReturns = 'a' then @WTDAnn else @WTD end),
	YearToDateHeader = (case when @AnnualizeReturns = 'a' then @YTDAnn else @YTD end),
	CumulativeHeader = (case 	when @AnnualizeReturns = 'a' then @ITDAnn else @ITD end),

	[ActualAllocation] = 1,
	[TotalMarketValue] = @TotMV,
	[EndingMarketValue1] = t2.InceptionToDateEndingMarketValue,
	[EndingMarketValue2] = null,
	[EndingMarketValue3] = null,

--	Day to Date Returns
	[DayToDateEffectiveTWR1] = t2.DayToDateAnnualizedTWR,
	[DayToDateEffectiveTWR2] = null,
	[DayToDateEffectiveTWR3] = null,
	[DayToDateShowPeriod] = convert(bit, case when charindex( ',DTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Week to Date Returns
	[WeekToDateEffectiveTWR1] = t2.WeekToDateAnnualizedTWR,
	[WeekToDateEffectiveTWR2] = null,
	[WeekToDateEffectiveTWR3] = null,
	[WeekToDateShowPeriod] = convert(bit, case when charindex( ',WTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Month to Date Returns
	[MonthToDateEffectiveTWR1] = t2.MonthToDateAnnualizedTWR,
	[MonthToDateEffectiveTWR2] = null,
	[MonthToDateEffectiveTWR3] = null,
	[MonthToDateShowPeriod] = convert(bit, case when charindex( ',MTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Quarter to Date Returns
	[QuarterToDateEffectiveTWR1] = t2.QuarterToDateAnnualizedTWR,
	[QuarterToDateEffectiveTWR2] = null,
	[QuarterToDateEffectiveTWR3] = null,
	[QuarterToDateShowPeriod] = convert(bit, case when charindex( ',QTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Inception to Date Returns
	[InceptionToDateEffectiveTWR1] = t2.InceptionToDateAnnualizedTWR,
	[InceptionToDateEffectiveTWR2] = null,
	[InceptionToDateEffectiveTWR3] = null,
	[InceptionToDateShowPeriod] = convert(bit, case when charindex( ',ITD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Year to Date Returns
	[YearToDateEffectiveTWR1] = t2.YearToDateAnnualizedTWR,
	[YearToDateEffectiveTWR2] = null,
	[YearToDateEffectiveTWR3] = null,
	[YearToDateShowPeriod] = convert(bit, case when charindex( ',YTD,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 1 Year Returns
	[Latest1YearEffectiveTWR1] = t2.Latest1YearAnnualizedTWR,
	[Latest1YearEffectiveTWR2] = null,
	[Latest1YearEffectiveTWR3] = null,
	[Latest1YearShowPeriod] = convert(bit, case when charindex( ',L1Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 2 Year Returns
	[Latest2YearsEffectiveTWR1] = t2.SinceDateAnnualizedTWR,
	[Latest2YearsEffectiveTWR2] = null,
	[Latest2YearsEffectiveTWR3] = null,
	[Latest2YearsShowPeriod] = convert(bit, case when charindex( ',L2Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 3 Year Returns
	[Latest3YearsEffectiveTWR1] = t2.Latest3YearsAnnualizedTWR,
	[Latest3YearsEffectiveTWR2] = null,
	[Latest3YearsEffectiveTWR3] = null,
	[Latest3YearsShowPeriod] = convert(bit, case when charindex( ',L3Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 4 Year Returns
	[Latest4YearsEffectiveTWR1] = t4.SinceDateAnnualizedTWR,
	[Latest4YearsEffectiveTWR2] = null,
	[Latest4YearsEffectiveTWR3] = null,
	[Latest4YearsShowPeriod] = convert(bit, case when charindex( ',L4Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Latest 5 Year Returns
	[Latest5YearsEffectiveTWR1] = t2.Latest5YearsAnnualizedTWR,
	[Latest5YearsEffectiveTWR2] = null,
	[Latest5YearsEffectiveTWR3] = null,
	[Latest5YearsShowPeriod] = convert(bit, case when charindex( ',L5Y,', @delimitedPeriods ) > 0 then 1 else 0 end),

--	Cumulative
	CumulativeEffectiveTWR1 = t.CumulativeTWRAnnualized,
	CumulativeEffectiveTWR2 = null,
	CumulativeEffectiveTWR3 = null,
	@PortfolioInceptionDate, --p1.InceptionToDatePeriodFromDate,

	[DateFooterID1] = null,
	[DateFooterID2] = null,
	[DateFooterID3] = null,
	[FooterText] = @footerstring
	
from APXUser.fPerformanceHistoryPeriod(@totport2) t2
left join @Hierarchy h on -1 = 1
--	h.Classification1ID = p1.ClassificationID and
--	h.Classification1MemberID = p1.ClassificationMemberID
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  	p.PortfolioBaseID = t2.PortfolioBaseID
join @Decor decor on decor.APXLocaleID = p.LocaleID
join dbo.vAoPropertyLangPerLocale pl on
	pl.APXLocaleID = p.LocaleID and pl.PropertyID = @ClassificationID1
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID1 
	and l.PropertyLookupID = t2.ClassificationMemberID
--left join dbo.AdvSecurityLang sec on
--	sec.APXLocaleID = p.LocaleID and @ClassificationID1 = -8 and sec.SecurityID = p1.ClassificationMemberID
left join APXUser.fPerformanceHistory(@totport) t on
	t2.PortfolioBaseID = t.PortfolioBaseID and
	t2.ClassificationMemberCode = t.ClassificationMemberCode and
	t.PeriodThruDate = t2.ThruDate
left join APXUser.fPerformanceHistoryPeriod(@totport4) t4 on
	t2.PortfolioBaseID = t4.PortfolioBaseID and
	t2.ClassificationMemberCode = t4.ClassificationMemberCode 

where @ShowIndexes = 1 or t2.IsIndex = 0 and
	t2.PortfolioBaseID = @PortfolioBaseID and
	t2.PortfolioBaseIDOrder = @PortfolioBaseIDOrder and
	t2.ClassificationMemberCode = 'totport'
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
	
	[ShowClassification3] = CASE --Show class 3 if an ips entry exists
			WHEN ips3.Id IS NOT NULL 
				THEN 'y'
			ELSE 'n'
		END,

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
		when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, p1.Latest2YearsPeriodFromDate, p1.ThruDate)) then @L2YAnn
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
	CumulativeEffectiveTWR2 = f2.CumulativeTWR,
	CumulativeEffectiveTWR3 = f3.CumulativeTWR,

	@PortfolioInceptionDate, 
	
	null, 
	null, 
	null, 

	[FooterText] = @footerstring
from @PerformanceTable1 p1
join @Hierarchy h on 
	h.Classification1ID = p1.ClassificationID and
	h.Classification1MemberID = p1.ClassificationMemberID
left join @PerformanceTable2 p2 on
	p2.ClassificationID = h.Classification2ID and
	p2.ClassificationMemberID = h.Classification2MemberID and
	p2.ThruDate = p1.ThruDate
left join @PerformanceTable3 p3 on
	p3.ClassificationID = h.Classification3ID and
	p3.ClassificationMemberID = h.Classification3MemberID and
	p3.ThruDate = p1.ThruDate
left join @FlyByTWR f2 on
	f2.ClassLevel = @ClassificationID2 AND
	p2.ClassificationMemberCode = f2.ClassificationMemberCode
left join @FlyByTWR f3 on
	f3.ClassLevel = @ClassificationID3 AND
	p3.ClassificationMemberCode = f3.ClassificationMemberCode
left join @filter fund on
	fund.ClassificationID = h.Classification3ID and
	fund.ClassificationMemberID = h.Classification3MemberID
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
  	p.PortfolioBaseID = p1.PortfolioBaseID
join @Decor decor on decor.APXLocaleID = p.LocaleID
join dbo.vAoPropertyLangPerLocale pl on
	pl.APXLocaleID = p.LocaleID and pl.PropertyID = @ClassificationID1
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID1 and l.PropertyLookupID = p1.ClassificationMemberID
--left join dbo.AdvSecurityLang sec on
--	sec.APXLocaleID = p.LocaleID and @ClassificationID1 = -8 and sec.SecurityID = p1.ClassificationMemberID
left join APXUser.fPerformanceHistory(@Cumulative1) c1 on
	p1.PortfolioBaseID = c1.PortfolioBaseID and
	p1.ClassificationMemberID = c1.ClassificationMemberID and
	c1.PeriodThruDate = @CumulativeThruDate
left join APXUser.fPerformanceHistory(@Cumulative2) c2 on
	p2.PortfolioBaseID = c2.PortfolioBaseID and
	p2.ClassificationMemberID = c2.ClassificationMemberID and
	c2.PeriodThruDate = @CumulativeThruDate
left join APXUser.fPerformanceHistory(@Cumulative3) c3 on
	p3.PortfolioBaseID = c3.PortfolioBaseID and
	p3.ClassificationMemberID = c3.ClassificationMemberID and
	c3.PeriodThruDate = @CumulativeThruDate
left join APXUserCustom.InvestmentGuidelines ips3 on
	ips3.AccountCode = p.PortfolioBaseCode and	
	ips3.AssetClass = h.Classification3DisplayName
where (@ShowIndexes = 1 or p1.IsIndex = 0) and
	p1.PortfolioBaseID = @PortfolioBaseID and
	p1.PortfolioBaseIDOrder = @PortfolioBaseIDOrder and
	((p2.EndingMarketValue IS NOT NULL AND h.Classification2DisplayName IS NOT NULL) 
		OR (p2.EndingMarketValue IS NULL and h.AssetClass <> 2)) and
	((p3.EndingMarketValue IS NOT NULL AND h.Classification3DisplayName IS NOT NULL) 
		OR (p3.EndingMarketValue IS NULL AND h.AssetClass <> 3))
	
order by h.Classification1DisplayOrder, h.Classification2DisplayOrder, h.Classification3DisplayOrder asc

DELETE r
FROM @Output r
WHERE r.ActualAllocation < 0.001 
	AND NOT EXISTS(SELECT * FROM @Output o 
					WHERE o.Classification1ID = r.Classification1ID  
						AND o.Classification2ID = r.Classification2ID
						AND o.AssetClass <> r.AssetClass
						AND o.ActualAllocation >= 0.001
				  )

DELETE r 
FROM @Output r 
INNER JOIN @Output o 
	ON r.ActualAllocation - o.ActualAllocation < .001
		AND o.AssetClass = 3
		AND r.AssetClass = 2 
		AND o.Classification2MemberID = r.Classification2MemberID
		
INSERT INTO @tDistinctNotes
	SELECT InceptionDate, Classification1MemberOrder, Classification2MemberOrder
			FROM @temp 
				INNER JOIN @Output o
					ON o.Classification2DisplayOrder = Classification1MemberOrder
					AND ((o.Classification3DisplayOrder = Classification2MemberOrder 
							AND o.ShowClassification3 = 'y')
						  OR ((o.Classification3DisplayOrder IS NULL OR o.ShowClassification3 = 'n') 
							AND Classification2MemberOrder = 0))
		ORDER BY Classification1MemberOrder, Classification2MemberOrder ASC
--SELECT * FROM @temp
--Select * from @tDistinctNotes t
INSERT INTO @distinctnotes
	select --ROW_NUMBER() OVER(order by Min(t.id)),
	 t.IndeptionDate from @tDistinctNotes t
	group by t.IndeptionDate
	order by MIN(t.id)

insert #InceptionDates_Sub
	SELECT [RowID], [ClassificationID], [ClassificationMemberID], [InceptionDate] 
	FROM(
		SELECT d.RowID, t.[ClassificationID], t.[ClassificationMemberID], t.[InceptionDate], t.[Classification1MemberOrder], t.[Classification2MemberOrder]
			FROM @temp t
		JOIN
			@distinctnotes d
			ON d.InceptionDate = t.InceptionDate
--where InceptionDate > @PortfolioInceptionDate
		) A
		ORDER BY A.Classification1MemberOrder, A.Classification2MemberOrder asc


DECLARE @Since varchar(max) = (SELECT LOWER(APXSSRS.fReportTranslation(@LocaleID,'Header','Since')))
IF @LocaleID IN (2060, 3084, 1036, 5132, 6156, 4108) -- French
BEGIN
SET LANGUAGE French --To get correct date names
END

select @footerstring = STUFF((
	select ', ' 
		+ convert(nvarchar(32),RowID) 
		+ ' - ' 
		+ @Since 
		+ ' ' 
		+ CASE WHEN @LocaleID IN (2060, 3084, 1036, 5132, 6156, 4108) -- French
			THEN RIGHT('0' + DATENAME(DAY, InceptionDate), 2)  
				+ ' ' 
				+ DATENAME(MONTH, InceptionDate) 
				+ ' ' 
				+ DATENAME(YEAR, InceptionDate)
			ELSE
		  DATENAME(MONTH, InceptionDate)
			+ ' ' 
			+ RIGHT('0' + DATENAME(DAY, InceptionDate), 2) 
			+ ', ' 
			+ DATENAME(YEAR, InceptionDate) 
		  END
	from @distinctnotes
	for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
	
IF @LocaleID IN (2060, 3084, 1036, 5132, 6156, 4108) -- French
BEGIN
SET LANGUAGE English --Revert back
END

UPDATE @Output
SET DateFooterID1 = CAST((SELECT ROWID FROM #InceptionDates_Sub s WHERE s.ClassificationMemberID = Classification1MemberID) AS nvarchar(max))
	, DateFooterID2 = CAST((SELECT ROWID FROM #InceptionDates_Sub s WHERE s.ClassificationMemberID = Classification2MemberID) AS nvarchar(max))
	, DateFooterID3 = CAST((SELECT ROWID FROM #InceptionDates_Sub s WHERE s.ClassificationMemberID = Classification3MemberID) AS nvarchar(max))
	, FooterText = @footerstring


--SELECT * FROM @Hierarchy
--SELECT * FROM @PerformanceTable2
--SELECT * from APXUser.fPerformanceHistoryPeriod(@PerfSummary3)
--SELECT * from APXUser.fPerformanceHistoryPeriod(@PerfSummary4)

SELECT * FROM @Output

drop table #InceptionDates_Sub
	
end





GO


