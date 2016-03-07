/*	TEST CODE
declare	@Portfolios nvarchar(32) = '@master'
	,@Date datetime = '02/28/14'
	,@UseSettlementDate int
	,@ReportingCurrencyCode char(2) = 'us'
	,@ShowTaxLotsLumped bit
	,@LocaleID int
	,@PriceTypeID int
	,@SessionGuid nvarchar(max)
	,@ShowCurrencyFullPrecision bit
	,@SecType nvarchar(32) = 'us0259'
	,@Symbol nvarchar(32) = 'FPNIX'

exec [APXUserCustom].[pSecurityHeldByAccount] @Portfolios, 
	@Date, @UseSettlementDate, @ReportingCurrencyCode, @ShowTaxLotsLumped, 
	@LocaleID, @PriceTypeID, @SessionGuid, @ShowCurrencyFullPrecision, @SecType, @Symbol
*/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pSecurityHeldByAccount]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pSecurityHeldByAccount]
GO

create procedure [APXUserCustom].[pSecurityHeldByAccount]
@Portfolios nvarchar(32)
	,@Date datetime
	,@UseSettlementDate int
	,@ReportingCurrencyCode char(2)
	,@ShowTaxLotsLumped bit
	,@LocaleID int
	,@PriceTypeID int
	,@SessionGuid nvarchar(max)
	,@ShowCurrencyFullPrecision bit
	,@SecType nvarchar(32)
	,@Symbol nvarchar(32)

as
begin
declare @ReportData varbinary(max)

exec APXUser.pSessionInfoSetGuid @SessionGuid
declare @PortMembers table (PortfolioBaseIDOrder int, GroupID int, PortfolioBaseID int)
insert @PortMembers
select g.DisplayOrder, g.PortfolioGroupID, g.MemberID 
from APXUser.vPortfolioGroupMemberFlattened g
where g.PortfolioGroupCode = REPLACE(REPLACE(@Portfolios,'@',''),'+','')

exec APXUser.pAppraisal @ReportData = @ReportData out
	,@Portfolios = @Portfolios
	,@Date = @Date
	,@UseSettlementDate = @UseSettlementDate
	,@ReportingCurrencyCode = @ReportingCurrencyCode
	,@ShowTaxLotsLumped = @ShowTaxLotsLumped
	,@LocaleID = @LocaleID
	,@PriceTypeID = @PriceTypeID

declare @Holdings table (PortfolioBaseID int, SecuritySymbol nvarchar(50), SecurityName nvarchar(max), Quantity float, CostBasis float, FormatQuantity nvarchar(32), MarketValue float)
insert @Holdings
select
	a.PortfolioBaseID,
	s.SecuritySymbol,
	s.SecurityName,
	a.Quantity,
	a.CostBasis,
	FormatQuantity = case when s.QuantityPrecision = 0 then '#,0' else '#,0.' + REPLICATE('0', s.QuantityPrecision) end,
	a.MarketValue
from APXUser.fAppraisal (@ReportData) a 
	join APXUser.vSecurityVariant s on s.SecurityID = a.SecurityID and
		s.IsShort = a.IsShortPosition and
		s.IsUnsupervised = 0
	join APXUser.vSecurityPropertyLookupLS t on t.SecurityID = a.SecurityID and
		t.IsShort = a.IsShortPosition and
		t.PropertyID = -19
where t.KeyString = @SecType and
	s.SecuritySymbol = @Symbol

select pm.PortfolioBaseIDOrder,
	p.PortfolioBaseID,
	p.PortfolioBaseCode,
	primaryContact.ContactCode [PrimaryContactCode],
	cCustom.Custom02,
	c.Email,
	p.ReportHeading1,
	p.ReportHeading2,
	p.ReportHeading3,
	rc.CurrencyName as ReportingCurrencyName,
	h.SecuritySymbol,
	h.SecurityName,
	h.Quantity,
	h.FormatQuantity,
	h.CostBasis,
	p.FormatReportingCurrency,
	h.MarketValue
from @PortMembers pm
	left join @Holdings h on h.PortfolioBaseID = pm.PortfolioBaseID
	join APXUserCustom.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
		p.PortfolioBaseID = pm.PortfolioBaseID
	join APXUser.vPortfolio port on 
		port.PortfolioID = pm.PortfolioBaseID
	join APXUser.vCurrency rc on
		rc.CurrencyCode = @ReportingCurrencyCode
	left join APXUser.vContactCustom cCustom on
		cCustom.ContactID = port.OwnerContactID
	left join APXUser.vContact c on
		c.ContactID = port.OwnerContactID
/*
AZK 2014/03/11
Adding primary contact grouping.
*/
	left join APXUser.vContact primaryContact on primaryContact.ContactID = port.PrimaryContactID
end