if object_id('APXUserCustom.pReportCommissionPurpose') is not null
	drop procedure APXUserCustom.pReportCommissionPurpose
go
create procedure APXUserCustom.pReportCommissionPurpose
		-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@ToDate datetime,
	
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	--@CompositeFromDate datetime = null,
	--@CompositeToDate datetime = null,
	@PriceTypeID int = null,
	@OverridePortfolioSettings bit = null,
	
	-- Other optional parameters
	@LocaleID int = null,					-- Use Portfolio Settings
	@ShowCurrencyFullPrecision bit = null	-- Use Settings

as
begin
declare @ReportData varbinary(max)
	,@FromDate datetime

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
select @FromDate = APXUser.fGetGenericDate('{bdty}', @ToDate)

exec APXUser.pTransactionActivity @ReportData = @ReportData out
	,@Portfolios = @Portfolios
	,@FromDate = @FromDate
	,@ToDate = @ToDate

select t.PortfolioBaseIDOrder
	,p.ReportHeading1
	,p.ReportHeading2
	,p.ReportHeading3
	,t.BrokerRepName [BrokerFirmName]
	,case when t.CommissionPurposeID is null then 'Commission Purpose - Undefined' 
		else c.PurposeDesc end [Purpose]
	,t.CommissionPurposeID
	,sum(t.Commission) [Commission]
	,'Year to Date' [Period]
	,'YTD' [PeriodID]
from APXUser.fTransactionActivity (@ReportData) t
	left join APXUser.vCommissionPurpose c on c.CommissionPurposeID = t.CommissionPurposeID
	join APXUser.vPortfolioBase p on p.PortfolioBaseID = t.PortfolioBaseID
where t.Commission is not null
group by t.PortfolioBaseIDOrder, t.BrokerRepName, t.CommissionPurposeID, c.PurposeDesc	,p.ReportHeading1, p.ReportHeading2, p.ReportHeading3
union all
select t.PortfolioBaseIDOrder
	,p.ReportHeading1
	,p.ReportHeading2
	,p.ReportHeading3
	,t.BrokerRepName [BrokerFirmName]
	,case when t.CommissionPurposeID is null then 'Commission Purpose - Undefined' 
		else c.PurposeDesc end [Purpose]
	,t.CommissionPurposeID
	,sum(t.Commission) [Commission]
	,'Quarter To Date' [Period]
	,'QTD' [PeriodID]
from APXUser.fTransactionActivity (@ReportData) t
	left join APXUser.vCommissionPurpose c on c.CommissionPurposeID = t.CommissionPurposeID
	join APXUser.vPortfolioBase p on p.PortfolioBaseID = t.PortfolioBaseID
where t.Commission is not null and
	t.TradeDate >= APXUser.fGetGenericDate('{bdtq}', @ToDate)
group by t.PortfolioBaseIDOrder, t.BrokerRepName, t.CommissionPurposeID, c.PurposeDesc	,p.ReportHeading1, p.ReportHeading2, p.ReportHeading3
union all
select t.PortfolioBaseIDOrder
	,p.ReportHeading1
	,p.ReportHeading2
	,p.ReportHeading3
	,t.BrokerRepName [BrokerFirmName]
	,case when t.CommissionPurposeID is null then 'Commission Purpose - Undefined' 
		else c.PurposeDesc end [Purpose]
	,t.CommissionPurposeID
	,sum(t.Commission) [Commission]
	,'Month To Date' [Period]
	,'MTD' [PeriodID]
from APXUser.fTransactionActivity (@ReportData) t
	left join APXUser.vCommissionPurpose c on c.CommissionPurposeID = t.CommissionPurposeID
	join APXUser.vPortfolioBase p on p.PortfolioBaseID = t.PortfolioBaseID
where t.Commission is not null and
	t.TradeDate >= APXUser.fGetGenericDate('{bdtm}', @ToDate)
group by t.PortfolioBaseIDOrder, t.BrokerRepName, t.CommissionPurposeID, c.PurposeDesc	,p.ReportHeading1, p.ReportHeading2, p.ReportHeading3

end
go