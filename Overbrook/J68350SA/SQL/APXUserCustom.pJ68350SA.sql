IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pJ68350SA]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pJ68350SA]
GO

create procedure [APXUserCustom].[pJ68350SA]
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@ToDate datetime,
	@ClassificationID int,
	@ReportingCurrencyCode char(2) = null,
	
	-- Optional parameters
	@FeeMethod int = null,
	@AnnualizeReturns char(1) = null,
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@LocaleID int = null
as begin
declare @ReportData varbinary(max)

exec APXUser.pSessionInfoSetGuid @SessionGuid
declare @DataHandle as uniqueidentifier = newid()

exec APXUser.pPerformanceHistoryPeriodBatch
	@DataHandle = @DataHandle,
	@DataName = 'PerformanceHistoryPeriod',
	@Portfolios = @Portfolios,
	@FromDate = @ToDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@FeeMethod = @FeeMethod,
	@AccruePerfFees = @AccruePerfFees,
	@AllocatePerfFees = @AllocatePerfFees,
	@AnnualizeReturns = @AnnualizeReturns,
	@LocaleID = @LocaleID

exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=0
-- ***************  Get Portfolio Overview Portfolio List ***************
declare @ReportPOData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'PerformanceHistoryPeriod', @ReportData = @ReportPOData out
SELECT DISTINCT
	DataHandle = @DataHandle,
	FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
	p.LocaleID,
	c.CurrencyName,
	a.ThruDate
FROM APXUser.fPerformanceHistoryPeriod(@ReportPOData) a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
join APXUser.vCurrency c on c.CurrencyCode = @ReportingCurrencyCode

end