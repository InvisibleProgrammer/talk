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

declare @RetVal int

exec @RetVal = CompleteTodo 1, 2

select @RetVal as RetVal
go

