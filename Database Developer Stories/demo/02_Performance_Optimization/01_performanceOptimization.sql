create or alter procedure MySecretProc (
	@MyParam int
)
as
begin
	declare @Counter int = 0
	declare @Id int
    declare MySecretCursor cursor for select Id from Users

	open MySecretCursor

	fetch next from MySecretCursor into @Id
	while @@FETCH_STATUS = 0
	begin
		if @Id = @MyParam
			set @Counter = @Counter + 1

		fetch next from MySecretCursor into @Id
	end

	close MySecretCursor
	deallocate MySecretCursor

	if @Counter > 1
		set @Counter = 1

	return @Counter
end
go


declare @RetVal int

exec @RetVal = MySecretProc @MyParam = 3
select @RetVal as [Return value]
go
