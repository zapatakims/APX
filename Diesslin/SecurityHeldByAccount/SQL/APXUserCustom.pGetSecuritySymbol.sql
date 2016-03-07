IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[APXUserCustom].[pGetSecuritySymbol]') AND type in (N'P', N'PC'))
DROP PROCEDURE [APXUserCustom].[pGetSecuritySymbol]
GO

create procedure [APXUserCustom].[pGetSecuritySymbol]
	@SecType nvarchar(32)
as
begin
select 
	s.SecuritySymbol [Value],
	s.SecuritySymbol + ' - ' + s.SecurityName [Name]
from APXUser.vSecurityVariant s
	join APXUser.vSecurityPropertyLookupLS ls on ls.SecurityID = s.SecurityID and
		ls.IsShort = s.IsShort
where ls.PropertyID = -19 and
		ls.IsShort = 0 and
		ls.KeyString = @SecType and
		s.IsUnsupervised = 0
end