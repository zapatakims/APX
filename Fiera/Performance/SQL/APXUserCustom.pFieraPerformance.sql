IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pFieraPerformance]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pFieraPerformance]
GO

create procedure [APXUserCustom].[pFieraPerformance]
@SessionGuid nvarchar(max)
,@Portfolios nvarchar(32)-- = 'contrib'
,@FromDate datetime-- = '12/31/2011'
,@ToDate datetime-- = '12/31/2012'

--	Optional Parameters
,@AccruePerfFees bit = null
,@AllocatePerfFees bit = null
,@ReportingCurrencyCode char(2) = null
,@FeeMethod int = null
,@LocaleID int

as begin
exec APXUser.pSessionInfoSetGuid @SessionGuid

declare @DataHandle as uniqueidentifier = newid()

declare @ClassificationID int = -4
exec APXUser.pGetEffectiveParameter
@FeeMethod = @FeeMethod

declare @PerformanceHistory varbinary(max),
@PerformanceHistoryDetail varbinary(max)

exec APXUser.pPerformanceHistoryBatch
@DataHandle = @DataHandle,
@DataName = 'PerformanceHistory',
-- Required Parameters
@Portfolios = @Portfolios,
@FromDate = @FromDate,
@ToDate = @ToDate,
@ClassificationID = @ClassificationID,

-- Optional Parameters
@ReportingCurrencyCode = @ReportingCurrencyCode out,
@IntervalLength = 1,
@FeeMethod = @FeeMethod,
@AccruePerfFees = @AccruePerfFees,
@AllocatePerfFees = @AllocatePerfFees,
@LocaleID = @LocaleID

exec APXUser.pPerformanceHistoryDetailBatch
@DataHandle = @DataHandle,
@DataName = 'PerformanceHistoryDetail',
-- Required Parameters
@Portfolios = @Portfolios,
@FromDate = @FromDate,
@ToDate = @ToDate,
@ClassificationID = -9,

-- Optional Parameters
@ReportingCurrencyCode = @ReportingCurrencyCode out,
@FeeMethod = @FeeMethod,
@AccruePerfFees = @AccruePerfFees,
@AllocatePerfFees = @AllocatePerfFees,
@LocaleID = @LocaleID

exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=0
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory', @ReportData = @PerformanceHistory out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistoryDetail', @ReportData = @PerformanceHistoryDetail out

declare @StrategyBenchmarks table (PortfolioBaseID int, StrategyBenchmark nvarchar(255))
insert into @StrategyBenchmarks
select distinct
ph.PortfolioBaseID
,case when c.AssetClass = 'e' then c.StrategyIndex
when c.AssetClass = 'f' then c.StrategyIndexfindex
when c.AssetClass = 'o' then c.StrategyIndexoindex
else null end
from APXUser.fPerformanceHistory(@PerformanceHistory) ph
join APXUser.vPortfolioBaseCustom c on c.PortfolioBaseID = ph.PortfolioBaseID

declare @temp table (PortfolioBaseID int, TotalPortfolioMV float)
insert into @temp
select
PortfolioBaseID
,EndingMarketValue
from APXUser.fPerformanceHistory(@PerformanceHistory) ph
where ClassificationMemberCode = 'totport' and
ph.PeriodThruDate = ThruDate

declare @netadd table (PortfolioBaseID int, PeriodThruDate datetime, NetFlow float)
insert into @netadd
select
PortfolioBaseID
,PeriodThruDate
,sum(NetAdditions + NetTransfers)
from APXUser.fPerformanceHistoryDetail(@PerformanceHistoryDetail)
group by PortfolioBaseID,PeriodThruDate

declare @Strategy table (Strategy sql_variant, Value sql_variant)
insert @Strategy
select a.Value [Strategy]
,b.Value [Value]
from APXUser.vPortfolioBaseCustomLabels a
join (select * from APXUser.vPortfolioBaseCustomLabels
where Label like ('$saa%') and LEN(Label) = 8) b on a.Label = left(b.Label,7)
where a.Label like ('$saa%') and LEN(a.Label) = 7
declare @NetOrGross char(1) = 'n'
if @FeeMethod = 2 set @NetOrGross = 'g'

