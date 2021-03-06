IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pReportBondDistributionDataHandle]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pReportBondDistributionDataHandle]
GO

create procedure [APXUserCustom].[pReportBondDistributionDataHandle]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	
	-- Optional parameters for sqlrep proc
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	
	@ShowCurrencyFullPrecision bit = null,	-- Use Settings
	@YieldOptionID int = null,				-- Use Settings (0)
	@LocaleID int = null,					-- Use Portfolio Settings
	
	-- Other optional parameters
	@MaturityScale int = 2, -- 1: Months 2: Years
	@MaturityBracket1 int = 1,
	@MaturityBracket2 int = 3,
	@MaturityBracket3 int = 5,
	--@MaturityBracket4 int = 7,
	--@MaturityBracket5 int = 10,
	@DurationBracket1 int = 1,
	@DurationBracket2 int = 3,
	@DurationBracket3 int = 5,
	@DurationBracket4 int = 7,
	@DurationBracket5 int = 10,
	@CouponBracket1 int = 1,
	@CouponBracket2 int = 3,
	@CouponBracket3 int = 5,
	@CouponBracket4 int = 7,
	@CouponBracket5 int = 10,
	
	@DataHandleName nvarchar(max) = 'Appraisal'
as
begin
-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- Execute the sqlrep proc that will fill the @ReportData varbinary(max).
-- To get the effective value for 'Use Settings' parameters, specify 'out'.
declare @ReportData varbinary(max)
exec APXUser.pReportDataGetFromHandle @DataHandle, @DataHandleName, @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder,  @ReportData=@ReportData out
--    Get the effective values for 'Use Settings' parameters that are not passed to pAppraisal.
--    Also calculate some new variables that are internal to this proc.
declare @YieldIsCurrent bit
exec APXUser.pGetEffectiveParameter
	-- Parameters passed into this proc that need to be resolved
	@ShowCurrencyFullPrecision = @ShowCurrencyFullPrecision out,
	-- Parameters internal to this proc that are derived from other parameters.
	@YieldOptionID = @YieldOptionID, -- Effective value determined above. Need for determining @YieldIsCurrent.
	@YieldIsCurrent = @YieldIsCurrent out -- A boolean that is derived from multi-valued @YieldOptionID.
--declare @timer datetime = getdate()
declare @MaturityBracket1Text as nvarchar(max) =  case when @MaturityScale = 1 then 'Under ' + CAST(@MaturityBracket1 as nvarchar(max)) + case when @MaturityBracket1 > 1 then ' Mths' else ' Mth' end
                                                       else 'Under ' + CAST(@MaturityBracket1 as nvarchar(max)) + case when @MaturityBracket1 > 1 then ' Yrs' else ' Yr' end
                                                  end
declare @MaturityBracket2Text as nvarchar(max) =  case when @MaturityScale = 1 then CAST(@MaturityBracket1 as nvarchar(max)) + case when @MaturityBracket1 > 1 then ' Mths' else ' Mth' end  + ' - ' + CAST(@MaturityBracket2 as nvarchar(max)) + case when @MaturityBracket2 > 1 then ' Mths' else ' Mth' end
                                                       else CAST(@MaturityBracket1 as nvarchar(max)) + case when @MaturityBracket1 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@MaturityBracket2 as nvarchar(max)) + case when @MaturityBracket2 > 1 then ' Yrs' else ' Yr' end
                                                  end
declare @MaturityBracket3Text as nvarchar(max) =  case when @MaturityScale = 1 then CAST(@MaturityBracket2 as nvarchar(max)) + case when @MaturityBracket2 > 1 then ' Mths' else ' Mth' end  + ' - ' + CAST(@MaturityBracket3 as nvarchar(max)) + case when @MaturityBracket3 > 1 then ' Mths' else ' Mth' end
                                                       else CAST(@MaturityBracket2 as nvarchar(max)) + case when @MaturityBracket2 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@MaturityBracket3 as nvarchar(max)) + case when @MaturityBracket3 > 1 then ' Yrs' else ' Yr' end
                                                  end
