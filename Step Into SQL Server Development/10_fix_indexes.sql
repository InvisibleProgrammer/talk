select OBJECT_NAME(object_id) 
from sys.sql_modules
where definition like '%Todos%'
order by 1

/*
AddTodo			-- nothing
CompleteTodo	-- UserId = @LocalUserId and TodoId = @LocalTodoId, TodoId = @LocalTodoId
ListTodos		-- UserId = @UserId, UserId = @UserId and Completed = @CompletedOnly
ModifyTodo		-- UserId = @LocalUserId and TodoId = @LocalTodoId, TodoId = @LocalTodoId

UserId, TodoId	-- TodoId serves it
PK CL TodoId
UQ NCL UserId
UserId, Completed
*/

select * from Todos

create nonclustered index IDX_Todos_UserId_filt_Completed on Todos (UserId)
where Completed = 1
go
