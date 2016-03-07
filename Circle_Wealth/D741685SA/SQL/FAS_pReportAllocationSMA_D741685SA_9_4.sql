USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]    Script Date: 03/12/2015 14:41:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]
GO

USE [APXFirm]
GO

/****** Object:  StoredProcedure [APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]    Script Date: 03/12/2015 14:41:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
declare @sessionGUID nvarchar(48)
exec [APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]
-- Required Parameters
@SessionGuid = @SessionGuid,
@Portfolios = 'abrom',
@Date = '6/30/2013',
@ReportingCurrencyCode = 'us'
*/

CREATE procedure [APXUserCustom].[FAS_pReportAllocationSMA_D741685SA_9_4]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@Date datetime,
	@ClassificationID int = -4,
	
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@CompositeFromDate datetime = null,
	@CompositeToDate datetime = null,
	@IncludeClosedPortfolios bit = null,
	@IncludeUnsupervisedAssets bit = null,
	@BondCostBasisID int = null,			-- Use Settings (0)
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AccruedInterestID int = null,			-- Use Settings (0)
	@YieldOptionID int = null,				-- Use Settings (0)
	@MFBasisIncludeReinvest bit = null,		-- Use Settings
	@ShowMultiCurrency bit = null,			-- Use Settings
	@ShowIndustrySector bit = null,			-- Use Settings
	@ShowIndustryGroup bit = null,			-- Use Settings
	@UseSettlementDate bit = null,			-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@OverridePortfolioSettings bit = null	
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier 
set @DataHandle = newid()
-- 2. Execute the sqlrep proc that will fill the @ReportData XML.
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
exec APXUser.pAppraisalBatch
    
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @Date,
  
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@CompositeFromDate = @CompositeFromDate,
	@CompositeToDate = @CompositeToDate,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@AccruedInterestID = @AccruedInterestID,
	@YieldOptionID = @YieldOptionID out,
	@BondCostBasisID = @BondCostBasisID out,
	@MFBasisIncludeReinvest = @MFBasisIncludeReinvest out,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@OverridePortfolioSettings = @OverridePortfolioSettings

declare @consolidate bit
set @consolidate = 0
select @consolidate = case SUBSTRING(@Portfolios,1,1) when  '@' then 1 when '&' then 1 else 0 end
declare @GroupBaseID as int 
set @GroupBaseID = null
if @consolidate = 1
	begin
	declare @Portfolios2 nvarchar(max) 
	set @Portfolios2 =  '+' + @Portfolios
	declare @ExcludePortfolioHoldings bit
	set @ExcludePortfolioHoldings = 1
	exec APXUser.pAppraisalBatch
		-- Required Parameters
		@DataHandle = @DataHandle,
		@DataName = 'AppraisalParent',
		@Portfolios = @Portfolios2,
		@Date = @Date,
		-- Optional Parameters
		@ReportingCurrencyCode = @ReportingCurrencyCode out,
		@CompositeFromDate = @CompositeFromDate,
		@CompositeToDate = @CompositeToDate,
		@IncludeClosedPortfolios = @IncludeClosedPortfolios,
		@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
		@AccruedInterestID = @AccruedInterestID,
		@YieldOptionID = @YieldOptionID out,
		@BondCostBasisID = @BondCostBasisID out,
		@MFBasisIncludeReinvest = @MFBasisIncludeReinvest out,
		@UseSettlementDate = @UseSettlementDate out,
		@LocaleID = @LocaleID,
		@PriceTypeID = @PriceTypeID,
		@OverridePortfolioSettings = @OverridePortfolioSettings,
		@ExcludePortfolioHoldings = @ExcludePortfolioHoldings
	end
-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 0
--  Get Appraisal Data
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Appraisal', @ReportData = @ReportData out
if @consolidate = 1
	begin
	declare @ReportData2 varbinary(max)
	exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'AppraisalParent', @ReportData = @ReportData2 out
	select DISTINCT @GroupBaseID  = PortfolioBaseID from APXUser.fAppraisal(@ReportData2)
	end
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@BondCostBasisID = @BondCostBasisID,
	@YieldOptionID = @YieldOptionID,						-- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out					-- A boolean that is derived from multi-valued @YieldOptionID.
declare @NC_Desc char(14)
set @NC_Desc = 'Not Classified'
declare @Undefined int
set @Undefined = 2000000000 -- used for undefined classifiction members

