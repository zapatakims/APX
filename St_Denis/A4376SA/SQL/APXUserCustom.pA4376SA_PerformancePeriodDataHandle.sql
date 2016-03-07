IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pA4376SA_PerformancePeriodDataHandle]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pA4376SA_PerformancePeriodDataHandle]
GO

create procedure [APXUserCustom].[pA4376SA_PerformancePeriodDataHandle]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	
	-- Optional parameters for sqlrep proc
	@FeeMethod int = null,
	@Period1 char(3) = null,
	@Period2 char(3) = null,
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AccruedInterestID smallint = null,		-- Use Settings
	@ShowMultiCurrency bit = null,			-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@OverridePortfolioSettings bit = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@UseACB bit = null,						-- Use Settings
	@DataHandleName1 nvarchar(max) = 'Performance',
	@DataHandleName2 nvarchar(max) = null
as
begin

declare @PerfFromDate1 datetime,
	@PerfFromDate2 datetime

-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData.
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @PerformanceHistoryData1 varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName1, @PortfolioBaseID=@PortfolioBaseID, @PortfolioBaseIDOrder=@PortfolioBaseIDOrder, @ReportData=@PerformanceHistoryData1 out
if @Period2 is not null
	begin
	declare @PerformanceHistoryData2 varbinary(max)
	exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName2, @PortfolioBaseID=@PortfolioBaseID, @PortfolioBaseIDOrder=@PortfolioBaseIDOrder, @ReportData=@PerformanceHistoryData2 out
	end
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @ShowFees bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	-- Parameters internal to this proc that are derived from other parameters.
	@FeeMethod = @FeeMethod, -- Need for determining @ShowFees.
	@ShowFees = @ShowFees out, -- A boolean that is derived from @FeeMethod
	@UseACB = @UseACB out

declare @PerfThruDate datetime, @PerfFromDate datetime, @InceptionDate datetime
select @PerfThruDate = ThruDate, @PerfFromDate = FromDate, @InceptionDate = InceptionDate from APXUser.fPerformanceHistoryDetail(@PerformanceHistoryData1)

set @PerfFromDate1 = APXSSRS.fFromDate(@PerfFromDate1, @PerfThruDate, @Period1)
if @Period1 = 'itd' set @PerfFromDate1 = @PerfFromDate


set @PerfFromDate2 = APXSSRS.fFromDate(@PerfFromDate2, @PerfThruDate, @Period2)
if @Period2 = 'itd' select @PerfFromDate2 = FromDate from APXUser.fPerformanceHistoryDetail(@PerformanceHistoryData2)

if @Period2 is null
	begin
	SELECT 
		FromDate = @PerfFromDate1,
		p.FormatReportingCurrency,
		p.LegacyLocaleID,
		p.LocaleID,
		--ShowAccruedInterest = APXUser.fShowAccruedInterestOnPerformanceReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID),
		--ShowFees = @ShowFees,
		--ShowMultiCurrency = @ShowMultiCurrency,
		--UseACB = @UseACB,
		Period,
		PeriodOrder,
		[MarketValueDate1] = bmv.BeginningMarketValue,--case when Period = 'itd' then bmv.EndingMarketValue else bmv.BeginningMarketValue end,
		--AccruedInterestDate1,
		--Additions,
		--Withdrawals,
		--TransfersIn,
		--TransfersOut,
		[NetFlows] = perf.Amount,
		--Dividends,
		--Interest,
		--AccruedInterestDelta,
		--RealizedGainLossOnMval,
		--UnrealizedGainLossOnMval,
		--PriceRealizedGainLossOnMval,
		--PriceUnrealizedGainLossOnMval,
		--FXRealizedGainLossOnMval,
		--FXUnrealizedGainLossOnMval,
		--ManagementFees,
		--ManagementFeesPaidByClient,
		--PortfolioFees,
		--PortfolioFeesPaidByClient,
		--MarketValueDate2,
		[MarketValueDate2] = emv.EndingMarketValue,
		--AccruedInterestDate2,
		perf.PortfolioBaseID
	FROM (	SELECT PeriodType = 'Period1',
				Period = @Period1,
				PeriodOrder = 1,
				phd.PortfolioBaseID,
				[Amount] = sum(isnull(phd.NetTransfers,0) + isnull(phd.NetAdditions,0))
			from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1) phd
			group by phd.PortfolioBaseID
			)	perf
	join (select * from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1) where PeriodThruDate = @PerfThruDate) emv on
		emv.PortfolioBaseID = perf.PortfolioBaseID
	join (select * from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1) where PeriodFromDate = @PerfFromDate1) bmv on
		bmv.PortfolioBaseID = perf.PortfolioBaseID
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = perf.PortfolioBaseID
	ORDER BY emv.PortfolioBaseIDOrder, emv.ClassificationMemberID, emv.ClassificationMemberName
	end
