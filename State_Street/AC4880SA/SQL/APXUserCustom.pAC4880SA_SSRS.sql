IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pAC4880SA_SSRS]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pAC4880SA_SSRS]
GO

/****** Object:  StoredProcedure [APXUserCustom].[pAC4880SA_SSRS]    Script Date: 03/13/2015 18:15:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--DECLARE
--@SessionGuid nvarchar(48),
--@FromDate date = '2/20/2009',
--@ThruDate date = '12/31/2014',

CREATE procedure [APXUserCustom].[pAC4880SA_SSRS]
	@SessionGuid nvarchar(48),
	@Portfolios nvarchar(max),
	@FromDate date,
	@ThruDate date,
	@RunSinceInception bit = 'true'
as
begin

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid
--As part of this process _History views exist for Portfolio and Contact data.
--However, data does not exist for DeliveryAddress data.  This must be stored daily in a database, similar to the _Hist views.
--First check if records exist for the day in question, and delete.  Then inset for today.
DECLARE @Date date = GETDATE()
if @RunSinceInception = 'true'
	set @FromDate = '01/01/1950'
	
declare @incdate datetime  = '01/01/1950'

--Get the list of all the portfolios
declare @AllPortfolios table(portfolioid int, portfoliocode nvarchar(max))

--To force the report in consolidation mode always
set @Portfolios = REPLACE(@Portfolios,'+','')

declare @rpt varbinary(max)
exec APXUser.pAppraisal  @ReportData= @rpt out,
	@Portfolios = @Portfolios, 
	@Date = @Date,
	@ExcludePortfolioHoldings = 1,
	@IncludeClosedPortfolios = 1

insert into @AllPortfolios
select app.PortfolioBaseID,pb.PortfolioBaseCode from apxuser.fAppraisal(@rpt) app
join APXUser.vPortfolioBase pb on pb.PortfolioBaseID = app.PortfolioBaseID

--table to fetch the latest entry of a field in temp table
declare @audittemp table(id int, time datetime,cont int null)

------1. For ReportHeading1----- 

delete from @audittemp
insert into @audittemp
--Fetching the latest entry of a portfolio in the custom table. It will decide Since what date we need to fetch the data from _audit tables for a portfolio.
select PortfolioID,Max(AuditEventTime),null from APXUserCustom.tAC4880SA_AoObjectAudit_Hist group by PortfolioID

	--Inserting only new rows into temp table
insert into APXUserCustom.tAC4880SA_AoObjectAudit_Hist
select cast(ao.ObjectID as int),ao.DisplayName, ao.AuditEventIDIn,ao.AuditEventIDOut,cast(evt.AuditEventTime as datetime),uB.DisplayName
from @AllPortfolios port
join dbo.AoObject_Audit ao on ao.ObjectID = port.portfolioid
join dbo.AdvAuditEvent evt on ao.AuditEventIDIn = evt.AuditEventID
left join @audittemp tmp on ao.ObjectID = tmp.id
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(tmp.time,@incdate)

----2. For StartDate and ClosedDate-----
delete from @audittemp
insert into @audittemp

--Fetching the latest entry of a portfolio in the custom table. It will decide Since what date we need to fetch the data from _audit tables for a portfolio.
select PortfolioID,Max(AuditEventTime),null from APXUserCustom.tAC4880SA_PortfolioBaseAudit_Hist group by PortfolioID
	
	--Inserting only new rows into temp table
insert into APXUserCustom.tAC4880SA_PortfolioBaseAudit_Hist
select pb.PortfolioBaseID, pb.StartDate, pb.CloseDate, pb.AuditEventIDIn, pb.AuditEventIDOut,cast(evt.AuditEventTime  as datetime),uB.DisplayName
from @AllPortfolios port 
join dbo.AdvPortfolioBase_Audit pb on port.portfolioid = pb.PortfolioBaseID
join dbo.AdvAuditEvent evt on pb.AuditEventIDIn = evt.AuditEventID
left join @audittemp tmp on tmp.id =pb.PortfolioBaseID
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(tmp.time,@incdate)


----3. For Portfolio Custom Columns-----
delete from @audittemp
insert into @audittemp

--Fetching the latest entry of a portfolio in the custom table. It will decide Since what date we need to fetch the data from _audit tables for a portfolio.
select PortfolioID,Max(AuditEventTime),null from APXUserCustom.tAC4880SA_PortfolioBaseExtAudit_Hist group by PortfolioID

	--Inserting only new rows into temp table
insert into APXUserCustom.tAC4880SA_PortfolioBaseExtAudit_Hist
select ext.PortfolioBaseID,ext.RichterBoberAllocation,ext.TacticalWeight, ext.AuditEventIDIn,ext.AuditEventIDOut,evt.AuditEventTime,uB.DisplayName
from  @AllPortfolios port
join dbo.AdvPortfolioBaseExt_Audit ext on port.portfolioid = ext.PortfolioBaseID
join dbo.AdvAuditEvent evt on ext.AuditEventIDIn = evt.AuditEventID
left join @audittemp tmp on tmp.id = ext.PortfolioBaseID
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(tmp.time,@incdate)

----4. For Interested Parties Mailing----
delete from @audittemp
insert into @audittemp

--Fetching the latest entry of a contact for a particular portfolio in the custom table. It will decide Since what date we need to fetch the data from _audit tables for a portfolio-contact combination.
select PortfolioID,Max(AuditEventTime),ContactID from APXUserCustom.tAC4880SA_InterestPartiesMailing_Hist group by PortfolioID,ContactID

	--copying only those rows which are not present in temp tables
insert into APXUserCustom.tAC4880SA_InterestPartiesMailing_Hist
select intp.PortfolioID,intp.ContactID,intp.AddressID,intp.HasMailing01,intp.HasMailing02,intp.HasMailing03,intp.HasMailing04,intp.HasMailing05,intp.HasMailing06
	,intp.HasMailing07,intp.HasMailing08,intp.HasMailing09,intp.HasMailing10,intp.HasMailing11,intp.HasMailing12,intp.HasMailing13,intp.HasMailing14
	,intp.HasMailing15,intp.HasMailing16,intp.HasMailing17,intp.HasMailing18,intp.HasMailing19,intp.HasMailing20,intp.HasMailing21,intp.HasMailing22,intp.HasMailing23
	,intp.HasMailing24,intp.HasMailing25,intp.HasMailing26,intp.HasMailing27,intp.HasMailing28,intp.HasMailing29,intp.HasMailing30,intp.HasMailing31,intp.HasMailing32
	,intp.AuditEventIDIn,intp.AuditEventIDOut,evt.AuditEventTime, uB.DisplayName
from @AllPortfolios port
join APX.InterestedPartyMailing_Audit intp on port.portfolioid =intp.PortfolioID
join dbo.AdvAuditEvent evt on intp.AuditEventIDIn = evt.AuditEventID
left join @audittemp tmp on tmp.id = intp.PortfolioID and tmp.cont = intp.ContactID
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(tmp.time,@incdate)


----5. For Contacts Address----
delete from @audittemp
insert into @audittemp

--Fetching the latest entry of a Address in the custom table. It will decide Since what date we need to fetch the data from _audit tables for an Address.
select AddressID,Max(AuditEventTime),null from APXUserCustom.tAC4880SA_ContactDefaultAddress_Hist group by AddressID

	--copying only those rows which are not present in temp tables
insert into APXUserCustom.tAC4880SA_ContactDefaultAddress_Hist
select cAdr.AddressID,cAdr.ObjectGUID,cAdr.AddressLabel,cAdr.Line1,cadr.Line2,cAdr.Line3,cAdr.Line4,cAdr.City,cAdr.State,cAdr.Zip,
cAdr.Country,NULL AddressContactID,NULL AddressContactCode, cAdr.OwnerContactID,(select ContactCode from apxuser.vContact where ContactID = cAdr.OwnerContactID),
NULL OwnedBy, addr.Duration,addr.AddressFull,addr.IsSendMail,addr.IsSendExpress,addr.Custom01,addr.Custom02,addr.Custom03,addr.Custom04,
addr.HasAttr01,addr.HasAttr02,addr.HasAttr03,addr.HasAttr04,NULL AuditDate,NULL AuditID,cAdr.AuditEventIDIn,cAdr.AuditEventIDOut,evt.AuditEventTime,uB.DisplayName
from dbo.QbAddress_audit cAdr
join dbo.AdvAuditEvent evt on cAdr.AuditEventIDIn = evt.AuditEventID
join(select AddressID,Duration,AddressFull,IsSendMail,IsSendExpress,Custom01,Custom02,Custom03,Custom04,HasAttr01,HasAttr02,HasAttr03,HasAttr04 
from  AdvApp.vContactAddress group by AddressID,AddressOwnerContactID,Duration,AddressFull,IsSendMail,IsSendExpress,Custom01,Custom02,Custom03,
Custom04,HasAttr01,HasAttr02,HasAttr03,HasAttr04) addr on addr.AddressID = cAdr.AddressID
left join @audittemp tmp on tmp.id = cAdr.AddressID
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(tmp.time,@incdate)

--added for Address Label change-- added on Mar10,2015
declare @maxtime datetime
select top 1 @maxtime = AuditDate from APXUserCustom.tAC4880SA_ContactDefaultAddressLabel_Hist order by AuditDate desc
insert into APXUserCustom.tAC4880SA_ContactDefaultAddressLabel_Hist
select DefaultAddressID, cAdr1.AddressLabel,  ContactCode,ContactID, GETDATE(), AuditEventIDIn, AuditEventIDOut, hist.AuditEventTime,uB.DisplayName
from Advapp.vContact_Hist hist
left join apxuser.vContactAddress cAdr1 on cAdr1.AddressID = hist.DefaultAddressID
join dbo.AdvAuditEvent evt on hist.AuditEventIDIn = evt.AuditEventID
join APXuser.vUserBase uB on uB.UserBaseID = evt.UserID
where evt.AuditEventTime >= isnull(@maxtime,@incdate)
order by ContactID,AuditEventIDIn

set @ThruDate = DATEADD(DAY, 1, @ThruDate)
--Then create list of fields to analyze

----1.Portfolio Fields to analyse----
DECLARE @PortfolioFields table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @PortfolioFields
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.views v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'vPortfolio_Hist'
AND v3.name = 'AdvApp'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('ShortName'
,'PortfolioStatus'
,'TaxNumber'
,'TaxStatus'
,'PortfolioTypeCode'
,'InvestmentGoal'
,'PrimaryContactID'
,'OwnerContactID'
,'BillingContactID'
,'BankContactID'
)

----2.Contact Fields to analyse----
DECLARE @ContactFields table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @ContactFields
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.views v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'vContact_Hist'
AND v3.name = 'AdvApp'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('Salutation'
,'DeliveryName'
, 'FirstName'
, 'MiddleName'
, 'LastName'
, 'ContactName'
, 'Custom16'
, 'Custom09'
, 'Custom10'
, 'Custom03'
)

----3.Default Address  to analyse--------
DECLARE @DefaultAddressFields table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @DefaultAddressFields
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.tables v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'tAC4880SA_ContactDefaultAddress_Hist'
AND v3.name = 'ApxUserCustom'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('AddressLine1'
,'AddressLine2'
,'AddressLine3'
,'AddressLine4'
,'AddressCity'
,'AddressStateCode'		--	2015/04/24 AZK AddressStateCode, not AddressState
--,'AddressZip'
,'AddressPostalCode'		--	2015/04/24 AZK AddressPostalCode, not AddressZip
,'AddressCountry'
,'AddressLabel'  --Added on Mar2015
)

declare @CurrentAddressFields table (id int identity, FieldName nvarchar(max))
--	2015/04/24 AZK Needs to line up with @DefaultAddressFields, field names are inserted alphabetically. QBAddress fields have different names so we can't insert it in the same manner
insert into @CurrentAddressFields select 'City'
insert into @CurrentAddressFields select 'Country'
insert into @CurrentAddressFields select 'AddressLabel'
insert into @CurrentAddressFields select 'Line1'
insert into @CurrentAddressFields select 'Line2'
insert into @CurrentAddressFields select 'Line3'
insert into @CurrentAddressFields select 'Line4'
insert into @CurrentAddressFields select 'Zip'
insert into @CurrentAddressFields select 'State'

----4.ReportHeading1  to analyse--------
DECLARE @AdditionalPortfolioFields_RH table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @AdditionalPortfolioFields_RH
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.tables v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'tAC4880SA_AoObjectAudit_Hist'
AND v3.name = 'ApxUserCustom'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('ReportHeading1'
)

----5.Start and Close Dates to analyse----
DECLARE @AdditionalPortfolioFields_dt table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @AdditionalPortfolioFields_dt
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.tables v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'tAC4880SA_PortfolioBaseAudit_Hist'
AND v3.name = 'ApxUserCustom'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('StartDate'
,'ClosedDate'
)

----6.Portfolio Custom Fields to analyse----
DECLARE @AdditionalPortfolioFields_cust table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @AdditionalPortfolioFields_cust
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.tables v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'tAC4880SA_PortfolioBaseExtAudit_Hist'
AND v3.name = 'ApxUserCustom'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('RichterBoberAllocation'
,'TacticalWeight'
)

----7.Interested Parties Mailing Fields to analyse----
DECLARE @InterestedPartiesMailing table (id INT IDENTITY, FieldName nvarchar(max))
INSERT INTO @InterestedPartiesMailing
SELECT v1.name
--, v2.name, v3.name
FROM sys.columns v1
INNER JOIN sys.tables v2 on V1.OBJECT_ID = V2.OBJECT_ID
INNER JOIN sys.schemas v3 on v3.schema_id = v2.schema_id
and V2.NAME = 'tAC4880SA_InterestPartiesMailing_Hist'
AND v3.name = 'ApxUserCustom'
--AND v1.name in ('InterestOrDividendRate')
AND v1.name in
('HasMailing01','HasMailing02','HasMailing03','HasMailing04','HasMailing05','HasMailing06','HasMailing07','HasMailing08'
,'HasMailing09','HasMailing10','HasMailing11','HasMailing12','HasMailing13','HasMailing14','HasMailing15','HasMailing16'
,'HasMailing17','HasMailing18','HasMailing19','HasMailing20','HasMailing21','HasMailing22','HasMailing23','HasMailing24'
,'HasMailing25','HasMailing26','HasMailing27','HasMailing28','HasMailing29','HasMailing30','HasMailing31','HasMailing32'
)

declare @s nvarchar(max) = ''
declare @FromDatec nvarchar(max) = @FromDate
declare @ThruDatec nvarchar(max) = @ThruDate
--Then run consecutive queries, one for each field in @FieldstoProcess, accumlate results in #t, and then select those results.
--Portfolio Properties
CREATE TABLE #t
(
PortfolioBaseID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, UserName nvarchar(500)
)
-- Additional Portfolio Properties
CREATE TABLE #t1
(
PortfolioBaseID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)
CREATE TABLE #t2
(
PortfolioBaseID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)
CREATE TABLE #t3
(
PortfolioBaseID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)
--ContactProperties
CREATE TABLE #c
(
ContactID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, UserName nvarchar(500)
)
--Address Properties
CREATE TABLE #a
(
AddressID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)
--Address Properties for 'AdressLabel'    --Added on Mar2015
CREATE TABLE #a1
(
AddressID int,AddressContactID int, FieldName nvarchar(255), OldValue nvarchar(255), NewValue nvarchar(255), AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)
--Interested Party Mailing Properties
CREATE TABLE #i
(
PortfolioID int, ContactID int, FieldName nvarchar(255), OldValue bit, NewValue bit, AuditEventID int, AuditEventTime datetime, UserName nvarchar(500)
)

-- Processing portfolio fields
declare @counter int = 1
declare @countto int = (select MAX(id) from @PortfolioFields)
declare @FieldName nvarchar(max) = '', @currentFieldName nvarchar(max) = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @PortfolioFields t where t.id = @counter
      SET @s = N'select A.PortfolioID as PortfolioBaseID, ' 
      + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID], uB.DisplayName
      FROM AdvApp.vPortfolio_Hist A JOIN AdvApp.vPortfolio_Hist B ON A.PortfolioID = B.PortfolioID AND A.AuditEventIDIn = B.AuditEventIDOut
      JOIN APXuser.vUserBase uB on uB.UserBaseID = A.AuditUserID
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1'
      INSERT INTO #t
      exec(@s)
      
      SET @counter = @counter + 1
END

--Processing ReportHeading1
set @counter = 1
set @countto = (select MAX(id) from @AdditionalPortfolioFields_RH)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @AdditionalPortfolioFields_RH t where t.id = @counter
      SET @s = N'select A.PortfolioID as PortfolioBaseID, ' 
      + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID] , A.AuditEventTime, A.UserName
      FROM APXUserCustom.tAC4880SA_AoObjectAudit_Hist A JOIN APXUserCustom.tAC4880SA_AoObjectAudit_Hist B ON A.PortfolioID = B.PortfolioID AND A.AuditEventIDIn = B.AuditEventIDOut
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1'
      INSERT INTO #t1
      exec(@s)
      SET @counter = @counter + 1
END

--Processing Start and Closed Dates
set @counter = 1
set @countto = (select MAX(id) from @AdditionalPortfolioFields_dt)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @AdditionalPortfolioFields_dt t where t.id = @counter
      SET @s = N'select A.PortfolioID as PortfolioBaseID, ' 
      + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID] , A.AuditEventTime, A.UserName
      FROM APXUserCustom.tAC4880SA_PortfolioBaseAudit_Hist A JOIN APXUserCustom.tAC4880SA_PortfolioBaseAudit_Hist B ON A.PortfolioID = B.PortfolioID AND A.AuditEventIDIn = B.AuditEventIDOut
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1'
      INSERT INTO #t2
      exec(@s)
      SET @counter = @counter + 1
END

--Processing Portfolio Cusotm Fields
set @counter = 1
set @countto = (select MAX(id) from @AdditionalPortfolioFields_cust)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @AdditionalPortfolioFields_cust t where t.id = @counter
      SET @s = N'select A.PortfolioID as PortfolioBaseID, ' 
      + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID] , A.AuditEventTime, A.UserName
      FROM APXUserCustom.tAC4880SA_PortfolioBaseExtAudit_Hist A JOIN APXUserCustom.tAC4880SA_PortfolioBaseExtAudit_Hist B ON A.PortfolioID = B.PortfolioID AND A.AuditEventIDIn = B.AuditEventIDOut
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1'
      INSERT INTO #t3
      exec(@s)
      SET @counter = @counter + 1
END

-- Processing contact fields 
set @counter = 1
set @countto = (select MAX(id) from @ContactFields)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @ContactFields t where t.id = @counter
      SET @s = N'select A.ContactID as ContactID, ' 
      + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID], uB.DisplayName
      FROM AdvApp.vContact_Hist A JOIN AdvApp.vContact_Hist B ON A.ContactID = B.ContactID AND A.AuditEventIDIn = B.AuditEventIDOut
      JOIN APXuser.vUserBase uB on uB.UserBaseID = A.AuditUserID
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1'
      INSERT INTO #c
      exec(@s)
      SET @counter = @counter + 1
END

--Processing Default Address Field
set @counter = 1
set @countto = (select MAX(id) from @DefaultAddressFields)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @DefaultAddressFields t where t.id = @counter
	  SELECT @currentFieldName = t.FieldName FROM @CurrentAddressFields t where t.id = @counter	--	2015/04/24 AZK Needs to line up with field names from QbAddress field.

	  --For All DefaultAddressFields other than AddressLabel	--Changed on Mar2015
		if(@FieldName != 'AddressLabel')
		begin	  
			  SET @s = N'select A.AddressID as AddressID, ' 
			  + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
			  , A.AuditEventIDIn [AuditEventID], A.AuditEventTime, A.UserName
			  FROM ApxUserCustom.tAC4880SA_ContactDefaultAddress_Hist A INNER JOIN ApxUserCustom.tAC4880SA_ContactDefaultAddress_Hist B ON A.AddressID = B.AddressID AND A.AuditEventIDIn = B.AuditEventIDOut
			  WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
			  AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1 '

		--	2015/04/24 AZK Need to union against current address labels/fields to get the most recent change. Original report logic was always 1 step behind.

			  + 'UNION 
			  select A.AddressID as AddressID, ' 
			  + char(39) + @FieldName + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @currentFieldName + '] as NewValue 
			  ,A.AuditEventID, vA.AuditEventTime, B.UserName
			  FROM APXUserCustom.vQbAddress A INNER JOIN ApxUserCustom.tAC4880SA_ContactDefaultAddress_Hist B ON A.AddressID = B.AddressID AND A.AuditEventID = B.AuditEventIDOut
			  JOIN APXUserCustom.vAuditEvent vA on vA.AuditEventID = A.AuditEventID
			  WHERE vA.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND vA.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
			  AND CASE WHEN COALESCE(A.[' + @currentFieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1 '

			  INSERT INTO #a
			  exec(@s)
		end
		
		--Added for AddressLabel change  --Added on Mar10,2015 
		else
		begin
			declare @ContactAddressLabelAudit table (ContactCode nvarchar(max), ContactId int, prevAddressId int,prevAddressLabel nvarchar(max), CurrAddressId int,CurrAddressLabel nvarchar(max), NextAddressId int,NextAddressLabel nvarchar(max), AuditEventID int, AuditEventTime datetime,UserName nvarchar(max))
			;
			
			WITH CTE AS (
			select   
			row rownum,   
			DefaultAddressID,
			AddressLabel,   
			ContactCode,
			ContactID,   
			AuditEventIDIn,   
			AuditEventIDOut,
			AuditEventTime,
			UserName
			from  APXUserCustom.tAC4880SA_ContactDefaultAddressLabel_Hist a
			)
			insert into @ContactAddressLabelAudit
			SELECT   cte.ContactCode,cte.ContactID, case when prev.ContactID = cte.ContactID then prev.DefaultAddressID else null end prev,
				case when prev.ContactID = cte.ContactID then prev.AddressLabel else null end prevlbl,
				cte.DefaultAddressID   curr,  cte.AddressLabel currlbl,  
				--case when next.ContactID = cte.ContactID then next.DefaultAddressID else null end  
				null next, null nextlbl,
				cte.AuditEventIDIn,cte.AuditEventTime, cte.UserName
				
			FROM   CTE CTE
			LEFT   JOIN   CTE   prev   ON   prev.rownum   = cte.rownum -1
			--LEFT   JOIN   CTE   next   ON   next.rownum   =   CTE.rownum   +   1
			where   (isnull(prev.DefaultAddressID,100001)   <>   isnull(cte.DefaultAddressID,100001))  --and (prev.ContactID is null or cte.ContactID is null or prev.ContactID = cte.ContactID))  
				--or   (isnull(next.DefaultAddressID,100001)   <>   isnull(cte.DefaultAddressID,100001) ))--and (prev.ContactID is null or cte.ContactID is null or next.ContactID = cte.ContactID)) 

			INSERT INTO #a1
			select c.CurrAddressId,c.ContactId,'AddressLabel',prevAddressLabel,CurrAddressLabel,c.AuditEventID,c.AuditEventTime,c.UserName from @ContactAddressLabelAudit c
			--left join apxuser.vContactAddress cAdr1 on cAdr1.AddressID = c.CurrAddressId
			--left join apxuser.vContactAddress cAdr2 on cAdr2.AddressID = c.prevAddressId
			where isnull(prevAddressId,-9999) <> isnull(CurrAddressId,-9999)
			 --and isnull(NextId,-9999) <> CurrId
		
			--select * from #a1 a order by a.AddressContactID,a.AuditEventID
		  
		end
      SET @counter = @counter + 1
END

declare @Caption nvarchar(500)
--Processing Interested Parties
set @counter = 1
set @countto = (select MAX(id) from @InterestedPartiesMailing)
set @FieldName = ''
WHILE (@counter <= @countto)
      BEGIN
      SELECT @FieldName = t.FieldName FROM @InterestedPartiesMailing t where t.id = @counter
      
      SELECT @Caption = c.Caption FROM dbo.vQbRowDefRowDefinitionField c where c.FieldTag = @FieldName and c.ViewName = 'dbo.vQbRowDefInterestedPartyMailing'
      
      SET @s = N'select A.PortfolioID as PortfolioID, A.ContactID as ContactID,' 

      + char(39) + @Caption + char(39) + ' as FieldName, B.[' + @FieldName + '] as OldValue, A.[' + @FieldName + '] as NewValue 
      , A.AuditEventIDIn [AuditEventID], A.AuditEventTime, A.UserName
      FROM ApxUserCustom.tAC4880SA_InterestPartiesMailing_Hist A INNER JOIN ApxUserCustom.tAC4880SA_InterestPartiesMailing_Hist B ON A.PortfolioID = B.PortfolioID AND A.ContactID = B.ContactID AND A.AuditEventIDIn = B.AuditEventIDOut
      WHERE A.AuditEventTime >= ' + char(39) + @FromDatec + char(39) + ' AND A.AuditEventTime < ' + char(39) + @ThruDatec + char(39) + '
      AND CASE WHEN COALESCE(A.[' + @FieldName + '], ' + char(39) + char(39) + ') = COALESCE(B.[' + @FieldName + '], ' + char(39) + char(39) + ') THEN 0 ELSE 1 END = 1 '
      INSERT INTO #i
      exec(@s)
      SET @counter = @counter + 1
END

DELETE FROM ApxUserCustom.tAC4880SA_Changes_ContactFields
DELETE FROM ApxUserCustom.tAC4880SA_Changes_PortfolioFields
DELETE FROM ApxUserCustom.tAC4880SA_Changes_AdditionalPortfolioFields
DELETE FROM ApxUserCustom.tAC4880SA_Changes_ContactDefaultAddressFields
DELETE FROM APXUserCustom.tAC4880SA_Changes_InterestPartyMailing

INSERT INTO ApxUserCustom.tAC4880SA_Changes_PortfolioFields
SELECT * FROM #t a


INSERT INTO ApxUserCustom.tAC4880SA_Changes_AdditionalPortfolioFields
SELECT * FROM #t1 group by PortfolioBaseID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime,UserName
union all
SELECT * FROM #t2 group by PortfolioBaseID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime,UserName
union all
SELECT * FROM #t3 group by PortfolioBaseID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime,UserName

INSERT INTO ApxUserCustom.tAC4880SA_Changes_ContactFields
SELECT * FROM #c a


INSERT INTO ApxUserCustom.tAC4880SA_Changes_ContactDefaultAddressFields
SELECT cAdd.AddressContactID,a.FieldName,a.OldValue,a.NewValue,a.AuditEventID,a.AuditEventTime,a.UserName FROM #a a
join APXUser.vContactAddress cAdd on a.AddressID = cAdd.AddressID
where FieldName !='AddressLabel'
group by cAdd.AddressContactID,a.AddressID,a.FieldName,a.OldValue,a.NewValue,a.AuditEventID,a.AuditEventTime,a.UserName


--For Fields 'AddressLabel'  --Added on Mar2015
INSERT INTO ApxUserCustom.tAC4880SA_Changes_ContactDefaultAddressFields
SELECT AddressContactID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime,UserName FROM #a1
where FieldName ='AddressLabel'
--group by AddressContactID,AddressID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime 

INSERT INTO ApxUserCustom.tAC4880SA_Changes_InterestPartyMailing
SELECT * FROM #i 
group by PortfolioID,ContactID,FieldName,OldValue,NewValue,AuditEventID,AuditEventTime,UserName

DROP TABLE #t
DROP TABLE #t1
DROP TABLE #t2
DROP TABLE #t3
DROP TABLE #c
DROP TABLE #a
DROP TABLE #i

SELECT * 
FROM (SELECT 
		A.*,
		COALESCE(c.ContactCode, 'Portfolio') [ContactCode], 
		COALESCE(p.PortfolioBaseCode, '') [PortfolioBaseCode],
		v.AuditEventTime, 
		d.UserBaseName, 
		e.DisplayName [FunctionDisplayName], 
		d.DisplayName [AuditUserName]
		FROM (SELECT 
				'Portfolio' [FieldType], 
				p.PortfolioBaseID, 
				0 [ContactID], 
				p.FieldName, 
				COALESCE(p.OldValue,'') OldValue, 
				COALESCE(p.NewValue,'') NewValue, 
				p.AuditEventID 
			  FROM ApxUserCustom.tAC4880SA_Changes_PortfolioFields p
			  UNION
			  SELECT
				'Contact' [FieldType], 
				i.PortfolioID, 
				i.ContactID [ContactID], 
				c.FieldName, 
				COALESCE(c.OldValue,'') OldValue, 
				COALESCE(c.NewValue,'') NewValue,
				c.AuditEventID 
			  FROM AdvApp.vPortfolioInterestedParty i 
			  JOIN ApxUserCustom.tAC4880SA_Changes_ContactFields c on
				c.ContactID = i.ContactID
				) A
		JOIN dbo.AdvAuditEvent v ON 
			a.AuditEventID = v.AuditEventID
		JOIN AdvApp.vUserBase d on 
			v.UserID = d.UserBaseID
		JOIN AdvApp.vFunction e on 
			v.FunctionID = e.FunctionID
		LEFT JOIN AdvApp.vPortfolioBase p on 
			p.PortfolioBaseID = A.PortfolioBaseID  --Doing a left join because maybe some portfolios get deleted?
		LEFT JOIN AdvApp.vContact c on 
			c.ContactID = A.ContactID  --Left join because set to 0 in first select above
		UNION
		SELECT
			'DefaultAddress' [FieldType], 
			i.PortfolioID, 
			i.ContactID [ContactID], 
			a.FieldName, 
			COALESCE(a.OldValue,'') OldValue, 
			COALESCE(a.NewValue,'') NewValue, 
			a.AuditEventID AuditEventID,
			c.ContactCode, 
			p.PortfolioBaseCode,
			a.AuditEventTime [AuditEventTime],
			'' [UserBaseName],
			''[FunctionDisplayName], 
			a.UserName [AuditUserName]
		FROM AdvApp.vPortfolioInterestedParty i   ---This join makes this not work on PortfolioBases!!!
		JOIN ApxUserCustom.tAC4880SA_Changes_ContactDefaultAddressFields a on 
			a.ContactID = i.ContactID
		LEFT JOIN AdvApp.vPortfolioBase p on 
			p.PortfolioBaseID = i.PortfolioID  --Doing a left join because maybe some portfolios get deleted?
		LEFT JOIN AdvApp.vContact c on 
			c.ContactID = i.ContactID  --Left join because set to 0 in first select above
		UNION
		SELECT
			'Portfolio' [FieldType], 
			a.PortfolioBaseID, 
			0 [ContactID], 
			a.FieldName, 
			COALESCE(a.OldValue,'') OldValue, 
			COALESCE(a.NewValue,'') NewValue, 
			a.AuditEventID AuditEventID,
			'Portfolio' ContactCode, 
			p.PortfolioBaseCode,
			a.AuditEventTime  [AuditEventTime],
			'' [UserBaseName],
			'' [FunctionDisplayName], 
			a.UserName [AuditUserName]
		FROM ApxUserCustom.tAC4880SA_Changes_AdditionalPortfolioFields a 
		LEFT JOIN AdvApp.vPortfolioBase p on 
			p.PortfolioBaseID = a.PortfolioBaseID  --Doing a left join because maybe some portfolios get deleted?
		UNION
		SELECT
			'InterestedPartyMailing' [FieldType], 
			a.PortfolioBaseID, 
			a.ContactID [ContactID], 
			a.FieldName, 
			COALESCE(a.OldValue,'') OldValue, 
			COALESCE(a.NewValue,'') NewValue, 
			a.AuditEventID AuditEventID,
			c.ContactCode, p.PortfolioBaseCode,
			a.AuditEventTime [AuditEventTime],
			'' [UserBaseName],
			''[FunctionDisplayName], 
			a.UserName [AuditUserName]
		FROM ApxUserCustom.tAC4880SA_Changes_InterestPartyMailing a
		LEFT JOIN AdvApp.vPortfolioBase p on 
			p.PortfolioBaseID = a.PortfolioBaseID  --Doing a left join because maybe some portfolios get deleted?
		LEFT JOIN AdvApp.vContact c on 
			c.ContactID = a.ContactID  --Left join because set to 0 in first select above
		) output
where PortfolioBaseID in (select portfolioId from @AllPortfolios)

END

GO
