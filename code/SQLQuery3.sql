-- create database VPMS to store all data
create database V__PMS

use V__PMS

-- creating table for user
create table user_table
(
    userId varchar(4) primary key,
    password varchar(10),
    username varchar(10),
	jobTitle varchar(10),
	firstname varchar(10),
	lastNmae varchar(10),
	email varchar(20),
	phone varchar(10)
)


-- creating table for leave
create table leave
(
  leaveId varchar(4) primary key,
  reason varchar(20),
  leavecount int,
  startDate date,
  endDate date,
  approvedDate date,
  appliedDate date,
  recomDate date,
  userId varchar(4),
  constraint userId_fk FOREIGN KEY(userId) REFERENCES user_table(userId)
ON DELETE cascade ON UPDATE cascade
)

-- creating table for project
create table project
(
 projectid varchar(4) primary key,
 name varchar(10),
 description varchar(30),
 progress varchar(10),
 stage varchar(20),
 cost int
)


-- creating table for task
create table task
(
 taskid varchar(4) primary key,
 name varchar(10),
 description varchar(30),
 status varchar(10),
 estimatedTime time,
 projectid varchar(4),
 constraint projectid2_fk FOREIGN KEY(projectid) REFERENCES project(projectid)
  ON DELETE cascade ON UPDATE cascade
)

-- creating table for staff_employee

create table staff_employee
(
    staffId varchar(4) primary key,
    assignedate date,
    reassignedate date,
	taskid varchar(4),
	constraint staffId_fk FOREIGN KEY(staffId) REFERENCES user_table(userId),
	constraint task2_fk FOREIGN KEY(taskid) REFERENCES task(taskid)
)



 -- creating table for budget
 create table budget
(
 budgetid varchar(4) primary key,
 description varchar(30),
 budgetValue int,
 projectid varchar(4),
 constraint projectid_fk FOREIGN KEY(projectid) REFERENCES project(projectid)
ON DELETE cascade ON UPDATE cascade
)

 -- creating table for invoice
create table invoice
(
 invoiceId varchar(4),
 name varchar(10),
 description varchar(30),
 createddate date,
 projectid varchar(4),
  constraint projectid1_fk FOREIGN KEY(projectid) REFERENCES project(projectid)
  ON DELETE no action ON UPDATE cascade
)

-- creating table for email
create table email
(
 emailId varchar(4),
 userId varchar(4),
 sendDate_time datetime,
 constraint userId1_fk FOREIGN KEY(userId) REFERENCES user_table(userId)
)

 select * from user_table
 select * from leave
 select * from project
 select * from task
  select * from staff_employee
 select * from budget
 select * from invoice
 select * from email

 insert into project values('P001','PMS','Bellvantage','gain','pre-sale',50000)
 
 insert into budget values('b001','host',400000,'p001')
 
 --view pre-sale project details
  select *
  from project
  where stage='pre-sale'

  -- view leave count of given userId
  select l.leavecount
  from user_table u,leave l
  where u.userId=l.userId



 ---insert data to user_table in stored procedure
 go
create proc insertdata_user
@id varchar(4),
@pass varchar(10),
@uname varchar(10),
@job varchar(10),
@fname varchar(10),
@lname varchar(10),
@email varchar(20),
@phone varchar(10)
as
begin
    if not exists (select * from user_table where userId=@id)
	   begin
	      insert into user_table values(@id,@pass,@uname,@job,@fname,@lname,@email,@phone)
	   end
end

---- executing query
exec insertdata_user  'u001','xxxx','abc def','manager', 'abc','def','abs@gmail.com','07xxxxxxxx'

--- view all tasks details in employee wise creating view
 go
 create view viewTask
 as
   select t.taskid,t.name,t.description,t.status,t.estimatedTime,t.projectid,s.staffId,s.assignedate,s.reassignedate
   from staff_employee s,task t
   where s.taskid=t.taskid


select * from viewTask


-- --- when we try to insert data to viewTask view, then base tables should be updated.
-- for that we use triggers

 go
create trigger insert_view
on viewTask
instead of insert
as 
begin
  declare @taskid varchar(4)
  declare @name varchar(10)
  declare @des varchar(30)
  declare @status varchar(10)
  declare @estimatedTime time 
  declare @pid varchar(4)
  declare @sid varchar(4)
  declare @assDate date
  declare @reassDate date

   select @taskid=taskid,@name=name,@des=description,@status=status,@estimatedTime=estimatedTime,
   @pid=projectid,@sid=staffId,@assDate=assignedate,@reassDate=reassignedate
  from inserted
 
  if not exists (select * from staff_employee where staffId=@sid) 
  begin
   insert into staff_employee values (@sid,@assDate,@reassDate,null)
   insert into task values (@taskid,@name,@des,@status,@estimatedTime,@pid)
    update staff_employee set taskid=@taskid where staffId=@sid
   end
end


--insert date to viewTask view

insert into viewTask values ('t001','login','login to moodle','yes','05:30:40','P001','u001','2020-mar-20','2020-aug-15') 



---view all tasks details project wise creating view
go
alter view project_view
as
select t.taskid,t.status,p.projectid,p.cost
from project p,task t
where p.projectid=t.taskid


-- excute view
select * from project_view


--- check project is loss or gain using a function

go
alter function check_progress(@pid varchar(4))
returns varchar(10)
as
begin
   declare @progress varchar(10)
   declare @cost int
   declare @budget int

   select @cost=cost from project where projectid=@pid
   select @budget=budgetValue from budget where projectid=@pid

   if @cost<@budget
   begin
      set @progress='gain'
   end

   if @cost>@budget
   begin
      set @progress='loss'
   end

   return @progress
end

declare @val varchar(10)
exec @val=check_progress 'p001'
print @val


---- when project cost is updated, project progress should be changed as gain or loss.
--   using triggers
 --when we give cost , project table should be updated. For that we create stored procedure,

-- first new cost should be calculated.
  go
  alter function totalcost(@cost int,@pid varchar(4))
  returns int
  as
  begin
    declare @previous_cost int
	 declare @updated_cost int
    select @previous_cost=cost from project where projectid=@pid
	set @updated_cost=@previous_cost+@cost
     return @updated_cost
  end

  -- after that this totalcost should be updated to project table. Here we have created 
  -- stored procedure for that

  go
  create proc update_project
  @cost int,
  @pid varchar(4)
  as
  begin
     declare @totalcost int
	 exec @totalcost=totalcost @cost,@pid
	 update project set cost=@totalcost where projectid=@pid
  end

  execute update_project 20000, 'p001'

  -- when cost of project table is updated, progress of project also should be updated as gain or loss
  --first we check project progress of given project id.check project is loss or gain using a function

go
alter function check_progress(@pid varchar(4))
returns varchar(10)
as
begin
   declare @progress varchar(10)
   declare @cost int
   declare @budget int

   select @cost=cost from project where projectid=@pid
   select @budget=budgetValue from budget where projectid=@pid

   if @cost<@budget
   begin
      set @progress='gain'
   end

   if @cost>@budget
   begin
      set @progress='loss'
   end

   return @progress
   end

   --- finally progress of project table is updated

   go
create trigger update_projecttrig
on project
after update
as 
begin
    declare @progress varchar(10)
   declare @pid varchar(4)
    select @pid=projectid from inserted

	exec @progress=check_progress @pid

	update project set progress=@progress where projectid=@pid
end


