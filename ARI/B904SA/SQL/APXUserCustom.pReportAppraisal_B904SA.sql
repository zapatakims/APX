USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pReportAppraisal_B904SA]    Script Date: 12/15/2013 17:46:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportAppraisal_B904SA]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportAppraisal_B904SA]
GO

USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pReportAppraisal_B904SA]    Script Date: 12/15/2013 17:46:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- $Header: $/APX/Trunk/APX/APXDatabase/APXFirm/sp/SSRSReports/pReportAppraisal.sql  2012-06-18 12:18:06 PDT  ADVENT/astanchi $
-- This proc provides colunms that can be used in an APX Apprasial report.  It's main features are:
-- 1. It accepts all standard APX report parameters and resolves them to their correct values.
-- 2. It provides the correct column content based on the effective values of these parameters.
-- 3. It follows all APX conventions for presenting column content (e.g. DirectSpotRate, UnrealizedGainLoss) 
CREATE procedure [APXUserCustom].[pReportAppraisal_B904SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@Date datetime,
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@ClassificationID1 int = null,
	@ClassificationID2 int = null,
	@CompositeFromDate datetime = null,
	@CompositeToDate datetime = null,
	@FiscalYearStartDate datetime = null,
	@IncludeClosedPortfolios bit = null,
	@IncludeUnsupervisedAssets bit = null,
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@ShowTaxLotsLumped bit = null,			-- Use Settings
	@AccruedInterestID int = null,			-- Use Settings (0)
	@YieldOptionID int = null,				-- Use Settings (0)
	@BondCostBasisID int = null,			-- Use Settings (0)
	@MFBasisIncludeReinvest bit = null,		-- Use Settings
	@ShowMultiCurrency bit = null,			-- Use Settings
	@ShowIndustrySector bit = null,			-- Use Settings
	@ShowIndustryGroup bit = null,			-- Use Settings
	@UseSettlementDate bit = null,			-- Use Settings
	@ShowCurrentMBSFace bit = null,			-- Use Settings
	@ShowCurrentTIPSFace bit = null,		-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@ShowSecuritySymbol char(1) = null,		-- Use Settings
	@OverridePortfolioSettings bit = null
	
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pAppraisal
    
	-- Required Parameters
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@Date = @Date,
    
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@CompositeFromDate = @CompositeFromDate,
	@CompositeToDate = @CompositeToDate,
	@FiscalYearStartDate = @FiscalYearStartDate,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@ShowTaxLotsLumped = @ShowTaxLotsLumped out,
	@AccruedInterestID = @AccruedInterestID,
	@YieldOptionID = @YieldOptionID out,
	@BondCostBasisID = @BondCostBasisID out,
	@MFBasisIncludeReinvest = @MFBasisIncludeReinvest out,
	@UseSettlementDate = @UseSettlementDate out,
	@ShowCurrentMBSFace = @ShowCurrentMBSFace out,
	@ShowCurrentTIPSFace = @ShowCurrentTIPSFace out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@OverridePortfolioSettings = @OverridePortfolioSettings
	
declare @FirmLogoTable table(PortfolioBaseID dtID primary key, FirmLogo nvarchar(72))
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fAppraisal(@ReportData) ) p
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @CostIsAdjusted bit
declare @SecuritySymbolIsVisible bit
declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@ShowIndustryGroup = @ShowIndustryGroup out,
	@ShowIndustrySector = @ShowIndustrySector out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	@ShowSecuritySymbol = @ShowSecuritySymbol out,			-- Needed for detemining @SecuritySymbolIsVisible.
	-- Parameters internal to this proc that are derived from other parameters.
	@BondCostBasisID = @BondCostBasisID,					-- Effective value determined above. Need for determining @CostIsAdjusted.
	@CostIsAdjusted = @CostIsAdjusted out,					-- A boolean that is derived from multi-valued @BondCostBasisID.
	@SecuritySymbolIsVisible = @SecuritySymbolIsVisible out,-- A boolean that is derived from multi-valued @ShowSecuritySymbol.
	@YieldOptionID = @YieldOptionID,						-- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out					-- A boolean that is derived from multi-valued @YieldOptionID.
-- 4. Select the columns for the report.
select
	a.AccruedInterest,
	-- TODO: This column is VERY expensive
	-- Indicates whether Accrued Interest is visible.
	-- Based on the effective value of @AccruedInterestID and Security.IsBond.
