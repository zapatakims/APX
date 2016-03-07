USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_InterestPartiesMailing_Hist]    Script Date: 01/05/2015 16:27:33 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_InterestPartiesMailing_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_InterestPartiesMailing_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_InterestPartiesMailing_Hist]    Script Date: 01/05/2015 16:27:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_InterestPartiesMailing_Hist](
	[PortfolioID] [dbo].[dtID] NULL,
	[ContactID] [dbo].[dtID] NULL,
	[AddressID] [dbo].[dtID] NULL,
	[HasMailing01] [dbo].[dtBoolean] NULL,
	[HasMailing02] [dbo].[dtBoolean] NULL,
	[HasMailing03] [dbo].[dtBoolean] NULL,
	[HasMailing04] [dbo].[dtBoolean] NULL,
	[HasMailing05] [dbo].[dtBoolean] NULL,
	[HasMailing06] [dbo].[dtBoolean] NULL,
	[HasMailing07] [dbo].[dtBoolean] NULL,
	[HasMailing08] [dbo].[dtBoolean] NULL,
	[HasMailing09] [dbo].[dtBoolean] NULL,
	[HasMailing10] [dbo].[dtBoolean] NULL,
	[HasMailing11] [dbo].[dtBoolean] NULL,
	[HasMailing12] [dbo].[dtBoolean] NULL,
	[HasMailing13] [dbo].[dtBoolean] NULL,
	[HasMailing14] [dbo].[dtBoolean] NULL,
	[HasMailing15] [dbo].[dtBoolean] NULL,
	[HasMailing16] [dbo].[dtBoolean] NULL,
	[HasMailing17] [dbo].[dtBoolean] NULL,
	[HasMailing18] [dbo].[dtBoolean] NULL,
	[HasMailing19] [dbo].[dtBoolean] NULL,
	[HasMailing20] [dbo].[dtBoolean] NULL,
	[HasMailing21] [dbo].[dtBoolean] NULL,
	[HasMailing22] [dbo].[dtBoolean] NULL,
	[HasMailing23] [dbo].[dtBoolean] NULL,
	[HasMailing24] [dbo].[dtBoolean] NULL,
	[HasMailing25] [dbo].[dtBoolean] NULL,
	[HasMailing26] [dbo].[dtBoolean] NULL,
	[HasMailing27] [dbo].[dtBoolean] NULL,
	[HasMailing28] [dbo].[dtBoolean] NULL,
	[HasMailing29] [dbo].[dtBoolean] NULL,
	[HasMailing30] [dbo].[dtBoolean] NULL,
	[HasMailing31] [dbo].[dtBoolean] NULL,
	[HasMailing32] [dbo].[dtBoolean] NULL,
	[AuditEventIDIn] [int] NULL,
	[AuditEventIDOut] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

