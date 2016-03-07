IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pG876637SA]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pG876637SA]
GO

create procedure [APXUserCustom].[pG876637SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@Date datetime,
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@ClassificationID int = null,
	@ClassificationID1 int = null,
	@ClassificationID2 int = null,
	@ClassificationID3 int = null,
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
	@ShowMultiCurrency bit = 0,			-- Use Settings
	--@ShowIndustrySector bit = null,			-- Use Settings
	--@ShowIndustryGroup bit = null,			-- Use Settings
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
--declare @timer datetime = getdate()
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
--select 1, GETDATE() - @timer
declare @FirmLogoTable table(PortfolioBaseID dtID primary key, FirmLogo nvarchar(72))
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fAppraisal(@ReportData) ) p
--select 2, GETDATE() - @timer
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @CostIsAdjusted bit
declare @SecuritySymbolIsVisible bit
declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	--@ShowIndustryGroup = @ShowIndustryGroup out,
	--@ShowIndustrySector = @ShowIndustrySector out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	@ShowSecuritySymbol = @ShowSecuritySymbol out,			-- Needed for detemining @SecuritySymbolIsVisible.
	-- Parameters internal to this proc that are derived from other parameters.
	@BondCostBasisID = @BondCostBasisID,					-- Effective value determined above. Need for determining @CostIsAdjusted.
	@CostIsAdjusted = @CostIsAdjusted out,					-- A boolean that is derived from multi-valued @BondCostBasisID.
	@SecuritySymbolIsVisible = @SecuritySymbolIsVisible out,-- A boolean that is derived from multi-valued @ShowSecuritySymbol.
	@YieldOptionID = @YieldOptionID,						-- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out					-- A boolean that is derived from multi-valued @YieldOptionID.
--select 3, GETDATE() - @timer
declare @PortTbl table(
	PortfolioBaseID dtID,
	LegacyLocaleID dtID,
	LocaleID dtID,
	AccruedInterestID dtID,
	CurrencyPrecision dtID,
	FormatReportingCurrency nvarchar(255),
	PrefixedPortfolioBaseCode nvarchar(255),
	PortfolioBaseCode nvarchar(255),
	ReportHeading1 nvarchar(255),
	ReportHeading2 nvarchar(255),
	ReportHeading3 nvarchar(255),
	ReportingCurrencyCode char(2),
	ReportingCurrencyName nvarchar(255),
	ReportingCurrencySymbol nvarchar(255),
	Primary Key (PortfolioBaseID)
)
insert into @PortTbl (
		PortfolioBaseID,
	LegacyLocaleID,
	LocaleID,
	AccruedInterestID,
	CurrencyPrecision,
	FormatReportingCurrency,
	PrefixedPortfolioBaseCode,
	PortfolioBaseCode,
	ReportHeading1,
	ReportHeading2,
	ReportHeading3,
	ReportingCurrencyCode,
	ReportingCurrencyName,
	ReportingCurrencySymbol)
select DISTINCT
	a.PortfolioBaseID,
	LegacyLocaleID,
	LocaleID,
	AccruedInterestID,
	CurrencyPrecision,
	FormatReportingCurrency,
	PrefixedPortfolioBaseCode,
	PortfolioBaseCode,
	ReportHeading1,
	ReportHeading2,
	ReportHeading3,
	ReportingCurrencyCode,
	ReportingCurrencyName,
	ReportingCurrencySymbol
from @FirmLogoTable a
	join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p
	on a.PortfolioBaseID = p.PortfolioBaseID
--select 4, GETDATE() - @timer
-- Get the decoration text into a local table
declare @Decor table(APXLocaleID dtID primary key, ShortText nvarchar(255), UnsupervisedText nvarchar(255))
insert into @Decor (APXLocaleID, ShortText, UnsupervisedText)
select q.LocaleID, APXSSRS.fShortSecurityNameDecoration(q.LocaleID), 
	case when IsNull(@IncludeUnsupervisedAssets, 0) = 1 then APXSSRS.fUnsupervisedSecurityTypeNameDecoration(q.LocaleID) else '' end
