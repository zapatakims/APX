USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetClassificationInceptionDatesDetail]    Script Date: 01/20/2016 09:27:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetClassificationInceptionDatesDetail]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetClassificationInceptionDatesDetail]
GO

USE [APXFirm]
GO

/****** Object:  UserDefinedFunction [APXUserCustom].[fGetClassificationInceptionDatesDetail]    Script Date: 01/20/2016 09:27:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE function [APXUserCustom].[fGetClassificationInceptionDatesDetail] (@ReportData varbinary(max))
returns @output TABLE 
(
    -- Columns returned by the function
    ClassificationMemberCode nvarchar(max) NOT NULL, 
    ClassificationMemberID int NULL, 
    ClassificationMemberName nvarchar(max) NULL, 
    ClassificationMemberOrder int NULL,
    InceptionDate datetime NULL,
    SellDate datetime NULL
)
as 
begin
	
	with history as (
				SELECT ClassificationMemberCode, ClassificationMemberID, 
				ClassificationMemberName, ClassificationMemberOrder, PeriodFromDate, 
				PeriodThruDate, EndingMarketValue
				FROM APXUser.fPerformanceHistoryDetail(@ReportData)
				WHERE ClassificationMemberCode <> 'totport'
					AND ClassificationMemberCode <> 'Total'
	), classes as (
		SELECT DISTINCT ClassificationMemberCode, ClassificationMemberID, 
				ClassificationMemberName, ClassificationMemberOrder
		FROM history
	)
	INSERT INTO @output
	SELECT ClassificationMemberCode
		, ClassificationMemberID
		, ClassificationMemberName
		, ClassificationMemberOrder
		, CASE 
			WHEN lastZero.InceptionDate IS NOT NULL 
				AND periodAfterZero.InceptionDate IS NULL 
			  THEN inceptionFromStart.SellDate --asset not held since last zero (should probably be no inception, but using sell date so as not to break procs)
			ELSE COALESCE(periodAfterZero.InceptionDate, inceptionFromStart.InceptionDate)
		  END [InceptionDate]
		, inceptionFromStart.SellDate
	FROM classes
	OUTER APPLY(
		SELECT MAX(PeriodThruDate) [InceptionDate]
		FROM history
		WHERE history.EndingMarketValue = 0
			and history.ClassificationMemberID = classes.ClassificationMemberID
	) lastZero
	OUTER APPLY (
		SELECT MIN(PeriodThruDate) [InceptionDate]
		FROM history
		WHERE history.EndingMarketValue <> 0
			AND history.PeriodFromDate >= lastZero.InceptionDate -- >= here because sometimes from dates are wrong/have gaps in their data
			and history.ClassificationMemberID = classes.ClassificationMemberID
	) periodAfterZero
	OUTER APPLY(
		SELECT MIN(PeriodFromDate) [InceptionDate]
			, MAX(PeriodThruDate) [SellDate]
		FROM history
		WHERE history.ClassificationMemberID = classes.ClassificationMemberID
			AND history.EndingMarketValue <> 0
	) inceptionFromStart
	WHERE inceptionFromStart.SellDate IS NOT NULL --exclude any classes that don't have a non zero endmarketvalue

	return

end



GO


