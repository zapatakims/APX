if exists (select * from sys.objects where object_id = OBJECT_ID(N'[APXUserCustom].[D812203APX_ContributionReportDataHandle]') AND type in (N'P', N'PC'))
drop procedure [APXUserCustom].[D812203APX_ContributionReportDataHandle]
go

/*
declare	@SessionGuid nvarchar(48),
	@DataHandle nvarchar(48) = 'F4B46DF9-4860-4380-BA1C-D63580DAFF74',	

	-- Optional parameters for sqlrep proc
	@PortfolioBaseID int = 180,
	@PortfolioBaseIDOrder int = 1,
	@RollUp bit = 0,

	@PriceTypeID int = null,
	@ClassificationID1 int = -666,
	@ClassificationID2 int = -19,
	@ClassificationID3 int = -7,
	@ClassificationID4 int = -6

exec [APXUserCustom].[D812203APX_ContributionReportDataHandle] @SessionGuid = @SessionGuid, 
	@DataHandle = @DataHandle,
	@PortfolioBaseID = @PortfolioBaseID,
	@PortfolioBaseIDOrder = @PortfolioBaseIDOrder,
	@RollUp = @RollUp,
	@PriceTypeID = @PriceTypeID,
	@ClassificationID1 = @ClassificationID1,
	@CLassificationID2 = @ClassificationID2,
	@ClassificationID3 = @ClassificationID3,
	@ClassificationID4 = @ClassificationID4
*/

create procedure [APXUserCustom].[D812203APX_ContributionReportDataHandle]
	@SessionGuid nvarchar(48),
	@DataHandle nvarchar(48),	
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@RollUp bit,

	@PriceTypeID int = null,
	@ClassificationID1 int = null,
	@ClassificationID2 int = null,
	@ClassificationID3 int = null,
	@ClassificationID4 int = null
as
begin
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

declare @PerfData varbinary(max),	--	security-level
	@SecTWR varbinary(max)

--	Security-level FX and price performance
exec APXUser.pReportDataGetFromHandle @DataHandle, 'perf', @PortfolioBaseID = @PortfolioBaseID, @PortfolioBaseIDOrder = @PortfolioBaseIDOrder, @ReportData=@PerfData out

declare @PortMV float

select @PortMV = MarketValueDate2 from APXUser.fPerformance(@PerfData) where ClassificationMemberName = 'Total'
if @RollUp = 0
begin
select
	isnull(c1.DisplayOrder,-1) [Grouping1DisplayOrder]
	,c1.ClassificationName [Grouping1Name]
	,c1.MemberName [Grouping1MemberName]
	,isnull(c2.DisplayOrder,-1) [Grouping2DisplayOrder]
	,c2.ClassificationName [Grouping2Name]
	,c2.MemberName [Grouping2MemberName]
	,isnull(c3.DisplayOrder,-1) [Grouping3DisplayOrder]
	,c3.ClassificationName [Grouping3Name]
	,c3.MemberName [Grouping3MemberName]
	,isnull(c4.DisplayOrder,-1) [Grouping4DisplayOrder]
	,c4.ClassificationName [Grouping4Name]
	,c4.MemberName [Grouping4MemberName]
	,sec.SecuritySymbol
	,sec.SecurityName
	,sec.LocalCurrencyISOCode
	,p.Quantity
	,p.CostBasis
	,p.UnitCost
	,price.ClosePrice
	,@PortMV [PortfolioMV]
	,p.MarketValueDate2 [MarketValue]
	,p.MarketValueDate2 / @PortMV [Weight]
	,p.MarketValueDate2 / @PortMV * p.AnnualizedIRR [Contribution]
	,p.FXUnrealizedGainLossOnMval + p.FXRealizedGainLossOnMval [FXGain]
	,p.PriceUnrealizedGainLossOnMval + p.PriceRealizedGainLossOnMval [PriceGain]
	,p.AnnualizedPriceIRR / 100 [AnnualizedPriceIRR]
	,p.AnnualizedFXIRR / 100 [AnnualizedFXIRR]
	,p.AnnualizedIRR / 100 [AnnualizedIRR]
	,p.FXRealizedGainLossOnMval
	,p.FXUnrealizedGainLossOnMval
	,p.TotalGain + p.Fees [TotalGain]
from APXUser.fPerformance(@PerfData) p
	left join APXUser.vSecurityVariant sec on 
		sec.SecurityID = p.SecurityID and
		sec.IsShort = p.IsShortPosition and
		sec.SecTypeCode = p.SecTypeCode
	left join APXUser.vSecurityPrice price on
		price.SecurityID = p.SecurityID and
		price.PriceTypeID = @PriceTypeID and
		price.PriceDate = p.ThruDate
