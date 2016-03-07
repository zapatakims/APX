USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pA4376PerfTableWithIndexes]    Script Date: 2/24/2015 9:04:40 AM ******/
DROP PROCEDURE [APXUserCustom].[pA4376PerfTableWithIndexes]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pA4376PerfTableWithIndexes]    Script Date: 2/24/2015 9:04:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create procedure [APXUserCustom].[pA4376PerfTableWithIndexes]
-- Required Parameters
@SessionGuid nvarchar(48),
@PortfolioBaseID int,
@PortfolioBaseIDOrder int,
@DataHandle nvarchar(48),
@Periods nvarchar(max),
@ClassificationID int,
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
-- Set the Session Guid and Data Handle
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @resultset table(
ClassificationMemberCode [nvarchar](max) null,
ClassificationMemberName [nvarchar](max) null,
ClassificationMemberOrder [int] null,
ClassificationName	[nvarchar](max) null,
DayToDateEffectiveTWR	[float]  null,
DayToDateHeader	[nvarchar](255) null,
DayToDatePeriodFromDate	[datetime] null,
DayToDateShowPeriod	[bit] null,
FormatReportingCurrency	nvarchar(5) null,
InceptionToDateEffectiveTWR	[float] null,
InceptionToDateHeader	[nvarchar](255) null,
InceptionToDatePeriodFromDate	[datetime] null,
InceptionToDateShowPeriod	[bit] null,
IsIndex	[int] null,
Latest1YearEffectiveTWR	[float] null,
Latest1YearHeader	[nvarchar](255) null,
Latest1YearPeriodFromDate	[datetime] null,
Latest1YearShowPeriod	[bit] null,
Latest3YearsEffectiveTWR	[float] null,
Latest3YearsHeader	[nvarchar](255) null,
Latest3YearsPeriodFromDate	[datetime] null,
Latest3YearsShowPeriod	[bit] null,
Latest5YearsEffectiveTWR	[float] null,
Latest5YearsHeader	[nvarchar](255) null,
Latest5YearsPeriodFromDate	[datetime] null,
Latest5YearsShowPeriod	[bit] null,
LegacyLocaleID	[int] null,
LocaleID	[int] null,
MonthToDateEffectiveTWR	[float] null,
MonthToDateHeader	[nvarchar](255) null,
MonthToDatePeriodFromDate	[datetime] null,
MonthToDatesShowPeriod	[bit] null,
PrefixedPortfolioBaseCode	[nvarchar](max) null,
PortfolioBaseID	[int] null,
PortfolioBaseIDOrder	[int] null,
QuarterToDateEffectiveTWR	[float] null,
QuarterToDateHeader	[nvarchar](255),
QuarterToDatePeriodFromDate	[datetime] null,
QuarterToDateShowPeriod	[bit] null,
SinceDateIRREffectiveTWR	[float] null,
SinceDateIRRHeader	[nvarchar](255),
SinceDateIRRPeriodFromDate	[datetime] null,
SinceDateIRRShowPeriod	[bit] null,
SinceDateTWREffectiveTWR	[float] null,
SinceDateTWRHeader	[nvarchar](255),
SinceDateTWRPeriodFromDate	[datetime] null,
SinceDateTWRShowPeriod	[bit] null,
ThruDate	[datetime] null,
WeekToDateEffectiveTWR	[float] null,
WeekToDateHeader	[nvarchar](255),
WeekToDatePeriodFromDate	[datetime] null,
WeekToDateShowPeriod	[bit] null,
YearToDateEffectiveTWR	[float] null,
YearToDateHeader	[nvarchar](255),
YearToDatePeriodFromDate	[datetime] null,
YearToDateShowPeriod [bit] null
);
declare @customIndexes table(
id int identity
,tag nvarchar(10)
,indexName nvarchar(max)
,indexCode int	--id number of index
);
declare @i int = 1

--first, execute the underlying procedure into the result set.
insert into @resultset
exec APXSSRS.pReportPerformanceHistoryPeriodDataHandle
@SessionGuid = @SessionGuid,
@PortfolioBaseID = @PortfolioBaseID,
@PortfolioBaseIDOrder = @PortfolioBaseIDOrder,
@DataHandle = @DataHandle,
@Periods = @Periods,
@ReportingCurrencyCode = @ReportingCurrencyCode,
@ClassificationID = @ClassificationID,
@AnnualizeReturns = @AnnualizeReturns,
@LocaleID = @LocaleID,
@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision,
@ShowIndexes = @ShowIndexes


