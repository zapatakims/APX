if object_id('[APXUserCustom].[pPMHistsectSubReport]') is not null
	drop procedure [APXUserCustom].[pPMHistsectSubReport]
go
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = '@casetrade'
	,@ToDate datetime = '12/31/09'
	,@FeeMethod int
	,@PortfolioBaseID int = 180
	,@PortfolioBaseIDOrder int = 1
	,@DataHandle nvarchar(48) = 'CE793B73-F069-4B50-BA30-6C135DFC6A60'
	,@Interval char(3) = 'ytd'
	,@ReportingCurrencyCode char(2) = 'us'
	,@LocaleID int = null

--exec APXUserCustom.pPMHistsect @SessionGuid = @SessionGuid, @Portfolios = @Portfolios, @ToDate = @ToDate, @FeeMethod = @FeeMethod, @ReportingCurrencyCode = @ReportingCurrencyCode
exec APXUserCustom.pPMHistsectSubReport @SessionGuid, @PortfolioBaseID, @PortfolioBaseIDOrder, @DataHandle, @Interval, @FeeMethod, @ReportingCurrencyCode, @LocaleID
*/
create procedure [APXUserCustom].[pPMHistsectSubReport]
	@SessionGuid nvarchar(max)
	,@PortfolioBaseID int
	,@PortfolioBaseIDOrder int
	,@DataHandle nvarchar(48)
	,@Interval char(3)
	,@FeeMethod int = null
	,@ReportingCurrencyCode char(2) = null
	,@LocaleID int = null
as begin

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @PH varbinary(max)
	,@PHCumulative varbinary(max)
	,@PHDetail varbinary(max)
	,@InceptDate datetime
	,@AnnualFromDate datetime
	,@ThruDate datetime

exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistoryDetail', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PHDetail out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerformanceHistory', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PHCumulative out

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

declare @NetAdd table (PortfolioBaseID int, PeriodFromDate datetime, PeriodThruDate datetime, NetAddWith float)
insert @NetAdd
select p.PortfolioBaseID,
	p.PeriodFromDate,
	p.PeriodThruDate,
	isnull(sum(t.NetAddWith), sum(phd.NetAdditions + phd.NetTransfers))
from APXUser.fPerformanceHistoryDetail (@PHDetail) phd
join APXUser.fPerformanceHistory (@PH) p on p.PortfolioBaseID = phd.PortfolioBaseID and
	p.PeriodFromDate <= phd.PeriodFromDate and
	p.PeriodThruDate >= phd.PeriodThruDate and
	p.ClassificationMemberCode = phd.ClassificationMemberCode
left join APXUserCustom.tA904SACustomData t on phd.PortfolioBaseID = t.PortfolioBaseID
	and t.PeriodToDate = phd.PeriodThruDate
group by p.PortfolioBaseID, p.PeriodFromDate, p.PeriodThruDate

declare @minDate datetime
select @minDate = MIN(PeriodFromDate) from APXUser.fPerformanceHistory(@PH)

select ph.ClassificationMemberCode
	,null [PeriodFromDate]
	,ph.PeriodFromDate [PeriodThruDate]
	,ph.ThruDate
	,null [BeginningMarketValue]
	,ph.BeginningMarketValue [EndingMarketValue]
	,case when @Interval = 'm' then null else sum(t.NetAddWith) end as [NetAdditions]
	,case when @Interval = 'm' then null else SUM(t2.NetAddWith) end as [CumulativeNetAdditions]
	,twr.TWR
	,case when @Interval = 'm' then null else phcum.CumulativeTWR end as [CumulativeTWR]
	,ph.IsIndex
from APXUser.fPerformanceHistory (@PH) ph
	left join APXUser.fPerformanceHistory(@ReportData) twr on twr.PortfolioBaseID = ph.PortfolioBaseID
		and twr.PeriodThruDate = ph.PeriodFromDate
		and twr.ClassificationMemberCode = ph.ClassificationMemberCode
	left join APXUser.fPerformanceHistory(@PHCumulative) phcum on phcum.PortfolioBaseID = ph.PortfolioBaseID
		and phcum.PeriodThruDate = ph.PeriodFromDate
		and phcum.ClassificationMemberCode = ph.ClassificationMemberCode
	left join APXUser.fPerformanceHistoryDetail(@PHDetail) phd on phd.PortfolioBaseID = ph.PortfolioBaseID
		--and phd.PeriodFromDate = ph.PeriodFromDate
		and phd.PeriodThruDate = ph.PeriodThruDate
		and phd.ClassificationMemberCode = ph.ClassificationMemberCode
	left join @NetAdd t on t.PortfolioBaseID = phd.PortfolioBaseID and
		t.PeriodThruDate = ph.PeriodFromDate
	left join @NetAdd t2 on t2.PortfolioBaseID = t.PortfolioBaseID and
		t2.PeriodThruDate <= t.PeriodThruDate
