USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioFields_Hist]    Script Date: 01/05/2015 16:28:07 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_PortfolioFields_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_PortfolioFields_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_PortfolioFields_Hist]    Script Date: 01/05/2015 16:28:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_PortfolioFields_Hist](
	[PortfolioID] [int] NULL,
	[StartDate] [datetime] NULL,
	[ClosedDate] [datetime] NULL,
	[ReportHeading1] [nvarchar](max) NULL,
	[RichterBoberAllocation] [nvarchar](max) NULL,
	[TacticalWeight] [nvarchar](max) NULL,
	[AuditDate] [datetime] NULL,
	[AuditID] [int] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

