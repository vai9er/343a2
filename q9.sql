-- Inseparable.
-- Inseparable Report pairs of students who were part of a multi-member group
-- whenever the assignment permitted it, and always worked together (possibly with other students 
-- in a larger group). Note: The result will also be empty if no assignment allows multi-member 
-- groups or if one or more assignments that allow multi-member groups has no groups declared.
-- HINT: SQL allows you to compare strings lexicographically 
-- (in the order they would appear in the dictionary). 
-- Consequently, you can use comparison operators (>, <, =, ≥, ≤) 
-- or ORDER BY on string attributes in the same way you use them on integer 
-- attributes. For example, the result of select ’apple’ > ’banana’; would be False, 
--since ’apple’ would appear first in the dictionary.

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
Create View loners AS
Select Membership.username
From AssignmentGroup JOIN multi_assignments
	ON multi_assignments.assignment_id = AssignmentGroup.assignment_id
	JOIN Membership
	ON Membership.group_id = AssignmentGroup.group_ID
Group by Membership.group_id, Membership.username
Having count(Membership.username) = 1;

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
Where N1.assignment_id = N2.assignment_id and N1.username != N2.username and N1.group_id != N2.group_id;

-- All possible pairs
Create View possible_pairs AS
Select Distinct N1.username as student1, N2.username as student2
From never_alone N1, never_alone N2
Where N1.username != N2.username;

-- Inseperable
Create View Inseperable AS
Select student1, student2
from possible_pairs
where (student1, student2) NOT IN (SELECT student1, student2 FROM impossible_pairs);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9 (student1, student2)
Select student1, student2
from Inseperable;