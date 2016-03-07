USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fShowQuantity]    Script Date: 12/01/2013 18:41:23 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fShowQuantity]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fShowQuantity]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fShowQuantity]    Script Date: 12/01/2013 18:41:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create function [APXUserCustom].[fShowQuantity](
      @CanBeBoughtSold bit,
      @ReportingCurrencyCode dtCurrencyCode,
      @PositionCurrency dtCurrencyCode)
returns bit as
begin
---Change in the logic of this calculation should also be replicated in APXUser.pReportAppraisal
      return case
            when @CanBeBoughtSold = 0 and @ReportingCurrencyCode = @PositionCurrency then 0
            else 1 end
end


GO


