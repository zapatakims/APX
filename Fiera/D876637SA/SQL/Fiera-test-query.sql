declare 
	-- Required Parameters
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max) = '+@PwEschn',
	@ToDate datetime = '11/30/2014',
	@ClassificationID1 int = 230,
	@ClassificationID2 int = 229,
	@ClassificationID3 int = 228,
	@ReportingCurrencyCode dtCurrencyCode = 'ca',
	@Periods nvarchar(max) = 'YTD',

	@DataHandle nvarchar(max) = '8805DE1E-79AE-4E26-9A43-4BBA30D160B1',
	@PortfolioBaseID int = 12976,
	@PortfolioBaseIDOrder int = 1

exec[APXUserCustom].[pD876637SA] 
	@SessionGuid = @SessionGuid,
	@Portfolios = @Portfolios,
	@ToDate = @ToDate,
	@ClassificationID1 = @ClassificationID1,
	@ClassificationID2 = @ClassificationID2,
	@ClassificationID3 = @ClassificationID3,
	@ReportingCurrencyCode = @ReportingCurrencyCode

exec [APXUserCustom].[pD876636SA_PerformanceTable]
	-- Required Parameters
	@SessionGuid = @SessionGuid,
	@PortfolioBaseID = @PortfolioBaseID,
	@PortfolioBaseIDOrder = @PortfolioBaseIDOrder,
	@DataHandle = @DataHandle,
	@Periods = @Periods,
	--@Periods nvarchar(max),
	@ClassificationID1 = @ClassificationID1,
	-- Optional parameters for sqlrep proc
	@ClassificationID2 = @ClassificationID2,
	@ClassificationID3 = @ClassificationID3,
	@ReportingCurrencyCode = @ReportingCurrencyCode