/****** Object:  UserDefinedFunction [APXUserCustom].[fGetAnnualizedReturn]    Script Date: 08/22/2013 16:36:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetAnnualizedReturn]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetAnnualizedReturn]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE Function [APXUserCustom].[fGetAnnualizedReturn](@Return float, @StartDate datetime, @EndDate datetime)
returns float
with execute as caller
begin

declare @daysInPeriod float, @daysInYear float
set @daysInPeriod=0
set @daysInYear=12

WHILE CONVERT(datetime,LEFT(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0, DATEADD(mm, @daysInPeriod, @StartDate))+1,0)), 11)) < @EndDate
BEGIN
set @daysInPeriod=@daysInPeriod+1
END

--Checks for partial years and adds days accordingly
declare @modulus int, @years int

set @modulus=CONVERT(int, @daysInPeriod) % 12
set @years=CONVERT(int, @daysInPeriod) / 12

IF (@modulus <> 0 OR @StartDate <> CONVERT(datetime, LEFT(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@StartDate)+1,0)),11)) OR @EndDate <> CONVERT(datetime, LEFT(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@EndDate)+1,0)), 11)))
BEGIN
declare @subPeriodDate datetime
set @subPeriodDate = DATEADD(yy, @years, @startdate)

set @daysInPeriod = CONVERT(float, DATEDIFF(d, @EndDate, @subPeriodDate))

set @daysInYear=CONVERT(float, DATEDIFF(d, @EndDate, DATEADD(yy, -1, @EndDate)))

set @daysInPeriod = @daysInPeriod + Convert(float, @years) * @daysInYear

END

return (select (POWER((1 + @Return/100),(@daysInYear/@daysInPeriod))-1)*100)

end


GO


