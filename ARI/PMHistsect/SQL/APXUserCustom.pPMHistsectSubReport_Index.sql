if object_id('[APXUserCustom].[pPMHistsectSubReport_Index]') is not null
	drop procedure [APXUserCustom].[pPMHistsectSubReport_Index]
go
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = 'ari'
	,@ToDate datetime = '12/31/12'
	,@FeeMethod int
	,@PortfolioBaseID int = 1009
	,@PortfolioBaseIDOrder int = 1
	,@DataHandle nvarchar(48) = '2D7A619B-FA0F-4BEC-A39D-9D11DC71A349'
	,@Interval char(3) = 'ytd'
	,@IndexArray nvarchar(max) = '283,261'
	,@ReportingCurrencyCode char(2) = 'us'
	,@LocaleID int = null

--exec APXUserCustom.pPMHistsect @SessionGuid = @SessionGuid, @Portfolios = @Portfolios, @ToDate = @ToDate, @FeeMethod = @FeeMethod, @ReportingCurrencyCode = @ReportingCurrencyCode
exec APXUserCustom.pPMHistsectSubReport_Index @SessionGuid, @PortfolioBaseID, @PortfolioBaseIDOrder, @DataHandle, @Interval, @IndexArray, @FeeMethod, @ReportingCurrencyCode, @LocaleID
exec APXUserCustom.pReportPerformanceHistoryPeriodDataHandle @SessionGuid,@PortfolioBaseID,@PortfolioBaseIDOrder,@DataHandle,@IndexArray,@Periods, @ReportingCurrencyCode,@AnnualizeReturns,@LocaleID, @ShowCurrencyFullPrecision, @ShowIndexes, @DataHandleName nvarchar(max) = 'PerformanceHistorySummary'
*/
create procedure [APXUserCustom].[pPMHistsectSubReport_Index]
	@SessionGuid nvarchar(max)
	,@PortfolioBaseID int
	,@PortfolioBaseIDOrder int
	,@DataHandle nvarchar(48)
	,@Interval char(3)
	,@IndexArray nvarchar(max) = null
	,@FeeMethod int = null
	,@ReportingCurrencyCode char(2) = null
	,@LocaleID int = null
as begin

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @maxCount int
select @maxCount = COUNT(name) from APXUserCustom.CSVToTable(@IndexArray)

declare @PH varbinary(max)
	,@PHCumulative varbinary(max)
	,@InceptDate datetime
	,@AnnualFromDate datetime
	,@ThruDate datetime

exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistory', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PHCumulative out

declare @temp table ([ID] int Identity, IndexID int, IndexName nvarchar(max), PortfolioBaseID int, IndexDesc nvarchar(72), PeriodFromDate datetime, PeriodThruDate datetime, EffectiveRate float, [TWR] float)

DECLARE @intFlag INT
SET @intFlag = 1
WHILE (@intFlag <= @maxCount)
BEGIN
	insert into @temp
	select r.IndexID,
		i.IndexName,
		ph.PortfolioBaseID,
		i.IndexDesc,
		ph.PeriodFromDate,
		ph.PeriodThruDate,
		r.Rate * APXUserCustom.fGetFXRate(i.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=ph.PortfolioBaseid) ELSE @ReportingCurrencyCode END, ph.PeriodThruDate) [EffectiveRate],
		APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, r.IndexID, @ReportingCurrencyCode, ph.PeriodFromDate, ph.PeriodThruDate) [TWR]
	from APXUser.fPerformanceHistory (@PHCumulative) ph
	left join APXUser.vMarketIndexRate r on ph.PeriodThruDate = r.AsOfDate
	join APXUser.vMarketIndex i on i.IndexID = r.IndexID
	join APXUserCustom.CSVToTable(@IndexArray) a on a.ID = @intFlag and
		a.name = r.IndexID
	where ph.IsIndex = 0
	SET @intFlag = @intFlag + 1
END

declare @output table (IndexDisplayOrder int, IndexID int, IndexName nvarchar(max), PortfolioBaseID int, IndexDesc nvarchar(72), PeriodFromDate datetime, PeriodThruDate datetime, EffectiveRate float, [TWR] float, CumulativeTWR float)

