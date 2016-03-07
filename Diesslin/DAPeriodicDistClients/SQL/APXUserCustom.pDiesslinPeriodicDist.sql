if object_id('[APXUserCustom].[pDiesslinPeriodicDist]') is not null
	drop procedure [APXUserCustom].[pDiesslinPeriodicDist]
go

-- exec [APXUserCustom].[pDiesslinPeriodicDist] null, '@abroms','11/10/09'

CREATE procedure [APXUserCustom].[pDiesslinPeriodicDist]
@SessionGuid nvarchar(48),
@Portfolios nvarchar(max),
@Date datetime
--@ReportingCurrencyCode dtCurrencyCode = null,	-- Use Settings
--@LocaleID int = null							-- Use Portfolio Settings

as
begin

declare
@DataHandle as uniqueidentifier = newid(),
@ReportData varbinary(max),
@TransactionData varbinary(max),
@DistToDate datetime,
@DistFromDate datetime,
@TranFromDate datetime,
@TranToDate datetime,
@balDate datetime

select @DistToDate = DATEADD(D,7,@Date)			--	+7 days
select @TranToDate = DATEADD(D,10,@Date)		--	+10 days
select @DistFromDate = DATEADD(D, -7, @Date)	--	-7 days
select @TranFromDate = DATEADD(D,-10,@Date)		--	-10 days

select @balDate = DATEADD(D, -1, @Date)	--	Transactions are on an AM-to-AM basis, so subtract a day.

exec APXUser.pSessionInfoSetGuid @SessionGuid = @SessionGuid

exec APXUser.pAppraisalBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Appraisal',
	@Portfolios = @Portfolios,
	@Date = @balDate
	-- Optional Parameters
	--@ReportingCurrencyCode = @ReportingCurrencyCode out,
	--@LocaleID = @LocaleID
		
exec APXUser.pTransactionActivityBatch
	-- Required Parameters
	@DataHandle = @DataHandle,
	@DataName = 'Transaction',
	@Portfolios = @Portfolios,
	@FromDate = @TranFromDate,--@DistFromDate,
	@ToDate = @TranToDate--@DistToDate
		
exec APXUser.pReportBatchExecute @DataHandle, @ExplodeData= 0

exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Appraisal', @ReportData = @ReportData out
exec APXUser.pReportDataGetFromHandle @DataHandle = @DataHandle, @DataName = 'Transaction', @ReportData = @TransactionData out

declare
@bdtm datetime,
@edtm datetime,
@bdlm datetime,
@edlm datetime,
@bdnm datetime

select @bdtm = APXUser.fGetGenericDate('{bdtm}',@Date)
select @edtm = APXUser.fGetGenericDate('{edtm}', @Date)
select @bdlm = APXUser.fGetGenericDate('{bdlm}',@Date)
select @edlm = APXUser.fGetGenericDate('{edlm}', @Date)
select @bdnm = DATEADD(D,1,@edtm)

declare @PaidDist table (PortfolioBaseID int, TradeDate datetime, TradeAmount float)

insert @PaidDist
select
	t.PortfolioBaseID,
	t.TradeDate,
	--sum(t.TradeAmount) [lo_TradeAmount]
	t.TradeAmount [lo_TradeAmount]
from APXUser.fTransactionActivity (@TransactionData) t
where t.TransactionCode = 'lo' and t.SecTypeCode1 = 'ca'
--	group by t.TradeDate, t.PortfolioBaseID

declare @temp table (PortfolioBaseID int, PortfolioBaseIDOrder int, PortfolioBaseCode char(32), PortfolioTypeCode char(55),
ShortName varchar(255), CashBalance float, DistNet float, DistGross float, DistFrequency varchar(255), DistDay1 datetime, DistDay2 datetime, DistDay3 datetime,
Custom02 varchar(255), TradeAmount float, TradeDate datetime)

insert @temp
select
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.PortfolioBaseCode,
	port.PortfolioTypeCode,
	--p.ReportHeading1,
	port.ShortName,
	sum(a.MarketValue) [CashBalance],
	pCustom.DistNet,
	pCustom.DistGross,
	pCustom.DistFrequency,
	case pCustom.DistDay1
		when '0' then @edlm
		when '-1' then DATEADD(d,-1, @edlm)
		else DATEADD(d,convert(int,pCustom.DistDay1), @bdlm) - 1
	end as DistDay1,
	case pCustom.DistDay1
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay1), @bdtm) - 1
	end as DistDay2,
	case pCustom.DistDay1
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay1), @bdnm) - 1
	end as DistDay3,
	cCustom.Custom02,
	isnull(pd.TradeAmount,0) [TradeAmount],
	isnull(pd.TradeDate, @balDate) [TradeDate]--,
	--case
	--	when pCustom.DistNet IS NULL then 'Not Distributed'
	--	when (pd.TradeAmount = pCustom.DistNet) then 'Paid'
	--	else 'Approaching'
	--end as Dist