declare @entity table (PortfolioBaseID int, GroupCode nvarchar(32), MarketValue float)
insert @entity
select distinct
ph.PortfolioBaseID
,c.MGroup
,perf.MarketValue
from APXUser.fPerformanceHistory(@PerformanceHistory) ph
join APXUser.vPortfolioBaseCustom c on c.PortfolioBaseID = ph.PortfolioBaseID
join APXUser.vPortfolioBase p on p.PortfolioBaseCode = SUBSTRING(c.MGroup,CHARINDEX('@',c.MGroup)+1,LEN(c.MGroup)-CHARINDEX('@',c.MGroup)+1)
left join APXUser.vPerformance perf on perf.PortfolioBaseID = p.PortfolioBaseID and
perf.PerfDate = ph.ThruDate and
perf.RowTypeCode = 't' and
perf.PerfCategoryCode = 'a' and
perf.NetOrGrossCode = @NetOrGross

declare @AssetClassMV table (PortfolioBaseID int, ClassificationMemberCode nvarchar(max), EndingMarketValue float)
insert into @AssetClassMV
select PortfolioBaseID, ClassificationMemberCode, EndingMarketValue
from APXUser.fPerformanceHistory(@PerformanceHistory) ph
where ph.ClassificationMemberCode <> 'totport' and ph.IsIndex = 0 and ph.PeriodThruDate = ph.ThruDate

select
DATENAME(MM,ph.PeriodThruDate) + ' ' + DATENAME(YYYY,ph.PeriodThruDate) [PeriodThruDate]
,DATEADD(MONTH, DATEDIFF(MONTH, 0, ph.PeriodThruDate), 0) AS [Date]
,ph.PortfolioBaseID
,ph.PortfolioBaseIDOrder
,p.PortfolioBaseCode
,ph.ClassificationMemberCode
,ph.ClassificationMemberOrder
,ph.TWR
,ph.EndingMarketValue
,n.NetFlow
,temp.TotalPortfolioMV
,c.AssetClass
--,case when ISNULL(e.MarketValue,0) = 0 then 0 else assetClassMV.EndingMarketValue / e.MarketValue end as [assetClassPct]--	could be EndingMarketValue????
,case when ISNULL(e.MarketValue,0) = 0 then 0 else temp.TotalPortfolioMV / e.MarketValue end as [assetClassPct]
,ISNULL(assetClassMV.EndingMarketValue,0) [AssetClassMV]
,c.GipCompGroup
,c.MGroup
,ISNULL(e.MarketValue,0) [EntityGroupMV]
,c.StrategyName
,Strategy.Strategy
,p.StartDate
,u.DisplayName [OwnerName]
,contact.LastName + ', ' + contact.FirstName + contact.MiddleName [OwnerContactName]
,s.StrategyBenchmark
,APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID,m.IndexID,@ReportingCurrencyCode,ph.PeriodFromDate,ph.PeriodThruDate) [IndexReturn]
from APXUser.fPerformanceHistory(@PerformanceHistory) ph
join @netadd n on
n.PortfolioBaseID = ph.PortfolioBaseID and
n.PeriodThruDate = ph.PeriodThruDate
join APXUser.vPortfolioBase p on p.PortfolioBaseID = ph.PortfolioBaseID
join APXUser.vPortfolioBaseCustom c on c.PortfolioBaseID = ph.PortfolioBaseID
left join @Strategy strategy on strategy.Value = c.StrategyName
join APXUser.vPortfolio port on port.PortfolioID = ph.PortfolioBaseID
left join APXUser.vUserBase u on u.UserBaseID = port.OwnedBy
left join APXUser.vContact contact on contact.ContactID = port.PrimaryContactID
left join @StrategyBenchmarks s on s.PortfolioBaseID = ph.PortfolioBaseID
left join APXUser.vMarketIndex m on m.IndexName = s.StrategyBenchmark
left join @entity e on e.PortfolioBaseID = ph.PortfolioBaseID
left join @AssetClassMV assetClassMV on assetClassMV.PortfolioBaseID = ph.PortfolioBaseID and
assetClassMV.ClassificationMemberCode = c.AssetClass
left join @temp temp on temp.PortfolioBaseID = ph.PortfolioBaseID--	could be this
where ph.IsIndex = 0 and
ph.ClassificationMemberCode = 'totport'
end
