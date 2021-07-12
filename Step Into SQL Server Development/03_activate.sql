-- Activate

select * from Users
select * from sys.procedures
go

create table UserActivationTicket (
	UserId bigint not null,
	ActivationTicket varchar(10) not null,

	constraint PK_UserActivationTicket primary key clustered (ActivationTicket)
)

go

alter table Users
add ConfirmedAt datetime null 
go

update Users set ConfirmedAt = GETUTCDATE() where Confirmed = 1
go


create or alter procedure ActivateUser (
	@ActivationTicket varchar(10)
)
as 
begin
	set nocount on

	declare @LocalActivationTicket varchar(10) = @ActivationTicket
	declare @UserId bigint

	if @LocalActivationTicket is null or @LocalActivationTicket = ''
		return 1 -- input check failed

	select @UserId = UserId from UserActivationTicket where ActivationTicket = @LocalActivationTicket

	if @UserId is null
		return 2 -- activation ticket not found

	if not exists (select 1 from Users where UserId = @UserId and Confirmed = 0)
		return 3 -- user not found or already activated

	update Users set Confirmed = 1, ConfirmedAt = GETUTCDATE() where UserId = @UserId

	delete from UserActivationTicket where ActivationTicket = @LocalActivationTicket

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
  
 insert into Users(EmailAddress, PasswordHash)  
 values (@LocalEmailAddress, @PasswordHash)  
  
 set @UserId = @@IDENTITY  

 insert into UserActivationTicket (UserId, ActivationTicket)
 select @UserId, @LocalActivationTicket
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)

 return 0  
end  
go

insert into UserActivationTicket (UserId, ActivationTicket)
values (2, 'abc123xxx')
go

declare @RetVal int 

exec @RetVal = ActivateUser @ActivationTicket = 'abc123xxx'
select @RetVal as RetVal
go