--declare @MaturityBracket4Text as nvarchar(max) =  case when @MaturityScale = 1 then CAST(@MaturityBracket3 as nvarchar(max)) + case when @MaturityBracket3 > 1 then ' Mths' else ' Mth' end  + ' - ' + CAST(@MaturityBracket4 as nvarchar(max)) + case when @MaturityBracket4 > 1 then ' Mths' else ' Mth' end
--                                                       else CAST(@MaturityBracket3 as nvarchar(max)) + case when @MaturityBracket3 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@MaturityBracket4 as nvarchar(max)) + case when @MaturityBracket4 > 1 then ' Yrs' else ' Yr' end
--                                                  end
--declare @MaturityBracket5Text as nvarchar(max) =  case when @MaturityScale = 1 then CAST(@MaturityBracket4 as nvarchar(max)) + case when @MaturityBracket4 > 1 then ' Mths' else ' Mth' end  + ' - ' + CAST(@MaturityBracket5 as nvarchar(max)) + case when @MaturityBracket5 > 1 then ' Mths' else ' Mth' end
--                                                       else CAST(@MaturityBracket4 as nvarchar(max)) + case when @MaturityBracket4 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@MaturityBracket5 as nvarchar(max)) + case when @MaturityBracket5 > 1 then ' Yrs' else ' Yr' end
--                                                  end
declare @MaturityBracket6Text as nvarchar(max) =  case when @MaturityScale = 1 then 'Over ' + CAST(@MaturityBracket3 as nvarchar(max))+  case when @MaturityBracket3 > 1 then ' Mths' else ' Mth' end
                                                       else 'Over ' + CAST(@MaturityBracket3 as nvarchar(max))+  case when @MaturityBracket3 > 1 then ' Yrs' else ' Yr' end
                                                  end
