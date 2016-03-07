USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_Changes_AdditionalPortfolioFields]    Script Date: 01/05/2015 16:26:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[tAC4880SA_Changes_AdditionalPortfolioFields]') AND type in (N'U'))
DROP TABLE [APXUserCustom].[tAC4880SA_Changes_AdditionalPortfolioFields]
GO

USE [APXFirm]
GO

/****** Object:  Table [APXUserCustom].[tAC4880SA_Changes_AdditionalPortfolioFields]    Script Date: 01/05/2015 16:26:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [APXUserCustom].[tAC4880SA_Changes_AdditionalPortfolioFields](
	[PortfolioBaseID] [int] NULL,
	[FieldName] [nvarchar](255) NULL,
	[OldValue] [nvarchar](255) NULL,
	[NewValue] [nvarchar](255) NULL,
	[AuditEventID] [int] NULL,
	[AuditEventTime] [datetime] NULL,
	[UserName] [nvarchar](500) NULL
) ON [PRODDATA]

GO

