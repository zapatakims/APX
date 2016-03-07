if object_id('[APXUserCustom].[pSubreportTransactionActivity]') is not null
	drop procedure [APXUserCustom].[pSubreportTransactionActivity]
go
/*
declare @SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32) = 'case'
	,@FromDate datetime = '12/31/05'
	,@ToDate datetime = '12/31/06'
exec APXUserCustom.pReportTransactionActivity @SessionGuid = @SessionGuid, @Portfolios = @Portfolios, @FromDate = @FromDate, @ToDate = @ToDate

declare @SessionGuid nvarchar(max)
	,@DataHandle nvarchar(max) = 'AE00A8C0-8FC0-415A-9EFB-0BCA0F79987D'
	,@PortfolioBaseID int = 8
	,@PortfolioBaseIDOrder int = 1
	,@CategoryList nvarchar(max)
	,@IncludeCurrencyPurchasesSales bit
	,@IncludeAccruedInterestTransactions bit
	,@IncludeUnsupervisedAssets bit
	,@LocaleID int
	,@PageBreakSection bit

exec [APXUserCustom].[pSubreportTransactionActivity] @SessionGuid = @SessionGuid, @DataHandle = @DataHandle, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder
	,@CategoryList = @CategoryList, @CostIsAdjusted = 0, @ShowComments = 0, @ShowMultiCurrency = 0, @ShowCurrencyFullPrecision = 0, @ShowSecuritySymbol = 0, @SecuritySymbolIsVisible = 0, @UseSettlementDate = 0
	,@ReportingCurrencyCode = 'us', @IncludeCurrencyPurchasesSales = 0, @IncludeUnsupervisedAssets = 0, @IncludeAccruedInterestTransactions = 0, @LocaleID = 1033, @PageBreakSection = 0
*/
create procedure [APXUserCustom].[pSubreportTransactionActivity]
	@SessionGuid nvarchar(max)
	,@DataHandle nvarchar(max)
	,@PortfolioBaseID int
	,@PortfolioBaseIDOrder int
	,@CategoryList nvarchar(max) = null
	,@CostIsAdjusted bit
	,@ShowComments bit
	,@ShowMultiCurrency bit = null
	,@ShowCurrencyFullPrecision bit = null
	,@ShowSecuritySymbol char(1) = null
	,@SecuritySymbolIsVisible bit
	,@UseSettlementDate bit = null
	,@ReportingCurrencyCode dtCurrencyCode = null
	,@IncludeCurrencyPurchasesSales bit
	,@IncludeAccruedInterestTransactions bit
	,@IncludeUnsupervisedAssets bit = null
	,@LocaleID int = null
	,@PageBreakSection bit
as begin
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @DataHandleName1 nvarchar(max) = 'TransactionActivity'
	,@DataHandleName2 nvarchar(max) = 'RealizedGainLoss'

declare @transactionActivityData varbinary(max)
	,@realizedGainLossData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName1, @PortfolioBaseID=@PortfolioBaseID, @PortfolioBaseIDOrder=@PortfolioBaseIDOrder, @ReportData=@transactionActivityData out
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName2, @PortfolioBaseID=@PortfolioBaseID, @PortfolioBaseIDOrder=@PortfolioBaseIDOrder, @ReportData=@realizedGainLossData out
declare @FirmLogoTable table(PortfolioBaseID dtID primary key, FirmLogo nvarchar(72))
insert into @FirmLogoTable
select distinct p.PortfolioBaseID, FirmLogo = APX.fPortfolioCustomLabel(p.PortfolioBaseID, '$flogo', 'logo.jpg')
from ( select distinct PortfolioBaseID from APXUser.fTransactionActivity(@transactionActivityData) ) p