declare @DurationBracket1Text as nvarchar(max) =  'Under ' + CAST(@DurationBracket1 as nvarchar(max)) + case when @DurationBracket1 > 1 then ' Yrs' else ' Yr' end
declare @DurationBracket2Text as nvarchar(max) =  CAST(@DurationBracket1 as nvarchar(max)) + case when @DurationBracket1 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@DurationBracket2 as nvarchar(max)) + case when @DurationBracket2 > 1 then ' Yrs' else ' Yr' end
declare @DurationBracket3Text as nvarchar(max) =  CAST(@DurationBracket2 as nvarchar(max)) + case when @DurationBracket2 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@DurationBracket3 as nvarchar(max)) + case when @DurationBracket3 > 1 then ' Yrs' else ' Yr' end
declare @DurationBracket4Text as nvarchar(max) =  CAST(@DurationBracket3 as nvarchar(max)) + case when @DurationBracket3 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@DurationBracket4 as nvarchar(max)) + case when @DurationBracket4 > 1 then ' Yrs' else ' Yr' end
declare @DurationBracket5Text as nvarchar(max) =  CAST(@DurationBracket4 as nvarchar(max)) + case when @DurationBracket4 > 1 then ' Yrs' else ' Yr' end  + ' - ' + CAST(@DurationBracket5 as nvarchar(max)) + case when @DurationBracket5 > 1 then ' Yrs' else ' Yr' end
declare @DurationBracket6Text as nvarchar(max) =  'Over ' + CAST(@DurationBracket5 as nvarchar(max))+  case when @DurationBracket5 > 1 then ' Yrs' else ' Yr' end
declare @CouponBracket1Text as nvarchar(max) =  'Under ' + CAST(@CouponBracket1 as nvarchar(max)) + '%'
declare @CouponBracket2Text as nvarchar(max) =  CAST(@CouponBracket1 as nvarchar(max)) + '%' + ' - ' + CAST(@CouponBracket2 as nvarchar(max)) + '%'
declare @CouponBracket3Text as nvarchar(max) =  CAST(@CouponBracket2 as nvarchar(max)) + '%' + ' - ' + CAST(@CouponBracket3 as nvarchar(max)) + '%'
declare @CouponBracket4Text as nvarchar(max) =  CAST(@CouponBracket3 as nvarchar(max)) + '%' + ' - ' + CAST(@CouponBracket4 as nvarchar(max)) + '%'
declare @CouponBracket5Text as nvarchar(max) =  CAST(@CouponBracket4 as nvarchar(max)) + '%' + ' - ' + CAST(@CouponBracket5 as nvarchar(max)) + '%'
declare @CouponBracket6Text as nvarchar(max) =  'Over ' + CAST(@CouponBracket5 as nvarchar(max))+  '%'
-- Get the decoration text into a local table
declare @Context char(6) = 'Header';
declare @Decor table(
	APXLocaleID dtID primary key,
	MaturityBracket1Text nvarchar(255), 
	MaturityBracket2Text nvarchar(255),
	MaturityBracket3Text nvarchar(255), 
	MaturityBracket4Text nvarchar(255),	
	MaturityBracket5Text nvarchar(255), 
	MaturityBracket6Text nvarchar(255),
	DurationBracket1Text nvarchar(255), 
	DurationBracket2Text nvarchar(255),
	DurationBracket3Text nvarchar(255), 
	DurationBracket4Text nvarchar(255),	
	DurationBracket5Text nvarchar(255), 
	DurationBracket6Text nvarchar(255),
	CouponBracket1Text nvarchar(255), 
	CouponBracket2Text nvarchar(255),
	CouponBracket3Text nvarchar(255), 
	CouponBracket4Text nvarchar(255),	
	CouponBracket5Text nvarchar(255), 
	CouponBracket6Text nvarchar(255)
)
insert into @Decor (APXLocaleID,
	MaturityBracket1Text, 
	MaturityBracket2Text, 
	MaturityBracket3Text, 
	--MaturityBracket4Text, 
	--MaturityBracket5Text, 
	MaturityBracket6Text,
	DurationBracket1Text, 
	DurationBracket2Text, 
	DurationBracket3Text, 
	DurationBracket4Text, 
	DurationBracket5Text, 
	DurationBracket6Text,
	CouponBracket1Text, 
	CouponBracket2Text, 
	CouponBracket3Text, 
	CouponBracket4Text, 
	CouponBracket5Text, 
	CouponBracket6Text)
select q.LocaleID, 
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket1Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket2Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket3Text),
	--APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket4Text),
	--APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket5Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@MaturityBracket6Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket1Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket2Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket3Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket4Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket5Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@DurationBracket6Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket1Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket2Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket3Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket4Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket5Text),
	APXSSRS.fReportTranslation(q.LocaleID,@Context,@CouponBracket6Text)
from (
	select distinct p.LocaleID
	from APXUser.fAppraisal(@ReportData) a
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on p.PortfolioBaseID = a.PortfolioBaseID
	where @LocaleID is null
	union
	select @LocaleID
	where @LocaleID is not null
	) q
