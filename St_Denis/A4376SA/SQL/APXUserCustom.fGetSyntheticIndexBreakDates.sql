USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSyntheticIndexBreakDates]    Script Date: 06/02/2014 14:15:41 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetSyntheticIndexBreakDates]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetSyntheticIndexBreakDates]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetSyntheticIndexBreakDates]    Script Date: 06/02/2014 14:15:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create function [APXUserCustom].[fGetSyntheticIndexBreakDates] (@PortfolioBaseID int, @StartDate datetime, @EndDate datetime)
returns TABLE
as return
(
Select
MonthEnd as BreakDate
FROM (
Select
DateAdd(day, - Datepart(day, MonthEnd), MonthEnd) as Monthend
FROM
(
select
DATEADD(MONTH, row_number() over (order by object_id),  @StartDate)   as MonthEnd
from sys.all_objects
) as Dates
where
DateAdd(day, - Datepart(day, MonthEnd), MonthEnd)  between @StartDate AND @EndDate
UNION Select @StartDate
UNION Select @EndDate
UNION Select IndexDate from APXUser.vPortfolioIndexes where IndexDate is not null and PortfolioBaseID = @PortfolioBaseID
) as Dates
WHERE
Monthend between @StartDate and  @EndDate

)




GO

