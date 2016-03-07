USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_ContactDefaultAddressLabel_Hist]    Script Date: 03/13/2015 17:55:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_ContactDefaultAddressLabel_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_ContactDefaultAddressLabel_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_ContactDefaultAddressLabel_Hist]    Script Date: 03/13/2015 17:55:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_ContactDefaultAddressLabel_Hist](
	[row] [dbo].[dtID] IDENTITY(1,1) NOT NULL,
	[DefaultAddressID] [dbo].[dtID] NULL,
	[AddressLabel] [dbo].[dtLookup] NULL,
	[ContactCode] [dbo].[name32] NULL,
	[ContactID] [dbo].[dtID] NULL,
	[AuditDate] [datetime] NULL,
	[AuditEventIDIn] [int] NULL,
	[AuditEventIDOut] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

