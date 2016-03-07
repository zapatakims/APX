IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pGetReportingClassification]') AND type in (N'P'))
DROP PROCEDURE [APXUserCustom].[pGetReportingClassification]
GO

CREATE PROCEDURE [APXUserCustom].[pGetReportingClassification] (@NullName name72 = null, @ExcludePortPerf bit = 0)
AS
BEGIN
	
	declare @values table (ClassificationID int, ClassificationName name72)
	if (@NullName is not null)
		insert into @values select null, @NullName 
	
	insert into @values
		select ClassificationID = null, ClassificationName = 'None'
		union all
		select pr.PropertyID, pr.DisplayName
		from APX.PerfClass pc
		left join dbo.AoProperty pr on pr.PropertyID = pc.PerfClassID
		where pc.AllowReporting = 1 
			and (pc.PerfClassID <> -9)
			and (pc.PerfClassID <> -8)
		order by ClassificationName		
		select ClassificationID, ClassificationName from @values
END
GO