-- 4. Get the ratings.
declare @NotRated char(9) = 'Not Rated'
declare @sandpRatings table(RatingID int PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
declare @moodyRatings table(RatingID int PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
declare @fitchRatings table(RatingID int PRIMARY KEY, SortOrder smallint, Rating str16, Category tinyint, IsException bit)
insert into @fitchRatings select * from APXSSRS.fRatings('f')
insert into @moodyRatings select * from APXSSRS.fRatings('m')
insert into @sandpRatings select * from APXSSRS.fRatings('s')
declare @fitchNotRatedID int = (select RatingID from @fitchRatings where Rating = @NotRated)
declare @moodyNotRatedID int = (select RatingID from @moodyRatings where Rating = @NotRated)
declare @sandpNotRatedID int = (select RatingID from @sandpRatings where Rating = @NotRated)
--select GETDATE() - @timer; set @timer = GETDATE()
declare @holdings table(
	PortfolioBaseIDOrder dtID,
	SecurityID dtID,
	SecTypeCode dtSecTypeCode,
	IsShortPosition dtBoolean,
	Coupon dtFloat,
	Duration dtFloat,
	FitchRatingID smallint,
--	LotNumber dtID, -- need to make it unique
	MaturityDate date,
	MarketValue dtFloat,
	MarketValueNoAI dtFloat,
	MoodyRatingID smallint,
	PortfolioBaseID dtID,
	ReportDate date,
--	SecuritySymbol nvarchar(32), -- ???
--	SecurityName nvarchar(max), -- ??,
	SpRatingID smallint,
	TotalMarketValue dtFloat,
	Yield dtFloat)
--	,primary key(PortfolioBaseIDOrder, SecurityID, SecTypeCode, IsShortPosition, LotNumber))
INSERT INTO @holdings
	SELECT
		a.PortfolioBaseIDOrder,
		a.SecurityID,
		a.SecTypeCode,
		a.IsShortPosition,
		
		Coupon = a.ReportingCurrencyInterestOrDividendRate,
		a.Duration,
		FitchRatingID = case
			when s.FitchRating in ('B','C','D') then
				(select r.RatingID from @fitchRatings r where r.Rating = s.FitchRating and
				 r.Category = (case when s.MatureDate is not null and s.IssueDate is not null and DateDiff(day,APXUser.fGetGenericDate('{edtm}',DateAdd(month,-13,s.MatureDate)),APXUser.fGetGenericDate('{edtm}',s.MatureDate)) > DateDiff(day, s.IssueDate, s.MatureDate) then 5 else 1 end))
			else
				coalesce((select r.RatingID from @fitchRatings r where r.Rating = s.FitchRating), @fitchNotRatedID)
			end,
--		isnull(a.LotNumber, 0),	
		-- Get Effective Maturity Date of Bond
		MaturityDate = CASE 
		WHEN s.isMBS = 1 THEN Coalesce(a.effectivematuritydate, a.estmaturitydate)
		ELSE
			Coalesce(a.bondstatusdate,
					CASE	WHEN s.MatureDate < a.effectivematuritydate THEN s.MatureDate
							ELSE a.effectivematuritydate
					END)
		END,
		MarketValue = ISNULL(a.ZeroMarketValue,0) + ISNULL(a.AccruedInterest,0),
		MarketValueNoAI = ISNULL(a.MarketValue,0), -- used for weightings
		MoodyRatingID = case
			when s.MoodyRating = 'SG' then
				(select r.RatingID from @moodyRatings r where r.Rating = s.MoodyRating and
				 r.Category = (case when s.IsVRS = 1 then 6 else 5 end))
			else
				coalesce((select r.RatingID from @moodyRatings r where r.Rating = s.MoodyRating), @moodyNotRatedID)
			end,		
		a.PortfolioBaseID,
		a.ReportDate,
--		s.SecuritySymbol,
--		s.SecurityName,
		SpRatingID = coalesce((select r.RatingID from @sandpRatings r where r.Rating = s.SPRating), @sandpNotRatedID),
		TotalMarketValue = SUM(ISNULL(a.ZeroMarketValue,0) + ISNULL(a.AccruedInterest,0)) OVER (Partition by a.PortfolioBaseIDOrder),
		a.Yield
	FROM APXUser.fAppraisal(@ReportData) a
--		JOIN APXUser.vSecurity sec
--			on sec.SecurityID = a.SecurityID
		JOIN APXUser.vSecurityVariant s
			on s.SecurityID = a.SecurityID
			and s.SectypeCode = a.SecTypeCode
			and s.IsShort = a.IsShortPosition
	WHERE s.IsBond = 1 and
		a.PortfolioBaseID = @PortfolioBaseID and
		a.PortfolioBaseIDOrder = @PortfolioBaseIDOrder
	
SELECT
	tblhold.DataType,
	tblhold.Bracket,
	Label = case when DataType = 'Duration' then
					case when tblhold.Bracket = 1 then decor.DurationBracket1Text
						 when tblhold.Bracket = 2 then decor.DurationBracket2Text
						 when tblhold.Bracket = 3 then decor.DurationBracket3Text
						 when tblhold.Bracket = 4 then decor.DurationBracket4Text
						 when tblhold.Bracket = 5 then decor.DurationBracket5Text
						 else decor.DurationBracket6Text
					end
				 when DataType = 'Coupon' then
					case when tblhold.Bracket = 1 then decor.CouponBracket1Text
						 when tblhold.Bracket = 2 then decor.CouponBracket2Text
						 when tblhold.Bracket = 3 then decor.CouponBracket3Text
						 when tblhold.Bracket = 4 then decor.CouponBracket4Text
						 when tblhold.Bracket = 5 then decor.CouponBracket5Text
						 else decor.CouponBracket6Text
					end
				 when DataType = 'Maturity' then
					case when tblhold.Bracket = 1 then decor.MaturityBracket1Text
						 when tblhold.Bracket = 2 then decor.MaturityBracket2Text
						 when tblhold.Bracket = 3 then decor.MaturityBracket3Text
						 --when tblhold.Bracket = 4 then decor.MaturityBracket4Text
						 --when tblhold.Bracket = 5 then decor.MaturityBracket5Text
						 else decor.MaturityBracket6Text
					end
				 else tblhold.Label
			end,
--	tblhold.SecuritySymbol,
--	tblhold.SecurityName,
	tblhold.MarketValue,
	tblhold.MarketValueNoAI,
	tblhold.PercentAssets,
--	tblhold.Yield,
--	tblhold.Coupon,
--	tblhold.Duration,
	tblhold.WeightedYield,
	tblhold.WeightedCoupon,
	tblhold.WeightedDuration,
	p.FormatReportingCurrency,
	p.LegacyLocaleID,
	-- The effective value of @LocaleID.
	-- If @LocaleID is not specified or null, then portfolioBase.LocaleID.
	-- Otherwise @LocaleID.
--	LocaleID = isnull(@LocaleID, portfolioBase.LocaleID),
	p.LocaleID,
		
--	tblhold.PortfolioBaseID,
	tblhold.PortfolioBaseIDOrder,
--	ReportHeading1 = isnull(nullif(portfolioBase.ReportHeading1, ''), '?'),	
--	ReportHeading2 = nullif(portfolioBase.ReportHeading2, ''),
--	ReportHeading3 = nullif(portfolioBase.ReportHeading3, ''),
	
--	ReportingCurrencyCode = reportingCurrency.CurrencyCode,
--  ReportingCurrencyName = reportingCurrency.CurrencyName,
    @YieldIsCurrent as YieldIsCurrent
FROM (	
	SELECT
		DataType = 'Duration',
		Bracket =	case 
								when hold.Duration < @DurationBracket1 then 1
								when hold.Duration < @DurationBracket2 then 2
								when hold.Duration < @DurationBracket3 then 3
								when hold.Duration < @DurationBracket4 then 4
								when hold.Duration < @DurationBracket5 then 5
								else 6
							end,
		Label =	'',
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0 then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	UNION ALL
	SELECT
		DataType = 'Maturity',
		Bracket = case	when @MaturityScale = 1 then
							case 
								when hold.MaturityDate < DateAdd(MONTH,Cast(@MaturityBracket1 as int),hold.ReportDate) then 1
								when hold.MaturityDate < DateAdd(MONTH,Cast(@MaturityBracket2 as int),hold.ReportDate) then 2
								when hold.MaturityDate < DateAdd(MONTH,Cast(@MaturityBracket3 as int),hold.ReportDate) then 3
								--when hold.MaturityDate < DateAdd(MONTH,Cast(@MaturityBracket4 as int),hold.ReportDate) then 4
								--when hold.MaturityDate < DateAdd(MONTH,Cast(@MaturityBracket5 as int),hold.ReportDate) then 5
								else 6
							end
						else case 
								when hold.MaturityDate < DateAdd(YYYY,Cast(@MaturityBracket1 as int),hold.ReportDate) then 1
								when hold.MaturityDate < DateAdd(YYYY,Cast(@MaturityBracket2 as int),hold.ReportDate) then 2
								when hold.MaturityDate < DateAdd(YYYY,Cast(@MaturityBracket3 as int),hold.ReportDate) then 3
								--when hold.MaturityDate < DateAdd(YYYY,Cast(@MaturityBracket4 as int),hold.ReportDate) then 4
								--when hold.MaturityDate < DateAdd(YYYY,Cast(@MaturityBracket5 as int),hold.ReportDate) then 5
								else 6
							end
					end,
		Label =	'',
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0 then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	UNION ALL
	SELECT
		DataType = 'Coupon',
		Bracket = case 
								when hold.Coupon < @CouponBracket1 then 1
								when hold.Coupon < @CouponBracket2 then 2
								when hold.Coupon < @CouponBracket3 then 3
								when hold.Coupon < @CouponBracket4 then 4
								when hold.Coupon < @CouponBracket5 then 5
								else 6
							end,
        Label = '',
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0 then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	UNION ALL
	SELECT
		DataType = 'SPRating',
		Bracket = r.SortOrder,
		Label = r.Rating,
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0  then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	join @sandpRatings r on r.RatingID = hold.SpRatingID
	UNION ALL
	SELECT
		DataType = 'MoodyRating',
		Bracket = r.SortOrder,
		Label = r.Rating,
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0  then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	join @moodyRatings r on r.RatingID = hold.MoodyRatingID
	UNION ALL
	SELECT
		DataType = 'FitchRating',
		Bracket = r.SortOrder,
		Label = r.Rating,
		hold.MarketValue,
		hold.MarketValueNoAI,
		PercentAssets = case when isnull(hold.TotalMarketValue,0) = 0 then 0 else hold.MarketValue/hold.TotalMarketValue end,
--		hold.Yield,
--		hold.Coupon,
--		hold.Duration,
		WeightedYield = (hold.Yield * hold.MarketValueNoAI),
		WeightedCoupon = (hold.Coupon * hold.MarketValueNoAI),
		WeightedDuration = (hold.Duration * hold.MarketValueNoAI),
		hold.PortfolioBaseID,
		hold.PortfolioBaseIDOrder
--		hold.SecTypeCode,
--		hold.SecurityID,
--		hold.IsShortPosition
--		hold.SecurityName,
--		hold.SecuritySymbol
	FROM @holdings hold
	join @fitchRatings r on r.RatingID = hold.FitchRatingID
) tblhold
left join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, @ShowCurrencyFullPrecision) p on
	p.PortfolioBaseID = tblhold.PortfolioBaseID
left join @Decor decor on decor.APXLocaleID = p.LocaleID
--	join APXUser.vPortfolioBaseSettingEx portfolioBase on
--		portfolioBase.PortfolioBaseID = tblhold.PortfolioBaseID
--	join ApxUser.vCurrency reportingCurrency on
--		reportingCurrency.CurrencyCode = case @ReportingCurrencyCode
--		when 'PC' then portfolioBase.ReportingCurrencyCode
--		else @ReportingCurrencyCode end
order by tblhold.PortfolioBaseIDOrder, tblhold.DataType, tblhold.Bracket, tblhold.Label
--select GETDATE() - @timer; set @timer = GETDATE()
end
