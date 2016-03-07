IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pD876637SA]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pD876637SA]
GO

create procedure [APXUserCustom].[pD876637SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@ToDate datetime,
	@ClassificationID1 int,
	@ClassificationID2 int = null,
	@ClassificationID3 int = null,
	@ReportingCurrencyCode dtCurrencyCode,
	
	-- Optional parameters
	@FeeMethod int = null,
	@AnnualizeReturns char(1) = null,
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@UseIRRCalc bit = null,
	@LocaleID int = null					-- Use Portfolio Settings
	
as 
begin
declare @IntervalLength int = 1

-- Set the Session Guid and Data Handle
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()
-- Get the effective parameter values for parameters that are not passed to pAppraisal.
declare @ShowFees bit
EXEC APXUser.pGetEffectiveParameter
  @FeeMethod = @FeeMethod,   -- input for @ShowFees
  @ShowFees = @ShowFees out

-- ***************  Appraisal ***************
exec APXUser.pAppraisalBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @ToDate,
	@ReportingCurrencyCode = @ReportingCurrencyCode

-- ***************  Performance History ***************
declare @InceptionToDate bit = 1
declare @PortPerfID int = -9
exec APXUser.pPerformanceHistoryBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistory',
	@Portfolios = @Portfolios,
	@FromDate = @ToDate,
	@ToDate = @ToDate,
	@ClassificationID = @PortPerfID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees =@AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = @AnnualizeReturns,
	@UseIRRCalc = @UseIRRCalc,
	@InceptionToDate = @InceptionToDate,
	@LocaleID = @LocaleID,
	@IntervalLength = @IntervalLength

-- ***************  Cumulative Performance History ***************
exec APXUser.pPerformanceHistoryBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Cumulative1',
	@Portfolios = @Portfolios,
	@FromDate = @ToDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID1,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees =@AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = 'n',
	@UseIRRCalc = @UseIRRCalc,
	@InceptionToDate = @InceptionToDate,
	@LocaleID = @LocaleID,
	@IntervalLength = @IntervalLength

-- ***************  Performance History Summary ***************
declare @ExcludeSinceDateIRR bit = 1
declare @FromDate datetime 
select @FromDate = DATEADD(YYYY,-2,@ToDate)
exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerfSummary1',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID1,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = @AnnualizeReturns,
	@UseIRRCalc = @UseIRRCalc,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID

-- ***************  Performance History Summary for latest 4-year ***************
select @FromDate = DATEADD(YYYY,-4,@ToDate)
exec APXUser.pPerformanceHistoryPeriodBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'PerfSummary2',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID1,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = @AnnualizeReturns,
	@UseIRRCalc = @UseIRRCalc,
	@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
	@LocaleID = @LocaleID

if @ClassificationID2 is not null
begin
	select @FromDate = DATEADD(YYYY,-2,@ToDate)
	exec APXUser.pPerformanceHistoryPeriodBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'PerfSummary3',
		@Portfolios = @Portfolios,
		@FromDate = @FromDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID2,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees = @AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = @AnnualizeReturns,
		@UseIRRCalc = @UseIRRCalc,
		@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
		@LocaleID = @LocaleID

	-- ***************  Performance History Summary for latest 4-year ***************
	select @FromDate = DATEADD(YYYY,-4,@ToDate)
	exec APXUser.pPerformanceHistoryPeriodBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'PerfSummary4',
		@Portfolios = @Portfolios,
		@FromDate = @FromDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID2,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees = @AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = @AnnualizeReturns,
		@UseIRRCalc = @UseIRRCalc,
		@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
		@LocaleID = @LocaleID

	-- ***************  Cumulative Performance History ***************
	exec APXUser.pPerformanceHistoryBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'Cumulative2',
		@Portfolios = @Portfolios,
		@FromDate = @ToDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID2,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees =@AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = 'n',
		@UseIRRCalc = @UseIRRCalc,
		@InceptionToDate = @InceptionToDate,
		@LocaleID = @LocaleID,
		@IntervalLength = @IntervalLength

end

if @ClassificationID3 is not null
begin
	select @FromDate = DATEADD(YYYY,-2,@ToDate)
	exec APXUser.pPerformanceHistoryPeriodBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'PerfSummary5',
		@Portfolios = @Portfolios,
		@FromDate = @FromDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID3,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees = @AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = @AnnualizeReturns,
		@UseIRRCalc = @UseIRRCalc,
		@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
		@LocaleID = @LocaleID

	-- ***************  Performance History Summary for latest 4-year ***************
	select @FromDate = DATEADD(YYYY,-4,@ToDate)
	exec APXUser.pPerformanceHistoryPeriodBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'PerfSummary6',
		@Portfolios = @Portfolios,
		@FromDate = @FromDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID3,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees = @AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = @AnnualizeReturns,
		@UseIRRCalc = @UseIRRCalc,
		@ExcludeSinceDateIRR = @ExcludeSinceDateIRR,
		@LocaleID = @LocaleID

	-- ***************  Cumulative Performance History ***************
	exec APXUser.pPerformanceHistoryBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'Cumulative3',
		@Portfolios = @Portfolios,
		@FromDate = @ToDate,
		@ToDate = @ToDate,
		@ClassificationID = @ClassificationID3,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@FeeMethod = @FeeMethod,
		@AccruePerfFees =@AccruePerfFees,
		@AllocatePerfFees = @AllocatePerfFees,
		@AnnualizeReturns = 'n',
		@UseIRRCalc = @UseIRRCalc,
		@InceptionToDate = @InceptionToDate,
		@LocaleID = @LocaleID,
		@IntervalLength = @IntervalLength
end

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 1
-- ***************  Get Portfolio Overview Portfolio List ***************
declare @reportPerformanceHistory as varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory', @ReportData = @reportPerformanceHistory out

declare @reportData table (DataHandle nvarchar(255), FirmLogo nvarchar(255), FromDate datetime, LegacyLocaleID int, LocaleID int, PortfolioBaseID int,
PortfolioBaseIDOrder int, PortfolioBaseCode nvarchar(32), ReportHeading1 nvarchar(255), ReportHeading2 nvarchar(255), ReportHeading3 nvarchar(255),
ReportingCurrencyCode char(2), ReportingCurrencyName nvarchar(255), ThruDate datetime)

insert @reportData
SELECT 
	DataHandle = @DataHandle,
	FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
	a.FromDate,
	p.LegacyLocaleID,
	p.LocaleID,
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.PortfolioBaseCode,
	p.ReportHeading1,	
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
    p.ReportingCurrencyName,
	a.ThruDate
FROM APXUser.fReportDataIndex(@reportPerformanceHistory) a
join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder

declare @KeyString char(1) = 'y', @ClassificationName nvarchar(255) = 'Fund'
declare @filter table (ClassificationID int, ClassificationMemberID int, ClassificationMemberCode char(1))
insert @filter
select distinct
	[ClassificationID] = assetClass3.PropertyID,
	[ClassificationMemberID] = assetClass3.PropertyLookupID,
	[ClassificationMemberCode] = isnull(ls.DisplayName,'n')
from APXUser.vSecurityPropertyLookupLS ls
join APXUser.vSecClass sc on
	sc.ClassificationID = ls.PropertyID and
	ls.IsShort = 0
join APXUser.vSecurityPropertyLookupLS assetClass3 on
	assetClass3.PropertyID = @ClassificationID3 and
	assetClass3.SecurityID = ls.SecurityID and
	assetClass3.IsShort = 0
where sc.ClassificationName = @ClassificationName and
	isnull(ls.DisplayName,'n') = @KeyString

declare @PortfolioInceptionDate datetime
--declare @InceptionDates table (RowID int identity, ClassificationID int, ClassificationMemberID int, InceptionDate datetime)
create table #InceptionDates (RowID int identity, ClassificationID int, ClassificationMemberID int, InceptionDate datetime)

declare @temp table (OrderID int, ClassificationID int, ClassificationMemberID int, Classification1MemberOrder int, Classification2MemberOrder int, InceptionDate datetime)
declare @footerstring nvarchar(max)
declare @PerfSummary1 varbinary(max), @PerfSummary2 varbinary(max), @PerfSummary3 varbinary(max), @PerfSummary4 varbinary(max), @PerfSummary5 varbinary(max), @PerfSummary6 varbinary(max),
	@Cumulative1 varbinary(max), @Cumulative2 varbinary(max), @Cumulative3 varbinary(max), @Holdings varbinary(max)

declare @Hierarchy table (Classification1DisplayOrder int, Classification1ID int, Classification1MemberID int, Classification1DisplayName nvarchar(max),
	Classification2DisplayOrder int, Classification2ID int, Classification2MemberID int, Classification2DisplayName nvarchar(max),
	Classification3DisplayOrder int, Classification3ID int, Classification3MemberID int, Classification3DisplayName nvarchar(max))
insert @Hierarchy
select distinct 
	-- Classification 1
	[Classification1DisplayOrder] = s1.DisplayOrder,
	[Classification1ID] = @ClassificationID1,
	[Classification1MemberID] = s1.ClassificationMemberID,
	--[Classification1Label] = s1.Label,
	left(s1.Label,len(s1.Label) - patindex('%([0-9])%',s1.Label) + 1),

	-- Classification 2
	[Classification2DisplayOrder] = s2.DisplayOrder,
	[Classification2ID] = @ClassificationID2,
	[Classification2MemberID] = s2.ClassificationMemberID,
	left(s2.Label,len(s2.Label) - patindex('%([0-9])%',s2.Label) + 1),

	-- Classification 3
	[Classification3DisplayOrder] = s3.DisplayOrder,
	[Classification3ID] = @ClassificationID3,
	[Classification3MemberID] = s3.ClassificationMemberID,
	left(s3.Label,len(s3.Label) - patindex('%([0-9])%',s3.Label) + 1)
from APXUserCustom.AssetClassHierarchy a
left join APXUser.vSecClassMember s1 on 
	s1.ClassificationID = @ClassificationID1 and
	s1.Label = a.AssetClass1 
left join APXUser.vSecClassMember s2 on 
	s2.ClassificationID = @ClassificationID2 and
	s2.Label = a.AssetClass2
left join APXUser.vSecClassMember s3 on 
	s3.ClassificationID = @ClassificationID3 and
	s3.Label = a.AssetClass3

declare @footerTable table (PortfolioBaseIDOrder int, PortfolioBaseID int, FooterText nvarchar(max))
declare @MaxID int, @i int = 1, @PortfolioBaseID int, @PortfolioBaseIDOrder int
select @MaxID = MAX(PortfolioBaseIDOrder) from @reportData
while @i <= @MaxID
begin
	select @PortfolioBaseID = PortfolioBaseID, @PortfolioBaseIDOrder = PortfolioBaseIDOrder from @reportData where PortfolioBaseIDOrder = @i

	exec APXUser.pReportDataGetFromHandle @DataHandle, 'PerfSummary1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @PerfSummary1 out
	exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative1 out
	exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative2 out
	exec APXUser.pReportDataGetFromHandle @DataHandle, 'Cumulative3', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData = @Cumulative3 out

	select @PortfolioInceptionDate = InceptionToDatePeriodFromDate from APXUser.fPerformanceHistoryPeriod(@PerfSummary1)

	--insert @temp
	--select 1, @ClassificationID1, ph.ClassificationMemberID, ph.ClassificationMemberOrder, MIN(ph.PeriodFromDate)
	--from APXUser.fPerformanceHistory(@Cumulative1) ph
	--where ph.ClassificationMemberID is not null 
	--	and ph.IsIndex = 0
	--group by ph.ClassificationMemberID, ph.ClassificationMemberOrder
	--order by ph.ClassificationMemberOrder

	insert @temp
	select 2, @ClassificationID2, ph.ClassificationMemberID, ph.ClassificationMemberOrder, 0, MIN(ph.PeriodFromDate)
	from APXUser.fPerformanceHistory(@Cumulative2) ph
	where ph.ClassificationMemberID is not null 
		and ph.IsIndex = 0
	group by ph.ClassificationMemberID, ph.ClassificationMemberOrder

	insert @temp
	select 3, @ClassificationID3, ph.ClassificationMemberID, h.Classification2DisplayOrder, ph.ClassificationMemberOrder, MIN(ph.PeriodFromDate)
	from APXUser.fPerformanceHistory(@Cumulative3) ph
	join @filter filter on
		filter.ClassificationMemberID = ph.ClassificationMemberID and
		filter.ClassificationID = @ClassificationID3
	join @Hierarchy h on 
		h.Classification3ID = @ClassificationID3 and
		h.Classification3MemberID = ph.ClassificationMemberID
	where ph.ClassificationMemberID is not null 
		and ph.IsIndex = 0
		and filter.ClassificationMemberCode = 'y'
	group by ph.ClassificationMemberID, ph.ClassificationMemberOrder, h.Classification2DisplayOrder

	insert #InceptionDates
	select ClassificationID, ClassificationMemberID, InceptionDate from @temp 
	where InceptionDate > @PortfolioInceptionDate
	order by Classification1MemberOrder, Classification2MemberOrder asc
--select * from @temp
--select * from #InceptionDates
	select @footerstring = STUFF((
		select ', ' + convert(nvarchar(32),RowID) + ' - ' + 'since ' + convert(nvarchar(32),InceptionDate,101)
		from #InceptionDates
		for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

	insert into @footerTable
	select @PortfolioBaseIDOrder, @PortfolioBaseID, @footerstring
	delete from @temp

	truncate table #InceptionDates
	set @i = @i + 1
end

drop table #InceptionDates

select r.DataHandle,
	r.FirmLogo,
	r.FromDate,
	r.LegacyLocaleID,
	r.LocaleID,
	r.PortfolioBaseCode,
	r.PortfolioBaseID,
	r.PortfolioBaseIDOrder,
	r.ReportHeading1,
	r.ReportHeading2,
	r.ReportHeading3,
	r.ReportingCurrencyCode,
	r.ReportingCurrencyName,
	r.ThruDate,
	f.FooterText
from @reportData r
join @footerTable f on
	f.PortfolioBaseID = r.PortfolioBaseID and
	f.PortfolioBaseIDOrder = r.PortfolioBaseIDOrder

end

GO


