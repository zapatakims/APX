if exists (select * from sys.objects where object_id = OBJECT_ID(N'[APXUserCustom].[pGetAllocationClassification]') AND type in (N'P', N'PC'))
drop procedure [APXUserCustom].[pGetAllocationClassification]
go

create procedure [APXUserCustom].[pGetAllocationClassification] (@NullName name72 = null)
AS
BEGIN
	
	declare @values table (ClassificationID int, ClassificationName name72)
	if (@NullName is not null)
		insert into @values select null, @NullName 
	insert into @values
		select -999, ' '
	insert into @values
		select ClassificationID = pr.PropertyID, ClassificationName = pr.DisplayName
		from APX.PerfClass pc
		left join dbo.AoProperty pr on pr.PropertyID = pc.PerfClassID
		where pc.AllowReporting = 1 AND pc.PerfClassID NOT IN(-8, -9) -- Exclude SecPerf and PortPerf
		order by pr.DisplayName
	select ClassificationID, ClassificationName from @values
END
