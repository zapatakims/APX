if object_id('[APXUserCustom].[pGetIndexes]') is not null
	drop procedure [APXUserCustom].[pGetIndexes]
go

create PROCEDURE [APXUserCustom].[pGetIndexes]
AS
BEGIN
	
	declare @values table
	(IndexID int, IndexName nvarchar(max))
	-- list is in synch with ApxRdl
	insert into @values
	select
		IndexID,
		IndexName
	From APX.vIndex
	select IndexID, IndexName
	from @values
	order by IndexID	
END