--Update the SinceDate values if needed for the portfolio, setting to NULL if InceptionDate > 10 Year Date
--MWB 01212015
declare @PerfHistPeriodFromDate10Year datetime
declare @ToDate datetime
declare @InceptionDate datetime
set @ToDate = (select top 1 rd.ThruDate from @resultset rd where IsIndex = 0)
set @InceptionDate = (select top 1 rd.InceptionToDatePeriodFromDate from @resultset rd where IsIndex = 0)
set @PerfHistPeriodFromDate10Year =(select top 1 SinceDateIRRPeriodFromDate from @resultset
where IsIndex = 0)
-- CASE WHEN MONTH(@ToDate) = 2 AND Day(@ToDate) = 29 THEN ApxUser.fGetGenericDate('{edtm}', DATEADD(year, -10, @ToDate)) ELSE DATEADD(year, -10, @ToDate) END
declare @SetToNull int = 0
SELECT  @SetToNull = CASE WHEN @InceptionDate > @PerfHistPeriodFromDate10Year THEN 1 ELSE 0 END
IF @SetToNull = 1
BEGIN
UPDATE @resultset
SET SinceDateTWREffectiveTWR = NULL,
SinceDateTWRPeriodFromDate = @PerfHistPeriodFromDate10Year
WHERE IsIndex = 0
END

--find indexes to add
insert into @customIndexes
select t.Label, b.IndexDesc,b.IndexID from APXUser.vPortfolioBaseCustomLabels t
inner join APXUser.vMarketIndex b on b.IndexName = t.Value
where t.PortfolioBaseID = @PortfolioBaseID
and t.Label like '$[ef]idx%' order by t.Label --equity fixed incomes only

--populate result set with indexes.
--note that this result set the labels are set as Index MemberCode, but isIndex is 0
while (@i <= (select COUNT(*) from @customIndexes))
begin
insert into @resultset values (
(select substring(tag,2,1) from @customIndexes where id = @i),
(select indexName from @customIndexes where id = @i),
(select indexCode from @customIndexes where id = @i),
'Index',

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --DayToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 DayToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 DayToDateHeader	from @resultset),
(select top 1 DayToDatePeriodFromDate	from @resultset),
(select top 1 DayToDateShowPeriod	from @resultset),
(select top 1 FormatReportingCurrency	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --InceptionToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 InceptionToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 InceptionToDateHeader	from @resultset),
(select top 1 InceptionToDatePeriodFromDate	from @resultset),
(select top 1 InceptionToDateShowPeriod	from @resultset),

0, --This is not a portfolio index, it will be considered an asset class

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --Latest1YearEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 Latest1YearPeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 Latest1YearHeader	from @resultset),
(select top 1 Latest1YearPeriodFromDate	from @resultset),
(select top 1 Latest1YearShowPeriod	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --Latest3Years
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 Latest3YearsPeriodFromDate from @resultset),	--	2015-04-22 AZK this was incorrectly set to Latest3YearsEffectiveTWR, and unable to compute.
(select top 1 ThruDate from @resultset))),
(select top 1 Latest3YearsHeader	from @resultset),
(select top 1 Latest3YearsPeriodFromDate	from @resultset),
(select top 1 Latest3YearsShowPeriod	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --Latest5YearsEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 Latest5YearsPeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 Latest5YearsHeader	from @resultset),
(select top 1 Latest5YearsPeriodFromDate	from @resultset),
(select top 1 Latest5YearsShowPeriod	from @resultset),
(select top 1 LegacyLocaleID	from @resultset),
(select top 1 LocaleID	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --MonthToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 MonthToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 MonthToDateHeader	from @resultset),
(select top 1 MonthToDatePeriodFromDate	from @resultset),
(select top 1 MonthToDatesShowPeriod	from @resultset),
(select top 1 PrefixedPortfolioBaseCode	from @resultset),
(select top 1 PortfolioBaseID	from @resultset),
(select top 1 PortfolioBaseIDOrder	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --QuarterToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 QuarterToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 QuarterToDateHeader	from @resultset),
(select top 1 QuarterToDatePeriodFromDate	from @resultset),
(select top 1 QuarterToDateShowPeriod	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --SinceDateIRREffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 SinceDateIRRPeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 SinceDateIRRHeader	from @resultset),
(select top 1 SinceDateIRRPeriodFromDate	from @resultset),
(select top 1 SinceDateIRRShowPeriod	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --SinceDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 SinceDateTWRPeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 SinceDateTWRHeader	from @resultset),
(select top 1 SinceDateTWRPeriodFromDate	from @resultset),
(select top 1 SinceDateTWRShowPeriod	from @resultset),
(select top 1 ThruDate	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --WeekToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 WeekToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 WeekToDateHeader	from @resultset),
(select top 1 WeekToDatePeriodFromDate	from @resultset),
(select top 1 WeekToDateShowPeriod	from @resultset),

(select APXUserCustom.fGetIndexReturn(
@PortfolioBaseID, --YearToDateEffectiveTWR
(select indexCode from @customIndexes where id = @i),
@ReportingCurrencyCode,
(select top 1 YearToDatePeriodFromDate from @resultset),
(select top 1 ThruDate from @resultset))),
(select top 1 YearToDateHeader	from @resultset),
(select top 1 YearToDatePeriodFromDate	from @resultset),
(select top 1 YearToDateShowPeriod from @resultset)
)
set @i = @i + 1
end

