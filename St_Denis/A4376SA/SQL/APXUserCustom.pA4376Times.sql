USE [APXFirm]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pA4376Times]') AND type in (N'P')) 
DROP PROCEDURE [APXUserCustom].[pA4376Times] 
GO 
-- $Header: $/APX/Trunk/APX/APXDatabase/APXFirm/sp/SSRSReports/pReportTransactionActivity.sql  2014-01-14 13:59:54 PST  ADVENT/astanchi $
-- This proc provides colunms that can be used in an APX Transaction Summary report.  
--	Rep creates pa/sa transactions for delivered in fixed income securities without a pa/sa, these generated transactions have no PortfolioTransactionID
--	PortfolioTransactionID  and TranID is not unique -> Rep produces two rows per PortfolioTransactionID for each currency forward trade.
--  Realized Gain: Currency gains create a separate realized gain/loss transaction with the same Portfolio Transaction ID

create procedure [APXUserCustom].[pA4376Times]
	@NullName name72 = null
as
begin

exec APXUser.pSessionInfoSetGuid @sessionguid=null

declare @results table (
	Name nvarchar(32),
	Period nvarchar(5)
	);

insert into @results
exec APXUser.pGetTimePeriods @NullName

insert into @results values ('Latest 1 Year','L1Y')

select * from @results
end