declare @Dividend nvarchar(max) = 'DIVIDEND'
declare @Purchase nvarchar(max) = 'PURCHASE'
declare @Sale nvarchar(max) = 'SALE'
declare @DVGains nvarchar(max) = 'CAPITAL GAIN DISTRIBUTION'
-- store Transaction Category ID and Name mapping
declare @TransactionCategory table(TransactionCategoryName str32 primary key, TsumcatName str32, TsumcatID tinyint);
	insert into @TransactionCategory VALUES ('ADJUST CAPITAL', 'Adjustments to Cost',15);
	insert into @TransactionCategory VALUES ('ADJUST CAPITAL (SHORT)', 'Adjustments to Cost',15);
	insert into @TransactionCategory VALUES ('CALL', 'Calls',8);
	insert into @TransactionCategory VALUES ('CONTRIBUTION', 'Contributions',13);
	insert into @TransactionCategory VALUES (@Dividend,'Dividends', 3);
	insert into @TransactionCategory VALUES (@DVGains,'Capital Gain Distributions', 4);
	insert into @TransactionCategory VALUES ('EXPENSE','Expenses', 12);
	insert into @TransactionCategory VALUES ('INTEREST','Interest',5)
	insert into @TransactionCategory VALUES ('MATURITY','Maturities',11);
	insert into @TransactionCategory VALUES (@Purchase,'Purchases',1);
	insert into @TransactionCategory VALUES ('PURCHASED ACCRUED INTEREST','Interest',5);
	insert into @TransactionCategory VALUES ('PUT', 'Puts', 9);
	insert into @TransactionCategory VALUES ('REINVESTED DIVIDEND', 'Purchases', 1);
	insert into @TransactionCategory VALUES ('RETURN OF CAPITAL', 'Return of Capital', 7);
	insert into @TransactionCategory VALUES ('RETURN OF CAPITAL (SHORT)','Return of Capital', 7);
	insert into @TransactionCategory VALUES ('RETURN OF PRINCIPAL', 'Principal Payments', 6);
	insert into @TransactionCategory VALUES ('RETURN OF PRINCIPAL (SHORT)', 'Principal Payments', 6);
	insert into @TransactionCategory VALUES (@Sale,'Sales',2);
	insert into @TransactionCategory VALUES ('SHORT COVER','Sales',2);
	insert into @TransactionCategory VALUES ('SHORT SALE','Purchases',1);
	insert into @TransactionCategory VALUES ('SOLD ACCRUED INTEREST', 'Interest',5);
	insert into @TransactionCategory VALUES ('WITHDRAWAL', 'Withdrawals', 14);
	insert into @TransactionCategory VALUES ('CAPITAL CALL', 'Capital Calls', 16);
	insert into @TransactionCategory VALUES ('SINK PAYMENT', 'Sink Payments', 10);

--declare @timer datetime = getdate()
-- Add @realizedGains table
declare @realizedGains table(
	PortfolioBaseID dtID,
	PortfolioTransactionID dtID,
	LotNumber dtID,
	RealizedGainLoss dtFloat,
	RealizedGainLossLocal dtFloat,
	Proceeds dtFloat,
	ProceedsLocal dtFloat,
	CostBasis dtFloat,
	CostBasisLocal dtFloat,
	Amortization dtFloat,
	AmortizationLocal dtFloat,
	SoldQuantity dtFloat,
	primary key(PortfolioBaseID, PortfolioTransactionID, LotNumber))
insert @realizedGains
	select DISTINCT
		PortfolioBaseID,
		PortfolioTransactionID,
		LotNumber,
		SUM(RealizedGainLoss),
		SUM(RealizedGainLossLocal),
		SUM(case when r.IsShortPosition = 1 and s.CanBeBoughtSold = 1 then -r.Proceeds else r.Proceeds end),
		SUM(case when r.IsShortPosition = 1 and s.CanBeBoughtSold = 1 then -r.ProceedsLocal else r.ProceedsLocal end),
		SUM(case when r.IsShortPosition = 1 and s.CanBeBoughtSold = 1 then -r.CostBasis else r.CostBasis end),
		SUM(case when r.IsShortPosition = 1 and s.CanBeBoughtSold = 1 then -r.CostBasisLocal else r.CostBasisLocal end),
		SUM(r.Amortization),
		SUM(r.AmortizationLocal),
		SUM(Quantity)
	from APXUser.fRealizedGainLoss(@realizedGainLossData) r
	join APXUser.vSecurityVariant s on
		s.SecurityID = r.SecurityID and
		s.SectypeCode = r.SecTypeCode and
		s.IsShort = r.IsShortPosition
	group by PortfolioBaseIDOrder, PortfolioBaseID, PortfolioTransactionID, LotNumber
