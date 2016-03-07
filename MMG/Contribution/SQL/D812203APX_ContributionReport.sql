if exists (select * from sys.objects where object_id = OBJECT_ID(N'[APXUserCustom].[D812203APX_ContributionReport]') AND type in (N'P', N'PC'))
drop procedure [APXUserCustom].[D812203APX_ContributionReport]
go

/*
declare	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max) = 'case',
	@FromDate datetime = '12/31/2007',
	@ToDate datetime = '12/31/2008'

exec [APXUserCustom].[D812203APX_ContributionReport] @SessionGuid = @SessionGuid, 
	@Portfolios = @Portfolios, 
	@FromDate = @FromDate, 
	@ToDate = @ToDate
*/

create procedure [APXUserCustom].[D812203APX_ContributionReport]
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,

	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AccruedInterestID int = null,			-- Use Settings (0)
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@OverridePortfolioSettings bit = null,

	@UseIRRCalc bit = null,
	@AccruePerfFees bit = null,
	@AllocatePerfFees bit = null,
	@AnnualizeReturns char(1) = null,
	@FeeMethod int = null,
	@UseACB bit = null						-- Use Settings
as
begin

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @PerfData varbinary(max)
	,@DataHandle uniqueidentifier = newid()

declare @ShowFees bit
exec APXUser.pGetEffectiveParameter
  
	-- Parameters passed into this proc that need to be resolved
	@AnnualizeReturns = @AnnualizeReturns out,
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
  
	-- Parameters internal to this proc that are derived from other parameters.
	@FeeMethod = @FeeMethod, -- Need for determining @ShowFees.
	@ShowFees = @ShowFees out -- A boolean that is derived from @FeeMethod.

--	Always do security-level performance.
exec APXUser.pPerformanceBatch @DataHandle = @DataHandle
	,@DataName = 'perf'
	,@Portfolios = @Portfolios
	,@FromDate = @FromDate
	,@ToDate = @ToDate
	,@ClassificationID = -8
	,@ReportingCurrencyCode = @ReportingCurrencyCode out
	,@FeeMethod = @FeeMethod
	,@UseACB = @UseACB
	,@AccruePerfFees = @AccruePerfFees
	,@AllocatePerfFees = @AllocatePerfFees
	,@AnnualizeReturns = @AnnualizeReturns
	,@UseIRRCalc = @UseIRRCalc
	,@OverridePortfolioSettings = @OverridePortfolioSettings
	,@AccruedInterestID = @AccruedInterestID
	,@PriceTypeID = @PriceTypeID
	,@LocaleID = @LocaleID

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=1
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'perf', @ReportData = @PerfData out

select 
	DataHandle = @DataHandle,
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
from APXUser.fReportDataIndex(@PerfData) a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
end