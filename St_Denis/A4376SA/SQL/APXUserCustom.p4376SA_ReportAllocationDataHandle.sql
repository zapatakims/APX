
/****** Object:  StoredProcedure [APXUserCustom].[p4376SA_ReportAllocationDataHandle]    Script Date: 01/21/2015 11:44:49 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[p4376SA_ReportAllocationDataHandle]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[p4376SA_ReportAllocationDataHandle]
GO

CREATE procedure [APXUserCustom].[p4376SA_ReportAllocationDataHandle]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	@ClassificationID int, -- = null,
	@ReportingCurrencyCode dtCurrencyCode,
	-- Optional parameters for sqlrep proc
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@YieldOptionID int = null,				-- Use Settings (0)
	@LocaleID int = null,					-- Use Portfolio Settings
	
	-- Other optional parameters
	@FixedIncomeOnly bit = 0,
	@AssetClasses nvarchar(max) = null,		-- A comma-delimited version of an SSRS multi-valued parameter.
	@DataHandleName nvarchar(max) = 'Appraisal',
	@MFBasisIncludeReinvest bit = null
as
begin
--declare @timer datetime = getdate()
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData.
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@ReportData out
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@YieldOptionID = @YieldOptionID, -- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out -- A boolean that is derived from multi-valued @YieldOptionID.



--Get the `CA` security type market value
declare @CAmv float
SET @CAmv = 
(select SUM(ZeroMarketValue) + SUM(AccruedInterest) FROM ApxUser.fAppraisal(@ReportData) rd
where rd.SecTypeCode = 'ca')

set @CAmv = 0 --	2015-04-22 AZK uncommented to restore cash market values in Allocation Summary.

declare @CashDisplayName nvarchar(72) 
set @CashDisplayName = (select top 1 v.MemberName from ApxUser.fAppraisal(@ReportData) rd INNER JOIN
ApxUser.vSecurityVariant vs on vs.SecurityID = rd.SecurityID and vs.IsShort = rd.IsShortPosition and vs.SecTypeCode = rd.SecTypeCode
JOIN ApxUser.vClassificationMemberEx v on vs.AssetClassCode = v.Label and v.ClassificationID = -4
where rd.SecTypeCode = 'ca')

-- 4. Select the columns for the report.
select
	ClassificationMemberName = max(IsNull(l.LookupLabel, h.ClassificationMemberName)),
	ClassificationMemberOrder = h.ClassificationMemberOrder,
	ClassificationName = max(pl.DisplayName),
	FormatReportingCurrency = max(p.FormatReportingCurrency),
	LegacyLocaleID = max(p.LegacyLocaleID),
	LocaleID = max(p.LocaleID),
    MarketValue = sum(h.MarketValueTotal),
    PercentAssets = sum(h.PercentAssetsTotal),
	h.PortfolioBaseIDOrder,
	WeightedYield = sum(h.Yield),
	ShowYield = MAX(CAST(h.ShowYield as INT)),
    Yield = case sum(h.MarketValueTotal) when 0 then 0 else SUM(h.Yield) / sum(h.MarketValueTotal) end,
	YieldIsCurrent = @YieldIsCurrent,
	ZeroMarketValue = sum(h.ZeroMarketValueTotal), 
	CashAssetClassName = @CashDisplayName,
	CAsectypeadjustment = @CAmv
from (
		select
			PortfolioBaseIDOrder, PortfolioBaseID, ClassificationMemberName, ClassificationMemberOrder, ClassificationMemberID,
			MarketValueTotal, PercentAssetsTotal, ShowYield, Yield, ZeroMarketValueTotal --  * -- TODO: Specify only what you need
		from APXSSRS.fHoldings(@AssetClasses, @ClassificationID, @FixedIncomeOnly, @LocaleID, @MFBasisIncludeReinvest, @ReportData)
	 ) h
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
	p.PortfolioBaseID = h.PortfolioBaseID
join dbo.vAoPropertyLangPerLocale pl on
	pl.APXLocaleID = p.LocaleID and pl.PropertyID = @ClassificationID
left join dbo.vAoPropertyLookupLangPerLocale l on 
	l.APXLocaleID = p.LocaleID and l.PropertyID = @ClassificationID and l.PropertyLookupID = h.ClassificationMemberID
where h.PortfolioBaseID = @PortfolioBaseID	and
	h.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
	group by
		h.PortfolioBaseIDOrder, 
		h.ClassificationMemberOrder,
		h.ClassificationMemberName
	order by
		h.PortfolioBaseIDOrder,
		h.ClassificationMemberOrder,
		h.ClassificationMemberName
/* These are multi-currency fields that might be needed later.
		DirectSpotRate = a.SpotRate,
		
		-- How the spot rate should be displayed on a report
		-- Round to 9 decimal places because that is the number of decimal places APX stores
		DisplaySpotRate = Round(case when fx.ShowInverted = 1 then 1 / a.SpotRate else a.SpotRate end,9),
		
		-- The precision format string for values stated in their local currency (like LocalMarketValue and LocalCostBasis).
		-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'true', then LocalCurrency.CurrencyPrecision. 
		-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'false', then ReportingCurrency.CurrencyPrecision.
		-- Otherwise zero decimals
		FormatLocalCurrency = convert(varchar(13), case @ShowCurrencyFullPrecision
			when 1 then (case @ShowMultiCurrency 
							when 1 then 
								case when s.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', s.LocalCurrencyPrecision) end
							else 
								case when reportingCurrency.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', reportingCurrency.CurrencyPrecision) end
						 end)
			else '#,0' end),
		
		a.LocalAccruedInterest,
		
		-- The Local Currency Display Order that can be used for grouping and sorting.
		-- If the effective value of @ShowMultiCurrency is 'true', then Security.LocalCurrencySequenceNo.
		-- Otherwise null.
		LocalCurrencyDisplayOrder = case @ShowMultiCurrency
			when 1 then s.LocalCurrencySequenceNo
			else null end,		
		
		-- The Local Currency Name.
		-- If the effective value of @ShowMultiCurrency is 'true', then Security.LocalCurrencyName
		-- Otherwise null.
		LocalCurrencyName = case @ShowMultiCurrency
			when 1 then s.LocalCurrencyName
			else null end,
		
		a.LocalMarketValue,
*/
end


GO


