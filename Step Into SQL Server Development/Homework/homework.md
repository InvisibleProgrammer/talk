# Step Into Meetups

## Step Into Database Development
## Homework assignment

### Task
Given a table with the following columns and about 10 million rows: 

```
User:
	UserId
	EmailAddress
	PasswordHash
	UserStatus
	Confirmed
	CreatedAt
	ModifiedAt
```
1. How you can delete all the rows where Confirmed = 0? 
2. How to add a new, non-null column (LastPasswordChangedAt) that stores the minute-precision date of the last password change? For the existing records, it should contain `2020-01-01 12:00`.
3. How could you refactor passwords and move password hashes into a new table called `UserPassword`?

*Note*: The database runs 7/24. There is no time to stop it and you should make sure

	- users can use the database
	- you shouldn't generate too many transaction logs in a given minute (to make sure the database logs can be transferred to other datacenters in every minute)
	- there is no time window when nobody uses the database
	