else
	begin
	SELECT 
		FromDate = @PerfFromDate2,
		p.FormatReportingCurrency,
		p.LegacyLocaleID,
		p.LocaleID,
		--ShowAccruedInterest = APXUser.fShowAccruedInterestOnPerformanceReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID),
		--ShowFees = @ShowFees,
		--ShowMultiCurrency = @ShowMultiCurrency,
		--UseACB = @UseACB,
		Period,
		PeriodOrder,
		[MarketValueDate1] = bmv.BeginningMarketValue,--case when Period = 'itd' then bmv.EndingMarketValue else bmv.BeginningMarketValue end,
		--perf.AccruedInterestDate1,
		--perf.Additions,
		--perf.Withdrawals,
		--perf.TransfersIn,
		--perf.TransfersOut,
		[NetFlows] = perf.Amount,
		--perf.Dividends,
		--perf.Interest,
		--perf.AccruedInterestDelta,
		--perf.RealizedGainLossOnMval,
		--perf.UnrealizedGainLossOnMval,
		--perf.PriceRealizedGainLossOnMval,
		--perf.PriceUnrealizedGainLossOnMval,
		--perf.FXRealizedGainLossOnMval,
		--perf.FXUnrealizedGainLossOnMval,
		--perf.ManagementFees,
		--perf.ManagementFeesPaidByClient,
		--perf.PortfolioFees,
		--perf.PortfolioFeesPaidByClient,
		--perf.MarketValueDate2,
		[MarketValueDate2] = emv.EndingMarketValue,
		--perf.AccruedInterestDate2,
		perf.PortfolioBaseID
	FROM (	SELECT PeriodType = 'Period1',
				Period = @Period1,
				PeriodOrder = 1,
				perf.PortfolioBaseID,
				[Amount] = sum(isnull(perf.NetTransfers,0) + isnull(perf.NetAdditions,0)),
				[FromDate] = @PerfFromDate1
			from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1) perf
			group by perf.PortfolioBaseID
			
			UNION ALL
			
			SELECT  PeriodType = 'Period2',
				Period = @Period2,
				PeriodOrder = 2,
				perf.PortfolioBaseID,
				[Amount] = sum(isnull(perf.NetTransfers,0) + isnull(perf.NetAdditions,0)),
				[FromDate] = @PerfFromDate2
			FROM APXUser.fPerformanceHistoryDetail(@PerformanceHistoryData2) perf
			group by perf.PortfolioBaseID

	)	perf
		join (select * 
				from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1)
				where PeriodThruDate = @PerfThruDate) emv on
			emv.PortfolioBaseID = perf.PortfolioBaseID
		join (select * 
				from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData1) 
				where PeriodFromDate = @PerfFromDate1
				union all
			select *
				from APXUser.fPerformanceHistoryDetail (@PerformanceHistoryData2)
				where PeriodFromDate = @PerfFromDate2) bmv on
			bmv.PortfolioBaseID = perf.PortfolioBaseID and
			bmv.PeriodFromDate = perf.FromDate
		join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
			p.PortfolioBaseID = perf.PortfolioBaseID
	ORDER BY emv.PortfolioBaseIDOrder, emv.ClassificationMemberID, emv.ClassificationMemberName
	end
--select @PerfFromDate1, @PerfFromDate2
--select * from APXUser.fPerformanceHistoryDetail(@PerformanceHistoryData2)
end

GO


