IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pDARMD]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pDARMD]
GO

create procedure [APXUserCustom].[pDARMD]
	@SessionGuid nvarchar(max),
	@Portfolios nvarchar(32),
	@ToDate datetime,
	@ReportingCurrencyCode dtCurrencyCode,
	
	-- Optional parameters
	@FeeMethod int = null,
	@IncludeClosedPortfolios bit = null,
	@IncludeUnsupervisedAssets bit = null,
	@AccruedInterestID int = null,			-- Use Settings (0)
	@UseSettlementDate bit = null,			-- Use Settings
	@LocaleID int = null,					-- Use Portfolio Settings
	@PriceTypeID int = null,
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@OverridePortfolioSettings bit = null

as begin
exec APXUser.pSessionInfoSetGuid @SessionGuid

declare @DataHandle as uniqueidentifier = newid(),
	@AgeAsOfDate datetime,
	@ContFromDate datetime,
	@ContToDate datetime

declare @Contributions varbinary(max),
	@Holdings varbinary(max)

select @AgeAsOfDate = DATEADD(YYYY,1,@ToDate)

-- Long outs = asofdate+1 through asofdate+365
select @ContFromDate = DATEADD(DAY,1,@ToDate)
	,@ContToDate = DATEADD(DAY,365,@ToDate)

-- ***************  Appraisal ***************
exec APXUser.pAppraisalBatch
    
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @ToDate,
    
	-- Optional Parameters
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@IncludeClosedPortfolios = @IncludeClosedPortfolios,
	@IncludeUnsupervisedAssets = @IncludeUnsupervisedAssets,
	@AccruedInterestID = @AccruedInterestID,
	@LocaleID = @LocaleID,
	@PriceTypeID = @PriceTypeID,
	@OverridePortfolioSettings = @OverridePortfolioSettings
	

-- ***************  Contributions/Withdrawals ***************
exec APXUser.pContributionWithdrawalsBatch

	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Contributions',
	@Portfolios = @Portfolios,
	@FromDate = @ContFromDate,
	@ToDate = @ContToDate,
	@PeriodOptions = 2,
	@ClassificationID = -9,
	@ShowSkippedCompositeMembers = 0,
	@ShowOnlyPortfoliosWithCashFlows = 1,
	@Threshold = 0,
	@AccumulateFlowsForThePeriod = 0,
	@RevalueAtFlowDate = 0,
	@ExcludeCashAssetClass = 0,
	@ReportingCurrencyCode = @ReportingCurrencyCode,
	@FeeMethod = @FeeMethod,
	@ByPortfolioAndAssetClass = 1,
	@IntervalLength = 1,
	@OverridePortfolioSettings = @OverridePortfolioSettings,
	@AccruedInterestID = @AccruedInterestID,
	@PriceTypeID = @PriceTypeID,
	@LocaleID = @LocaleID

-- Execute multiple accounting functions asynchronously
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData=0

-- ***************  Get Portfolio Overview Portfolio List ***************
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Contributions', @ReportData = @Contributions out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Appraisal', @ReportData = @Holdings out

declare @contact table (PortfolioBaseID int, OwnerContactID int, BlBkCID nvarchar(32), PM nvarchar(4), OwnerName nvarchar(255), 
	OwnerEmail nvarchar(255), OwnerDOB nvarchar(255), OwnerDOD nvarchar(255), OwnerAge numeric(10,2), spouseContactID int, SpouseName nvarchar(255),
	SpouseEmail nvarchar(255), SpouseDOB nvarchar(255), SpouseAge numeric(10,2), SpouseDOD nvarchar(255), RMDMethod nvarchar(max), RMDNotes nvarchar(max), TaxNumber nvarchar(max))

insert @contact
select distinct
	h.PortfolioBaseID,
	p.OwnerContactID,
	ownerCustom.Custom01,
	LEFT(ownerCustom.Custom02,4),
	pOwner.LastName + ', ' + pOwner.FirstName + ' ' + pOwner.MiddleName,
	coalesce(pOwner.Email,pOwner.Email2,pOwner.Email3),
	convert(nvarchar(255),pOwner.BirthDate,1),
	ownerCustom.Custom11,
	case when ownerCustom.Custom11 = '' then
		CAST(CAST(DATEDIFF(DAY,pOwner.BirthDate,@AgeAsOfDate) as float) / 365.25 as numeric(10,2))
		else CAST(CAST(DATEDIFF(DAY,pOwner.BirthDate,ownerCustom.Custom11) as float) / 365.25 as numeric(10,2)) end,
	spouse.ContactID [spouseContactID],
	spouseInfo.LastName + ', ' + spouseInfo.FirstName + ' ' + spouseInfo.MiddleName,
	coalesce(spouseInfo.Email,spouseInfo.Email2,spouseInfo.Email3),
	convert(nvarchar(255),spouseInfo.BirthDate,1),
	case when ownerCustom.Custom11 = '' then
		case when DATEDIFF(YEAR,@AgeAsOfDate,spouseCustom.Custom11) > 1
			then 1--cast(CAST(DATEDIFF(MONTH,spouseInfo.BirthDate,spouseCustom.Custom11) as float) / 12 as numeric(10,2))
			else cast(cast(DATEDIFF(MONTH,spouseInfo.BirthDate,@AgeAsOfDate) as float) / 12 as numeric(10,2))
		end
		else cast(cast(DATEDIFF(MONTH,spouseInfo.BirthDate,ownerCustom.Custom11) as float) / 12 as numeric(10,2))
	end,
	spouseCustom.Custom11,
	ownerCustom.RMDMethod,
	ownerCustom.RMDNotes,
	pOwner.TaxID
