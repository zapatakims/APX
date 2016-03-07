USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_ContactDefaultAddress_Hist]    Script Date: 01/05/2015 16:27:19 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_ContactDefaultAddress_Hist]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_ContactDefaultAddress_Hist]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_ContactDefaultAddress_Hist]    Script Date: 01/05/2015 16:27:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_ContactDefaultAddress_Hist](
	[AddressID] [dbo].[dtID] NULL,
	[AddressGUID] [dbo].[dtObjectGUID] NULL,
	[AddressLabel] [dbo].[dtLookup] NULL,
	[AddressLine1] [dbo].[nstr72] NULL,
	[AddressLine2] [dbo].[nstr72] NULL,
	[AddressLine3] [dbo].[nstr72] NULL,
	[AddressLine4] [dbo].[nstr72] NULL,
	[AddressCity] [dbo].[nstr72] NULL,
	[AddressStateCode] [dbo].[nstrProvinceCode] NULL,
	[AddressPostalCode] [dbo].[strPostalCode] NULL,
	[AddressCountry] [dbo].[nstr32] NULL,
	[AddressContactID] [dbo].[dtID] NULL,
	[AddressContactCode] [dbo].[name32] NULL,
	[AddressOwnerContactID] [dbo].[dtID] NULL,
	[AddressOwnerContactCode] [dbo].[name32] NULL,
	[OwnedBy] [dbo].[dtID] NULL,
	[Duration] [dbo].[name32] NULL,
	[AddressFull] [dbo].[nstr255] NULL,
	[IsSendMail] [dbo].[dtBoolean] NULL,
	[IsSendExpress] [dbo].[dtBoolean] NULL,
	[Custom01] [dbo].[dtCustom] NULL,
	[Custom02] [dbo].[dtCustom] NULL,
	[Custom03] [dbo].[dtCustom] NULL,
	[Custom04] [dbo].[dtCustom] NULL,
	[HasAttr01] [dbo].[dtBoolean] NULL,
	[HasAttr02] [dbo].[dtBoolean] NULL,
	[HasAttr03] [dbo].[dtBoolean] NULL,
	[HasAttr04] [dbo].[dtBoolean] NULL,
	[AuditDate] [datetime] NULL,
	[AuditID] [int] NULL,
	[AuditEventIDIn] [int] NULL,
	[AuditEventIDOut] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

SET ANSI_PADDING OFF
GO

