create or alter procedure BanUser (
	@EmailAddress nvarchar(255)
)
as
begin
	set nocount on

	declare @LocalEmailAddress nvarchar(255) = @EmailAddress
	
	if @LocalEmailAddress = null or @LocalEmailAddress = ''
		return 1 -- input check failed

	update Users
		set UserStatus = 2 
	where EmailAddress = @LocalEmailAddress and UserStatus <> 99

	if @@ROWCOUNT = 0
		return 2 -- user not found
	return 0
end
go

declare @RetVal int 

exec @RetVal = BanUser 'zsolt.miskolczi@logmein.com'
select @RetVal 

select * from Users
update Users set UserStatus = 1 where EmailAddress = 'zsolt.miskolczi@logmein.com'
select * from Users

go
