IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[vAuditEvent]') AND type in (N'V'))
DROP VIEW [APXUserCustom].[vAuditEvent]
GO

/****** Object:  View [APX].[vAuditEvent]    Script Date: 4/24/2015 9:05:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- $Header: $/APX/Trunk/APX/APXDatabase/APXFirm/View/Common/vAuditEvent.sql  2010-06-21 18:42:17 PDT  ADVENT\twilson $
create view [APXUserCustom].[vAuditEvent] as
select
	ae.AuditEventID as AuditEventID
	,ae.UserID as UserID
	,ou.DisplayName as UserDisplayName
	,ae.FunctionID as FunctionID
	,f.DisplayName as FunctionDisplayName
	,ae.JobID as JobID
	,ae.ProcessID as ProcessID
	,ae.AuditEventTime as AuditEventTime
from 
	AdvAuditEvent ae 
	join dbo.Aouser u on u.UserID = ae.UserID
	join dbo.AoObject ou on ou.ObjectID = u.UserID
	join dbo.AoFunction f on f.FunctionID = ae.FunctionID

GO


