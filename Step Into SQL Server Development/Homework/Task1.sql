/*
1. How you can delete all the rows where Confirmed = 0? 
*/

-- Bad
begin transaction
delete from Users where Confirmed = 0

rollback

/* check scripts */
/*

DBCC SQLPERF(logspace)
DBCC SHRINKDATABASE(N'stepIntoDb' )
GO
exec sp_spaceused 'users'

exec sp_lock
select OBJECT_NAME(1205579333)

*/

go

begin tran

declare @BatchSize int = 4000
declare @MinId bigint = 0
declare @MaxId bigint 
declare @ProcessedCount int = @BatchSize

while @ProcessedCount = @BatchSize
begin
	select top(@BatchSize) @MaxId = UserId
	from Users
	where UserId > @MinId and Confirmed = 0
	order by UserId

	delete top(@BatchSize)
	from Users
	where UserId between @MinId and @MaxId
		and Confirmed = 0

	set @ProcessedCount = @@ROWCOUNT

	set @MinId = @MaxId 

	if @ProcessedCount = @BatchSize
		waitfor delay '00:00:01' -- wait for a sec
end

rollback

go


