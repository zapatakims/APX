if object_id('[APXUserCustom].[pMDS_ParsecPortfolioSummary_Exposure]') is not null
	drop procedure [APXUserCustom].[pMDS_ParsecPortfolioSummary_Exposure]
go

create procedure [APXUserCustom].[pMDS_ParsecPortfolioSummary_Exposure]
/*	Test code
	exec [APXUserCustom].[pParsecReport_Exposure]
	@SessionGuid = NULL
	,@Portfolios = 'case'
	,@FromDate = '12/31/08'
	,@ToDate = '12/31/09'
	,@ClassificationID1 = -4
	,@AccruePerfFees = NULL
	,@AllocatePerfFees = NULL
	,@BenchmarkCode = 'sp500'
	--,@ClassificationID2 int
	--,@ClassificationID3 int
	--,@ClassificationID4 int
	--,@ClassificationID5 int
	--,@ClassificationID6 int
	--,@ClassificationID7 int
	,@FeeMethod = NULL
	,@ReportingCurrencyCode = NULL
*/
	@SessionGuid nvarchar(max)
	,@Portfolios nvarchar(32)
	,@FromDate datetime
	,@ToDate datetime
	,@ClassificationID1 int
	,@Exclusions1 nvarchar(max)
	,@AccruePerfFees bit
	,@AllocatePerfFees bit
	,@BenchmarkCode nvarchar(max)
	--,@ClassificationID2 int
	--,@ClassificationID3 int
	--,@ClassificationID4 int
	--,@ClassificationID5 int
	--,@ClassificationID6 int
	--,@ClassificationID7 int
	,@FeeMethod int
	,@ReportingCurrencyCode char(2)

as begin

declare @ReportData varbinary(max)

exec APXUser.pSessionInfoSetGuid @SessionGuid

exec APXUser.pAttributionSinglePeriod @ReportData = @ReportData out
	,@Portfolios = @Portfolios
	,@FromDate = @FromDate
	,@ToDate = @ToDate
	,@ClassificationID1 = @ClassificationID1
	,@Exclusions1 = @Exclusions1
	--,@ClassificationID2 = @ClassificationID2
	--,@ClassificationID3 = @ClassificationID3
	--,@ClassificationID4 = @ClassificationID4
	--,@ClassificationID5 = @ClassificationID5
	--,@ClassificationID6 = @ClassificationID6
	--,@ClassificationID7 = @ClassificationID7
	,@BenchmarkCode = @BenchmarkCode
--	,@BenchmarkType = 1
	,@FeeMethod = @FeeMethod
	,@ReportingCurrencyCode = @ReportingCurrencyCode

select classification.*,
	'Portfolio' [Name],
--	i.IndexName,
	--i.IndexDesc,
	--a.BenchmarkID,
	--a.BenchmarkWeight,
	a.PortfolioWeight [Weight]
from APXUser.fAttributionSinglePeriod (@ReportData) a
	join APXUser.vSecClassMember classification on
		classification.ClassificationMemberID = a.ClassificationMemberID and
		classification.ClassificationID = a.ClassificationID and
		classification.ClassificationID = @ClassificationID1
union all
select classification.*,
--	i.IndexName,
	i.IndexDesc [Name],
	--a.BenchmarkID,
	--a.BenchmarkWeight,
	a.BenchmarkWeight [Weight]
from APXUser.fAttributionSinglePeriod (@ReportData) a
	join APXUser.vSecClassMember classification on
		classification.ClassificationMemberID = a.ClassificationMemberID and
		classification.ClassificationID = a.ClassificationID and
		classification.ClassificationID = @ClassificationID1
	join APXUser.vMarketIndex i on
		i.IndexID = a.BenchmarkID
end