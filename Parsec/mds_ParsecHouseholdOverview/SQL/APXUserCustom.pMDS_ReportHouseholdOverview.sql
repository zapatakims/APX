IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pMDS_ReportHouseholdOverview]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pMDS_ReportHouseholdOverview]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pMDS_ReportHouseholdOverview]    Script Date: 01/17/2014 20:47:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create procedure [APXUserCustom].[pMDS_ReportHouseholdOverview]
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@ToDate datetime,
	-- Optional parameters for sqlrep proc
	@FeeMethod int = null,
	@ReportingCurrencyCode dtCurrencyCode = null, -- Use Settings
	@LocaleID int = null					-- Use Portfolio Settings
	
as
begin
-- Set the Session Guid
exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
declare @FromDate as datetime = @ToDate
declare @InceptionDate datetime
declare @ClassificationID as int = -9
declare @InceptionToDate as bit = 1
declare @ExcludePerformanceHistory as bit = 1
declare @reportData as varbinary(max)
exec APXUser.pPerformanceHistory
	-- Required Parameters
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@FeeMethod = @FeeMethod,
	@LocaleID = @LocaleID,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@InceptionToDate = @InceptionToDate,
	@ExcludePerformanceHistory = 0
select @InceptionDate = ph.InceptionDate from APXUser.fPerformanceHistory (@ReportData) ph

exec APXUser.pPerformanceHistory
	-- Required Parameters
	@ReportData = @ReportData out,
	@Portfolios = @Portfolios,
	@FromDate = @FromDate,
	@ToDate = @ToDate,
	@ClassificationID = @ClassificationID,
	-- Optional Parameters
	@FeeMethod = @FeeMethod,
	@LocaleID = @LocaleID,
	@ReportingCurrencyCode = @ReportingCurrencyCode out,
	@InceptionToDate = @InceptionToDate,
	@ExcludePerformanceHistory = @ExcludePerformanceHistory
select 
      -- Performance History
	  ph.PortfolioBaseID
	  ,ph.PortfolioBaseIDOrder
	  ,ph.FromDate
	  ,ph.ThruDate
	  ,@InceptionDate as InceptionDate
	  ,FirmLogo = APX.fPortfolioCustomLabel(ph.PortfolioBaseID, '$flogo', 'logo.jpg')
	  ,p.PrefixedPortfolioBaseCode
	  ,p.ReportHeading1
	  ,p.ReportHeading2
	  ,p.ReportHeading3
	  ,p.LocaleID
	  ,CurrencyName = p.ReportingCurrencyName
	  ,p.ReportingCurrencyCode
from APXUser.fPerformanceHistory(@ReportData) ph
	join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p on
		p.PortfolioBaseID = ph.PortfolioBaseID
order by ph.PortfolioBaseIDOrder
end

GO


