IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportUnsupervised_D85383SA]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pReportUnsupervised_D85383SA] 
GO 

create procedure [APXUserCustom].[pReportUnsupervised_D85383SA]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	@LocaleID int,
	@ReportingCurrencyCode char(2),
	@ShowCurrencyFullPrecision bit = null	-- Use Settings
as
begin
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @ReportData varbinary(max)

declare @BeginningMarketValue1 float,
	@BeginningMarketValue2 float,
	@EndingMarketValue float,
	@GrandTotalMV float,
	@UnrealizedGainLoss1 float, -- calcuated
	@UnrealizedGainLoss2 float, -- calcuated
	@RealizedGainLoss1 float,
	@RealizedGainLoss2 float,
	@Income1 float,
	@Income2 float,
	
	@Holdings varbinary(max),
	@Holdings1 varbinary(max),
	@Holdings2 varbinary(max),
	@GainLoss1 varbinary(max),
	@GainLoss2 varbinary(max),
	@Transactions1 varbinary(max),
	@Transactions2 varbinary(max)

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@Holdings out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@Holdings1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@Holdings2 out

exec APXUser.pReportDataGetFromHandle @DataHandle, 'RealizedGainLoss1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@GainLoss1 out
exec APXUser.pReportDataGetFromHandle @DataHandle, 'RealizedGainLoss2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@GainLoss2 out

exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Transaction1', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIdOrder, @ReportData=@Transactions1 out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Transaction2', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@Transactions2 out

exec APXUser.pGetEffectiveParameter @ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out

select @BeginningMarketValue1 = SUM(a.MarketValue) from APXUser.fAppraisal(@Holdings1) a
join APXUser.vSecurityVariant s1 on
	s1.SecurityID = a.SecurityID and
	s1.IsShort = a.IsShortPosition and
	s1.SecTypeCode = a.SecTypeCode and
	s1.IsUnsupervised = 1
group by a.PortfolioBaseID

select @BeginningMarketValue2 = SUM(a.MarketValue) from APXUser.fAppraisal(@Holdings2) a
join APXUser.vSecurityVariant s1 on
	s1.SecurityID = a.SecurityID and
	s1.IsShort = a.IsShortPosition and
	s1.SecTypeCode = a.SecTypeCode and
	s1.IsUnsupervised = 1
group by a.PortfolioBaseID

select @EndingMarketValue = SUM(a.MarketValue) from APXUser.fAppraisal(@Holdings) a
join APXUser.vSecurityVariant s1 on
	s1.SecurityID = a.SecurityID and
	s1.IsShort = a.IsShortPosition and
	s1.SecTypeCode = a.SecTypeCode and
	s1.IsUnsupervised = 1
group by a.PortfolioBaseID

select @GrandTotalMV = SUM(a.MarketValue) from APXUser.fAppraisal(@Holdings) a
group by a.PortfolioBaseID

select @UnrealizedGainLoss1 = @EndingMarketValue - @BeginningMarketValue1
select @UnrealizedGainLoss2 = @EndingMarketValue - @BeginningMarketValue2

select @RealizedGainLoss1 = SUM(RealizedGainLoss) from APXUser.fRealizedGainLoss(@GainLoss1) r
join APXUser.vSecurityVariant s on 
	s.SecurityID = r.SecurityID and
	s.IsShort = r.IsShortPosition and
	s.SecTypeCode = r.SecTypeCode and
	s.IsUnsupervised = 1
group by r.PortfolioBaseID

select @RealizedGainLoss2 = SUM(RealizedGainLoss) from APXUser.fRealizedGainLoss(@GainLoss2) r
join APXUser.vSecurityVariant s on 
	s.SecurityID = r.SecurityID and
	s.IsShort = r.IsShortPosition and
	s.SecTypeCode = r.SecTypeCode and
	s.IsUnsupervised = 1
group by r.PortfolioBaseID

select @Income1 = sum(t.TradeAmount)
from APXUser.fTransactionActivity(@Transactions1) t
join APXUser.vSecurityVariant s on 
	s.SecurityID = t.SecurityID1 and
	s.IsShort = t.IsShortPosition1 and
	s.SecTypeCode = t.SecTypeCode1 and 
	s.IsUnsupervised = 1
where t.TransactionCategory in ('DIVIDEND','INTEREST')

select @Income2 = sum(t.TradeAmount)
from APXUser.fTransactionActivity(@Transactions2) t
join APXUser.vSecurityVariant s on 
	s.SecurityID = t.SecurityID1 and
	s.IsShort = t.IsShortPosition1 and
	s.SecTypeCode = t.SecTypeCode1 and 
	s.IsUnsupervised = 1
where t.TransactionCategory in ('DIVIDEND','INTEREST')

select distinct
	p.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.FormatReportingCurrency,
	p.LegacyLocaleID,
	p.LocaleID,
	p.PrefixedPortfolioBaseCode,
	@BeginningMarketValue1 [BeginningMarketValue1],
	@BeginningMarketValue2 [BeginningMarketValue2],
	@EndingMarketValue [EndingMarketValue],
	@GrandTotalMV [PortfolioValue],
	@UnrealizedGainLoss1 [UnrealizedGainLoss1],
	@UnrealizedGainLoss2 [UnrealizedGainLoss2],
	@RealizedGainLoss1 [RealizedGainLoss1],
	@RealizedGainLoss2 [RealizedGainLoss2],
	@Income1 [IncomeReceived1],
	@Income2 [IncomeReceived2]
from APXUser.fAppraisal(@Holdings) a
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
	p.PortfolioBaseID = a.PortfolioBaseID
where a.PortfolioBaseID = @PortfolioBaseID and
	a.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
end

GO


