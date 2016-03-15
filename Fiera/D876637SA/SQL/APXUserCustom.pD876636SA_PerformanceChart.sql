USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pD876636SA_PerformanceChart]    Script Date: 01/04/2016 11:41:53 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pD876636SA_PerformanceChart]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pD876636SA_PerformanceChart]
GO

USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pD876636SA_PerformanceChart]    Script Date: 01/04/2016 11:41:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
EXEC [APXUserCustom].[pD876636SA_PerformanceChart]
	-- Required Parameters
	@SessionGuid = null,
	@PortfolioBaseID = 14547,
	@PortfolioBaseIDOrder = 1,
	@DataHandle = 'DB1D2601-9471-4CD7-A568-0ACF57704E49',
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode = 'ca', -- Use Settings
	@LocaleID  = null, 					-- Use Portfolio Settings
	-- Other optional parameters
	@DataHandleName = 'PerformanceHistory'
*/

CREATE procedure [APXUserCustom].[pD876636SA_PerformanceChart]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@LocaleID int = null, 					-- Use Portfolio Settings
	-- Other optional parameters
	@IncludeBeginningZeroRows bit = null,	-- For 'Growth Of A Dollar' charts.
	@DataHandleName nvarchar(max) = 'PerformanceHistory'
as
begin
declare	@ShowIndexes bit = 0, @ClassificationID int = -9

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@ReportData out
-- store value in the table so we only parse the xml once
declare @performanceHistory table
(
            PortfolioBaseId int,
            PortfolioBaseIDOrder int,
            IsIndex bit,
	        ClassificationMemberID int,
            ClassificationMemberName nvarchar(72),
            ClassificationMemberOrder int,
			ClassificationMemberCode nvarchar(72),
            InceptionDate datetime,
            TWR float,
            CumulativeTWR float,
            FromDate datetime,
            PeriodFromDate datetime,
            PeriodThruDate datetime
)
declare @Results table (
	ClassificationMemberID int,
	ClassificationMemberCode nvarchar(max),
	ClassificationMemberName nvarchar(max),
	ClassificationMemberOrder int,
	CumulativeTWR float,
	CurrencySymbol nvarchar(max),
	FormatReportingCurrency nvarchar(max),
	FromDate datetime,
	InceptionDate datetime,
	IsIndex int,
	LegacyLocaleID int,
	LocaleID int,
	PeriodThruDate datetime,
	PrefixedPortfolioBaseCode nvarchar(max),
	PortfolioBaseIDOrder int,
	TWR float,
	MaxCumulativeTWR float
)
insert into @performanceHistory
select 
		PortfolioBaseId,
		PortfolioBaseIDOrder,
		IsIndex,
        ClassificationMemberID,
		ClassificationMemberName,
		ClassificationMemberOrder,
		ClassificationMemberCode,
		InceptionDate,
		TWR,
		CumulativeTWR,
		FromDate,
		PeriodFromDate,
		PeriodThruDate 
from 
      APXUser.fPerformanceHistory(@ReportData)
declare @MinThruDate datetime = (select MIN(PeriodThruDate) from @performanceHistory)
-- Select the columns for the report.
INSERT INTO @Results
select top 1 
	ph.ClassificationMemberID,
	ph.ClassificationMemberCode,
	ClassificationMemberName = case
		when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
   		else IsNull(l.LookupLabel, ph.ClassificationMemberName) end,
	ph.ClassificationMemberOrder,
	[CumulativeTWR] = 0, 
	CurrencySymbol = p.ReportingCurrencySymbol,
    p.FormatReportingCurrency,
	ph.FromDate,
	ph.InceptionDate,
	ph.IsIndex,
	p.LegacyLocaleID,
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID, -- = isnull(@LocaleID, portfolioBase.LocaleID),
	[PeriodThruDate] = ph.FromDate,
    p.PrefixedPortfolioBaseCode,
	ph.PortfolioBaseIDOrder,
	[TWR] = 0,
	NULL
from @performanceHistory ph
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = ph.PortfolioBaseID
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID and l.PropertyLookupID = ph.ClassificationMemberID
where @ShowIndexes = 1 or ph.IsIndex = 0  and
	ph.PortfolioBaseId = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
union all
select
	ph.ClassificationMemberID,
	ph.ClassificationMemberCode,
	ClassificationMemberName = case
		when ph.ClassificationMemberName in('Total','Portfolio') then isnull(nullif(p.ReportHeading1, '?'), p.PortfolioBaseCode)
   		else IsNull(l.LookupLabel, ph.ClassificationMemberName) end,
	ph.ClassificationMemberOrder,
	ph.CumulativeTWR, 
	CurrencySymbol = p.ReportingCurrencySymbol,
    p.FormatReportingCurrency,
	ph.FromDate,
	ph.InceptionDate,
	ph.IsIndex,
	p.LegacyLocaleID,
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID, -- = isnull(@LocaleID, portfolioBase.LocaleID),
	ph.PeriodThruDate,
    p.PrefixedPortfolioBaseCode,
	ph.PortfolioBaseIDOrder,
	ph.TWR,
	NULL
-- 4a) Select the result set.
from (
	-- This query creates a beginning 'dummy zero' record at the minimum of PeriodThruDate.
	-- It finds the minimum PeriodThruDate of all rows, and then selects each row that has that minimum PeriodThruDate.
	-- Some portfolios will have rows, and other ones (without a row at min(PeriodThruDate)) will not have rows.
	-- These rows are used when plotting 'Growth of a Dollar' charts when you want the y-intercept to be 0.
	select 
		IsIndex,
		PortfolioBaseId,
		PortfolioBaseIDOrder,
		ClassificationMemberCode,
		ClassificationMemberID,
		ClassificationMemberName,
		ClassificationMemberOrder,
		InceptionDate,
		TWR = 0,
		CumulativeTWR = 0,
		FromDate,
		PeriodThruDate = PeriodFromDate
	from @performanceHistory ph
	where @IncludeBeginningZeroRows = 1 and PeriodThruDate = @MinThruDate
	union
	-- This query selects the actual performance rows, one row for each performance period.
	select
		IsIndex,
		PortfolioBaseId,
		PortfolioBaseIDOrder,
		ClassificationMemberCode,
		ClassificationMemberID,
		ClassificationMemberName,
		ClassificationMemberOrder,
		InceptionDate,
		TWR,
		CumulativeTWR,
		FromDate,
		PeriodThruDate 
	from @performanceHistory ph
) ph 
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = ph.PortfolioBaseID
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID and l.PropertyLookupID = ph.ClassificationMemberID
where @ShowIndexes = 1 or ph.IsIndex = 0  and
	ph.PortfolioBaseId = @PortfolioBaseID and
	ph.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by PortfolioBaseIDOrder, ClassificationMemberOrder, IsIndex, PeriodThruDate

UPDATE @Results
SET MaxCumulativeTWR = (SELECT Max(CumulativeTWR) FROM @Results)

SELECT * FROM @Results
end

GO


