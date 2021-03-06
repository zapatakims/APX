IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportFixedIncomeSummaryDataHandle]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportFixedIncomeSummaryDataHandle]
GO

create procedure [APXUserCustom].[pReportFixedIncomeSummaryDataHandle]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	@ReportingCurrencyCode dtCurrencyCode,
	
	-- Optional parameters for sqlrep proc
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@AccruedInterestID int = null,			-- Use Settings (0)
	@YieldOptionID int = null,				-- Use Settings (0)
	@LocaleID int = null,					-- Use Portfolio Settings
	@OverridePortfolioSettings bit = null,
	@DataHandleName nvarchar(max) = 'Appraisal'
as
begin
-- 1. Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- 2. Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@ReportData out
-- 3. Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
exec APXUser.pGetEffectiveParameter
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out
--declare @timer datetime = getdate()
-- 4. Get the ratings.
declare @NotRated char(9) = 'Not Rated'
declare @sandpRatings table(RatingID smallint PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
declare @moodyRatings table(RatingID smallint PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
declare @fitchRatings table(RatingID smallint PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
insert into @fitchRatings select * from APXSSRS.fRatings('f')
insert into @moodyRatings select * from APXSSRS.fRatings('m')
insert into @sandpRatings select * from APXSSRS.fRatings('s')
declare @fitchNotRatedID int = (select RatingID from @fitchRatings where Rating = @NotRated)
declare @moodyNotRatedID int = (select RatingID from @moodyRatings where Rating = @NotRated)
declare @sandpNotRatedID int = (select RatingID from @sandpRatings where Rating = @NotRated)

declare @Issuers table (
	PortfolioBaseIDOrder int,
	TotalIssuers int)
insert into @Issuers
	select
		a.PortfolioBaseIDOrder,
		count(distinct sec.IssuerID)
	from APXUser.fAppraisal(@ReportData) a
	join APXUser.vSecurityVariant s on
		s.SecurityID = a.SecurityID and
		s.SectypeCode = a.SecTypeCode and
		s.IsShort = a.IsShortPosition
	join APXUser.vSecurity sec on 
			sec.SecurityID = a.SecurityID and
			sec.SecTypeBaseCode = s.SecTypeBaseCode
	where s.IsBond = 1 and
		a.PortfolioBaseID = @PortfolioBaseID and
		a.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
	group by a.PortfolioBaseIDOrder

-- 11. Get the holdings
declare @holdings table(
	PortfolioBaseIDOrder int,
	SecurityID dtID,
	SecTypeCode dtSecTypeCode,
	IsShortPosition dtBoolean,
	AccruedInterest dtFloat,
	AnnualIncome dtFloat,
	CostBasis dtFloat,
	Coupon dtFloat,
	Duration dtFloat,
	FitchRatingID smallint,
	MarketValue dtFloat,
	MaturityDate date,
	MaturityDateYears float,
  	MoodyRatingID smallint,
	PortfolioBaseID dtID,
	Quantity dtFloat,
	ReportDate date,
	SPRatingID smallint,
	UnrealizedGainLoss dtFloat,
	Yield dtFloat,
	ZeroMarketValue dtFloat)
--	primary key(PortfolioBaseIDOrder, SecurityID, SecTypeCode, IsShortPosition))
insert into @holdings
	select
		a.PortfolioBaseIDOrder,
		a.SecurityID,
		a.SecTypeCode,
		a.IsShortPosition,
		a.AccruedInterest,
		AnnualIncome = case when a.BondStatusCode = 'd' then 0 else a.AnnualIncome end,
		CostBasis = case when s.IsZeroMarketValue = 1 then 0 else isnull(a.CostBasis, 0) end,
		Coupon = a.ReportingCurrencyInterestOrDividendRate,
		a.Duration,
		FitchRatingID = case
			when s.FitchRating in ('B','C','D') then
				(select r.RatingID from @fitchRatings r where r.Rating = s.FitchRating and
				 r.Category = (case when s.MatureDate is not null and s.IssueDate is not null and DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-13,s.MatureDate)),APXUser.fGetGenericDate('{edtm}',s.MatureDate)) > DateDiff(day, s.IssueDate, s.MatureDate) then 5 else 1 end))
			else
				coalesce((select r.RatingID from @fitchRatings r where r.Rating = s.FitchRating), @fitchNotRatedID)
			end,
		MarketValue = isnull(a.MarketValue, 0), -- used for weightings
		MaturityDate = case -- Get Effective Maturity Date of Bond
			when s.isMBS = 1 then isnull(a.effectivematuritydate, a.estmaturitydate)
			when a.BondStatusDate is not null then a.BondStatusDate
			when s.MatureDate < a.effectivematuritydate then s.MatureDate
			else a.effectivematuritydate end,
