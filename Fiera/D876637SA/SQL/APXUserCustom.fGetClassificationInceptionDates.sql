USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetClassificationInceptionDates]    Script Date: 03/14/2016 16:20:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetClassificationInceptionDates]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetClassificationInceptionDates]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetClassificationInceptionDates]    Script Date: 03/14/2016 16:20:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE function [APXUserCustom].[fGetClassificationInceptionDates] (@ReportData varbinary(max))
returns @output TABLE
(
-- Columns returned by the function
ClassificationMemberCode nvarchar(max) NOT NULL,
ClassificationMemberID int NULL,
ClassificationMemberName nvarchar(max) NULL,
ClassificationMemberOrder int NULL,
InceptionDate datetime NULL,
SellDate datetime NULL
)
as
begin

with cte_base as (
SELECT ClassificationMemberCode, ClassificationMemberID,
ClassificationMemberName, ClassificationMemberOrder, PeriodFromDate,
PeriodThruDate, EndingMarketValue, TWR, ROW_NUMBER() over (partition by ClassificationMemberCode order by PeriodFromDate) ROW_NUM
FROM APXUser.fPerformanceHistory(@ReportData)
WHERE IsIndex = 0 and ClassificationMemberCode <> 'totport'
), cte as (
select ClassificationMemberCode, ClassificationMemberID, ClassificationMemberName, ClassificationMemberOrder, PeriodFromDate, PeriodThruDate, ROW_NUM,
Island = ROW_NUM - ROW_NUMBER() OVER (PARTITION BY ClassificationMemberID ORDER BY ROW_NUM)
from cte_base
where EndingMarketValue <> 0
), cte_island as (
select ClassificationMemberCode, ClassificationMemberID, ClassificationMemberName, ClassificationMemberOrder, StartDate = MIN(PeriodThruDate), EndDate = MAX(PeriodThruDate)
from cte
group by ClassificationMemberCode, ClassificationMemberID, ClassificationMemberName, ClassificationMemberOrder, Island
)
insert into @output
select ClassificationMemberCode, ClassificationMemberID, ClassificationMemberName, ClassificationMemberOrder, MAX(StartDate) InceptionDate, MAX(EndDate) SellDate
from
(
select *, RANK() over ( partition by ClassificationMemberCode order by StartDate) as rnk
from cte_island
) a
group by ClassificationMemberCode, ClassificationMemberID,  ClassificationMemberName, ClassificationMemberOrder

return

end
GO


