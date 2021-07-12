select * from sys.tables

select * from users 
go

create table UserPassword (
	UserId bigint not null constraint PK_UserPassword primary key clustered,
	PasswordHash varchar(100) not null
)
go

insert into UserPassword (UserId, PasswordHash)
select UserId, PasswordHash from Users where UserStatus <> 99

go

-- collect sps that use password hash column
select OBJECT_NAME(object_id) from sys.sql_modules
where definition like '%Users%' and definition like '%PasswordHash%'
order by 1

/*
LoginUser
RegisterUser
*/

go

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

	return 0
end
go

create or alter procedure RegisterUser (  
 @EmailAddress nvarchar(2550),  
 @PasswordHash varchar(100),  
 @ActivationTicket varchar(10) = null,
 @UserId bigint out  
)  
as   
begin  
 set nocount on  
  
 declare @LocalEmailAddress nvarchar(2550) = @EmailAddress  
 declare @LocalPasswordHash varchar(100) = @EmailAddress  
 declare @LocalActivationTicket varchar(100) = @ActivationTicket
  
 if @LocalEmailAddress is null or @LocalEmailAddress = ''  
   or @LocalPasswordHash is null or @LocalPasswordHash = ''  
  return 1 -- input check failed  
  
 if exists (select 1 from Users where EmailAddress = @LocalEmailAddress and UserStatus <> 99)  
  return 2 -- user already exists  
  
 insert into Users(EmailAddress)  
 values (@LocalEmailAddress)  
  
 set @UserId = @@IDENTITY  

 insert into UserPassword (UserId, PasswordHash)
 values (@UserId, @PasswordHash)

 insert into UserActivationTicket (UserId, ActivationTicket)
 select @UserId, @LocalActivationTicket
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)

 return 0  
end  
go

create or alter procedure CreateUserPassword (
	@UserId bigint,
	@PasswordHash varchar(100)
)
as 
begin
	set nocount on

	declare @LocalUserId bigint = @UserId
	
	if @UserId is null or @PasswordHash is null or @PasswordHash = ''
		return 1 -- input check failed

	if not exists (select 1 from Users where UserId = @LocalUserId and UserStatus <> 99)
		return 2 -- no active user found

	if exists (select 1 from UserPassword where UserId = @LocalUserId)
		return 3 -- user already has password

	insert into UserPassword (UserId, PasswordHash)
	values (@LocalUserId, @PasswordHash)

	return 0 
end
go

alter table Users drop column PasswordHash
go

truncate table UserPassword
go