where ph.IsIndex = 0
	and ph.PeriodFromDate = @minDate
group by ph.ClassificationMemberCode
	,ph.PeriodFromDate
	,ph.ThruDate
	,ph.BeginningMarketValue
	,phd.NetAdditions
	,phcum.CumulativeTWR
	,ph.IsIndex
	,t.NetAddWith
	,twr.TWR
union all
select ph.ClassificationMemberCode
	,ph.PeriodFromDate
	,ph.PeriodThruDate
	,ph.ThruDate
	,ph.BeginningMarketValue
	,ph.EndingMarketValue
	,t.NetAddWith
	,SUM(t2.NetAddWith)
	,ph.TWR
	,phcum.CumulativeTWR
	,ph.IsIndex
from APXUser.fPerformanceHistory (@PH) ph
	join APXUser.fPerformanceHistory(@PHCumulative) phcum on phcum.PortfolioBaseID = ph.PortfolioBaseID
		and phcum.PeriodThruDate = ph.PeriodThruDate
		and phcum.ClassificationMemberCode = ph.ClassificationMemberCode
	left join APXUser.fPerformanceHistoryDetail(@PHDetail) phd on phd.PortfolioBaseID = ph.PortfolioBaseID
		--and phd.PeriodFromDate = ph.PeriodFromDate
		and phd.PeriodThruDate = ph.PeriodThruDate
		and phd.ClassificationMemberCode = ph.ClassificationMemberCode
	left join @NetAdd t on t.PortfolioBaseID = phd.PortfolioBaseID and
		t.PeriodThruDate = phd.PeriodThruDate
	left join @NetAdd t2 on t2.PortfolioBaseID = t.PortfolioBaseID and
		t2.PeriodThruDate <= t.PeriodThruDate
where ph.IsIndex = 0
group by ph.ClassificationMemberCode
	,ph.PeriodFromDate
	,ph.PeriodThruDate
	,ph.ThruDate
	,ph.BeginningMarketValue
	,ph.EndingMarketValue
	,phd.NetAdditions
	,phcum.CumulativeTWR
	,ph.TWR
	,ph.CumulativeTWR
	,ph.IsIndex
	,t.NetAddWith
	,phd.NetTransfers
union all
select ph.ClassificationMemberName
	,null
	,ph.PeriodFromDate
	,ph.ThruDate
	,null
	,r.Rate * APXUserCustom.fGetFXRate(i.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=ph.PortfolioBaseid) ELSE @ReportingCurrencyCode END, ph.PeriodFromDate)
	,null
	,null
	,twr.TWR
	,case when @Interval = 'm' then null else phcum.CumulativeTWR end
	,ph.IsIndex
from APXUser.fPerformanceHistory (@PH) ph
join APXUser.fPerformanceHistory(@PHCumulative) phcum on phcum.PortfolioBaseID = ph.PortfolioBaseID
	and phcum.PeriodThruDate = ph.PeriodThruDate
	and phcum.ClassificationMemberCode = ph.ClassificationMemberCode
left join APXUser.fPerformanceHistory(@ReportData) twr on twr.PortfolioBaseID = ph.PortfolioBaseID
	and twr.PeriodThruDate = ph.PeriodFromDate
	and twr.ClassificationMemberCode = ph.ClassificationMemberCode
left join APXUser.vMarketIndex i on i.IndexName = ph.ClassificationMemberCode
left join APXuser.vMarketIndexRate r on r.IndexID = i.IndexID
	and r.AsOfDate = ph.PeriodFromDate
where ph.IsIndex = 1
	and ph.PeriodFromDate = @minDate
	and ph.ClassificationMemberOrder = 1
union all
select ph.ClassificationMemberName
	,ph.PeriodFromDate
	,ph.PeriodThruDate
	,ph.ThruDate
	,ph.BeginningMarketValue
	,ph.EndingMarketValue
	,null
	,null
	,ph.TWR
	,phcum.CumulativeTWR
	,ph.IsIndex
from APXUser.fPerformanceHistory (@PH) ph
	join APXUser.fPerformanceHistory(@PHCumulative) phcum on phcum.PortfolioBaseID = ph.PortfolioBaseID
		and phcum.PeriodThruDate = ph.PeriodThruDate
		and phcum.ClassificationMemberCode = ph.ClassificationMemberCode
where ph.IsIndex = 1
	and ph.ClassificationMemberOrder = 1
end