--			ELSE Coalesce(a.bondstatusdate, (CASE WHEN secvar.MatureDate < a.effectivematuritydate THEN secvar.MatureDate ELSE a.effectivematuritydate END) END,
		MaturityDateYears = null,
		MoodyRatingID = case
			when s.MoodyRating = 'SG' then
				(select r.RatingID from @moodyRatings r where r.Rating = s.MoodyRating and
				 r.Category = (case when s.IsVRS = 1 then 6 else 5 end))
			else
				coalesce((select r.RatingID from @moodyRatings r where r.Rating = s.MoodyRating), @moodyNotRatedID)
			end,		
	  	a.PortfolioBaseID,
		a.Quantity,
		a.ReportDate,
		SpRatingID =
			coalesce((select r.RatingID from @sandpRatings r where r.Rating = s.SPRating), @sandpNotRatedID),
		a.UnrealizedGainLoss,
		a.Yield,
		ZeroMarketvalue = isnull(a.ZeroMarketValue, 0)
	from APXUser.fAppraisal(@ReportData) a
	join APXUser.vSecurityVariant s on
		s.SecurityID = a.SecurityID and
		s.SectypeCode = a.SecTypeCode and
		s.IsShort = a.IsShortPosition
	where s.IsBond = 1 and
		a.PortfolioBaseID = @PortfolioBaseID and
		a.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
--select * from @holdings order by MaturityDate
--return
--select GETDATE() - @timer; set @timer = GETDATE()
-- 12. Get ReportDateEdty and ReportDateEdly (Calls to APXUser.fGetGenericDate are VERY expensive)
declare @reportDates table(Base date primary key, Edly date, Edty date, Diff float)
insert into @reportDates (Base) (select distinct ReportDate from @holdings)
update @reportDates set
	Edly = APXUser.fGetGenericDate('{edly}',Base),
	Edty = APXUser.fGetGenericDate('{edty}',Base)
update @reportDates set
	Diff = CONVERT(FLOAT,DATEDIFF(day,Base,Edty)) / CONVERT(FLOAT,DATEDIFF(day,Edly,Edty))
-- 13. Get MaturityDateEdty and MaturityDateEdly (Calls to APXUser.fGetGenericDate are VERY expensive)
declare @maturityDates table(Base date primary key, Edly date, Edty date, Diff float) -- Unfortunately, MaturityDate can be null, so there can be no primary key
insert into @maturityDates (Base) (select distinct isnull(MaturityDate, ReportDate) from @holdings)
update @maturityDates set
	Edly = APXUser.fGetGenericDate('{edly}',Base),
	Edty = APXUser.fGetGenericDate('{edty}',Base)
update @maturityDates set
	Diff = (CONVERT(FLOAT,DATEDIFF(day,Edly,Base))/ CONVERT(FLOAT,DateDIFF(day,Edly,Edty)))
--select * from @maturityDates order by Base; return;
-- 14. Set the MaturityDateYears
update @holdings set MaturityDateYears =
	datediff(year, (select Edty from @reportDates where Base = ReportDate), (select Edly from @maturityDates where Base = MaturityDate)) +
	(select Diff from @maturityDates where Base = MaturityDate) + -- MaturityDateDiff
	(select Diff from @reportDates where Base = ReportDate) -- ReportDateDiff
--select GETDATE() - @timer; set @timer = GETDATE()
--select * from @holdings where PortfolioBaseIDOrder = 57 order by MaturityDateYears --; return;
-- 15.
SELECT
	-- TODO: This column is VERY expensive
	-- Indicates whether Accrued Interest is visible.
	-- Based on the effective value of @AccruedInterestID and Security.IsBond.
	AccruedInterestIsVisible = convert(bit, case
		when APXUser.fShowAccruedInterestOnAllReports(@OverridePortfolioSettings, @AccruedInterestID, p.AccruedInterestID) = 1 then 1
		else 0 end),
	tblhold.TotalAccruedInterest,
	tblhold.TotalAnnualIncome,
	tblhold.TotalCostBasis,
	tblhold.TotalParValue,
	tblhold.TotalMarketValue,
	tblhold.TotalGainLoss,
	tblhold.AverageYield,
	tblhold.AverageMaturity,
	tblhold.AverageCoupon,
	tblhold.AverageDuration,
	tblhold.AverageSPRating,
	tblhold.AverageMoodyRating,
	tblhold.AverageFitchRating,
	p.FormatReportingCurrency,
	p.LegacyLocaleID,
	p.LocaleID,
	tblissuers.TotalIssuers,
		
	tblhold.PortfolioBaseID,
	tblhold.PortfolioBaseIDOrder
FROM (	
	SELECT
		SUM(a.TotalParValue) as TotalParValue,
		SUM(a.TotalAnnualIncome) as TotalAnnualIncome,
		SUM(a.TotalCostBasis) as TotalCostBasis,
		SUM(a.TotalAccruedInterest) as TotalAccruedInterest,
		SUM(a.TotalMarketValue) as TotalMarketValue,
		SUM(a.TotalGainLoss) as TotalGainLoss,
		MAX(a.AverageYield) as AverageYield,
		MAX(a.AverageMaturity) as AverageMaturity,
		MAX(a.AverageCoupon) as AverageCoupon,
		MAX(a.AverageDuration) as AverageDuration,
		ISNULL(MAX(sap.Rating),@NotRated) as AverageSPRating,
		ISNULL(MAX(mdy.Rating),@NotRated) as AverageMoodyRating,
		ISNULL(MAX(fit.Rating),@NotRated) as AverageFitchRating,
		PortfolioBaseID = max(a.PortfolioBaseID),
		a.PortfolioBaseIDOrder
	FROM (
		SELECT
			TotalParValue = SUM(hold.Quantity),
			TotalMarketValue = SUM(hold.ZeroMarketValue),
			TotalCostBasis = SUM(hold.CostBasis),
			TotalGainLoss = SUM(hold.UnrealizedGainLoss),
			TotalAnnualIncome = SUM(hold.AnnualIncome),
			TotalAccruedInterest = SUM(hold.AccruedInterest),
			AverageYield = case when SUM(hold.MarketValue) = 0 then NULL else SUM(hold.Yield * hold.MarketValue)/SUM(hold.MarketValue) end,
			AverageMaturity = case when SUM(hold.MarketValue) = 0 then NULL else 
					--SUM(	(	DATEDIFF(year,APXUser.fGetGenericDate('{edty}',hold.ReportDate),APXUser.fGetGenericDate('{edly}',hold.MaturityDate))
					--		+	(CONVERT(FLOAT,DATEDIFF(day,hold.ReportDate,APXUser.fGetGenericDate('{edty}',hold.ReportDate)))/ CONVERT(FLOAT,DATEDIFF(day,APXUser.fGetGenericDate('{edly}',hold.ReportDate),APXUser.fGetGenericDate('{edty}',hold.ReportDate))))
					--		+	(CONVERT(FLOAT,DATEDIFF(day,APXUser.fGetGenericDate('{edly}',hold.MaturityDate),hold.MaturityDate))/ CONVERT(FLOAT,DateDIFF(day,APXUser.fGetGenericDate('{edly}',hold.MaturityDate),APXUser.fGetGenericDate('{edty}',hold.MaturityDate))))
					--		) * hold.MarketValue
					--	)/SUM(hold.MarketValue) 
					--SUM(	(	DATEDIFF(year,hold.ReportDateEdty,hold.MaturityDateEdly)
					--		--+	(CONVERT(FLOAT,DATEDIFF(day,hold.ReportDate,hold.ReportDateEdty))/ CONVERT(FLOAT,DATEDIFF(day,hold.ReportDateEdly,hold.ReportDateEdty)))
					--		+	hold.ReportDateDiff
					--		--+	(CONVERT(FLOAT,DATEDIFF(day,hold.MaturityDateEdly,hold.MaturityDate))/ CONVERT(FLOAT,DateDIFF(day,hold.MaturityDateEdly,hold.MaturityDateEdty)))
					--		+	hold.MaturityDateDiff
					--		) * hold.MarketValue
					--	)/SUM(hold.MarketValue) 
					SUM(hold.MaturityDateYears * hold.MarketValue) / SUM(hold.MarketValue) 
				end,
			AverageCoupon = case when SUM(hold.MarketValue) = 0 then NULL else SUM(hold.Coupon * hold.MarketValue)/SUM(hold.MarketValue) end,
			AverageDuration = case when SUM(hold.MarketValue) = 0 then NULL else SUM(hold.Duration * hold.MarketValue)/SUM(hold.MarketValue) end,
			AverageSPRating = null,
			AverageMoodyRating = null,
			AverageFitchRating = null,
			PortfolioBaseID = max(hold.PortfolioBaseID),
			hold.PortfolioBaseIDOrder
		FROM @holdings hold --CTE_Holdings hold
		GROUP BY hold.PortfolioBaseIDOrder --, PortfolioBaseID
		UNION ALL
		SELECT
			TotalParValue = null,
			TotalMarketValue = null,
			TotalCostBasis = null,
			TotalGainLoss = null,
			TotalAnnualIncome = null,
			TotalAccruedInterest = null,
			AverageYield = null,
			AverageMaturity = null,
			AverageCoupon = null,
			AverageDuration = null,
			AverageSPRating =	case 
									when SUM(hold.MarketValue) = 0 then NULL 
									else ROUND((SUM(sp.SortOrder * hold.MarketValue) / SUM(hold.MarketValue)) + case when (CONVERT(Decimal(38,8),(SUM(sp.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10) = 0 then 0 else (10 - (CONVERT(Decimal(38,8),(SUM(sp.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10)) end,-1)
								end,
			AverageMoodyRating = null,
			AverageFitchRating = null,
			PortfolioBaseID = max(hold.PortfolioBaseID),
			hold.PortfolioBaseIDOrder
		FROM @holdings hold --CTE_Holdings hold
		join @sandpRatings sp on sp.RatingID = hold.SPRatingID
--		WHERE hold.SPIsException = 0 and hold.SPOrder <= 310
		WHERE sp.IsException = 0 and sp.SortOrder <= 310
		GROUP BY hold.PortfolioBaseIDOrder --, PortfolioBaseID
		UNION ALL
		SELECT
			TotalParValue = null,
			TotalMarketValue = null,
			TotalCostBasis = null,
			TotalGainLoss = null,
			TotalAnnualIncome = null,
			TotalAccruedInterest = null,
			AverageYield = null,
			AverageMaturity = null,
			AverageCoupon = null,
			AverageDuration = null,
			AverageSPRating = null,
			AverageMoodyRating = case
				when SUM(hold.MarketValue) = 0 then NULL 
				else ROUND((SUM(moody.SortOrder * hold.MarketValue) / SUM(hold.MarketValue)) + case when (CONVERT(Decimal(38,8),(SUM(moody.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10) = 0 then 0 else (10 - (CONVERT(Decimal(38,8),(SUM(moody.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10)) end,-1) end,
			AverageFitchRating = null,
			PortfolioBaseID = max(hold.PortfolioBaseID),
			hold.PortfolioBaseIDOrder
		FROM @holdings hold --CTE_Holdings hold
		join @moodyRatings moody on moody.RatingID = hold.MoodyRatingID
--		WHERE hold.MoodyIsException = 0 and hold.MoodyOrder <= 260
		WHERE moody.IsException = 0 and moody.SortOrder <= 260
		GROUP BY hold.PortfolioBaseIDOrder --, PortfolioBaseID
		UNION ALL
		SELECT
			TotalParValue = null,
			TotalMarketValue = null,
			TotalCostBasis = null,
			TotalGainLoss = null,
			TotalAnnualIncome = null,
			TotalAccruedInterest = null,
			AverageYield = null,
			AverageMaturity = null,
			AverageCoupon = null,
			AverageDuration = null,
			AverageSPRating = null,
			AverageMoodyRating = null,
			AverageFitchRating = case
				when SUM(hold.MarketValue) = 0 then NULL
				else ROUND((SUM(fitch.SortOrder * hold.MarketValue) / SUM(hold.MarketValue)) + case when (CONVERT(Decimal(38,8),(SUM(fitch.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10) = 0 then 0 else (10 - (CONVERT(Decimal(38,8),(SUM(fitch.SortOrder * hold.MarketValue) / SUM(hold.MarketValue))) % 10)) end,-1) end,
			PortfolioBaseID = max(hold.PortfolioBaseID),
			hold.PortfolioBaseIDOrder
		FROM @holdings hold --CTE_Holdings hold
		join @fitchRatings fitch on fitch.RatingID = hold.FitchRatingID
		WHERE fitch.IsException = 0
		GROUP BY hold.PortfolioBaseIDOrder --, PortfolioBaseID
	) a
	left join @fitchRatings fit on fit.SortOrder = a.AverageFitchRating
	left join @moodyRatings mdy on mdy.SortOrder = a.AverageMoodyRating
	left join @sandpRatings sap on sap.SortOrder = a.AverageSPRating
--	join @fitchRatings fit on fit.SortOrder = a.AverageFitchRating
--	join @moodyRatings mdy on mdy.SortOrder = a.AverageMoodyRating
--	join @sandpRatings sap on sap.SortOrder = a.AverageSPRating
	GROUP BY a.PortfolioBaseIDOrder --, a.PortfolioBaseID
) tblhold
join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
	p.PortfolioBaseID = tblhold.PortfolioBaseID
join @Issuers tblIssuers on tblIssuers.PortfolioBaseIDOrder = tblhold.PortfolioBaseIDOrder
where tblhold.PortfolioBaseID = @PortfolioBaseID and
	  tblhold.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
order by tblhold.PortfolioBaseIDOrder
--select GETDATE() - @timer
end