from APXUser.vPortfolioBase p
left join APXUser.fAppraisal (@ReportData) a
	 on p.PortfolioBaseID = a.PortfolioBaseID and a.SecTypeCode = 'ca'
--join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p
--	 on p.PortfolioBaseID = a.PortfolioBaseID
join APXUser.vPortfolio port
	 on port.PortfolioID = a.PortfolioBaseID
left join APXUser.vPortfolioBaseCustom pCustom
	 on pCustom.PortfolioBaseID = p.PortfolioBaseID
left join APXUser.vContactCustom cCustom
	 on cCustom.ContactID = port.OwnerContactID
left join @PaidDist pd 
	 on pd.PortfolioBaseID = a.PortfolioBaseID and
	 pd.TradeAmount = pCustom.DistNet
--where (CHARINDEX(upper(CONVERT(varchar(3), @Date)), pCustom.DistFrequency, 0) > 0 or 
--CHARINDEX(upper(CONVERT(varchar(3), @DistFromDate)), pCustom.DistFrequency, 0) > 0 or
--CHARINDEX(upper(CONVERT(varchar(3), @DistToDate)), pCustom.DistFrequency, 0) > 0 or
--pCustom.DistFrequency = 'Monthly')
group by a.PortfolioBaseID, a.PortfolioBaseIDOrder, p.PortfolioBaseCode, port.PortfolioTypeCode, p.ReportHeading1, pCustom.DistNet, pCustom.DistFrequency, pCustom.DistDay1, cCustom.Custom02
	,pd.TradeAmount, pd.TradeDate, port.ShortName, pCustom.DistGross


--select
--	@DistFromDate [FromDate],
--	@DistToDate [ToDate],
--	t.PortfolioBaseCode,
--	t.DistFrequency,
--	t.DistDay1,
--	t.DistDay2,
--	t.DistDay3
--from @temp t

declare @output table (FromDate datetime, ToDate datetime, CashBalance float, Custom02 varchar(255), DistDay datetime, DistFrequency varchar(255), DistNet float, DistGross float, PortfolioBaseCode char(32), 
PortfolioBaseID int, PortfolioBaseIDOrder int, PortfolioTypeCode char(55), ShortName varchar(255), TradeAmount float, TradeDate datetime)

insert @output
select 
	@DistFromDate [FromDate],
	@DistToDate [ToDate],
	t.CashBalance,
	t.Custom02,
	case when t.DistDay1 < @DistFromDate then
		case when t.DistDay2 < @DistFromDate then t.DistDay3 else t.DistDay2 end
	else t.DistDay1
	end as DistDay,
	t.DistFrequency,
	t.DistNet,
	t.DistGross,
	t.PortfolioBaseCode,
	t.PortfolioBaseID,
	t.PortfolioBaseIDOrder,
	t.PortfolioTypeCode,
	t.ShortName,
	t.TradeAmount,
	t.TradeDate--,
	--CHARINDEX(upper(CONVERT(varchar(3), @Date)), t.DistFrequency, 0)
	--case when t.DistNet IS NULL then 'Not Distributed'
	--	when (t.DistDay <= @Date and t.DistDay >= @DistFromDate) then 'Paid'
	--	when (t.DistDay >= @Date and t.DistDay <= @DistToDate) then 'Approaching'
	--end as Dist
