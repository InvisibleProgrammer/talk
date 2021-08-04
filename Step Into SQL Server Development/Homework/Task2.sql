/*
2.	How to add a new, non-null column (LastPasswordChangedAt) 
	that stores the minute-precision date of the last password change? 
	
	For the existing records, it should contain `2020-01-01 12:00`.
*/

/*
	- rename constraints and indicies
	- create new table: Users_new
	- create view: vw_Users to read both User tables
	- modify stored procedures to use the view
	- batch copy the records to Users_tmp
	- modify view, drop users table
	- modify SPs
	- drop view
	- drop old table

*/
--sp_rename 'Users_temp', 'Users'

sp_rename 'DF_Confirmed', 'DF_Confirmed_save'
sp_rename 'DF_CreatedAt', 'DF_CreatedAt_save'
sp_rename 'DF_ModifiedAt', 'DF_ModifiedAt_save'
sp_rename 'DF_UserStatusStatus', 'DF_UserStatusStatus_save'
sp_rename 'PK_Users', 'PK_Users_save'
go

USE [stepIntoDb]
GO

CREATE TABLE Users_new(
	UserId bigint IDENTITY(1,1) NOT NULL,
	EmailAddress nvarchar(255) NOT NULL,
	PasswordHash varchar(100) NOT NULL,
	UserStatus tinyint NOT NULL,
	Confirmed bit NOT NULL,
	CreatedAt datetime NOT NULL,
	ModifiedAt datetime NOT NULL,
	ConfirmedAt datetime NULL,
	LastPasswordChangedAt datetime NOT NULL,
 CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId)
)
go

ALTER TABLE dbo.Users_new ADD  CONSTRAINT DF_UserStatusStatus  DEFAULT ((1)) FOR UserStatus
GO

ALTER TABLE dbo.Users_new ADD  CONSTRAINT DF_Confirmed  DEFAULT ((0)) FOR Confirmed
GO

ALTER TABLE dbo.Users_new ADD  CONSTRAINT DF_CreatedAt  DEFAULT (getutcdate()) FOR CreatedAt
GO

ALTER TABLE dbo.Users_new ADD  CONSTRAINT DF_ModifiedAt  DEFAULT (getutcdate()) FOR ModifiedAt
GO

create view vw_Users 
as 
select UserId, EmailAddress, PasswordHash, UserStatus, Confirmed, CreatedAt, ModifiedAt, ConfirmedAt
from Users
union all
select UserId, EmailAddress, PasswordHash, UserStatus, Confirmed, CreatedAt, ModifiedAt, ConfirmedAt
from Users_new
go

select object_name(object_id) from sys.sql_modules
where definition like '%users%'
go

/*
AddTodo
RegisterUser
ActivateUser
LoginUser
BanUser
CompleteTodo
ModifyTodo
ListTodos
*/
go

  
create or alter procedure AddTodo (  
 @UserId bigint,  
 @Title nvarchar(100),  
 @Description nvarchar(1000),  
 @TodoId bigint = null out   
)  
as   
begin  
 set nocount on  
  
 declare @LocalUserId bigint = @UserId  
  
 if @LocalUserId is null or @Title is null or @Title = ''  
  return 1 -- input check failed  
  
 if not exists (select 1 from vw_Users where UserId = @LocalUserId and UserStatus <> 99)  
  return 2 -- user not found  
  
 insert into Todos (UserId, Title, Description)  
 values (@LocalUserId, @Title, @Description)  
  
 set @TodoId = @@Identity  
  
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
    
 if exists (select 1 from vw_Users where EmailAddress = @LocalEmailAddress and UserStatus <> 99)    
  return 2 -- user already exists    
    
 insert into Users_new(EmailAddress, PasswordHash, LastPasswordChangedAt)    
 values (@LocalEmailAddress, @PasswordHash, GETUTCDATE())    
    
 set @UserId = @@IDENTITY    
  
 insert into UserActivationTicket (UserId, ActivationTicket)  
 select @UserId, @LocalActivationTicket  
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)  
  
 return 0    
end    
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
  
 if not exists (select 1 from vw_Users where UserId = @UserId and Confirmed = 0)  
  return 3 -- user not found or already activated  
  
 update vw_Users set Confirmed = 1, ConfirmedAt = GETUTCDATE() where UserId = @UserId  
  
 delete from UserActivationTicket where ActivationTicket = @LocalActivationTicket  
  
 return 0  
end  
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
  
 if @LocalEmailAddress = null or @LocalEmailAddress = ''  
   or @LocalPasswordHash = null or @LocalPasswordHash = ''  
  return 1 -- input check failed  
  
 select @DbPasswordHash = PasswordHash   
 from vw_Users   
 where EmailAddress = @LocalEmailAddress and UserStatus <> 99  
  and PasswordHash = @LocalPasswordHash  
  
 if @DbPasswordHash is null   
  return 2 -- user not found or user cannot log in  
  
 return 0  
end  
go

