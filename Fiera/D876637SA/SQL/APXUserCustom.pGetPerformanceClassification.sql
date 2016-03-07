IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pGetPerformanceClassification]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pGetPerformanceClassification]
GO

CREATE PROCEDURE [APXUserCustom].[pGetPerformanceClassification] (@NullName name72 = null, @ExcludePortPerf bit = 0)
AS
BEGIN
	select ClassificationID = null, ClassificationName = 'None'
	union all
	select ClassificationID = pr.PropertyID, ClassificationName = pr.DisplayName
	from APX.PerfClass pc
	left join dbo.AoProperty pr on pr.PropertyID = pc.PerfClassID
	where pc.AllowPerformanceUpdate = 1
	order by ClassificationName
END

GO