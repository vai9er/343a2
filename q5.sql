-- Uneven workloads.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	assignment_id integer NOT NULL,
	username varchar(25) NOT NULL,
	num_assigned integer NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS grader_groups CASCADE;
DROP VIEW IF EXISTS  min_max CASCADE;

-- Define views for your intermediate steps here:
-- Every group, grader, and assignment
CREATE VIEW grader_groups AS 
select Assignment.assignment_id, grader.username, count(AssignmentGroup.group_id) as num_assigned
From (Assignment JOIN AssignmentGroup ON Assignment.assignment_id = AssignmentGroup.assignment_id) JOIN GRADER ON AssignmentGroup.group_id = grader.group_id
GROUP BY Assignment.assignment_id, grader.username;

-- Min and max of every assignment
CREATE VIEW min_max AS
select assignment_id,min(num_assigned) as min_num, max(num_assigned) as max_num from grader_groups
GROUP BY assignment_id;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5(
	select g1.assignment_id, g1.username, g1.num_assigned
	FROM grader_groups g1
	WHERE g1.assignment_id in (
		select assignment_id
		from min_max
		where max_num - min_num > 10)
);
