IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pAA24660SA]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pAA24660SA]
GO

create procedure [APXUserCustom].[pAA24660SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@Date datetime
as begin

exec APXUser.pSessionInfoSetGuid @SessionGuid

declare	@FromDate datetime = '01/01/1904'

declare @synths table (IndexDate date, IndexDesc nvarchar(max), PercentWeight nvarchar(max))
insert @synths
select
	p.IndexDate,
	m.IndexDesc,
	convert(nvarchar(50),convert(numeric(18,0),p.PercentWeight)) + '%'
from APXUser.vPortfolioIndexes p
join APXUser.vMarketIndex m on m.IndexID = p.IndexID
join APXUserCustom.fGetSyntheticIndexBreakDates(@PortfolioBaseID, @FromDate, @Date) breaks on
	breaks.BreakDate = p.IndexDate
where p.PortfolioBaseID = @PortfolioBaseID and
	p.IndexDate is not null

declare @dates table (PeriodID int identity, IndexDate date)
insert @dates
select distinct IndexDate
from @synths

declare @SynthTable table (PeriodID int, PeriodFromDate date, PeriodThruDate date, IndexDesc nvarchar(max), PercentWeight nvarchar(255))
insert @SynthTable
select 
	i1.PeriodID,
	i1.IndexDate [PeriodFromDate],
	coalesce(i2.IndexDate,@Date) [PeriodThruDate],
	s.IndexDesc,
	s.PercentWeight
from @dates i1
left join @dates i2 on i2.PeriodID = i1.PeriodID + 1
left join @synths s on s.IndexDate = i1.IndexDate
order by i1.IndexDate asc

select
	[Main].*
from
    (
        select distinct
			ST2.PeriodID,
			convert(nvarchar(8),ST2.PeriodFromDate,1) + ' - ' + convert(nvarchar(8),ST2.PeriodThruDate,1) + ' ' +
            (
                Select ST1.PercentWeight + ' ' + ST1.IndexDesc + ' ' AS [text()]
                From @SynthTable ST1
                Where ST1.PeriodID = ST2.PeriodID
                ORDER BY ST1.PeriodID
                For XML PATH ('')
            ) [DisclaimerText]
        From @SynthTable ST2
    ) [Main]
end