from @temp t
--where (t.DistDay1 >= @DistFromDate and t.DistDay1 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or
--CHARINDEX((CONVERT(varchar(3), @Date)), t.DistFrequency, 0) > 0

delete from @temp

insert @temp
select
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.PortfolioBaseCode,
	port.PortfolioTypeCode,
	--p.ReportHeading1,
	port.ShortName,
	sum(a.MarketValue) [CashBalance],
	pCustom.DistNet2,
	pCustom.DistGross2,
	pCustom.DistFrequency2,
	case pCustom.DistDay2
		when '0' then @edlm
		when '-1' then DATEADD(d,-1, @edlm)
		else DATEADD(d,convert(int,pCustom.DistDay2), @bdlm) - 1
	end as DistDay1,
	case pCustom.DistDay2
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay2), @bdtm) - 1
	end as DistDay2,
	case pCustom.DistDay2
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay2), @bdnm) - 1
	end as DistDay3,
	cCustom.Custom02,
	isnull(pd.TradeAmount,0) [TradeAmount],
	isnull(pd.TradeDate, @balDate) [TradeDate]--,
	--case
	--	when pCustom.DistNet2 IS NULL then 'Not Distributed'
	--	when (pd.TradeAmount = pCustom.DistNet2) then 'Paid'
	--	else 'Approaching'
	--end as Dist
from APXUser.vPortfolioBase p
left join APXUser.fAppraisal (@ReportData) a
	 on p.PortfolioBaseID = a.PortfolioBaseID and a.SecTypeCode = 'ca'
--join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p
--	 on p.PortfolioBaseID = a.PortfolioBaseID
join APXUser.vPortfolio port
	 on port.PortfolioID = a.PortfolioBaseID
left join APXUser.vPortfolioBaseCustom pCustom
	 on pCustom.PortfolioBaseID = p.PortfolioBaseID
left join APXUser.vContactCustom cCustom
	 on cCustom.ContactID = port.OwnerContactID
left join @PaidDist pd 
	 on pd.PortfolioBaseID = a.PortfolioBaseID and
	 pd.TradeAmount = pCustom.DistNet2
--where (CHARINDEX(upper(CONVERT(varchar(3), @Date)), pCustom.DistFrequency2, 0) > 0 or 
--CHARINDEX(upper(CONVERT(varchar(3), @DistFromDate)), pCustom.DistFrequency2, 0) > 0 or
--CHARINDEX(upper(CONVERT(varchar(3), @DistToDate)), pCustom.DistFrequency2, 0) > 0 or
--pCustom.DistFrequency2 = 'Monthly')
group by a.PortfolioBaseID, a.PortfolioBaseIDOrder, p.PortfolioBaseCode, port.PortfolioTypeCode, p.ReportHeading1, pCustom.DistNet2, pCustom.DistFrequency2, pCustom.DistDay2, cCustom.Custom02
	,pd.TradeAmount, pd.TradeDate, port.ShortName, pCustom.DistGross2

insert @output
select 
	@DistFromDate [FromDate],
	@DistToDate [ToDate],
	t.CashBalance,
	t.Custom02,
	case when t.DistDay1 < @DistFromDate then
		case when t.DistDay2 < @DistFromDate then t.DistDay3 else t.DistDay2 end
	else t.DistDay1
	end as DistDay,
	t.DistFrequency,
	t.DistNet,
	t.DistGross,
	t.PortfolioBaseCode,
	t.PortfolioBaseID,
	t.PortfolioBaseIDOrder,
	t.PortfolioTypeCode,
	t.ShortName,
	t.TradeAmount,
	t.TradeDate--,
	--CHARINDEX(upper(CONVERT(varchar(3), @Date)), t.DistFrequency, 0)
	--case when t.DistNet IS NULL then 'Not Distributed'
	--	when (t.DistDay <= @Date and t.DistDay >= @DistFromDate) then 'Paid'
	--	when (t.DistDay >= @Date and t.DistDay <= @DistToDate) then 'Approaching'
	--end as Dist
from @temp t
--where (t.DistDay1 >= @DistFromDate and t.DistDay1 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or
--CHARINDEX((CONVERT(varchar(3), @Date)), t.DistFrequency, 0) > 0

delete from @temp

insert @temp
select
	a.PortfolioBaseID,
	a.PortfolioBaseIDOrder,
	p.PortfolioBaseCode,
	port.PortfolioTypeCode,
	--p.ReportHeading1,
	port.ShortName,
	sum(a.MarketValue) [CashBalance],
	pCustom.DistNet3,
	pCustom.DistGross3,
	pCustom.DistFrequency3,
	case pCustom.DistDay3
		when '0' then @edlm
		when '-1' then DATEADD(d,-1, @edlm)
		else DATEADD(d,convert(int,pCustom.DistDay3), @bdlm) - 1
	end as DistDay1,
	case pCustom.DistDay3
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay3), @bdtm) - 1
	end as DistDay2,
	case pCustom.DistDay3
		when '0' then @edtm
		when '-1' then DATEADD(d,-1, @edtm)
		else DATEADD(d,convert(int,pCustom.DistDay3), @bdnm) - 1
	end as DistDay3,
	cCustom.Custom02,
	isnull(pd.TradeAmount,0) [TradeAmount],
	isnull(pd.TradeDate, @balDate) [TradeDate]--,
	--case
	--	when pCustom.DistNet3 IS NULL then 'Not Distributed'
	--	when (pd.TradeAmount = pCustom.DistNet3) then 'Paid'
	--	else 'Approaching'
	--end as Dist
