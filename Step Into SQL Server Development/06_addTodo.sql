select * from sys.tables 
go
--drop table Todos
create table Todos (
	TodoId bigint not null identity(1, 1) constraint PK_Todos primary key clustered,
	UserId bigint not null constraint UQ_Todos_UserId unique,
	Title nvarchar(100) not null,
	Description nvarchar(1000) null,
	Completed bit not null constraint DF_Todos_Completed default 0,
	CreatedAt datetime not null constraint DF_Todos_CreatedAt default getutcdate(),
	ModifiedAt datetime not null constraint DF_Todos_ModifiedAt default getutcdate()
)
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

declare @RetVal int
declare @TodoId bigint

exec @RetVal = AddTodo 2, 'First Todo', null, @TodoId = @TodoId out

select @RetVal as RetVal, @TodoId as TodoId
go