create or alter procedure BanUser (  
 @EmailAddress nvarchar(255)  
)  
as  
begin  
 set nocount on  
  
 declare @LocalEmailAddress nvarchar(255) = @EmailAddress  
   
 if @LocalEmailAddress = null or @LocalEmailAddress = ''  
  return 1 -- input check failed  
  
 update vw_Users  
  set UserStatus = 2   
 where EmailAddress = @LocalEmailAddress and UserStatus <> 99  
  
 if @@ROWCOUNT = 0  
  return 2 -- user not found  
 return 0  
end  
go

create or alter procedure CompleteTodo (    
 @TodoId bigint,  
 @UserId bigint  
)    
as     
begin    
 set nocount on    
    
 declare @LocalTodoId bigint = @TodoId  
 declare @LocalUserId bigint = @UserId    
    
 if @LocalUserId is null or @LocalTodoId is null   
  return 1 -- input check failed    
    
 if not exists (select 1 from vw_Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 if not exists (select 1 from Todos where UserId = @LocalUserId and TodoId = @LocalTodoId)  
  return 3 -- todo not found  
  
 update Todos  
  set Completed = 1, ModifiedAt = GETUTCDATE()  
 where TodoId = @LocalTodoId  
    
 return 0    
end    

go

create or alter procedure ModifyTodo (    
 @TodoId bigint,  
 @UserId bigint,  
 @Title nvarchar(100),  
 @Description nvarchar(1000)  
)    
as     
begin    
 set nocount on    
    
 declare @LocalTodoId bigint = @TodoId  
 declare @LocalUserId bigint = @UserId    
    
 if @LocalUserId is null or @LocalTodoId is null or @Title is null or  @Title = ''  
  return 1 -- input check failed    
    
 if not exists (select 1 from vw_Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 if not exists (select 1 from Todos where UserId = @LocalUserId and TodoId = @LocalTodoId)  
  return 3 -- todo not found  
  
 update Todos  
  set Title = @Title, Description = @Description, ModifiedAt = GETUTCDATE()  
 where TodoId = @LocalTodoId  
    
 return 0    
end    
go

create or alter procedure ListTodos(    
 @UserId bigint,  
 @ColumnsIncluded varchar(5000),  
 @CompletedOnly bit,  
 @PageSize int,  
 @Page int,  
 @OrderBy varchar(100)  
)    
as     
begin    
 -- Really should use an ORM  
 set nocount on    
    
 declare @LocalUserId bigint = @UserId    
   
    
 if @LocalUserId is null or @ColumnsIncluded is null or @ColumnsIncluded = ''   
   or @PageSize is null or @Page is null   
   or @OrderBy is null or @OrderBy = ''  
  return 1 -- input check failed    
    
 if not exists (select 1 from vw_Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 declare @rowsToSkip int = @Page * @PageSize  
 declare @sqlParameters nvarchar(1000) = N'@UserId bigint, @PageSize int, @CompletedOnly bit, @rowsToSkip int'  
  
 declare @sql nvarchar(max) =   
   'select ' + @ColumnsIncluded + ' '  
  + 'from Todos where UserId = @UserId '  
  + case when @CompletedOnly is null then '' else ' and Completed = @CompletedOnly ' end  
  + 'order by ' + @OrderBy + ' '  
  + 'offset @rowsToSkip rows '   
  + 'fetch next @PageSize rows only '  
  
 exec sp_executesql @sql, @sqlParameters  
  , @UserId = @UserId, @PageSize = @PageSize, @CompletedOnly = @CompletedOnly  
  , @rowsToSkip = @rowsToSkip  
  
 return 0    
end    

go


begin transaction

declare @BatchSize int = 4000
declare @ProcessedCount int = @BatchSize

set identity_insert Users_new on

while @ProcessedCount = @BatchSize
begin
	delete top(@BatchSize) Users
	output deleted.UserId, deleted.EmailAddress, deleted.PasswordHash, deleted.UserStatus, deleted.Confirmed, deleted.CreatedAt, deleted.ModifiedAt, deleted.ConfirmedAt, isnull(deleted.LastPasswordChangedAt, '2020-01-01 12:00')
	into Users_new (UserId, EmailAddress, PasswordHash, UserStatus, Confirmed, CreatedAt, ModifiedAt, ConfirmedAt, LastPasswordChangedAt)

	set @ProcessedCount = @@ROWCOUNT

	
	--if @ProcessedCount = @BatchSize
	--	waitfor delay '00:00:01' -- wait for a sec

end

set identity_insert Users_new off

rollback transaction

go

alter view vw_Users
as 
select * from Users_new
go

drop table Users
go

sp_rename 'Users_new', 'Users'
go

alter view vw_Users
as 
select * from Users
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
    
 insert into Users(EmailAddress, PasswordHash, LastPasswordChangedAt)    
 values (@LocalEmailAddress, @PasswordHash, GETUTCDATE())    
    
 set @UserId = @@IDENTITY    
  
 insert into UserActivationTicket (UserId, ActivationTicket)  
 select @UserId, @LocalActivationTicket  
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)  
  
 return 0    
end    
go
  

  
create or alter procedure AddTodo (  
 @UserId bigint,  
 @Title nvarchar(100),  
 @Description nvarchar(1000),  
 @TodoId bigint = null out   
)  
as   
begin  
 set nocount on  
  
 declare @LocalUserId bigint = @UserId  
  
 if @LocalUserId is null or @Title is null or @Title = ''  
  return 1 -- input check failed  
  
 if not exists (select 1 from Users where UserId = @LocalUserId and UserStatus <> 99)  
  return 2 -- user not found  
  
 insert into Todos (UserId, Title, Description)  
 values (@LocalUserId, @Title, @Description)  
  
 set @TodoId = @@Identity  
  
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
    
 insert into Users(EmailAddress, PasswordHash, LastPasswordChangedAt)    
 values (@LocalEmailAddress, @PasswordHash, GETUTCDATE())    
    
 set @UserId = @@IDENTITY    
  
 insert into UserActivationTicket (UserId, ActivationTicket)  
 select @UserId, @LocalActivationTicket  
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)  
  
 return 0    
end    
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

create or alter procedure CompleteTodo (    
 @TodoId bigint,  
 @UserId bigint  
)    
as     
begin    
 set nocount on    
    
 declare @LocalTodoId bigint = @TodoId  
 declare @LocalUserId bigint = @UserId    
    
 if @LocalUserId is null or @LocalTodoId is null   
  return 1 -- input check failed    
    
 if not exists (select 1 from Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 if not exists (select 1 from Todos where UserId = @LocalUserId and TodoId = @LocalTodoId)  
  return 3 -- todo not found  
  
 update Todos  
  set Completed = 1, ModifiedAt = GETUTCDATE()  
 where TodoId = @LocalTodoId  
    
 return 0    
end    

go

create or alter procedure ModifyTodo (    
 @TodoId bigint,  
 @UserId bigint,  
 @Title nvarchar(100),  
 @Description nvarchar(1000)  
)    
as     
begin    
 set nocount on    
    
 declare @LocalTodoId bigint = @TodoId  
 declare @LocalUserId bigint = @UserId    
    
 if @LocalUserId is null or @LocalTodoId is null or @Title is null or  @Title = ''  
  return 1 -- input check failed    
    
 if not exists (select 1 from Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 if not exists (select 1 from Todos where UserId = @LocalUserId and TodoId = @LocalTodoId)  
  return 3 -- todo not found  
  
 update Todos  
  set Title = @Title, Description = @Description, ModifiedAt = GETUTCDATE()  
 where TodoId = @LocalTodoId  
    
 return 0    
end    
go

create or alter procedure ListTodos(    
 @UserId bigint,  
 @ColumnsIncluded varchar(5000),  
 @CompletedOnly bit,  
 @PageSize int,  
 @Page int,  
 @OrderBy varchar(100)  
)    
as     
begin    
 -- Really should use an ORM  
 set nocount on    
    
 declare @LocalUserId bigint = @UserId    
   
    
 if @LocalUserId is null or @ColumnsIncluded is null or @ColumnsIncluded = ''   
   or @PageSize is null or @Page is null   
   or @OrderBy is null or @OrderBy = ''  
  return 1 -- input check failed    
    
 if not exists (select 1 from Users where UserId = @LocalUserId and UserStatus <> 99)    
  return 2 -- user not found    
   
 declare @rowsToSkip int = @Page * @PageSize  
 declare @sqlParameters nvarchar(1000) = N'@UserId bigint, @PageSize int, @CompletedOnly bit, @rowsToSkip int'  
  
 declare @sql nvarchar(max) =   
   'select ' + @ColumnsIncluded + ' '  
  + 'from Todos where UserId = @UserId '  
  + case when @CompletedOnly is null then '' else ' and Completed = @CompletedOnly ' end  
  + 'order by ' + @OrderBy + ' '  
  + 'offset @rowsToSkip rows '   
  + 'fetch next @PageSize rows only '  
  
 exec sp_executesql @sql, @sqlParameters  
  , @UserId = @UserId, @PageSize = @PageSize, @CompletedOnly = @CompletedOnly  
  , @rowsToSkip = @rowsToSkip  
  
 return 0    
end    

go

drop view vw_Users
go


-- a better alternative: use nullable column
alter table Users add LastPasswordChangedAt_2 datetime null
go

begin transaction 

declare @MinId bigint = 0
declare @MaxId bigint
declare @BatchSize int = 4000
declare @ProcessedCount int = @BatchSize

while @ProcessedCount = @BatchSize
begin
	
	select top(@BatchSize) @MaxId = UserId
	from Users 
	where UserId >= @MinId
	order by UserId

	update top(@BatchSize) Users set LastPasswordChangedAt_2 = '2020-01-01 12:00'
	where UserId between @MinId and @MaxId

	set @ProcessedCount = @@ROWCOUNT
	
	set @MinId = @MaxId + 1
end

rollback transaction


select count(1) from Users where LastPasswordChangedAt_2 is null