--	first Classification
	left join APXUser.vSecurityPropertyLookupLS s1 on
		s1.PropertyID = @ClassificationID1 and
		s1.SecurityID = p.SecurityID and
		p.IsShortPosition = s1.IsShort and
		s1.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c1 on
		c1.ClassificationID = @ClassificationID1 and
		c1.MemberID = s1.PropertyLookupID

--	second Classification
	left join APXUser.vSecurityPropertyLookupLS s2 on
		s2.PropertyID = @ClassificationID2 and
		s2.SecurityID = p.SecurityID and
		p.IsShortPosition = s2.IsShort and
		s2.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c2 on
		c2.ClassificationID = @ClassificationID2 and
		c2.MemberID = s2.PropertyLookupID

--	third Classification
	left join APXUser.vSecurityPropertyLookupLS s3 on
		s3.PropertyID = @ClassificationID3 and
		s3.SecurityID = p.SecurityID and
		p.IsShortPosition = s3.IsShort and
		s3.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c3 on
		c3.ClassificationID = @ClassificationID3 and
		c3.MemberID = s3.PropertyLookupID

--	fourth Classification
	left join APXUser.vSecurityPropertyLookupLS s4 on
		s4.PropertyID = @ClassificationID4 and
		s4.SecurityID = p.SecurityID and
		p.IsShortPosition = s4.IsShort and
		s4.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c4 on
		c4.ClassificationID = @ClassificationID4 and
		c4.MemberID = s4.PropertyLookupID
end
else
begin
select
	(isnull(c1.MemberName,'') + ' ' + isnull(c2.MemberName,'') + ' ' + isnull(c3.MemberName,'') + ' ' + isnull(c4.MemberName,'')) [SecurityName]
	,sum(p.FXUnrealizedGainLossOnMval + p.FXRealizedGainLossOnMval) [FXGain]
	,case when sum(p.CostBasis) = 0 then 0 else sum(p.FXUnrealizedGainLossOnMval + p.FXRealizedGainLossOnMval) / sum(p.ACB) end [AnnualizedFXIRR]
	,sum(p.MarketValueDate2) / @PortMV [Weight]
	,case when sum(p.CostBasis) = 0 then 0 else sum(p.FXUnrealizedGainLossOnMval + p.FXRealizedGainLossOnMval) / sum(p.ACB) * sum(p.MarketValueDate2) / @PortMV end [Contribution]
from APXUser.fPerformance(@PerfData) p
	left join APXUser.vSecurityVariant sec on 
		sec.SecurityID = p.SecurityID and
		sec.IsShort = p.IsShortPosition and
		sec.SecTypeCode = p.SecTypeCode
	left join APXUser.vSecurityPrice price on
		price.SecurityID = p.SecurityID and
		price.PriceTypeID = @PriceTypeID and
		price.PriceDate = p.ThruDate
--	first Classification
	left join APXUser.vSecurityPropertyLookupLS s1 on
		s1.PropertyID = @ClassificationID1 and
		s1.SecurityID = p.SecurityID and
		p.IsShortPosition = s1.IsShort and
		s1.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c1 on
		c1.ClassificationID = @ClassificationID1 and
		c1.MemberID = s1.PropertyLookupID

--	second Classification
	left join APXUser.vSecurityPropertyLookupLS s2 on
		s2.PropertyID = @ClassificationID2 and
		s2.SecurityID = p.SecurityID and
		p.IsShortPosition = s2.IsShort and
		s2.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c2 on
		c2.ClassificationID = @ClassificationID2 and
		c2.MemberID = s2.PropertyLookupID

--	third Classification
	left join APXUser.vSecurityPropertyLookupLS s3 on
		s3.PropertyID = @ClassificationID3 and
		s3.SecurityID = p.SecurityID and
		p.IsShortPosition = s3.IsShort and
		s3.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c3 on
		c3.ClassificationID = @ClassificationID3 and
		c3.MemberID = s3.PropertyLookupID

--	fourth Classification
	left join APXUser.vSecurityPropertyLookupLS s4 on
		s4.PropertyID = @ClassificationID4 and
		s4.SecurityID = p.SecurityID and
		p.IsShortPosition = s4.IsShort and
		s4.SecurityID = p.ClassificationMemberID
	left join APXUser.vClassificationMemberEx c4 on
		c4.ClassificationID = @ClassificationID4 and
		c4.MemberID = s4.PropertyLookupID
	where p.SecurityID is not null
	group by c1.MemberName, c2.MemberName, c3.MemberName, c4.MemberName
end
end