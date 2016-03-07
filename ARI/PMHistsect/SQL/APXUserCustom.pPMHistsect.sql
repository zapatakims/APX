if object_id('[APXUserCustom].[pPMHistsect]') is not null
	drop procedure [APXUserCustom].[pPMHistsect]
go
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = '@casetrade'
	,@ToDate datetime = '12/31/09'
	,@FeeMethod int
	,@ReportingCurrencyCode char(2) = 'us'

exec APXUserCustom.pPMHistsect @SessionGuid = @SessionGuid, @Portfolios = @Portfolios, @ToDate = @ToDate, @FeeMethod = @FeeMethod, @ReportingCurrencyCode = @ReportingCurrencyCode
*/
create procedure [APXUserCustom].[pPMHistsect]
	@SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32)
	,@ToDate datetime
	,@ReportingCurrencyCode dtCurrencyCode

	-- Optional parameters
	,@FeeMethod int = null
	,@AnnualizeReturns char(1) = null
	,@AccruePerfFees bit = null
	,@AllocatePerfFees bit = null
	,@LocaleID int = null

as begin

declare	@ReportData varbinary(max)
	,@DataHandle uniqueidentifier = newid()
	,@InceptionDate datetime
	,@YTDDate datetime

select @YTDDate = APXUser.fGetGenericDate('{edly}',@ToDate)

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- Get the effective parameter values for parameters that are not passed to pAppraisal.

exec APXUser.pGetEffectiveParameter @ReportingCurrencyCode = @ReportingCurrencyCode out
	,@FeeMethod = @FeeMethod out
	
exec APXUser.pPerformanceHistoryPeriod @ReportData = @ReportData out
	,@Portfolios = @Portfolios
	,@FromDate = @ToDate
	,@ToDate = @ToDate
	,@ClassificationID = -9

select @InceptionDate = InceptionToDatePeriodFromDate from APXUser.fPerformanceHistoryPeriod (@ReportData)

exec APXUser.pPerformanceHistoryPeriodBatch 
    -- Required Parameters 
    @DataHandle = @DataHandle, 
    @DataName = 'PerformanceHistorySummary', 
    @Portfolios = @Portfolios, 
    @FromDate = @ToDate, 
    @ToDate = @ToDate, 
    @ClassificationID = -9, 
    -- Optional Parameters 
    @ReportingCurrencyCode = @ReportingCurrencyCode out, 
    @FeeMethod = @FeeMethod, 
    @AccruePerfFees =@AccruePerfFees, 
    @AllocatePerfFees = @AllocatePerfFees, 
    @AnnualizeReturns = @AnnualizeReturns, 
    @LocaleID = @LocaleID
    
exec APXUser.pPerformanceHistoryBatch @DataHandle = @DataHandle
	,@DataName = 'PerformanceHistory'
	,@Portfolios = @Portfolios
	,@FromDate = @ToDate
	,@ToDate = @ToDate
	,@ClassificationID = -9
	,@IntervalLength = 1
	,@InceptionToDate = 1
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@LocaleID = @LocaleID

exec APXUser.pPerformanceHistoryBatch @DataHandle = @DataHandle
	,@DataName = 'PerformanceHistoryYTD'
	,@Portfolios = @Portfolios
	,@FromDate = @YTDDate
	,@ToDate = @ToDate
	,@ClassificationID = -9
	,@IntervalLength = 3
	,@InceptionToDate = 0
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@LocaleID = @LocaleID

exec APXUser.pPerformanceHistoryDetailBatch @DataHandle = @DataHandle
	,@DataName = 'PerformanceHistoryDetail'
	,@Portfolios = @Portfolios
	,@FromDate = @ToDate
	,@ToDate = @ToDate
	,@ClassificationID = -9
	,@InceptionToDate = 1
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@LocaleID = @LocaleID

exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 1

exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistory', @ReportData = @ReportData out

select DataHandle = @DataHandle,
	FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
	a.FromDate,
	p.LocaleID,
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.ReportHeading1,	
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
    p.ReportingCurrencyName,
	a.ThruDate
FROM APXUser.fReportDataIndex(@ReportData) a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder

end