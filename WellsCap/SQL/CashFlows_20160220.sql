set nocount on
go

if object_id('tempdb..#PortfolioTransactionHistory') is not null
drop table #PortfolioTransactionHistory;

declare
	@SessionGuid nvarchar(72),
	@Portfolios nvarchar(max),
	@FromDate datetime,
	@ToDate datetime,
	@ReportingCurrencyCode dtCurrencyCode,
	@IncludeUnsupervisedAssets bit,
	@TurnOffCloseDateProcessing bit,
	@UseSettlementDate int,
	@PriceTypeID int,
	@LocaleID int,
	@securitySymbol nvarchar(32) = 'CASH',
	@postDate date = getdate(),
	@ReportData varbinary(max)

select 
	@FromDate = APXUser.fGetGenericDate('{bdlm}',getdate()), 
	@ToDate = APXUser.fGetGenericDate('{ednw}',getdate())

exec APXUser.pSessionCreate 'admin','advs',@SessionGuid = @SessionGuid out
exec APXUser.pSessionInfoSetGuid @SessionGuid;

select 
	* 
into #PortfolioTransactionHistory 
from APXUser.vPortfolioTransactionHistory th 
where 
	th.SourceID = 1 
	and th.TradeAmount > 100000 
	and th.PostDate = @postDate
	and th.TransactionCode IN ('dp', 'wd')

--select * from #PortfolioTransactionHistory

select @Portfolios = stuff((select distinct
								' ' + pb.PortfolioBaseCode
							from #PortfolioTransactionHistory pth
							join APXUser.vPortfolioBase pb 
								on pb.PortfolioBaseID = pth.PortfolioID 
							for xml path('')) ,1,1,'')

if @Portfolios is not null
begin
exec APXUser.pTransactionActivity
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ReportingCurrencyCode = @ReportingCurrencyCode,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@TurnOffCloseDateProcessing = @TurnOffCloseDateProcessing,
	@UseSettlementDate = @UseSettlementDate,
	@PriceTypeID = @PriceTypeID,
	@LocaleID = @LocaleID

select
	[PortfolioCode] = p.PortfolioBaseCode,
	[AccountName] = p.ReportHeading1,
	[TranCode] = ta.TransactionCode,
	[SecType] = ta.SecTypeCode1 + sec.PrincipalCurrencyCode,
	[TradeDate] = CONVERT(varchar, ta.TradeDate, 101),
	[SettleDate] = CONVERT(varchar, ta.SettleDate, 101),
	[ActualLocalAmount] = CASE WHEN ta.TransactionCode = 'dp' THEN ta.TradeAmount ELSE ta.TradeAmount * -1 END,
	[AbsoluteLocalAmount] = ta.TradeAmountLocal,
	[USDEquivalent] = ta.TradeAmount,
	[SourceCurrencyCode] = c.ISOCode,
	ta.TranID,
	[PostDate] = CONVERT(varchar, pth.PostDate, 101),
	[UserName] = u.DisplayName,
	cu.CustodianName,
	[Flag] = CASE WHEN cu.CustodianName like 'WFC%' OR cu.CustodianName like 'US Bank%' THEN 'Yes' ELSE '' END
from APXUser.fTransactionActivity (@ReportData) ta
join #PortfolioTransactionHistory pth
	on pth.PortfolioTransactionID = ta.PortfolioTransactionID
join APXUser.vPortfolioBase p
	on p.PortfolioBaseID = ta.PortfolioBaseID
join dbo.AdvAuditEvent a 
	on pth.AuditEventID = a.AuditEventID
join APXUser.vSecurityVariant sec
	on sec.SecurityID = ta.SecurityID1
	and sec.SecTypeCode = ta.SecTypeCode1
	and sec.IsShort = ta.IsShortPosition1
	and (sec.SecuritySymbol = @securitySymbol or @securitySymbol is null)
join APXUser.vCurrency c
	on c.CurrencyCode = sec.PrincipalCurrencyCode
join APXUser.vPortfolioBaseCustom cu 
	on ta.PortfolioBaseID = cu.PortfolioBaseID
join APXUser.vUserBase u 
	on a.UserID = u.UserBaseID
end
else
begin
	print 'No transactions found.'
end