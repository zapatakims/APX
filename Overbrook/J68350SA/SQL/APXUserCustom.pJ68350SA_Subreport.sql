IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pJ68350SA_Subreport]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pJ68350SA_Subreport]
GO

create procedure [APXUserCustom].[pJ68350SA_Subreport]
	@SessionGuid nvarchar(72),
	@DataHandle nvarchar(48),
	@ClassificationMembers nvarchar(max)
as begin
exec APXUser.pSessionInfoSetGuid @SessionGuid

declare @ReportData varbinary(max)
,@DataHandleName nvarchar(max) = 'PerformanceHistoryPeriod'
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @ReportData=@ReportData out

select 
ph.PortfolioBaseIDOrder,
p.ReportHeading1,
p.ReportHeading2,
p.ReportHeading3,
ph.IsIndex,
'Quarter to Date' [ColumnHeader],
case when ph.ClassificationMemberCode = 'totport' then -9999999
	else ph.ClassificationMemberOrder end as ClassificationMemberOrder,
ph.ClassificationMemberName,
ph.QuarterToDateAnnualizedTWR [Return],
ph.YearToDateEndingMarketValue [MarketValue]
from APXUser.fPerformanceHistoryPeriod(@ReportData) ph
join APXUser.vPortfolioBase p on p.PortfolioBaseID = ph.PortfolioBaseID
where (CHARINDEX(ph.ClassificationMemberCode,@ClassificationMembers) > 0) or
ph.ClassificationMemberName = 'Total' or
ph.IsIndex = 1
union all
select 
ph.PortfolioBaseIDOrder,
p.ReportHeading1,
p.ReportHeading2,
p.ReportHeading3,
ph.IsIndex,
'Year to Date',
case when ph.ClassificationMemberCode = 'totport' then -9999999
	else ph.ClassificationMemberOrder end as ClassificationMemberOrder,
ph.ClassificationMemberName,
ph.YearToDateAnnualizedTWR,
ph.YearToDateEndingMarketValue
from APXUser.fPerformanceHistoryPeriod(@ReportData) ph
join APXUser.vPortfolioBase p on p.PortfolioBaseID = ph.PortfolioBaseID
where (CHARINDEX(ph.ClassificationMemberCode,@ClassificationMembers) > 0) or
ph.ClassificationMemberName = 'Total' or
ph.IsIndex = 1
end