from (
	select distinct p.LocaleID
	from @PortTbl p
	where @LocaleID is null
	union
	select @LocaleID
	where @LocaleID is not null
	) q
	
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

--select 5, GETDATE() - @timer
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
	ClassificationMemberCode = classification.KeyString,
	ClassificationMemberDisplayOrder = classification.DisplayOrder,
	ClassificationMemberDisplayName = classification.DisplayName,
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
	a.LocalPrice,
	-- The Unit Cost to display based on the effective value of @ShowMultiCurrency.
	-- If the effective value of @ShowMultiCurrency is 'true' then LocalUnitCost.
	-- Otherwise UnitCost.
	EffectiveUnitCost = case @ShowMultiCurrency
		when 1 then a.LocalUnitCost
		else a.UnitCost end,
	a.LocalUnitCost,
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
    -- The security name concatenated with a line feed and the bond description or mutual fund.
    FullSecurityName =
		APXSSRS.fSecurityName1LangPerLocale(s.SecurityName, s.LocalCurrencyISOCode, s.MaturityDate, p.LocaleID, s.IsFFX, a.IsShortPosition, decor.ShortText) + 
        APXSSRS.fSecurityName2(a.BondDescription, a.MutualFund, @MFBasisIncludeReinvest, 1),
    
    s.IncomeTypeCode,
	-- The Industry Group Display Order that can be used for grouping and sorting.
	-- If the effective value of @ShowIndustryGroup is 'true', then Security.IndustryGroupDisplayOrder.
	-- Otherwise null.
	IndustryGroupDisplayOrder = industryGroup.DisplayOrder,
		
	-- Indicates if the 'IndustryGroup' grouping is visible.
	-- If the effective value of @ShowIndustryGroup is 'true', and Security.IndustryGroupCode <> '-3' (N/A), then 'true'.
	-- Otherwise 'false'.
	--IndustryGroupIsVisible = convert(bit, case
	--	when (industryGroup.KeyString <> '-3') then 1
	--	else 0 end),
	IndustryGroupIsVisible = convert(bit,case when AssetClass3 is null then 0 
		when (industryGroup.KeyString = 'NA') then 0
		else 1 end),
		
	-- The Industry Group Name.
	-- If the effective value of @ShowIndustryGroup is 'true', then Security.IndustryGroupName.
	-- Otherwise null.
	--IndustryGroupName = industryGroup.DisplayName,
	IndustryGroupName = left(industryGroup.DisplayName,len(industryGroup.DisplayName) - patindex('%([0-9])%',industryGroup.DisplayName) + 1),
	
	-- The Industry Sector Display Order that can be used for grouping and sorting.
	-- If the effective value of @ShowIndustrySector is 'true', then Security.SectorDisplayOrder.
	-- Otherwise null.
	IndustrySectorDisplayOrder = industrySector.DisplayOrder,
		
	-- Indicates if the 'IndustrySector' grouping is visible.
	-- If the effective value of @ShowIndustrySector is 'true', and Security.IndustrySectorCode <> '000' (N/A), then 'true'.
	-- Otherwise 'false'.
	--IndustrySectorIsVisible = convert(bit, case
	--	when (industrySector.KeyString <> '000') then 1
	--	else 0 end),
	IndustrySectorIsVisible = convert(bit, case when AssetClass2 is null then 0 
		when (industrySector.KeyString = 'NA') then 0
		else 1 end),
		
	-- The Industry Sector Name.
	-- If the effective value of @ShowIndustrySector is 'true', then Security.SectorName.
	-- Otherwise null.
	--IndustrySectorName = industrySector.DisplayName,
	IndustrySectorName = left(industrySector.DisplayName,len(industrySector.DisplayName) - patindex('%([0-9])%',industrySector.DisplayName) + 1),
	
	s.IsUnsupervised,
	
	s.IsZeroMarketValue,
	
	p.LegacyLocaleID,
	--Column added to include Local Currency Accrued Interest in a Multi-currency report
	a.LocalAccruedInterest,
	
	s.LocalCurrencyCode,
	s.LocalCurrencyISOCode,
	s.LocalCurrencySymbol,
		
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
	PortfolioBaseCode = case when CHARINDEX('@',p.PrefixedPortfolioBaseCode,0) = 0 then p.PortfolioBaseCode
		else null end,
	
	a.PortfolioBaseIDOrder,
	
	a.Quantity,
	
	a.ReportDate,
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	reportingCurr.ISOCode [ReportingCurrencyISOCode],

	InverseExchange = case when reportingCurr.ISOCode <> s.LocalCurrencyISOCode then 1 else 0 end,
	InverseExchangeRate = 1 / SpotRate,--[APXUserCustom].[fGetFxRate](s.LocalCurrencyCode, p.ReportingCurrencyCode, @Date),

	reportingCurr.CurrencySymbol [ReportingCurrencySymbol],
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
	
	--SecurityTypeName = securityType.DisplayName + case s.IsUnsupervised when 1 then decor.UnsupervisedText else '' end,
	SecurityTypeName = left(securityType.DisplayName,len(securityType.DisplayName) - patindex('%([0-9])%',securityType.DisplayName) + 1)
		 + case s.IsUnsupervised when 1 then decor.UnsupervisedText else '' end,

	SecurityTypeIsVisible = convert(bit, case when AssetClass1 is null then 0 
		when securityType.KeyString = 'NA' then 0 
		else 1 end),

	-- The effective value of @ShowMultiCurrency.
	-- If @ShowMultiCurrency is specified (but not null), then @ShowMultiCurrency.
	-- Otherwise Configuration.ShowMultiCurrency.
	ShowMultiCurrency = @ShowMultiCurrency,
	ShowQuantity = APXSSRS.fShowQuantity(s.CanBeBoughtSold,p.ReportingCurrencyCode,s.PrincipalCurrencyCode),
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
	left join @PortTbl p on p.PortfolioBaseID = a.PortfolioBaseID
	join APXUser.vCurrency reportingCurr on reportingCurr.CurrencyCode = p.ReportingCurrencyCode
	left join @Decor decor on decor.APXLocaleID = p.LocaleID 
	left join @FirmLogoTable flogo on	flogo.PortfolioBaseID = a.PortfolioBaseID
	left join APXUser.vSecurityVariantLangPerLocale s on
		s.APXLocaleID = p.LocaleID and
		s.SecurityID = a.SecurityID and
		s.SectypeCode = a.SecTypeCode and
		s.IsShort = a.IsShortPosition
	left join APXUser.vSecurityPropertyLookupLSLangPerLocale industrySector on 
		industrySector.APXLocaleID = p.LocaleID and
		(industrySector.PropertyID = @ClassificationID2) and
		industrySector.SecurityID = a.SecurityID and
		industrySector.isShort = a.IsShortPosition 
	left join APXUser.vSecurityPropertyLookupLSLangPerLocale industryGroup on 
		industryGroup.APXLocaleID = p.LocaleID and
		(industryGroup.PropertyID = @ClassificationID3) and
		industryGroup.SecurityID = a.SecurityID and
		industryGroup.isShort = a.IsShortPosition
	left join APXUser.vSecurityPropertyLookupLSLangPerLocale securityType on 
		securityType.APXLocaleID = p.LocaleID and
		(securityType.PropertyID = @ClassificationID1) and
		securityType.SecurityID = a.SecurityID and
		securityType.isShort = a.IsShortPosition
	left join APXUser.vSecurityPropertyLookupLSLangPerLocale classification on
		classification.APXLocaleID = p.LocaleID and
		classification.PropertyID = @ClassificationID and
		classification.SecurityID = a.SecurityID and
		classification.IsShort = a.IsShortPosition
	left join APXUserCustom.AssetClassHierarchy ah on ah.AssetClass3 = industryGroup.DisplayName and
		industrySector.DisplayName = ah.AssetClass2 and
		securityType.DisplayName = ah.AssetClass1
order by
	a.PortfolioBaseIDOrder,
	s.IsUnsupervised,
	s.LocalCurrencySequenceNo,
	securityType.DisplayOrder,
	industrySector.DisplayOrder,
	industryGroup.DisplayOrder,
	s.MaturityDate,
	FullSecurityName,
	a.LotNumber
--select 7, GETDATE() - @timer
end

GO


