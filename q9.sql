-- Inseparable.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9 (
	student1 varchar(25) NOT NULL,
	student2 varchar(25) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS multi_assignments CASCADE;
DROP VIEW IF EXISTS loners_groups CASCADE;
DROP VIEW IF EXISTS loners CASCADE;
DROP VIEW IF EXISTS never_alone CASCADE;
DROP VIEW IF EXISTS impossible_pairs CASCADE;
DROP VIEW IF EXISTS possible_pairs CASCADE;
DROP VIEW IF EXISTS Inseperable CASCADE;


-- Assignments where group_max > 1
CREATE VIEW multi_assignments AS
Select assignment_id from Assignment
WHERE group_max > 1;

-- Students who worked alone in multi_assignments

Create View loners_groups AS
Select Membership.group_id
From AssignmentGroup
	JOIN Membership
	ON Membership.group_id = AssignmentGroup.group_ID
Group by Membership.group_id
Having count(Membership.group_id) = 1;

Create View loners AS
Select Membership.username
From loners_groups JOIN Membership
	on Membership.group_id = loners_groups.group_id;

-- Students who nevver worked alone on multi_assignments
Create View never_alone AS
Select Membership.username, AssignmentGroup.group_iD, AssignmentGroup.assignment_id
From AssignmentGroup JOIN multi_assignments
	ON multi_assignments.assignment_id = AssignmentGroup.assignment_id
	JOIN Membership
	ON Membership.group_id = AssignmentGroup.group_ID
Where Membership.username NOT IN (SELECT username FROM loners);

-- All impossible pairs
Create View impossible_pairs AS
Select distinct N1.username as student1, N2.username as student2
From never_alone N1, never_alone N2
Where (N1.assignment_id = N2.assignment_id and N1.username != N2.username and N1.group_id != N2.group_id);

-- All possible pairs
Create View possible_pairs AS
Select Distinct N1.username as student1, N2.username as student2
From never_alone N1, never_alone N2
Where N1.username != N2.username
  AND N1.username not in (select username from loners)
  AND N2.username not in (select username from loners);

-- Inseperable
Create View Inseperable AS
Select student1, student2
from possible_pairs
where (student1, student2) NOT IN (SELECT student1, student2 FROM impossible_pairs) 
and student1 < student2
order by student1 asc;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9 (student1, student2)
Select student1, student2
from Inseperable;