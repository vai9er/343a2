-- High coverage.

SET search_path TO markus;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7 (
	grader varchar(25) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS all_students CASCADE;
DROP VIEW IF EXISTS all_students_assigned CASCADE;
DROP VIEW IF EXISTS graded_every_student CASCADE;

-- Define views for your intermediate steps here:
Create View all_students AS
select username
from MarkusUser
Where type = 'student';

Create View all_students_assigned AS
select g.username as g_name, s.username as s_name, s.group_id
From Grader g
JOIN Membership s
ON g.group_id = s.group_id;

Create View graded_every_student AS
Select Distinct A1.g_name
From all_students_assigned A1
Where not EXISTS(
	select s.username
	from all_students s
	Where not EXISTS(
		select 1 
		from all_students_assigned A2
		where a2.s_name = s.username and A1.g_name = A2.g_name
	)
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7 (grader)
Select g_name
from graded_every_student;
