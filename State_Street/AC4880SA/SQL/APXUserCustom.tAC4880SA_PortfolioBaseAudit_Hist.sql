USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioBaseAudit_Hist]    Script Date: 01/05/2015 16:27:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_PortfolioBaseAudit_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_PortfolioBaseAudit_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioBaseAudit_Hist]    Script Date: 01/05/2015 16:27:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_PortfolioBaseAudit_Hist](
	[PortfolioID] [int] NULL,
	[StartDate] [datetime] NULL,
	[ClosedDate] [datetime] NULL,
	[AuditEventIDIn] [int] NULL,
	[AuditEventIDOut] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

