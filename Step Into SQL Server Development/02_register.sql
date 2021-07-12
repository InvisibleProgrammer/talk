-- Registration

/* 
	UserId
	EmailAddress
	PasswordHash
	UserStatus (1 - Active; 99 - Deleted)
	Confirmed
	CreatedAt
	ModifiedAt



*/

create table Users (
	UserId bigint identity(1, 1) not null constraint PK_Users primary key clustered (UserId),
	EmailAddress nvarchar(255) not null, 
	PasswordHash varchar(100) not null,
	UserStatus tinyint not null constraint DF_UserStatusStatus default (1),
	Confirmed bit not null constraint DF_Confirmed default (0),
	CreatedAt datetime not null constraint DF_CreatedAt default getutcdate(),
	ModifiedAt datetime not null constraint DF_ModifiedAt default getutcdate()
)
go

create unique index IDX_EmailAddress on Users  (EmailAddress)
go

create or alter procedure RegisterUser (
	@EmailAddress nvarchar(2550),
	@PasswordHash varchar(100),
	@UserId bigint out
)
as 
begin
	set nocount on

	declare @LocalEmailAddress nvarchar(2550) = @EmailAddress
	declare @LocalPasswordHash varchar(100) = @EmailAddress

	if @LocalEmailAddress is null or @LocalEmailAddress = ''
			or @LocalPasswordHash is null or @LocalPasswordHash = ''
		return 1 -- input check failed

	if exists (select 1 from Users where EmailAddress = @LocalEmailAddress and UserStatus <> 99)
		return 2 -- user already exists

	insert into Users(EmailAddress, PasswordHash)
	values (@LocalEmailAddress, @PasswordHash)

	set @UserId = @@IDENTITY

	return 0
end
go

begin transaction 

declare @UserId bigint = null
declare @RetVal int

exec @RetVal = RegisterUser @EmailAddress = 'zsolt.miskolczi@logmein.com', @PasswordHash = 'abc123', @UserId = @UserId out

select @RetVal as RetVal, @UserId as UserId

rollback

go
