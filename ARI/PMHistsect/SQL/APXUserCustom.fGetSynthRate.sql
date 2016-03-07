/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSynthRate]    Script Date: 08/22/2013 16:38:07 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetSynthRate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetSynthRate]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSynthRate]    Script Date: 08/22/2013 16:38:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE Function [APXUserCustom].[fGetSynthRate](@PortfolioID int, @ReportingCurrencyCode varchar(2), @StartDate datetime,  @EndDate datetime)
returns float
with execute as caller
begin
return

(select
SUM(ReturnValue/100) as ReturnValue
from
(
Select
*,
CASE WHEN APXUserCustom.fGetIndexReturn(@PortfolioID, IndexID, @ReportingCurrencyCode, StartDate, PerfEndDate) is null then 1 else 0 end as NullCount,
(100 + APXUserCustom.fGetIndexReturn(@PortfolioID, IndexID, @ReportingCurrencyCode, StartDate, PerfEndDate)) * PercentWeight/100 as ReturnValue
FROM
(
Select
BreakDate as StartDate,
(Select Min(subD.BreakDate) from ApxUserCustom.fGetSyntheticIndexBreakDates(@PortfolioID, @StartDate, @EndDate) subD where subD.BreakDate > d.BreakDate)
as PerfEndDate,
CASE
WHEN DatePart(DAY, DATEADD(DAY,1, BreakDate)) = 1
THEN DateAdd(day, -1, DateAdd(month, 1, DATEADD(DAY,1,BreakDate)))
else DATEADD(day, - DatePart(day, DATEADD(Month,1, BreakDate)), DATEADD(Month,1, BreakDate))
END as EndDate
FROM
ApxUserCustom.fGetSyntheticIndexBreakDates(@PortfolioID, @StartDate, @EndDate) d
) as Dates
LEFT OUTER JOIN APXUser.vPortfolioIndexes breaks
on breaks.IndexDate =(Select MAX(IndexDate) from APXUser.vPortfolioIndexes where (IndexDate <= Dates.StartDate) and PortfolioBaseID = @PortfolioID)
and breaks.PortfolioBaseID = @PortfolioID
) as ReturnValues
WHERE
PerfEndDate is not null
Group By
PerfEndDate, EndDate
)
end

GO
