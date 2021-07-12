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

declare @RetVal int

exec @RetVal = ModifyTodo 1, 2, 'Modified Todo', 'Has description'

select @RetVal as RetVal
go