-- 4. Select the columns for the report.
declare @eol varchar(2); set @eol = APX.fNewLine(1) -- char(13) + char(10)
declare @delimitedCategoryList nvarchar(max)
set @delimitedCategoryList = ',' + @CategoryList + ','
--select * from APXUser.fTransactionActivity(@transactionActivityData) a; 
--select 1, GETDATE() - @timer -- 3.353, 3.310, 3919 rows
--return;
select
	r.Amortization,
	r.AmortizationLocal,
	a.Comments,
	a.Commission,
	a.CommissionLocal,
	CostBasis = case when a.IsCurrencyPurchasesSales = 1 then a.TradeAmount else r.CostBasis end,
	CostBasisLocal = case when a.IsCurrencyPurchasesSales = 1 then a.TradeAmountLocal else r.CostBasisLocal end,
	-- Indicates if the bond's cost basis is adjusted.
	-- Based on the effective value of @BondCostBasisID.
	CostIsAdjusted = @CostIsAdjusted,
	
	flogo.FirmLogo,
		
	-- The precision format string for 'per unit' values (like Price and CostPerShare).
	-- If the effective value of @ShowMultiCurrency is 'true', then LocalCurrency.CurrencyPrecision.
	-- Otherwise ReportingCurrency.CurrencyPrecision.
	FormatPerUnit = convert(varchar(13), case @ShowMultiCurrency
		when 1 then case when a.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', a.LocalCurrencyPrecision) end
		else case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end end),
		
	-- The precision format string for values stated in their local currency (like LocalMarketValue and LocalCostBasis).
	-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'true', then LocalCurrency.CurrencyPrecision. 
	-- If the effective value of @ShowCurrencyFullPrecision is 'true' and the effective value of @ShowMultiCurrency is 'false', then ReportingCurrency.CurrencyPrecision.
	-- Otherwise zero decimals
	FormatLocalCurrency = convert(varchar(13), case @ShowCurrencyFullPrecision
		when 1 then (case @ShowMultiCurrency 
						when 1 then 
							case when a.LocalCurrencyPrecision  = 0 then '#,0' else '#,0.' + REPLICATE('0', a.LocalCurrencyPrecision) end
						else 
							case when p.CurrencyPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', p.CurrencyPrecision) end
					 end)
		else '#,0' end),
	-- The precision format string for 'quantity' values (like shares or par).
	-- Security.QuantityPrecision is always used.
	FormatQuantity = case when a.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', a.QuantityPrecision) end,
	
	-- The precision format string for values stated in the reporting currency (like MarketValue and CostBasis).
	-- If the effective value of @ShowCurrencyFullPrecision is 'true', then ReportingCurrency.CurrencyPrecision.
	-- Otherwise zero (0).
	p.FormatReportingCurrency,
	-- The security name concatenated with the bond description or mutual fund - used for sorting
    FullSecurityName1 =
		APXSSRS.fSecurityName1(a.SecurityName, a.LocalCurrencyISOCode, a.MaturityDate, @LocaleID, a.IsFFX, a.IsShortPosition1) +
		isnull(APXSSRS.fSecurityName2(a.BondDescription, a.MutualFund, 0, 0), ''),
	FxRate = case when r.Proceeds = 0 then 0 else
				case when a.IsCurrencyPurchasesSales = 1
				then a.TradeAmountLocal / a.TradeAmount
				else r.ProceedsLocal / r.Proceeds 
				end 
		end,
	a.HasQuantity,
	a.IsNonReportingCurrencyCash,
	a.IsReportingCurrencyCash,
	a.IsUnsupervised,                    
	a.LocalCurrencyName,                    
	a.LocalCurrencySequenceNo,                    
		
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
	p.LocaleID,
	PageBreakSection = case when @PageBreakSection = 1 then tcat.TsumcatID else 1 end,
    p.PrefixedPortfolioBaseCode,
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
    
	PortfolioOwnerBaseID = portfolioTran.PortfolioID,
	Proceeds =	case 
					when a.IsCurrencyPurchasesSales = 1 then a.TradeAmount 
					when a.GainClassificationCode = 'i' and tcat.TsumcatName in ('Sales','Principal Payments', 'Puts', 'Calls', 'Maturities', 'Sink Payments')  then a.TradeAmount
					-- Must be kept in line with SSRS Transaction Summary (MC) cIsSale field
					else r.Proceeds 
				end,
	ProceedsLocal = case 
						when a.IsCurrencyPurchasesSales = 1 then a.TradeAmountLocal 
						when a.GainClassificationCode = 'i' and tcat.TsumcatName in ('Sales','Principal Payments', 'Puts', 'Calls', 'Maturities', 'Sink Payments') then a.TradeAmountLocal
						-- Must be kept in line with SSRS Transaction Summary (MC) cIsSale field
						else r.ProceedsLocal 
					end,
	a.Quantity,
	r.RealizedGainLoss,
	r.RealizedGainLossLocal,
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	p.ReportingCurrencyCode,
	p.ReportingCurrencyName,
	SecurityName1 = APXSSRS.fSecurityName1(a.SecurityName, a.LocalCurrencyISOCode, a.MaturityDate, @LocaleID, a.IsFFX, a.IsShortPosition1),
	SecurityName2 = APXSSRS.fSecurityName2(a.BondDescription, a.MutualFund, 1, 0),
	-- The SecuritySymbol to display based on the effective value of @ShowSecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'n', then null.
	-- If the effective value of @ShowSecuritySymbol is 'y', then the first 12 characters of Security.SecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'l', then the first 25 characters of Security.SecuritySymbol.
	-- Otherwise Security.SecuritySymbol.
	SecuritySymbol1 = APXUser.fDisplaySecuritySymbol(a.SecuritySymbol, @ShowSecuritySymbol),
	-- Indicates if the SecuritySymbol should be visible based on the effective value of @ShowSecuritySymbol.
	-- If the effective value of @ShowSecuritySymbol is 'n', then 'false'.
	-- Otherwise 'true'.
	SecuritySymbolIsVisible = @SecuritySymbolIsVisible,
	a.SettleDate,
	-- The effective value of @ShowMultiCurrency.
	-- If @ShowMultiCurrency is specified (but not null), then @ShowMultiCurrency.
	-- Otherwise Configuration.ShowMultiCurrency.
	ShowMultiCurrency = @ShowMultiCurrency,
	SoldQuantity = case 
					when a.GainClassificationCode = 'i' and tcat.TsumcatName in ('Sales','Principal Payments', 'Puts', 'Calls', 'Maturities', 'Sink Payments') then a.Quantity
					-- Must be kept in line with SSRS Transaction Summary (MC) cIsSale field
					else r.SoldQuantity
				end,
	a.ThruDate,
	a.TradeAmount,
	a.TradeAmountLocal,
	a.TradeDate,
	a.TransactionCategory,
	tcat.TsumcatName,
	tcat.TsumcatID,
	a.TranID,
	a.ValuationFactor,                    
	
	-- The effective value of @UseSettlementDate.
	-- If @UseSettlementDate is specified (but not null), then @UseSettlementDate.
	-- Otherwise Configuration.UseSettlementDate.
	UseSettlementDate = @UseSettlementDate
