IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[vQbAddress]') AND type in (N'V'))
DROP VIEW [APXUserCustom].[vQbAddress]
GO


/****** Object:  View [APX].[vAuditEvent]    Script Date: 4/24/2015 9:05:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- $Header: $/APX/Trunk/APX/APXDatabase/APXFirm/View/Common/vAuditEvent.sql  2010-06-21 18:42:17 PDT  ADVENT\twilson $
create view [APXUserCustom].[vQbAddress] as
select * from dbo.QbAddress
GO
