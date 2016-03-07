IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetBenchmarkReturn]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')) 
DROP FUNCTION [APXUserCustom].[fGetBenchmarkReturn] 
GO 
  
SET ANSI_NULLS ON
GO 
  
SET QUOTED_IDENTIFIER ON
GO 
  
CREATE Function [APXUserCustom].[fGetBenchmarkReturn](@ReportData varbinary(max), @IndexID int, @ReportingCurrencyCode char(2)) 
returns table
as return
select 
	t1.*,
	((select EXP(sum(log(1+TWR/100)))
		from (select ph.PortfolioBaseID,
				i.IndexDesc,
				ph.PeriodFromDate,
				ph.PeriodThruDate,
				r.Rate * APXUserCustom.fGetFXRate(i.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=ph.PortfolioBaseid) ELSE @ReportingCurrencyCode END, ph.PeriodThruDate) [EffectiveRate],
				APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, @IndexID, @ReportingCurrencyCode, ph.PeriodFromDate, ph.PeriodThruDate) [TWR]
			from APXUser.fPerformanceHistory (@ReportData) ph
			left join APXUser.vMarketIndexRate r on ph.PeriodThruDate = r.AsOfDate and
				ph.ClassificationMemberCode = 'totport'
			join APXUser.vMarketIndex i on i.IndexID = r.IndexID
			where r.IndexID = @IndexID) t2
	where t1.PeriodThruDate >= t2.PeriodThruDate)-1) * 100 as CumulativeReturn
from (select ph.PortfolioBaseID,
	i.IndexID,
	i.IndexName,
	i.IndexDesc,
	ph.PeriodFromDate,
	ph.PeriodThruDate,
	r.Rate * APXUserCustom.fGetFXRate(i.CurrencyCode, CASE WHEN @ReportingCurrencyCode='PC' THEN (select p.ReportingCurrencyCode from ApxUser.vPortfolioBaseSettingEx p where p.PortfolioBaseID=ph.PortfolioBaseid) ELSE @ReportingCurrencyCode END, ph.PeriodThruDate) [EffectiveRate],
	APXUserCustom.fGetIndexReturn(ph.PortfolioBaseID, @IndexID, @ReportingCurrencyCode, ph.PeriodFromDate, ph.PeriodThruDate) [TWR]
from APXUser.fPerformanceHistory (@ReportData) ph
left join APXUser.vMarketIndexRate r on ph.PeriodThruDate = r.AsOfDate and
	ph.ClassificationMemberCode = 'totport'
join APXUser.vMarketIndex i on i.IndexID = r.IndexID
where r.IndexID = @IndexID) t1