from APXUser.vPortfolioBase p
left join APXUser.fAppraisal (@ReportData) a
	 on p.PortfolioBaseID = a.PortfolioBaseID and a.SecTypeCode = 'ca'
--join APXSSRS.fPortfolioBase(@LocaleID, @ReportingCurrencyCode, 0) p
--	 on p.PortfolioBaseID = a.PortfolioBaseID
join APXUser.vPortfolio port
	 on port.PortfolioID = a.PortfolioBaseID
left join APXUser.vPortfolioBaseCustom pCustom
	 on pCustom.PortfolioBaseID = p.PortfolioBaseID
left join APXUser.vContactCustom cCustom
	 on cCustom.ContactID = port.OwnerContactID
left join @PaidDist pd 
	 on pd.PortfolioBaseID = a.PortfolioBaseID and
	 pd.TradeAmount = pCustom.DistNet3
--where (CHARINDEX(upper(CONVERT(varchar(3), @Date)), pCustom.DistFrequency3, 0) > 0 or 
--CHARINDEX(upper(CONVERT(varchar(3), @DistFromDate)), pCustom.DistFrequency3, 0) > 0 or
--CHARINDEX(upper(CONVERT(varchar(3), @DistToDate)), pCustom.DistFrequency3, 0) > 0 or
--pCustom.DistFrequency3 = 'Monthly')
group by a.PortfolioBaseID, a.PortfolioBaseIDOrder, p.PortfolioBaseCode, port.PortfolioTypeCode, p.ReportHeading1, pCustom.DistNet3, pCustom.DistFrequency3, pCustom.DistDay3, cCustom.Custom02
	,pd.TradeAmount, pd.TradeDate, port.ShortName, pCustom.DistGross3

insert @output
select 
	@DistFromDate [FromDate],
	@DistToDate [ToDate],
	t.CashBalance,
	t.Custom02,
	case when t.DistDay1 < @DistFromDate then
		case when t.DistDay2 < @DistFromDate then t.DistDay3 else t.DistDay2 end
	else t.DistDay1
	end as DistDay,
	t.DistFrequency,
	t.DistNet,
	t.DistGross,
	t.PortfolioBaseCode,
	t.PortfolioBaseID,
	t.PortfolioBaseIDOrder,
	t.PortfolioTypeCode,
	t.ShortName,
	t.TradeAmount,
	t.TradeDate--,
	--CHARINDEX(upper(CONVERT(varchar(3), @Date)), t.DistFrequency, 0)
	--case when t.DistNet IS NULL then 'Not Distributed'
	--	when (t.DistDay <= @Date and t.DistDay >= @DistFromDate) then 'Paid'
	--	when (t.DistDay >= @Date and t.DistDay <= @DistToDate) then 'Approaching'
	--end as Dist
from @temp t
--where (t.DistDay1 >= @DistFromDate and t.DistDay1 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or (t.DistDay2 >= @DistFromDate and t.DistDay2 <= @DistToDate) or
--CHARINDEX((CONVERT(varchar(3), @Date)), t.DistFrequency, 0) > 0

select o.*
	,case when o.DistNet IS NULL then 'Not Distributed'
		when (o.DistDay <= @Date and o.DistDay >= @DistFromDate) then 'Paid'
		when (o.DistDay >= @Date and o.DistDay <= @DistToDate) then 'Approaching'
	end as Dist
from @output o
where (o.DistDay >= @DistFromDate and o.DistDay <= @DistToDate) and
(CHARINDEX((CONVERT(varchar(3), DistDay)), DistFrequency, 0) > 0 or DistFrequency = 'Monthly')
end	
GO


/*	
	AZK 2014/03/23
	Added DistGross column to calculate Difference between DistGross, DistGross2, DistGross3, and cash balance.

	AZK 2014/03/11
	Removed logic to lump "lo" transactions of cash per Sean's request.
*/
