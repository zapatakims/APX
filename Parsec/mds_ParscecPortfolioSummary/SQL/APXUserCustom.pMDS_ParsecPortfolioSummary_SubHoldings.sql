if object_id('[APXUserCustom].[pMDS_ParsecPortfolioSummary_SubHoldings]') is not null
	drop procedure [APXUserCustom].[pMDS_ParsecPortfolioSummary_SubHoldings]
go

CREATE procedure [APXUserCustom].[pMDS_ParsecPortfolioSummary_SubHoldings]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@PortfolioBaseID int,
	@PortfolioBaseIDOrder int,
	@DataHandle nvarchar(48),
	-- Optional parameters for sqlrep proc
	@ClassificationID int = null,
	@ClassificationID2 int = null,
	@AssetClassCode char(1) = null

as
begin
-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
-- Execute the sqlrep proc that will fill the @ReportData
-- To get the effective value for 'Use Settings' parameters, specify 'out'
declare @ReportData varbinary(max)

exec APXUser.pReportDataGetFromHandle @DataHandle, 'Appraisal', @PortfolioBaseID=@PortfolioBaseID, @PortfolioBaseIDOrder=@PortfolioBaseIDOrder, @ReportData=@ReportData out

select 
	property.DisplayOrder
	,property.DisplayName
	,property.PropertyLookupID [DisplayID]
	,subclass.PropertyLookupID [subDisplayID]
	,subclass.DisplayOrder [subDisplayOrder]
	,subclass.DisplayName [subDisplayName]
	,a.MarketValue
	,a.Yield
from APXUser.fAppraisal (@ReportData) a
	join APXUser.vSecurityPropertyLookupLS property on
		property.SecurityID = a.SecurityID and
		property.IsShort = a.IsShortPosition and
		property.PropertyID = @ClassificationID
	join APXUser.vSecurityPropertyLookupLS class on
		class.SecurityID = a.SecurityID and
		class.IsShort = a.IsShortPosition and
		(class.PropertyID = -4)
	left join APXUser.vSecurityPropertyLookupLS subclass on
		subclass.SecurityID = a.SecurityID and
		subclass.IsShort = a.IsShortPosition and
		subclass.PropertyID = @ClassificationID2
where (class.KeyString = @AssetClassCode or @AssetClassCode is null)
end
GO