declare @FirmLogoTable table(PortfolioBaseID dtID primary key, FirmLogo nvarchar(72))
if @consolidate=1
begin
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fAppraisal(@ReportData2) ) p
end
else
begin
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fAppraisal(@ReportData) ) p
end

-- 4. Select the columns for the report.
SELECT
	FirmLogo = flogo.FirmLogo,
	ClassificationMemberDisplayName = tblmain.ClassificationMemberName,
	ClassificationMemberDisplayOrder = tblmain.ClassificationMemberOrder,
	p.FormatReportingCurrency,
	p.LocaleID,
	tblmain.MarketValue,
	tblmain.PortfolioBaseID,
	tblmain.PortfolioBaseIDOrder,
	p.PrefixedPortfolioBaseCode,
	tblmain.WeightedYield,
	tblmain.Yield,
	YieldIsCurrent = @YieldIsCurrent,
	tblmain.ZeroMarketValue,
	tblmain.AccruedInterest,
	tblmain.AccruedInterestIsVisible,
	tblmain.AnnualIncome,
	tblmain.Quantity,
	tblmain.FullSecurityName,
	tblmain.EffectiveCostBasis,
	tblmain.EffectivePrice,
	tblmain.EffectiveUnitCost,
	tblmain.EffectiveMaturityDate,
	tblmain.EstMaturityDate,
	tblmain.FormatLocalCurrency,
	tblmain.FormatPerUnit,
	tblmain.FormatQuantity,
	tblmain.IncomeTypeCode,
	tblmain.IndustryGroupDisplayOrder ,
	tblmain.IndustryGroupIsVisible,
	tblmain.IndustryGroupName ,
	tblmain.IndustrySectorDisplayOrder ,
	tblmain.IndustrySectorIsVisible,
	tblmain.IndustrySectorName ,
	tblmain.IsUnsupervised ,
	tblmain.IsZeroMarketValue ,
	tblmain.LocalCurrencyCode ,
	tblmain.LocalCurrencyDisplayOrder ,
	tblmain.LocalCurrencyName ,
	tblmain.LocalMarketValue,
	tblmain.LocalZeroMarketValue,
	tblmain.MaturityDate,
	tblmain.MFBasisIncludeReinvest,
	tblmain.ReportDate,
	tblmain.SecurityID,
	tblmain.SecuritySymbol,
	tblmain.SecuritySymbolIsVisible,
	tblmain.SecurityTypeDisplayOrder,
	tblmain.SecurityTypeName,
	tblmain.ShowMultiCurrency ,
	tblmain.TradeDate, 
	tblmain.UnrealizedGainLoss,
	tblmain.UnrealizedGainLossFX,
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	tblmain.ROW
FROM (SELECT
		h.ClassificationMemberName,
		h.ClassificationMemberOrder,
		MarketValue = sum(h.MarketValue),
		PortfolioBaseID = ISNULL(@GroupBaseID,MAX(h.PortfolioBaseID)),
		PortfolioBaseIDOrder = MAX(h.PortfolioBaseIDOrder),
		WeightedYield = sum(h.MarketValue * h.Yield),
		Yield = case sum(h.MarketValue)
					when 0 
					then 0
					else sum(h.MarketValue* h.Yield) / sum(h.MarketValue)
				end,
		ZeroMarketValue = sum(h.ZeroMarketValue),
		h.AccruedInterest,
		h.AccruedInterestIsVisible,
		AnnualIncome = sum(h.AnnualIncome),
		Quantity = sum(h.Quantity),
		FullSecurityName = h.FullSecurityName,
		EffectiveCostBasis = sum(h.EffectiveCostBasis),
		EffectivePrice = sum(h.EffectivePrice),
		EffectiveUnitCost = sum(h.EffectiveUnitCost),
		UnrealizedGainLoss = SUM(UnrealizedGainLoss),
		EffectiveMaturityDate = max(h.EffectiveMaturityDate),
		EstMaturityDate = max(h.EstMaturityDate),
		FormatPerUnit = max(h.FormatPerUnit),
		FormatLocalCurrency = max(h.FormatLocalCurrency),
		FormatQuantity = max(h.FormatQuantity),
		IncomeTypeCode = max(h.IncomeTypeCode),
		IndustryGroupDisplayOrder = max(h.IndustryGroupDisplayOrder),
		IndustryGroupIsVisible = h.IndustryGroupIsVisible,
		IndustryGroupName = max(h.IndustryGroupName),
		IndustrySectorDisplayOrder = max(h.IndustrySectorDisplayOrder),
		IndustrySectorIsVisible = h.IndustrySectorIsVisible,
		IndustrySectorName = max(h.IndustrySectorName),
		IsUnsupervised = h.IsUnsupervised,
		IsZeroMarketValue = h.IsZeroMarketValue,
		LocalCurrencyCode = max(h.LocalCurrencyCode),
		LocalCurrencyDisplayOrder = max(h.LocalCurrencyDisplayOrder),
		LocalCurrencyName = max(h.LocalCurrencyName),
		LocalMarketValue = max(h.LocalMarketValue),
		LocalZeroMarketValue = max(h.LocalZeroMarketValue),
		MaturityDate = max(h.MaturityDate),
		MFBasisIncludeReinvest = max(h.MFBasisIncludeReinvest),
		ReportDate = max(h.ReportDate),
		SecurityID = max(h.SecurityID),
		SecuritySymbol = max(h.SecuritySymbol),
		SecuritySymbolIsVisible = 1,--h.SecuritySymbolIsVisible,
		SecurityTypeDisplayOrder = max(h.SecurityTypeDisplayOrder),
		SecurityTypeName = max(h.SecurityTypeName),
		ShowMultiCurrency = 1,--max(h.ShowMultiCurrency ),
		TradeDate = max(h.TradeDate) ,
		UnrealizedGainLossFX = SUM(h.UnrealizedGainLossFX),
		h.ROW
	FROM (		SELECT 
				a.ClassificationMemberName,
				a.ClassificationMemberOrder,
				a.PortfolioBaseID,
				a.PortfolioBaseIDOrder,
				a.MarketValue,
				a.ZeroMarketValue,
				a.Yield,
				a.AccruedInterest,
				a.AccruedInterestIsVisible,
				a.AnnualIncome,
				a.Duration,
				a.Quantity,
				[UnrealizedGainLoss] = case when a.SecurityTypeCode = 'peus' then NULL else a.UnrealizedGainLoss end,
				a.FullSecurityName,
				[EffectiveCostBasis] = case when a.SecurityTypeCode = 'peus' then NULL else a.EffectiveCostBasis end,
				a.EffectivePrice,
				[EffectiveUnitCost] = case when a.SecurityTypeCode = 'pe' then NULL else a.EffectiveUnitCost end,
				a.EffectiveMaturityDate,
				a.EstMaturityDate,
				a.FormatPerUnit,
				a.FormatLocalCurrency,
				a.FormatQuantity,
				a.IncomeTypeCode,
				a.IndustryGroupDisplayOrder,
				a.IndustryGroupIsVisible,
				a.IndustryGroupName,
				a.IndustrySectorDisplayOrder,
				a.IndustrySectorIsVisible,
				a.IndustrySectorName,
				a.IsUnsupervised,
				a.IsZeroMarketValue,
				a.LocalCurrencyCode,
				a.LocalCurrencyDisplayOrder,
				a.LocalCurrencyName,
				a.LocalMarketValue,
				a.LocalZeroMarketValue,
				a.MaturityDate,
				a.MFBasisIncludeReinvest,
				a.ReportDate,
				a.SecurityID,
				a.SecuritySymbol,
				a.SecuritySymbolIsVisible,
				a.SecurityTypeDisplayOrder,
				a.SecurityTypeName,
				a.ShowMultiCurrency ,
				a.TradeDate, 
				a.UnrealizedGainLossFX,
				a.ROW
			FROM
			(	select  
					MarketValue = isnull(a.MarketValue,0) + isnull(a.AccruedInterest,0),
					ZeroMarketValue = isnull(a.ZeroMarketValue,0) + isnull(a.AccruedInterest,0),
					a.Yield,
					ClassificationMemberCode = null,--classification.KeyString,
					ClassificationMemberName = sp.DisplayName,
					ClassificationMemberOrder = ISNULL(sp.DisplayOrder,@Undefined),
					a.PortfolioBaseID,
					a.PortfolioBaseIDOrder,
					a.AccruedInterest,
					a.AnnualIncome,
					a.Duration,
					a.Quantity,
					FullSecurityName = s.SecurityName + (case when a.IsShortPosition = 1 then ' (Short)' else '' end) +
						(case when isnull(a.BondDescription, case when @MFBasisIncludeReinvest = 0 then a.MutualFund else null end) is null then '' else APX.fNewLine(1) + isnull(a.BondDescription, case when @MFBasisIncludeReinvest = 0 then a.MutualFund else null end) end),
					EffectiveCostBasis = a.LocalCostBasis,
					EffectivePrice = a.LocalPrice,
					EffectiveUnitCost = a.LocalUnitCost,
					UnrealizedGainLoss = case
						when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLoss, 0) = 0 then null
						else a.UnrealizedGainLoss end,
					AccruedInterestIsVisible = convert(bit, case
						when s.IsBond = 1 then (case when APXUser.fShowAccruedInterestOnAllReports(@OverridePortfolioSettings, @AccruedInterestID, (select AccruedInterestID from APXUser.vPortfolioSettingEx p where p.PortfolioID = a.PortfolioBaseID)) = 1 then 1 else 0 end)
						else 0 end),
					a.EffectiveMaturityDate,
					a.EstMaturityDate,
					FormatPerUnit = convert(varchar(13), case @ShowMultiCurrency
					when 1 then case when s.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', s.LocalCurrencyPrecision) end
					else case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end end),
					FormatLocalCurrency = convert(varchar(13), case @ShowCurrencyFullPrecision
					when 1 then (case @ShowMultiCurrency 
								when 1 then case when s.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', s.LocalCurrencyPrecision) end
								else case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end 
							 end) else '#,0' end),
					FormatQuantity = case when s.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', s.QuantityPrecision) end,
					s.IncomeTypeCode,
					IndustryGroupDisplayOrder = industryGroup.DisplayOrder,
					IndustryGroupIsVisible = convert(bit, case
						when @ShowIndustryGroup = 1 and (industryGroup.KeyString is null or industryGroup.KeyString <> '-3') then 1
						else 0 end),
					IndustryGroupName = industryGroup.DisplayName,
					IndustrySectorDisplayOrder = industrySector.DisplayOrder,
					IndustrySectorIsVisible = convert(bit, case
						when @ShowIndustrySector = 1 and (industrySector.KeyString is null or industrySector.KeyString <> '000') then 1
						else 0 end),
					IndustrySectorName = industrySector.DisplayName,
					s.IsUnsupervised,
					s.IsZeroMarketValue,
					s.LocalCurrencyCode,
					LocalCurrencyDisplayOrder = case @ShowMultiCurrency
					when 1 then s.LocalCurrencySequenceNo
					else null end,
					--a.LocalCurrencyInterestOrDividendRate,
					LocalCurrencyName = case @ShowMultiCurrency
					when 1 then s.LocalCurrencyName
					else null end,
					a.LocalMarketValue,
					a.LocalZeroMarketValue,
					s.MaturityDate,
					MFBasisIncludeReinvest = @MFBasisIncludeReinvest,
					a.ReportDate,
					s.SecurityID,
					SecuritySymbol = APXUser.fDisplaySecuritySymbol(s.SecuritySymbol, 1),
					SecuritySymbolIsVisible = 1,
					SecurityTypeDisplayOrder = securityType.DisplayOrder,
					SecurityTypeCode,
					SecurityTypeName = securityType.DisplayName + case s.IsUnsupervised when 1 then ' - UNSUPERVISED' else '' end,
					ShowMultiCurrency = @ShowMultiCurrency,
					a.TradeDate, 
					UnrealizedGainLossFX = case
					when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossFX, 0) = 0 then null
					else a.UnrealizedGainLossFX end, 
					UnrealizedGainLossPrice = case
					when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossPrice, 0) = 0 then null
					else a.UnrealizedGainLossPrice end, 
					UseSettlementDate = @UseSettlementDate,
					YieldIsCurrent = @YieldIsCurrent,
					ROW = 1
					from APXUser.fAppraisal(@ReportData) a
							join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
								p.PortfolioBaseID = a.PortfolioBaseID
							join APXUser.vSecurityVariant s on
								s.SecurityID = a.SecurityID and
								s.SectypeCode = a.SecTypeCode and
								s.IsShort = a.IsShortPosition
							join APXUser.vSecurityProperty securityType on 
								securityType.PropertyID = -19 and
								securityType.SecurityID = a.SecurityID and
								securityType.isShort = a.IsShortPosition
							left join APXUser.vSecurityProperty industrySector on 
								industrySector.PropertyID = -6 and
								industrySector.SecurityID = a.SecurityID and
								industrySector.isShort = a.IsShortPosition
							left join APXUser.vSecurityProperty industryGroup on 
								industryGroup.PropertyID = -7  and
								industryGroup.SecurityID = a.SecurityID and
								industryGroup.isShort = a.IsShortPosition
							left join APXUser.vSecurityProperty classification on
								classification.PropertyID = @ClassificationID and -- can be null
								classification.SecurityID = a.SecurityID and
								classification.IsShort = a.IsShortPosition
							LEFT JOIN APXSSRS.vSecurityPropertyReclassified sp on
								sp.propertyid = @ClassificationID and
								sp.SecurityID = a.SecurityID and
								sp.IsShort = a.IsShortPosition
							where (APX.fPortfolioCustomLabel(a.PortfolioBaseID,'$issma','n') <> 'y')
					
			  union all
			  
				select 
					MarketValue = SUM(isnull(sma.MarketValue,0) + isnull(sma.AccruedInterest,0)),
					ZeroMarketValue = SUM(isnull(sma.ZeroMarketValue,0) + isnull(sma.AccruedInterest,0)),
					Yield = case sum(isnull(sma.MarketValue,0) + isnull(sma.AccruedInterest,0))
							when 0 
							then 0
							else sum((isnull(sma.MarketValue,0) + isnull(sma.AccruedInterest,0))* sma.Yield) / sum(isnull(sma.MarketValue,0) + isnull(sma.AccruedInterest,0))
							end,
					ClassificationMemberCode = null,--classification.KeyString,
					ClassificationMemberName = MAX(COALESCE(cm.ClassificationMemberName, @NC_Desc)),
					ClassificationMemberOrder = MAX(COALESCE(cm.ClassificationMemberOrder, @Undefined)),
					sma.PortfolioBaseID,
					sma.PortfolioBaseIDOrder,
					AccruedInterest = MAX(sma.AccruedInterest),
					AnnualIncome = sum(isnull(sma.AnnualIncome,0)),
					Duration = max(sma.Duration),
					Quantity = sum(sma.quantity),
					FullSecurityName = cl.Value,
					EffectiveCostBasis = sum(sma.LocalCostBasis),
					EffectivePrice = max(sma.LocalPrice),
					EffectiveUnitCost = max(sma.LocalUnitCost),
					UnrealizedGainLoss = sum(sma.UnrealizedGainLoss),
					AccruedInterestIsVisible = null,--convert(bit, case
						--when s.IsBond = 1 then (case when APXUser.fShowAccruedInterestOnAllReports(@OverridePortfolioSettings, @AccruedInterestID, (select AccruedInterestID from APXUser.vPortfolioSettingEx p where p.PortfolioID = a.PortfolioBaseID)) = 1 then 1 else 0 end)
						--else 0 end),
					EffecctiveMaturityDate = null,-- a.EffectiveMaturityDate,
					EstMaturityDate = null,--a.EstMaturityDate,
					FormatPerUnit = null,
					FormatLocalCurrency = '#,0',
					FormatQuantity = null,--case when s.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', s.QuantityPrecision) end,
					IncomeTypeCode = null,--s.IncomeTypeCode,
					IndustryGroupDisplayOrder = max(industryGroup.DisplayOrder),
					IndustryGroupIsVisible = convert(bit, case
						when @ShowIndustryGroup = 1 and (industryGroup.KeyString is null or industryGroup.KeyString <> '-3') then 1
						else 0 end),
					IndustryGroupName = max(industryGroup.DisplayName),
					IndustrySectorDisplayOrder = max(industrySector.DisplayOrder),
					IndustrySectorIsVisible = convert(bit, case
						when @ShowIndustrySector = 1 and (industrySector.KeyString is null or industrySector.KeyString <> '000') then 1
						else 0 end),
					IndustrySectorName = max(industrySector.DisplayName),
					IsUnsupervised = 0,--s.IsUnsupervised,
					IsZeroMarketValue = 0,--s.IsZeroMarketValue,
					LocalCurrencyCode = null,--s.LocalCurrencyCode,
					LocalCurrencyDisplayOrder = 1,--case @ShowMultiCurrency
					--when 1 then s.LocalCurrencySequenceNo
					--else null end,
					--a.LocalCurrencyInterestOrDividendRate,
					LocalCurrencyName = null,--case @ShowMultiCurrency
					--when 1 then s.LocalCurrencyName
					--else null end,
					LocalMarketValue = sum(sma.LocalMarketValue),
					LocalZeroMarketValue = sum(sma.LocalZeroMarketValue),
					MaturityDate = null,--s.MaturityDate,
					MFBasisIncludeReinvest = 1,--@MFBasisIncludeReinvest,
					ReportDate = null,--sma.ReportDate,
					SecurityID = s.SecurityID,
					SecuritySymbol = null,--APXUser.fDisplaySecuritySymbol(s.SecuritySymbol, 1),
					SecuritySymbolIsVisible = 1,
					SecurityTypeDisplayOrder = null,--securityType.DisplayOrder,
					SecurityTypeCode,
					SecurityTypeName = null,--securityType.DisplayName + case s.IsUnsupervised when 1 then ' - UNSUPERVISED' else '' end,
					ShowMultiCurrency = null,--@ShowMultiCurrency,
					TradeDate = null,--sma.TradeDate, 
					UnrealizedGainLossFX = null,--case
					--when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossFX, 0) = 0 then null
					--else a.UnrealizedGainLossFX end, 
					UnrealizedGainLossPrice = null,--case
					--when a.IsReportingCurrencyCash = 1 and isnull(a.UnrealizedGainLossPrice, 0) = 0 then null
					--else a.UnrealizedGainLossPrice end, 
					UseSettlementDate = null,--@UseSettlementDate,
					YieldIsCurrent = null,--@YieldIsCurrent
					Row = 2
					from APXUser.fAppraisal(@ReportData) sma
							join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
								p.PortfolioBaseID = sma.PortfolioBaseID
							join APXUser.vSecurityVariant s on
								s.SecurityID = sma.SecurityID and
								s.SectypeCode = sma.SecTypeCode and
								s.IsShort = sma.IsShortPosition
							join APXUser.vSecurityProperty assetclass on 
								assetclass.PropertyID = -4 and
								assetclass.SecurityID = sma.SecurityID and
								assetclass.isShort = sma.IsShortPosition
							left join APXUser.vSecurityProperty industrySector on 
								industrySector.PropertyID = -6 and
								industrySector.SecurityID = sma.SecurityID and
								industrySector.isShort = sma.IsShortPosition
							left join APXUser.vSecurityProperty industryGroup on 
								industryGroup.PropertyID = -7  and
								industryGroup.SecurityID = sma.SecurityID and
								industryGroup.isShort = sma.IsShortPosition
							left join APXUser.vSecurityProperty classification on
								classification.PropertyID = @ClassificationID and -- can be null
								classification.SecurityID = sma.SecurityID and
								classification.IsShort = sma.IsShortPosition
							LEFT JOIN APXSSRS.fSMAClassifications() cm on
								cm.ClassificationID = @ClassificationID and 
								sma.PortfolioBaseID = cm.PortfolioBaseID
							join apxuser.vPortfolioBaseLabels cl on
								sma.PortfolioBaseID = cl.PortfolioBaseID
								and cl.Label = '$smaname'
				where (APX.fPortfolioCustomLabel(sma.PortfolioBaseID,'$issma','n') = 'y')	
				group by sma.PortfolioBaseIDOrder, sma.PortfolioBaseID, s.IsBond,cl.Value
				,s.MaturityDate,sma.ReportDate,s.SecurityID,sma.TradeDate,industryGroup.KeyString,industrySector.KeyString,SecurityTypeCode
			) a
		) h
		GROUP BY h.ClassificationMemberOrder, h.ClassificationMemberName,h.ROW,
		h.AccruedInterest,
		h.AccruedInterestIsVisible,h.IsUnsupervised,h.IsZeroMarketValue,
		h.IndustryGroupIsVisible,
		h.IndustrySectorIsVisible,
		h.FullSecurityName
	) tblmain
	left join @FirmLogoTable flogo on
		flogo.PortfolioBaseID = tblmain.PortfolioBaseID
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = (select PortfolioBaseID from APXUser.vPortfolioBase where PortfolioBaseCode=REPLACE(REPLACE(@Portfolios,'@',''),'+',''))
ORDER BY tblmain.row,tblmain.ClassificationMemberOrder, tblmain.ClassificationMemberName

end


GO