from APXUser.fAppraisal(@Holdings) h
join APXUser.vPortfolio p on p.PortfolioID = h.PortfolioBaseID
join APXUser.vContact pOwner on
	pOwner.ContactID = p.OwnerContactID
left join APXUser.vContactCustom ownerCustom on
	ownerCustom.ContactID = pOwner.ContactID
left join APXUser.vContactRelationship spouse on
	spouse.RelatedContactID = p.OwnerContactID and
	spouse.NatureOfRelationship = 'Spouse'
left join APXUser.vContact spouseInfo on 
	spouseInfo.ContactID = spouse.ContactID
left join APXUser.vContactCustom spouseCustom on
	spouseCustom.ContactID = spouse.ContactID
where (ownerCustom.Custom10 = '' or ownerCustom.Custom10 is null)
	and ((p.TaxStatus = 'Deferred' AND (CAST(CAST(DATEDIFF(MONTH,pOwner.BirthDate,@AgeAsOfDate) as float) / 12 as numeric(10,2)) >= 70.5)) OR
			p.PortfolioTypeCode = 'IRA Inherited')
	
--select * from @contact	--	for debugging

select 
--	account related stuff
	h.PortfolioBaseIDOrder,
	h.PortfolioBaseID,
	p.PortfolioBaseCode,
	po.TaxStatus,
	po.PortfolioTypeCode,
	pc.ManagementAgreement,

--	calc stuff
	SUM(h.ZeroMarketValue + isnull(h.AccruedInterest,0)) [Balance],
	isnull([APXUserCustom].[fGetRMDMultiplier](contact.OwnerAge, contact.SpouseAge, po.PortfolioTypeCode),1) [Multiplier],
	SUM(h.ZeroMarketValue + isnull(h.AccruedInterest,0)) * [APXUserCustom].[fGetRMDMultiplier](contact.OwnerAge, contact.SpouseAge, po.PortfolioTypeCode) [RMD], --	if a valid RMD value isn't available multiplier = 1
	flows.TradeAmount [LongOut],
	port.ReportingCurrencyPrecision,

--	contact related stuff
	contact.BlBkCID,
	contact.OwnerName,
	contact.OwnerAge,
	contact.OwnerDOB,
	contact.OwnerDOD,
	contact.OwnerEmail,
	contact.PM,
	contact.SpouseName,
	contact.SpouseAge,
	contact.SpouseDOB,
	contact.SpouseDOD,
	contact.SpouseEmail,
	contact.RMDMethod,
	contact.RMDNotes,
	contact.TaxNumber
from APXUser.fAppraisal(@Holdings) h
join APXUser.vPortfolioBase p on
	p.PortfolioBaseID = h.PortfolioBaseID
join APXUser.vPortfolio po on
	po.PortfolioID = h.PortfolioBaseID
join APXSSRS.fPortfolioBaseLangPerLocale(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) port on
	port.PortfolioBaseID = h.PortfolioBaseID
left join APXUser.vPortfolioBaseCustom pc on
	pc.PortfolioBaseID = h.PortfolioBaseID
left join (select 
				c.PortfolioBaseID,
				sum(c.TradeAmount) [TradeAmount]
			from APXUser.fContributionWithdrawals(@Contributions) c
			where c.TransactionCode in ('lo','to')
			group by c.PortfolioBaseID) flows on
	flows.PortfolioBaseID = h.PortfolioBaseID
join @contact contact on
	contact.PortfolioBaseID = h.PortfolioBaseID
group by h.PortfolioBaseIDOrder, h.PortfolioBaseID, port.ReportingCurrencyPrecision, flows.TradeAmount, po.TaxStatus, po.PortfolioTypeCode,
	pc.ManagementAgreement, p.PortfolioBaseCode, contact.BlBkCID, contact.OwnerName, contact.OwnerAge, contact.OwnerDOB, contact.OwnerDOD,
	contact.OwnerEmail, contact.PM, contact.SpouseName, contact.SpouseAge, contact.SpouseDOB, contact.SpouseDOD, contact.SpouseEmail, contact.RMDMethod,
	contact.RMDNotes, contact.TaxNumber
order by h.PortfolioBaseIDOrder
end