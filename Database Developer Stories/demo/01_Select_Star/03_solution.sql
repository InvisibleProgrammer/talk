
alter table Users add NoSelectStar as 1/0
go

select * from Users
go