--	AccruedInterestIsVisible = convert(bit, case
--		when APXUser.fShowAccruedInterestOnAllReports(@OverridePortfolioSettings, @AccruedInterestID, portfolio.AccruedInterestID) = 1 and s.IsBond = 1 then 1
--		else 0 end),
	AccruedInterestIsVisible = convert(bit, case
		when s.IsBond = 1 then (case when APXUser.fShowAccruedInterestOnAllReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID) = 1 then 1 else 0 end)
		else 0 end),
	a.AnnualIncome,
	ClassificationMemberCode1 = classification1.KeyString,
	ClassificationMemberDisplayOrder1 = classification1.DisplayOrder,
	ClassificationMemberDisplayName1 = classification1.DisplayName,
	ClassificationMemberCode2 = classification2.KeyString,
	ClassificationMemberDisplayOrder2 = classification2.DisplayOrder,
	ClassificationMemberDisplayName2 = classification2.DisplayName,
	-- Indicates if the bond's cost basis is adjusted.
	-- Based on the effective value of @BondCostBasisID.
	CostIsAdjusted = @CostIsAdjusted,
	-- For 3.0
	---- The direct spot rate in the form that it is normally quoted.
	--DirectSpotRate = case p.DisplayDirectRate
	--	when 1 then (1/a.SpotRate)
	--	else a.SpotRate end,
	-- The direct spot rate.
	-- Removed potential inversion in 4.0 because p.DisplayRate no longer exists.
	-- DirectSpotRate = a.SpotRate,
	
	-- How the spot rate should be displayed on a report
	-- Round to 9 decimal places because that is the number of decimal places APX stores
  -- APXUser.vFXRate is too slow, use sqlcar.rep InvertSpotRate instead
	DisplaySpotRate = Round(case a.InvertSpotRate when 1 then (1/a.SpotRate) else a.SpotRate end ,9),
		
	a.Duration,
		
	-- The Cost Basis to display based on the effective value of @ShowMultiCurrency.
	-- If the effective value of @ShowMultiCurrency is 'true' then LocalCostBasis.
	-- Otherwise CostBasis.
	EffectiveCostBasis = case @ShowMultiCurrency
		when 1 then a.LocalCostBasis
		else a.CostBasis end,
	
	a.EffectiveMaturityDate,
		
	-- The Price to display based on the effective value of @ShowMultiCurrency.
	-- If the effective value of @ShowMultiCurrency is 'true' then LocalPrice.
	-- Otherwise Price.
	EffectivePrice = case @ShowMultiCurrency
		when 1 then a.LocalPrice
		else a.Price end,
		
	-- The Unit Cost to display based on the effective value of @ShowMultiCurrency.
	-- If the effective value of @ShowMultiCurrency is 'true' then LocalUnitCost.
	-- Otherwise UnitCost.
	EffectiveUnitCost = case @ShowMultiCurrency
		when 1 then a.LocalUnitCost
		else a.UnitCost end,
	
	a.EstMaturityDate,
	flogo.FirmLogo,	
	-- The precision format string for 'per unit' values (like Price and CostPerShare).
	-- If the effective value of @ShowMultiCurrency is 'true', then LocalCurrency.CurrencyPrecision.
	-- Otherwise ReportingCurrency.CurrencyPrecision.
	FormatPerUnit = convert(varchar(13), case @ShowMultiCurrency
		when 1 then case when s.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', s.LocalCurrencyPrecision) end
		else case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end end),
		
	-- The precision format string for values stated in their local currency (like LocalMarketValue and LocalCostBasis).
	-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'true', then LocalCurrency.CurrencyPrecision. 
	-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'false', then p.CurrencyPrecision.
	-- Otherwise zero decimals
	FormatLocalCurrency = convert(varchar(13), case @ShowCurrencyFullPrecision
		when 1 then (case @ShowMultiCurrency 
						when 1 then 
							case when s.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', s.LocalCurrencyPrecision) end
						else 
							case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end
					 end)
		else '#,0' end),
	-- The precision format string for 'quantity' values (like shares or par).
	-- Security.QuantityPrecision is always used.
	FormatQuantity = case when s.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', s.QuantityPrecision) end,
	p.FormatReportingCurrency,
    -- The security name concatenated with a line fee and the bond description or mutual fund.
    FullSecurityName =
		APXUserCustom.fSecurityName1(s.SecurityName, s.LocalCurrencyISOCode, s.MaturityDate, @LocaleID, s.IsFFX, a.IsShortPosition) + 
        APXUserCustom.fSecurityName2(a.BondDescription, a.MutualFund, @MFBasisIncludeReinvest, 1),
    
    s.IncomeTypeCode,
	-- The Industry Group Display Order that can be used for grouping and sorting.
	-- If the effective value of @ShowIndustryGroup is 'true', then Security.IndustryGroupDisplayOrder.
	-- Otherwise null.
	IndustryGroupDisplayOrder = case @ShowIndustryGroup
		when 1 then industryGroup.DisplayOrder
		else null end,
		
	-- Indicates if the 'IndustryGroup' grouping is visible.
	-- If the effective value of @ShowIndustryGroup is 'true', and Security.IndustryGroupCode <> '-3' (N/A), then 'true'.
	-- Otherwise 'false'.
	IndustryGroupIsVisible = convert(bit, case
		when @ShowIndustryGroup = 1 and (industryGroup.KeyString is null or industryGroup.KeyString <> '-3') then 1
		else 0 end),
		
	-- The Industry Group Name.
	-- If the effective value of @ShowIndustryGroup is 'true', then Security.IndustryGroupName.
	-- Otherwise null.
	IndustryGroupName = case @ShowIndustryGroup
		when 1 then industryGroup.DisplayName
		else null end,
	
	-- The Industry Sector Display Order that can be used for grouping and sorting.
	-- If the effective value of @ShowIndustrySector is 'true', then Security.SectorDisplayOrder.
	-- Otherwise null.
	IndustrySectorDisplayOrder = case @ShowIndustrySector
		when 1 then industrySector.DisplayOrder
		else null end,
		
	-- Indicates if the 'IndustrySector' grouping is visible.
	-- If the effective value of @ShowIndustrySector is 'true', and Security.IndustrySectorCode <> '000' (N/A), then 'true'.
	-- Otherwise 'false'.
	IndustrySectorIsVisible = convert(bit, case
		when @ShowIndustrySector = 1 and (industrySector.KeyString is null or industrySector.KeyString <> '000') then 1
		else 0 end),
		
	-- The Industry Sector Name.
	-- If the effective value of @ShowIndustrySector is 'true', then Security.SectorName.
	-- Otherwise null.
	IndustrySectorName = case @ShowIndustrySector
		when 1 then industrySector.DisplayName
		else null end,
	
	s.IsUnsupervised,
	
	s.IsZeroMarketValue,
	
	--Column added to include Local Currency Accrued Interest in a Multi-currency report
	a.LocalAccruedInterest,
	
	s.LocalCurrencyCode,
		
	-- The Local Currency Display Order that can be used for grouping and sorting.
	-- If the effective value of @ShowMultiCurrency is 'true', then Security.LocalCurrencySequenceNo.
	-- Otherwise null.
	LocalCurrencyDisplayOrder = case @ShowMultiCurrency
		when 1 then s.LocalCurrencySequenceNo
		else null end,
	
	a.LocalCurrencyInterestOrDividendRate,
		
	-- The Local Currency Name.
	-- If the effective value of @ShowMultiCurrency is 'true', then Security.LocalCurrencyName
	-- Otherwise null.
	LocalCurrencyName = case @ShowMultiCurrency
		when 1 then s.LocalCurrencyName
		else null end,
		
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID,
	
	a.LocalMarketValue,
	
	a.LocalZeroMarketValue,
	
	a.MarketValue,
	
	s.MaturityDate,
	
	-- The effective value of @MFBasisIncludeReinvest.
	-- If @MFBasisIncludeReinvest is specified (but not null), then @MFBasisIncludeReinvest.
	-- If @MFBasisIncludeReinvest is not specified (or null), then Configuration.MFBasisIncludeReinvest.
	MFBasisIncludeReinvest = @MFBasisIncludeReinvest,
	
	p.PrefixedPortfolioBaseCode,
	
	a.PortfolioBaseIDOrder,
	
	a.Quantity,
	
	a.ReportDate,
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	s.SecurityID,
	
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
	
	SecurityTypeDisplayOrder = securityType.DisplayOrder,
	
	SecurityTypeName = securityType.DisplayName + case s.IsUnsupervised when 1 then ' - UNSUPERVISED' else '' end,
	
	-- The effective value of @ShowMultiCurrency.
	-- If @ShowMultiCurrency is specified (but not null), then @ShowMultiCurrency.
	-- Otherwise Configuration.ShowMultiCurrency.
	ShowMultiCurrency = @ShowMultiCurrency,
	ShowQuantity = APXUserCustom.fShowQuantity(s.CanBeBoughtSold,p.ReportingCurrencyCode,s.PrincipalCurrencyCode),
	ShowYield = s.ShowYield,
	a.TradeDate,
	
	-- The standard APX Unrealized Gain/Loss.
	-- The stanadard APX convention is to always hide (null) certain Unrealized Gain/Loss values.
	UnrealizedGainLoss = case
		when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLoss, 0) = 0 then null
		else a.UnrealizedGainLoss end, 
	
	-- The standard APX FX Unrealized Gain/Loss.
	-- The stanadard APX convention is to always hide (null) certain Unrealized Gain/Loss values.
	UnrealizedGainLossFX = case
		when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossFX, 0) = 0 then null
		else a.UnrealizedGainLossFX end, 
	
	-- The standard APX Price Unrealized Gain/Loss.
	-- The stanadard APX convention is to always hide (null) certain Unrealized Gain/Loss values.
	UnrealizedGainLossPrice = case
		when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossPrice, 0) = 0 then null
		else a.UnrealizedGainLossPrice end, 
	
	-- The effective value of @UseSettlementDate.
	-- If @UseSettlementDate is specified (but not null), then @UseSettlementDate.
	-- Otherwise Configuration.UseSettlementDate.
	UseSettlementDate = @UseSettlementDate,
	
	a.Yield,
	YieldIsCurrent = @YieldIsCurrent,
	a.ZeroMarketValue
