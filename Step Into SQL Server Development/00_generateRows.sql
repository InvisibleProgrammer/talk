select count(1) from users
select top(100) * from users
truncate table users

--select * from users
--go


--insert into Users (EmailAddress, PasswordHash, UserStatus, Confirmed, CreatedAt, ModifiedAt, ConfirmedAt)
--select 'a@b.com', '1324354', 1, 1, GETUTCDATE(), GETUTCDATE(), GETUTCDATE()

--go

--WITH
--  L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)), -- 2^1
--  L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),       -- 2^2
--  L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),       -- 2^4
--  L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),       -- 2^8
--  L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),       -- 2^16
--  L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),       -- 2^32
--  Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS k FROM L5)

--select k as id , 'a_' + cast (k as varchar) as a, 'b_' + cast (k/2 as varchar) as b 
--from nums
--where k <= 100 --10000000





--go

--create nonclustered index IDX_Users_ModifiedAt on Users (ModifiedAt)
--go

;
WITH
  L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)), -- 2^1
  L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),       -- 2^2
  L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),       -- 2^4
  L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),       -- 2^8
  L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),       -- 2^16
  L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),       -- 2^32
  Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS k FROM L5),
fn as (
	SELECT 'John' as firstName 
		UNION SELECT 'Tim' 
		UNION SELECT 'Jane' 
		UNION SELECT 'Jack' 
		UNION SELECT 'Steve' 
		UNION SELECT 'Ann' 
),
ln as (
	SELECT 'Doe' as lastName 
			UNION SELECT 'Allan' 
			UNION SELECT 'Johnson' 
			UNION SELECT 'Gates'
			UNION SELECT 'Nagy' 
			UNION SELECT 'Molnar' 
),
email as (
	SELECT 'gmail.com' as emailDomain
			UNION SELECT 'live.com'
			UNION SELECT 'logmein.com' 
			UNION SELECT 'stepinto.hu' 
)
insert into Users (EmailAddress, PasswordHash, UserStatus, Confirmed, CreatedAt, ModifiedAt, ConfirmedAt)
select 
	/* Email */ 
		-- First Name
			( 
				select top(1) fn.firstName + '.' + ln.lastName + '_' + cast (k as varchar) + '@' + email.emailDomain from fn, ln, email
				order by newid()

			) as email,
			--, 
	/* PasswordHash */ CONVERT(varchar(255), NEWID()), 
	/* UserStatus */ case when ABS(CHECKSUM(NEWID())) % 10 > 7 then 1 else 99 end, 
	/* Confirmed */ case when ABS(CHECKSUM(NEWID())) % 10 > 8 then 1 else 0 end, 
	/* CreatedAt */ DATEADD(day, (ABS(CHECKSUM(NEWID())) % 2380), '2015-01-01'), 
	/* ModifiedAt */ DATEADD(day, (ABS(CHECKSUM(NEWID())) % 2380), '2015-01-01'), 
	/* ConfirmedAt */ DATEADD(day, (ABS(CHECKSUM(NEWID())) % 2380), '2015-01-01')
from nums
--where k <= 100 --1000000
where k <= 10000000

go

select count(*) from Users 
where UserStatus = 1
go



--truncate table Users 

--select  DATEADD(day, (ABS(CHECKSUM(NEWID())) % 2380), '2015-01-01')

--select datediff(day, '2015-01-01', getutcdate())




go

create table UserPassword (
	UserId bigint not null constraint PK_UserPassword primary key clustered,
	PasswordHash varchar(100) not null
)
go

begin tran

declare @BatchSize int = 2000
declare @MinId bigint = 0
declare @MaxId bigint
declare @ProcessedRowCount int = @BatchSize

while @ProcessedRowCount = @BatchSize
begin
	insert into UserPassword(UserId, PasswordHash)
	select top(@BatchSize) UserId, PasswordHash
	from Users 
	where UserId > @MinId
		and UserStatus <> 99
	order by UserId

	set @ProcessedRowCount = @@ROWCOUNT

	--select @MinId = MAX(UserId) from UserPassword
	select top(1) @MinId = UserId from UserPassword order by UserId desc

	--print @ProcessedRowCount
end

rollback
go


select count(1)
	from Users 
	where UserId > 0
		and UserStatus <> 99

select top(2000) UserId, PasswordHash
	from Users 
	where UserId > 0
		and UserStatus <> 99
	order by UserId