create or alter procedure LoginUser (
	@EmailAddress nvarchar(255), 
	@PasswordHash varchar(100)
)
as
begin
	set nocount on

	declare @LocalEmailAddress nvarchar(255) = @EmailAddress
	declare @LocalPasswordHash varchar(100) = @PasswordHash
	
	declare @DbPasswordHash varchar(100)

	if @LocalEmailAddress = null or @LocalEmailAddress = ''
			or @LocalPasswordHash = null or @LocalPasswordHash = ''
		return 1 -- input check failed

	select @DbPasswordHash = PasswordHash 
	from Users 
	where EmailAddress = @LocalEmailAddress and UserStatus <> 99
		and PasswordHash = @LocalPasswordHash

	if @DbPasswordHash is null 
		return 2 -- user not found or user cannot log in

	return 0
end
go

declare @RetVal int 

exec @RetVal = LoginUser 'zsolt.miskolczi@logmein.com', 'abc123'
select @RetVal 
go
