if object_id('[APXUserCustom].[pReportTransactionActivity]') is not null
	drop procedure [APXUserCustom].[pReportTransactionActivity]
go
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = 'case'
	,@FromDate datetime = '12/31/10'
	,@ToDate datetime = '01/31/13'
exec APXUserCustom.pReportTransactionActivity @SessionGuid = @SessionGuid, @Portfolios = @Portfolios, @FromDate = @FromDate, @ToDate = @ToDate
*/
create procedure [APXUserCustom].[pReportTransactionActivity]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,
	-- Optional parameters for sqlrep proc
	@BondCostBasisID int = null,					-- Use Settings
	@ReportingCurrencyCode dtCurrencyCode = null,	-- Use Settings
	@UseSettlementDate bit = null,					-- Use Settings
	-- Other optional parameters
	@TurnOffCloseDateProcessing bit = null,
	@IncludeUnsupervisedAssets bit = null,
	@LocaleID int = null,							-- Use Portfolio Settings
	@PriceTypeID int = null,
	@ShowCurrencyFullPrecision bit = null,			-- Use Settings
	@ShowMultiCurrency bit = null,					-- Use Settings
	@ShowSecuritySymbol char(1) = null				-- Use Settings
as
begin
--   Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @DataHandle as uniqueidentifier = newid()

declare @SecuritySymbolIsVisible bit
declare @CostIsAdjusted bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	@ShowMultiCurrency = @ShowMultiCurrency out,
	@ShowSecuritySymbol = @ShowSecuritySymbol out,			-- Needed for detemining @SecuritySymbolIsVisible.
	-- Parameters internal to this proc that are derived from other parameters.
	@BondCostBasisID = @BondCostBasisID,					-- Effective value determined above. Need for determining @CostIsAdjusted.
	@CostIsAdjusted = @CostIsAdjusted out,					-- A boolean that is derived from multi-valued @BondCostBasisID.
	@SecuritySymbolIsVisible = @SecuritySymbolIsVisible out	-- A boolean that is derived from multi-valued @ShowSecuritySymbol.

-- To get the effective value for 'Use Settings' parameters, specify 'out'.
exec APXUser.pTransactionActivityBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'TransactionActivity',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	-- Optional Parameters
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@TurnOffCloseDateProcessing = @TurnOffCloseDateProcessing,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID
--exec APXUser.pAppraisalBatch
--	-- Required Parameters
--	@DataHandle = @DataHandle,
--	@DataName = 'Appraisal',
--	@Portfolios = @Portfolios,
--	@Date = @ToDate,
--	-- Optional Parameters
--	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
--	@IncludeClosedPortfolios = @TurnOffCloseDateProcessing,
--	@ReportingCurrencyCode = @ReportingCurrencyCode out,
--	@UseSettlementDate = @UseSettlementDate out,
--	@LocaleID = @LocaleID,
--	@PriceTypeID = @PriceTypeID
exec APXUser.pRealizedGainLossBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'RealizedGainLoss',
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@TurnOffCloseDateProcessing = @TurnOffCloseDateProcessing,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@BondCostBasisID = @BondCostBasisID out,
	@UseSettlementDate = @UseSettlementDate out,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID
-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData = 1

declare @ReportPOData varbinary(max)
	,@ReportTranData varbinary(max)
-- exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Appraisal', @ReportData = @ReportPOData out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'TransactionActivity', @ReportData = @ReportTranData out

declare @PortfolioBaseCode nvarchar(32), @PortfolioBaseID int
declare @PortfolioMembers table (PortfolioBaseIDOrder int identity, PortfolioBaseID int)

select @PortfolioBaseCode = REPLACE(REPLACE(REPLACE(@Portfolios,'+',''),'@',''),'&','')

--	Consolidated Group/Composite
if CHARINDEX('+',@Portfolios) > 0
begin
select @PortfolioBaseID = PortfolioBaseID from APXUser.vPortfolioBase where PortfolioBaseCode = @PortfolioBaseCode
insert @PortfolioMembers select @PortfolioBaseID
end

--	Unconsolidated group
if (CHARINDEX('+',@Portfolios) = 0 AND CHARINDEX('@',@Portfolios) > 0)
begin
	select @PortfolioBaseID = PortfolioBaseID from APXUser.vPortfolioBase where PortfolioBaseCode = @PortfolioBaseCode
	insert @PortfolioMembers
	select distinct MemberID from APXUser.vPortfolioGroupMemberFlattened where PortfolioGroupID = @PortfolioBaseID
end

--	Unconsolidated composite
if (CHARINDEX('+',@Portfolios) = 0 AND CHARINDEX('&',@Portfolios) > 0)
begin
	select @PortfolioBaseID = PortfolioBaseID from APXUser.vPortfolioBase where PortfolioBaseCode = @PortfolioBaseCode
	insert @PortfolioMembers
	select distinct MemberID from APXUser.vPortfolioCompositeMember 
	where PortfolioCompositeID = @PortfolioBaseID
		and EntryDate <= @FromDate and (ExitDate >= @ToDate or ExitDate is NULL)
end

--	Individual portfolio
if (CHARINDEX('+',@Portfolios) = 0 AND CHARINDEX('&',@Portfolios) = 0 AND CHARINDEX('@',@Portfolios) = 0)
insert @PortfolioMembers select PortfolioBaseID from APXUser.vPortfolioBase where PortfolioBaseCode = @PortfolioBaseCode

SELECT 
	DataHandle = @DataHandle,
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.ReportHeading1,	
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	case when t.ThruDate is Null then 0 else 1 end as HasTransactions,
	FromDate = @FromDate,
	case when t.ThruDate is null then @ToDate else t.ThruDate end as ThruDate,
	p.LocaleID,
	FirmLogo = APX.fPortfolioCustomLabel(a.PortfolioBaseID, '$flogo', 'logo.jpg'),
	CostIsAdjusted = @CostIsAdjusted,
	ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision,
	ShowSecuritySymbol = @ShowSecuritySymbol,
	SecuritySymbolIsVisible = @SecuritySymbolIsVisible,
	ShowMultiCurrency = @ShowMultiCurrency,
	UseSettlementDate = @UseSettlementDate
FROM --APXUser.fReportDataIndex(@ReportPOData) a
	@PortfolioMembers a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
	p.PortfolioBaseID = a.PortfolioBaseID
	left join APXUser.fReportDataIndex(@ReportTranData) t on t.PortfolioBaseID = a.PortfolioBaseID
ORDER BY a.PortfolioBaseIDOrder
end