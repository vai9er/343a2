-- High coverage.

SET search_path TO markus;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7 (
	grader varchar(25) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS groups_graders CASCADE;
DROP VIEW IF EXISTS num_assigns CASCADE;

-- Define views for your intermediate steps here:
-- The groups and their graders
CREATE VIEW groups_graders AS
SELECT Assignment.assignment_id, AssignmentGroup.group_id, Grader.username
FROM (Assignment JOIN AssignmentGroup on assignment.assignment_id = AssignmentGroup.assignment_id) JOIN Grader ON assignmentGroup.group_id = Grader.group_id;


-- Number of assignments with graders declared:
CREATE VIEW num_assigns AS
SELECT count (distinct assignment.assignment_id) as num
FROM Assignment JOIN AssignmentGroup on assignment.assignment_id = AssignmentGroup.assignment_id;

-- Assigned to mark every Assignment (First Condition)
CREATE VIEW assigns_marker AS
select username as grader
FROM groups_graders , num_assigns
GROUP BY username, num
HAVING count(distinct assignment_id) = num;


-- Every student in groups
CREATE VIEW students AS
select membership.username, membership.group_id, groups_graders.username as graders, assignment_id 
from (markususer LEFT JOIN Membership ON markususer.username = membership.username) LEFT JOIN groups_graders ON membership.group_id = groups_graders.group_id 
where type = 'student';


-- graders that graded every student in at least one assignment
CREATE VIEW all_markers AS
select s1.graders as grader
from students as s1 JOIN students as s2 ON s1.username = s2.username
WHERE  s1.graders = s2.graders
GROUP BY s1.graders
HAVING count(distinct s1.username) = (select count(distinct username) from students);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7(
	(select * from assigns_marker) INTERSECT (select * from all_markers)
);
