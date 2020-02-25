use DBDevStories
go

create table Users (
	Id int identity(1, 1) primary key not null,
	EmailAddress nvarchar(255) not null,
	PasswordHash nvarchar(100) not null,
	FirstName nvarchar(100) null,
	LastName nvarchar(100) null,
	IsActive bit null
)
go


insert into Users (EmailAddress, PasswordHash, FirstName, LastName, IsActive)
values 
	('john.doe@gmail.com', '30102309slfkjaslfj03912', 'John', 'Cena', 0),
	('john.doe@gmail.com', 'aoiruoi331464fsa32fa4sa', 'The Rock', null, 0),
	('john.doe@gmail.com', 'soeki224lk23j45l2q53kl4', 'Alexa', 'Bliss', 1),
	('john.doe@gmail.com', 'klj23lkj35j5l756l7j65l2', 'Randy', 'Orton', 1),
	('john.doe@gmail.com', '1lk2j3l12j34576lkjlj345', 'Ronda', 'Rousey', null)
go

