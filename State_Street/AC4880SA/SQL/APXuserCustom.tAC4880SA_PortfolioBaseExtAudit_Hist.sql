USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioBaseExtAudit_Hist]    Script Date: 01/05/2015 16:27:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_PortfolioBaseExtAudit_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_PortfolioBaseExtAudit_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioBaseExtAudit_Hist]    Script Date: 01/05/2015 16:27:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_PortfolioBaseExtAudit_Hist](
	[PortfolioID] [int] NULL,
	[RichterBoberAllocation] [nvarchar](max) NULL,
	[TacticalWeight] [nvarchar](max) NULL,
	[AuditEventIDIn] [int] NULL,
	[AuditEventIDOut] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

