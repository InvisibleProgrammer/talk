create table TestTable (
	Name varchar(100) not null,
	Description nvarchar(1000) not null
)
go

insert into TestTable (Name, Description)
values ('Hello', 'World')
go
