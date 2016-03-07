IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[fGetRMDMultiplier]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [APXUserCustom].[fGetRMDMultiplier]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
CREATE Function [APXUserCustom].[fGetRMDMultiplier](@OwnerAge float , @SpouseAge float, @PortfolioType nvarchar(255))
returns float
with execute as caller
as begin
declare @diff smallint,
	@value float

if @SpouseAge <> '' select @diff = FLOOR(@OwnerAge) - FLOOR(@SpouseAge)

if CHARINDEX('Inherited',@PortfolioType,0) > 0
begin
	--if @diff > 10
	--begin
	--	select @value = 1 / LifeExpectancy from APXUserCustom.RMD10Yr where FLOOR(@OwnerAge) = OwnerAge and FLOOR(@SpouseAge) = SpouseAge
	--end
	--else
	--begin
	--	select @value = 1 / LifeExpectancy from APXUserCustom.RMDInherited where FLOOR(@OwnerAge) = Age
	--end
	select @value = 1 / LifeExpectancy from APXUserCustom.RMDInherited where FLOOR(@OwnerAge) = Age
end
else
begin
	if @diff > 10
	begin
		select @value = 1 / LifeExpectancy from APXUserCustom.RMD10Yr where FLOOR(@OwnerAge) = OwnerAge and FLOOR(@SpouseAge) = SpouseAge
	end
	else
	begin
		select @value = 1 / LifeExpectancy from APXUserCustom.RMDNormal where FLOOR(@OwnerAge) = Age
	end
end
return @value
end