IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pH68350A]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pH68350A] 
GO 

/*
declare @SessionGuid nvarchar(max)
exec APXUser.pSessionCreate 'admin','advs', @SessionGuid = @SessionGuid out
exec APXUserCustom.pH68350A @SessionGuid, 'case', '12/31/07','12/31/12'
*/

create procedure [APXUserCustom].[pH68350A]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,
	-- Optional parameters for sqlrep proc
	@BondCostBasisID int = null,			-- Use Settings (0)
	@IncludeCapitalGains int = null,		-- 1,2,3
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@Separate5YearGains bit = null,
	@UseSettlementDate bit = null,			-- Use Settings
	-- Other optional parameters
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@ShowMultiCurrency bit = null,			-- Use Settings
	@ShowSecuritySymbol varchar(1) = null	-- Use Settings
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
	,@YTDReportData varbinary(max)
	,@YTDFromDate datetime

select @YTDFromDate = APXUser.fGetGenericDate('{edly}',@ToDate)
exec APXUser.pRealizedGainLoss
    
	-- Required Parameters
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
    
	-- Optional Parameters
	@BondCostBasisID = @BondCostBasisID out,
	@IncludeCapitalGains = @IncludeCapitalGains,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@Separate5YearGains = @Separate5YearGains,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID

exec APXUser.pRealizedGainLoss
    
	-- Required Parameters
	@ReportData = @YTDReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @YTDFromDate,
	@ToDate = @ToDate,
    
	-- Optional Parameters
	@BondCostBasisID = @BondCostBasisID out,
	@IncludeCapitalGains = @IncludeCapitalGains,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@Separate5YearGains = @Separate5YearGains,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID

declare @FirmLogoTable table(PortfolioBaseID dtID primary key, FirmLogo nvarchar(72))
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fRealizedGainLoss(@ReportData) ) p
-- Get the decoration text into a local table
declare @Decor table(APXLocaleID dtID primary key, ShortText nvarchar(255))
insert into @Decor (APXLocaleID, ShortText)
select q.LocaleID, APXSSRS.fShortSecurityNameDecoration(q.LocaleID)
from (
	select distinct p.LocaleID
	from @FirmLogoTable a
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on p.PortfolioBaseID = a.PortfolioBaseID
	where @LocaleID is null
	union
	select @LocaleID
	where @LocaleID is not null
	) q
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @CostIsAdjusted bit
declare @SecuritySymbolIsVisible bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	@ShowSecuritySymbol = @ShowSecuritySymbol out,			-- Needed for detemining @SecuritySymbolIsVisible.
	-- Parameters internal to this proc that are derived from other parameters.
	@BondCostBasisID = @BondCostBasisID,					-- Effective value determined above. Need for determining @CostIsAdjusted.
	@CostIsAdjusted = @CostIsAdjusted out,					-- A boolean that is derived from multi-valued @BondCostBasisID.
	@SecuritySymbolIsVisible = @SecuritySymbolIsVisible out	-- A boolean that is derived from multi-valued @ShowSecuritySymbol.
--select GETDATE()
--declare @timer as datetime = getdate()
-- 4. Select the columns for the report.
SELECT
	r.Amortization,
	avgcost.AverageCostCode,
	r.CloseDate,
	r.CostBasis,
	-- Indicates if the bond's cost basis is adjusted.
	-- Based on the effective value of @BondCostBasisID.
	CostIsAdjusted = @CostIsAdjusted,
		
	flogo.FirmLogo,
	r.HasQuantity,
	
	-- The precision format string for 'quantity' values (like shares or par).
	-- Security.QuantityPrecision is always used.
	FormatQuantity = case when s.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', s.QuantityPrecision) end,
	
	-- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
	-- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
	-- Otherwise zero (0).
	p.FormatReportingCurrency,
  
	r.IsCapitalGain,
	p.LegacyLocaleID,
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID,
	
	r.OpenDate,
	
	-- @IncludeCapitalGains == 3 means to include the capital gains on a separate page.
	-- PageBreakForCapitalGains can be used as a Grouping/Sorting field in the RDL file.
	PageBreakForCapitalGains = convert(tinyint, case @IncludeCapitalGains
		when 2 then (case when r.IsCapitalGain = 1 then 2 else 1 end)
		else 1 end),
    p.PrefixedPortfolioBaseCode,
	r.PortfolioBaseIDOrder,
	r.PortfolioTransactionID,
	r.Proceeds,
	r.Quantity,
	r.RealizedGainLoss,
	ytd.RealizedGainLoss [YTDGainLoss],
	r.RealizedGainLossFX,
	r.RealizedGainLossPrice,
	r.RealizedGainLoss5T,
	r.RealizedGainLossLT,
	r.RealizedGainLossMT,
	r.RealizedGainLossST,
	
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	
	SecurityName = s.SecurityName + (case when r.IsShortPosition = 1 then decor.ShortText else '' end),
		
	SecurityName2 = r.BondDescription,
	
	-- The SecuritySymbol to display based on the effective value of @ShowSecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'n', then null.
	-- If the effective value of @ShowSecuritySymbol is 'y', then the first 12 characters of Security.SecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'l', then the first 25 characters of Security.SecuritySymbol.
	-- Otherwise Security.SecuritySymbol.
	SecuritySymbol = APXUser.fDisplaySecuritySymbol(s.SecuritySymbol, @ShowSecuritySymbol),
	
	-- Indicates if the SecuritySymbol should be visible based on the effective value of @ShowSecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'n', then 'false'.
	-- Otherwise 'true'.
	SecuritySymbolIsVisible = @SecuritySymbolIsVisible,
	
	-- The effective value of @ShowMultiCurrency.
	-- If @ShowMultiCurrency is specified (but not null), then @ShowMultiCurrency.
	-- Otherwise Configuration.ShowMultiCurrency.
	ShowMultiCurrency = @ShowMultiCurrency,
	r.ThruDate,
	
	-- The effective value of @UseSettlementDate.
	-- If @UseSettlementDate is specified (but not null), then @UseSettlementDate.
	-- Otherwise Configuration.UseSettlementDate.
	UseSettlementDate = @UseSettlementDate
-- 5. Link to the appropriate views.
from APXUser.fRealizedGainLoss(@ReportData) r
	join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = r.PortfolioBaseID
	join APXUser.vSecurityVariantLangPerLocale s on
		s.SecurityID = r.SecurityID and
		s.SectypeCode = r.SecTypeCode and
		s.IsShort = r.IsShortPosition and
		s.APXLocaleID = p.LocaleID
	left join @FirmLogoTable flogo on
		flogo.PortfolioBaseID = r.PortfolioBaseID
	join APXSSRS.fPortfolioBaseAverageCostCode() avgcost on
		avgcost.PortfolioBaseID = r.PortfolioBaseID
   	join @Decor decor on decor.APXLocaleID = p.LocaleID
   	left join APXUser.fRealizedGainLoss(@YTDReportData) ytd on
   		ytd.PortfolioBaseID = r.PortfolioBaseID and
   		ytd.SecurityID = r.SecurityID
-- sort order impacts the RDL which uses aggregate function last()
order by PortfolioBaseIDOrder, IsCapitalGain, CloseDate, SecurityName, SecurityName2, OpenDate, RealizedGainLoss, r.LotNumber
--select GETDATE(), GETDATE() - @timer
end
