create or alter procedure MySecretProc (
	@MyParam int
)
as
begin
	if exists (select 1 from Users where Id = @MyParam)
		return 1

	return 0
end
go

declare @RetVal int

exec @RetVal = MySecretProc @MyParam = 3
select @RetVal as [Return value]
go
