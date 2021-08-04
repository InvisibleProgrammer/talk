/*
How could you refactor passwords and move password hashes into a new table called `UserPassword`?

New table: 
	UserPassword
		UserId
		PasswordHash
		LastPasswordChangedAt

+ create new table
+ readers: read from both tables
+ writers: write to the new table, do the import
+ batch move the password hashes
+ readers: read only from the new table
+ drop old columns
+ writers: write only the new table

*/

create table UserPassword (
	UserId bigint not null constraint PK_UserPassword primary key clustered,
	PasswordHash varchar(100) not null,
	LastPasswordChangedAt datetime not null
)
go

select object_name(object_id)
from sys.sql_modules
where definition like '%PasswordHash%'
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
   
 insert into UserPassword (UserId, PasswordHash, LastPasswordChangedAt)  
 values (@UserId, @PasswordHash, GETUTCDATE())  
      
 insert into UserActivationTicket (UserId, ActivationTicket)      
 select @UserId, @LocalActivationTicket      
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)      
      
 return 0        
end      
GO

  
create or alter procedure LoginUser (        
 @EmailAddress nvarchar(255),         
 @PasswordHash varchar(100)        
)        
as        
begin        
 set nocount on        
        
 declare @LocalEmailAddress nvarchar(255) = @EmailAddress        
 declare @LocalPasswordHash varchar(100) = @PasswordHash     
 declare @UserId bigint    
         
 declare @DbPasswordHash varchar(100)        
        
 if @LocalEmailAddress = null or @LocalEmailAddress = ''        
   or @LocalPasswordHash = null or @LocalPasswordHash = ''        
  return 1 -- input check failed        
        
 select @UserId = @UserId, @DbPasswordHash = PasswordHash     
 from Users         
 where EmailAddress = @LocalEmailAddress and UserStatus <> 99      
     
 if @UserId is null         
  return 2 -- user not found or user cannot log in        
     
 select @DbPasswordHash = PasswordHash
 from UserPassword 
 where UserId = @UserId

 return 0        
end 
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

	insert into UserPassword (UserId, PasswordHash, LastPasswordChangedAt)
	select UserId, PasswordHash, LastPasswordChangedAt
	from Users
	where UserId between @MinId and @MaxId

	set @ProcessedCount = @@ROWCOUNT
	
	set @MinId = @MaxId + 1
end

--exec sp_spaceused 'users'
--exec sp_spaceused 'userpassword'

rollback transaction
go

alter table Users drop column PasswordHash
go

alter table Users drop constraint DF_LastPasswordChangedAt 
go
alter table Users drop column LastPasswordChangedAt
go

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
   
 insert into UserPassword (UserId, PasswordHash, LastPasswordChangedAt)  
 values (@UserId, @PasswordHash, GETUTCDATE())  
      
 insert into UserActivationTicket (UserId, ActivationTicket)      
 select @UserId, @LocalActivationTicket      
 where not exists (select 1 from UserActivationTicket where ActivationTicket = @LocalActivationTicket)      
      
 return 0        
end      
GO

  
create or alter procedure LoginUser (        
 @EmailAddress nvarchar(255),         
 @PasswordHash varchar(100)        
)        
as        
begin        
 set nocount on        
        
 declare @LocalEmailAddress nvarchar(255) = @EmailAddress        
 declare @LocalPasswordHash varchar(100) = @PasswordHash     
 declare @UserId bigint    
         
 declare @DbPasswordHash varchar(100)        
        
 if @LocalEmailAddress = null or @LocalEmailAddress = ''        
   or @LocalPasswordHash = null or @LocalPasswordHash = ''        
  return 1 -- input check failed        
        
 select @UserId = @UserId    
 from Users         
 where EmailAddress = @LocalEmailAddress and UserStatus <> 99      
     
 if @UserId is null         
  return 2 -- user not found or user cannot log in        
     
 select @DbPasswordHash = PasswordHash
 from UserPassword 
 where UserId = @UserId

 return 0        
end 
go