-- 3. Join the Transaction Activity to additional views.
from 
	(	select 
			a.BondDescription,
			Comments = case @ShowComments
				when 1 then
					(case isnull(a.Comment01, '') when '' then '' else a.Comment01 + @eol end) + 
					(case isnull(a.Comment02, '') when '' then '' else a.Comment02 + @eol end) + 
					(case isnull(a.Comment03, '') when '' then '' else a.Comment03 + @eol end) + 
					(case isnull(a.Comment04, '') when '' then '' else a.Comment04 + @eol end) + 
					(case isnull(a.Comment05, '') when '' then '' else a.Comment05 + @eol end) + 
					(case isnull(a.Comment06, '') when '' then '' else a.Comment06 + @eol end) + 
					(case isnull(a.Comment07, '') when '' then '' else a.Comment07 + @eol end) + 
					(case isnull(a.Comment08, '') when '' then '' else a.Comment08 + @eol end) + 
					(case isnull(a.Comment09, '') when '' then '' else a.Comment09 + @eol end) + 
					(case isnull(a.Comment10, '') when '' then '' else a.Comment10 + @eol end) +
					(case isnull(a.Comment11, '') when '' then '' else a.Comment11 + @eol end) + 
					(case isnull(a.Comment12, '') when '' then '' else a.Comment12 + @eol end) + 
					(case isnull(a.Comment13, '') when '' then '' else a.Comment13 + @eol end) + 
					(case isnull(a.Comment14, '') when '' then '' else a.Comment14 + @eol end) + 
					(case isnull(a.Comment15, '') when '' then '' else a.Comment15 + @eol end) + 
					(case isnull(a.Comment16, '') when '' then '' else a.Comment16 + @eol end) + 
					(case isnull(a.Comment17, '') when '' then '' else a.Comment17 + @eol end) + 
					(case isnull(a.Comment18, '') when '' then '' else a.Comment18 + @eol end) + 
					(case isnull(a.Comment19, '') when '' then '' else a.Comment19 + @eol end) + 
					(case isnull(a.Comment20, '') when '' then '' else a.Comment20 + @eol end) +
					(case isnull(a.Comment21, '') when '' then '' else a.Comment21 + @eol end) + 
					(case isnull(a.Comment22, '') when '' then '' else a.Comment22 + @eol end) + 
					(case isnull(a.Comment23, '') when '' then '' else a.Comment23 + @eol end) + 
					(case isnull(a.Comment24, '') when '' then '' else a.Comment24 + @eol end) + 
					(case isnull(a.Comment25, '') when '' then '' else a.Comment25 + @eol end) + 
					(case isnull(a.Comment26, '') when '' then '' else a.Comment26 + @eol end)
				else null end,
			a.Commission,
			a.CommissionLocal,
			GainClassificationCode = case when a.IsShortPosition1 = 1 then sec.ShortGainClassificationCode else sec.LongGainClassificationCode end,
			a.HasQuantity,
			IsCurrencyPurchasesSales = case when ((a.IsNonReportingCurrencyCash = 1 or a.IsReportingCurrencyCash = 1) and (a.TransactionCode2 in ('by', 'sl'))) then 1 else 0 end,
			s.IsFFX,	
			a.IsNonReportingCurrencyCash,
			a.IsReportingCurrencyCash,
			a.IsShortPosition1,
			a.IsShortPosition2,
			s.IsUnsupervised,
			s.LocalCurrencyISOCode,
			s.LocalCurrencyName,
			s.LocalCurrencyPrecision,
			s.LocalCurrencySequenceNo,
			a.LotNumber,
			s.MaturityDate,
			a.MutualFund,
			a.PortfolioBaseID,
			a.PortfolioBaseIDOrder,
			a.PortfolioTransactionID,
			a.Quantity,
			s.QuantityPrecision,
			s.SecurityName,
			s.SecuritySymbol,
			a.SettleDate,
			a.ThruDate,
			TradeAmount = case 
				when a.TransactionCode = 'wd' and a.TransactionCategory = 'EXPENSE' then -a.TradeAmount 
				when a.TransactionCode = 'cc'  then -a.TradeAmount 
				else a.TradeAmount 
				end,
			TradeAmountLocal = case 
				when a.TransactionCode = 'wd' and a.TransactionCategory = 'EXPENSE' then -a.TradeAmountLocal 
				when a.TransactionCode = 'cc' then -a.TradeAmountLocal 
				else a.TradeAmountLocal 
				end,
			a.TradeDate,
			TransactionCategory  = case when a.TransactionCategory = @Dividend then
												case s2.Symbol
													 when 'dvshrt' then @DVGains
													 when 'dvmid' then @DVGains
													 when 'dvfive' then @DVGains
													 when 'dvlong' then @DVGains
													 when 'dvlong03' then @DVGains
													 when 'cashrt' then @DVGains
													 when 'camid' then @DVGains
													 when 'cafive' then @DVGains
													 when 'calong' then @DVGains
													 when 'calong03' then @DVGains
													 else @Dividend
												end
										when a.TransactionCategory is null and a.TransactionCode2 = 'by' and (a.IsNonReportingCurrencyCash = 1 or a.IsReportingCurrencyCash = 1)then @Purchase
										when a.TransactionCategory is null and a.TransactionCode2 = 'sl' and (a.IsNonReportingCurrencyCash = 1 or a.IsReportingCurrencyCash = 1)then @Sale
									   else a.TransactionCategory 
									   end,
			a.TranID,
			s.ValuationFactor
		from APXUser.fTransactionActivity(@transactionActivityData) a
		left join APXUser.vSecurityVariant s on
			s.SecurityID = a.SecurityID1 and
			s.SectypeCode = a.SecTypeCode1 and
			s.IsShort = a.IsShortPosition1
		left join APXUser.vSecType sec on
			sec.SecTypeCode = s.SectypeCode and
			sec.PrincipalCurrencyCode = s.PrincipalCurrencyCode
		left join dbo.AdvSecurity s2 on
			s2.SecurityID = a.SecurityID2 
		where a.SecTypeCode1 <> 'br'
			and (@IncludeCurrencyPurchasesSales = 1 or 
					NOT( (a.IsNonReportingCurrencyCash = 1 or a.IsReportingCurrencyCash = 1) and 
						(a.TransactionCode2 in ('by', 'sl'))
						)
				)
	) a
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = a.PortfolioBaseID
	-- Rep can generate pa/sa transactions which may not exist in the database
	left join APXUser.vPortfolioTransaction portfolioTran on
		portfolioTran.PortfolioTransactionID = a.PortfolioTransactionID
	left join @FirmLogoTable flogo on
		flogo.PortfolioBaseID = a.PortfolioBaseID
	left join @TransactionCategory tcat on
		tcat.TransactionCategoryName = a.TransactionCategory
	left join @realizedGains r on
		r.PortfolioBaseID = a.PortfolioBaseID and
		r.PortfolioTransactionID = a.PortfolioTransactionID and
		r.LotNumber = a.LotNumber and
		tcat.TsumcatName in ('Sales','Principal Payments', 'Puts', 'Calls', 'Maturities', 'Sink Payments')  
		-- these categories show Gain/Loss values on Transaction Summary SSRS
where
	(@IncludeAccruedInterestTransactions = 1 or (a.TransactionCategory not in ('PURCHASED ACCRUED INTEREST', 'SOLD ACCRUED INTEREST')))
	and (@CategoryList is null or charindex(',' + tcat.TsumcatName + ',', @delimitedCategoryList) > 0)
	and (a.IsUnsupervised = 0 or @IncludeUnsupervisedAssets = 1)
Order By
	a.PortfolioBaseIDOrder, PageBreakSection, TsumcatID, IsUnsupervised, FullSecurityName1, TradeDate, SettleDate, a.LotNumber, a.TranID
--select 1, GETDATE() - @timer -- 3.353, 3.310, 3919 rows
end