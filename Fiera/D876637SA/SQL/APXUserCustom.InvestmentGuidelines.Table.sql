USE [APXFirm]
GO
/****** Object:  Table [APXUserCustom].[InvestmentGuidelines]    Script Date: 11/20/2015 14:47:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [APXUserCustom].[InvestmentGuidelines](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AccountCode] [nvarchar](72) NULL,
	[AssetClass] [nvarchar](255) NULL,
	[Min] [float] NULL,
	[Bench] [float] NULL,
	[Max] [float] NULL,
 CONSTRAINT [PK_InvestmentGuidelines] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRODDATA]
) ON [PRODDATA]
GO
