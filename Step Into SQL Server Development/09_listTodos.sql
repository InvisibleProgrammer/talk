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
		+	'from Todos where UserId = @UserId '
		+	case when @CompletedOnly is null then '' else '	and Completed = @CompletedOnly ' end
		+	'order by ' + @OrderBy + ' '
		+	'offset @rowsToSkip rows ' 
		+	'fetch next @PageSize rows only '

	exec sp_executesql @sql, @sqlParameters
		, @UserId = @UserId, @PageSize = @PageSize, @CompletedOnly = @CompletedOnly
		, @rowsToSkip = @rowsToSkip

	return 0  
end  
go

declare @RetVal int

exec @RetVal = ListTodos 2, 'TodoId, Title', null, 20, 0, 'ModifiedAt'

select @RetVal as RetVal
go