-- 5. Link to the appropriate views.
from APXUser.fAppraisal(@ReportData) a
	join APXUserCustom.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = a.PortfolioBaseID
	left join @FirmLogoTable flogo on
		flogo.PortfolioBaseID = a.PortfolioBaseID
	join APXUser.vSecurityVariant s on
		s.SecurityID = a.SecurityID and
		s.SectypeCode = a.SecTypeCode and
		s.IsShort = a.IsShortPosition
	join APXUser.vSecurityPropertyLookupLS industrySector on 
		industrySector.PropertyID = -6 and
		industrySector.SecurityID = a.SecurityID and
		industrySector.isShort = a.IsShortPosition
	join APXUser.vSecurityPropertyLookupLS industryGroup on 
		industryGroup.PropertyID = -7 and
		industryGroup.SecurityID = a.SecurityID and
		industryGroup.isShort = a.IsShortPosition
	join APXUser.vSecurityPropertyLookupLS securityType on 
		securityType.PropertyID = -19 and
		securityType.SecurityID = a.SecurityID and
		securityType.isShort = a.IsShortPosition
-- Too slow!!
	--join APXUser.vFXRate fx on
	--	fx.NumeratorCurrencyCode = p.ReportingCurrencyCode and
	--	fx.DenominatorCurrencyCode = s.LocalCurrencyCode and
	--	fx.PriceDate = a.ReportDate
	left join APXUser.vSecurityPropertyLookupLS classification1 on
		classification1.PropertyID = @ClassificationID1 and
		classification1.SecurityID = a.SecurityID and
		classification1.IsShort = a.IsShortPosition
	left join APXUser.vSecurityPropertyLookupLS classification2 on
		classification2.PropertyID = @ClassificationID2 and
		classification2.SecurityID = a.SecurityID and
		classification2.IsShort = a.IsShortPosition
where classification1.DisplayName <> 'Not Applicable' or classification2.DisplayName <> 'Not Applicable'		
order by
	a.PortfolioBaseIDOrder,
	s.IsUnsupervised,
	case @ShowMultiCurrency -- LocalCurrencyDisplayOrder
		when 1 then s.LocalCurrencySequenceNo
		else null end,
	securityType.DisplayOrder,
	case @ShowIndustrySector -- IndustrySectorDisplayOrder
		when 1 then industrySector.DisplayOrder
		else null end,
	case @ShowIndustryGroup -- IndustryGroupDisplayOrder
		when 1 then industryGroup.DisplayOrder
		else null end,
	s.MaturityDate,
	FullSecurityName,
	a.LotNumber
end


GO


