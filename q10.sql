-- A1 report.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10 (
	group_id bigint NOT NULL,
	mark real DEFAULT NULL,
	compared_to_average real DEFAULT NULL,
	status varchar(5) DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS a1_groups CASCADE;
DROP VIEW IF EXISTS assign_weights CASCADE;
DROP VIEW IF EXISTS a1_marks CASCADE;
DROP VIEW IF EXISTS averagee CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW a1_groups AS
SELECT Assignment.assignment_id, AssignmentGroup.group_id
FROM Assignment JOIN AssignmentGroup on assignment.assignment_id = AssignmentGroup.assignment_id
WHERE description = 'A1';

-- Total mark of the assignment and the weight
CREATE VIEW assign_weights AS
SELECT Assignment.assignment_id, sum(out_of) as total, sum(weight) as weights
FROM  RubricItem JOIN Assignment ON Assignment.assignment_id = RubricItem.assignment_id
WHERE description = 'A1'
GROUP BY Assignment.assignment_id;


-- A1 Marks in percentage
CREATE VIEW a1_marks AS
SELECT a1_groups.group_id, (mark / weights) * 100 as mark 
FROM (a1_groups LEFT JOIN Result ON a1_groups.group_id = Result.group_id) LEFT JOIN assign_weights ON a1_groups.assignment_id = assign_weights.assignment_id;

-- A1 average 
CREATE VIEW averagee AS
select avg(mark) as average
from a1_marks;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q10(
	SELECT group_id, mark, mark - average as compared_to_average, CASE 
	WHEN mark = average THEN 'at'
	WHEN mark > average THEN 'above'
	when mark < average THEN 'below'
	ELSE NULL
	END AS status
	FROM a1_marks, averagee
	GROUP BY group_id, mark, average
);