SET @intFlag = 1
WHILE (@intFlag <= @maxCount)
BEGIN
	insert into @output
	select
		@intFlag,
		t1.IndexID,
		t1.IndexName,
		t1.PortfolioBaseID,
		t1.IndexDesc,
		t1.PeriodFromDate,
		t1.PeriodThruDate,
		t1.EffectiveRate,
		t1.TWR,
		((select EXP(sum(log(1+TWR/100)))
			from @temp t2
			join APXUserCustom.CSVToTable(@IndexArray) a on a.ID = @intFlag and
				a.name = t2.IndexID
			where t1.ID >= t2.ID)-1) * 100
	from @temp t1
	join APXUserCustom.CSVToTable(@IndexArray) a on a.ID = @intFlag and
		a.name = t1.IndexID
	SET @intFlag = @intFlag + 1
END

if @Interval = 'm'
begin
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistory', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PH out
end

if @Interval = 'y'
begin
select @InceptDate = InceptionDate, @ThruDate = ThruDate from APXUser.fPerformanceHistory (@PHCumulative)
select @AnnualFromDate = APXUser.fGetGenericDate('{edty}',@InceptDate)
if @AnnualFromDate = APXUser.fGetGenericDate('{edty}',getdate()) set @AnnualFromDate = @ThruDate
exec APXUser.pPerformanceHistory @ReportData = @PH out
	,@PortfolioObjectID = @PortfolioBaseID
	,@FromDate = @AnnualFromDate
	,@ToDate = @ThruDate
	,@ClassificationID = -9
	,@IntervalLength = 12
	,@InceptionToDate = 0
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@LocaleID = @LocaleID
end

if @Interval = 'ytd'
begin
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistoryYTD', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PH out
end

declare @ReportData varbinary(max)
if @InceptDate < @AnnualFromDate
begin
exec APXUser.pPerformanceHistory @ReportData = @ReportData out
	,@PortfolioObjectID = @PortfolioBaseID
	,@FromDate = @InceptDate
	,@ToDate = @AnnualFromDate
	,@ClassificationID = -9
	,@IntervalLength = 12
	,@InceptionToDate = 1
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@LocaleID = @LocaleID
end

declare @minDate datetime
select @minDate = MIN(PeriodFromDate) from APXUser.fPerformanceHistory(@PH)

select 
	o.IndexDisplayOrder,
	o.IndexID,
	o.PortfolioBaseID,
	o.IndexName,
	o.IndexDesc,
	null [PeriodFromDate],
	ph.PeriodFromDate [PeriodThruDate],
	r.Rate * APXUserCustom.fGetFXRate(i.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=ph.PortfolioBaseid) ELSE @ReportingCurrencyCode END, o.PeriodFromDate) [EffectiveRate],
	null [TWR],
	case when @Interval = 'm' then null else o.CumulativeTWR end [CumulativeTWR]
from APXUser.fPerformanceHistory (@PH) ph
join APXUser.fPerformanceHistory(@PHCumulative) phcum on phcum.PortfolioBaseID = ph.PortfolioBaseID
	and phcum.PeriodThruDate = ph.PeriodThruDate
	and phcum.IsIndex = 0
join @output o on 
	o.PeriodThruDate = ph.PeriodThruDate and
	o.PortfolioBaseID = ph.PortfolioBaseID
left join APXUser.fPerformanceHistory(@ReportData) twr on twr.PortfolioBaseID = ph.PortfolioBaseID
	and twr.PeriodThruDate = ph.PeriodFromDate
	and twr.IsIndex = 0
join APXUser.vMarketIndex i on i.IndexID = o.IndexID
left join APXUser.vMarketIndexRate r on r.IndexID = o.IndexID and
	r.AsOfDate = ph.PeriodFromDate
where ph.PeriodFromDate = @minDate and
	ph.IsIndex = 0
union all
select 
	o.IndexDisplayOrder,
	o.IndexID,
	o.PortfolioBaseID,
	o.IndexName,
	o.IndexDesc,
	ph.PeriodFromDate,
	ph.PeriodThruDate,
	o.EffectiveRate,
	APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, r.IndexID, @ReportingCurrencyCode, ph.PeriodFromDate, ph.PeriodThruDate),
	o.CumulativeTWR
from APXUser.fPerformanceHistory (@PH) ph
join @output o on 
	o.PeriodThruDate = ph.PeriodThruDate and
--	o.IndexName = ph.ClassificationMemberCode and
	o.PortfolioBaseID = ph.PortfolioBaseID
join APXUser.vMarketIndex i on i.IndexID = o.IndexID
left join APXUser.vMarketIndexRate r on r.IndexID = o.IndexID and
	r.AsOfDate = ph.PeriodThruDate
where ph.IsIndex = 0
order by IndexDisplayOrder, ph.PeriodFromDate

end