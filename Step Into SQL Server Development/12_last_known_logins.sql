create table LoginIPAddresses (
	UserId bigint not null constraint PK_LoginIPAddresses primary key clustered,
	IPAddress varchar(50) not null,
	LastUsed datetime not null constraint DF_LoginIPAddress_LastUsed default getutcdate()
)
go

create or alter procedure PreLoginInfoCheck (
	@EmailAddress nvarchar(255),
	@IPAddress varchar(100),
	@TrustedLogin bit out
)
as
begin
	set nocount on

	declare @LocalEmailAddress nvarchar(255) = @EmailAddress
	declare @LocalIPAddress varchar(100) = @IPAddress
	declare @UserId bigint

	if @LocalEmailAddress is null or @LocalEmailAddress = ''
			or @LocalIPAddress is null or @LocalIPAddress = ''
		return 1 -- input check failed

	select @UserId = UserId from Users where EmailAddress = @LocalEmailAddress and UserStatus <> 99

	if @UserId is null
		return 2 -- user not found


	set @TrustedLogin = 0

	if exists (select 1 from LoginIPAddresses where UserId = @UserId and IPAddress = @LocalIPAddress)
		set @TrustedLogin = 1

	return 0
end
go

create or alter procedure LoginUser (
	@EmailAddress nvarchar(255), 
	@PasswordHash varchar(100),
	@IPAddress varchar(100)
)
as
begin
	set nocount on

	declare @LocalEmailAddress nvarchar(255) = @EmailAddress
	declare @LocalPasswordHash varchar(100) = @PasswordHash
	
	declare @DbPasswordHash varchar(100)
	declare @UserId bigint

	if @LocalEmailAddress = null or @LocalEmailAddress = ''
			or @LocalPasswordHash = null or @LocalPasswordHash = ''
		return 1 -- input check failed

	select @UserId = UserId
	from Users 
	where EmailAddress = @LocalEmailAddress and UserStatus <> 99

	if @UserId is null 
		return 2 -- user not found


	select @DbPasswordHash = PasswordHash 
	from UserPassword 
	where UserId = @UserId
		and PasswordHash = @LocalPasswordHash

	if @DbPasswordHash is null 
		return 3 -- user has no password

	if @IPAddress > ''
		merge LoginIPAddresses as t
		using (select @UserId as UserId, @IPAddress as IPAddress) as s
		on t.UserId = s.UserId and t.IPAddress = s.IPAddress
		when matched then 
			update set LastUsed = getutcdate()
		when not matched then 
			insert (UserId, IPAddress) values (s.UserId, s.IPAddress);

	return 0
end
go