--return results
select
	ClassificationMemberCode,
	ClassificationMemberName,
	ClassificationMemberOrder,
	ClassificationName,
	DayToDateEffectiveTWR = case ClassificationName when 'Index' then case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, DayToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(DayToDateEffectiveTWR,DayToDatePeriodFromDate,ThruDate)
			else DayToDateEffectiveTWR end else DayToDateEffectiveTWR end,
	DayToDateHeader,
	DayToDatePeriodFromDate,
	DayToDateShowPeriod,
	FormatReportingCurrency,
	[InceptionToDateEffectiveTWR] = case ClassificationName when 'Index' then case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, InceptionToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(InceptionToDateEffectiveTWR,InceptionToDatePeriodFromDate,ThruDate)
			else InceptionToDateEffectiveTWR end else InceptionToDateEffectiveTWR end,
	InceptionToDateHeader,
	InceptionToDatePeriodFromDate,
	InceptionToDateShowPeriod,
	IsIndex,
	Latest1YearEffectiveTWR = case ClassificationName when 'Index' then case 
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, Latest1YearPeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(Latest1YearEffectiveTWR,Latest1YearPeriodFromDate,ThruDate)
			else Latest1YearEffectiveTWR end else Latest1YearEffectiveTWR end,
	Latest1YearHeader,
	Latest1YearPeriodFromDate,
	Latest1YearShowPeriod,
	Latest3YearsEffectiveTWR = case ClassificationName when 'Index' then case 
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, Latest3YearsPeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(Latest3YearsEffectiveTWR,Latest3YearsPeriodFromDate,ThruDate)
			else Latest3YearsEffectiveTWR end else Latest3YearsEffectiveTWR end,
	Latest3YearsHeader,
	Latest3YearsPeriodFromDate,
	Latest3YearsShowPeriod,
	Latest5YearsEffectiveTWR = case ClassificationName when 'Index' then case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, Latest5YearsPeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(Latest5YearsEffectiveTWR,Latest5YearsPeriodFromDate,ThruDate)
			else Latest5YearsEffectiveTWR end else Latest5YearsEffectiveTWR end,
	Latest5YearsHeader,
	Latest5YearsPeriodFromDate,
	Latest5YearsShowPeriod,
	LegacyLocaleID,
	LocaleID,
	MonthToDateEffectiveTWR = case ClassificationName when 'Index' then case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, MonthToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(MonthToDateEffectiveTWR,MonthToDatePeriodFromDate,ThruDate)
			else MonthToDateEffectiveTWR end else MonthToDateEffectiveTWR end,
	MonthToDateHeader,
	MonthToDatePeriodFromDate,
	MonthToDatesShowPeriod,
	PrefixedPortfolioBaseCode,
	PortfolioBaseID,
	PortfolioBaseIDOrder,
	QuarterToDateEffectiveTWR = case ClassificationName when 'Index' then case 
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, QuarterToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(QuarterToDateEffectiveTWR,QuarterToDatePeriodFromDate,ThruDate)
			else QuarterToDateEffectiveTWR end else QuarterToDateEffectiveTWR end,
	QuarterToDateHeader,
	QuarterToDatePeriodFromDate,
	QuarterToDateShowPeriod,
	SinceDateIRREffectiveTWR,
	SinceDateIRRHeader,
	SinceDateIRRPeriodFromDate,
	SinceDateIRRShowPeriod,
	SinceDateTWREffectiveTWR = case ClassificationName when 'Index' then case 
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, SinceDateTWRPeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(SinceDateTWREffectiveTWR,SinceDateTWRPeriodFromDate,ThruDate)
			else SinceDateTWREffectiveTWR end else SinceDateTWREffectiveTWR end,
	SinceDateTWRHeader,
	SinceDateTWRPeriodFromDate,
	SinceDateTWRShowPeriod,
	ThruDate,
	WeekToDateEffectiveTWR = case ClassificationName when 'Index' then case 
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, WeekToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(WeekToDateEffectiveTWR,WeekToDatePeriodFromDate,ThruDate)
			else WeekToDateEffectiveTWR end else WeekToDateEffectiveTWR end,
	WeekToDateHeader,
	WeekToDatePeriodFromDate,
	WeekToDateShowPeriod,
	YearToDateEffectiveTWR = case ClassificationName when 'Index' then case
			when @AnnualizeReturns = 'a' or (@AnnualizeReturns = 'o' and 366 <= datediff(day, YearToDatePeriodFromDate, ThruDate)) then APXUserCustom.fGetAnnualizedReturn(YearToDateEffectiveTWR,YearToDatePeriodFromDate,ThruDate)
			else YearToDateEffectiveTWR end else YearToDateEffectiveTWR end,
	YearToDateHeader,
	YearToDatePeriodFromDate,
	YearToDateShowPeriod 
from @resultset
where ClassificationMemberCode not in ('c','o')	--	2015-04-22 AZK Change request to suppress cash and other asset classes.
end

GO

