-- Distributions.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
	assignment_id integer NOT NULL,
	average_mark_percent real DEFAULT NULL,
	num_80_100 integer NOT NULL,
	num_60_79 integer NOT NULL,
	num_50_59 integer NOT NULL,
	num_0_49 integer NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS assign_weights CASCADE;
DROP VIEW IF EXISTS assignment_grades CASCADE;
DROP VIEW IF EXISTS assignment_percentages CASCADE;


-- Define views for your intermediate steps here:

-- Total mark of assignment and the weight
CREATE VIEW assign_weights AS
SELECT RubricItem.assignment_id, sum(out_of) as total, sum(weight) as weights
FROM  RubricItem
GROUP BY RubricItem.assignment_id;


-- All the assignment grades
CREATE VIEW assignment_grades AS  
SELECT assignment.assignment_id, assignmentgroup.group_id, mark
FROM (Assignment LEFT JOIN AssignmentGroup ON Assignment.assignment_id = AssignmentGroup.assignment_id) LEFT JOIN Result ON AssignmentGroup.group_id = Result.group_id;

-- Percentage Grades:
CREATE VIEW assignment_percentages AS
select assignment_grades.assignment_id, group_id, (mark / weights) * 100 as average
from assignment_grades LEFT JOIN assign_weights on assignment_grades.assignment_id = assign_weights.assignment_id;




-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1(
	SELECT assignment_id, sum(average) / count(average) as average_mark_percent, count(case when average between 80 and 100 then average end) as num_80_100, 
	count(case when average between 60 and 79 then average end) as num_60_79, count(case when average between 50 and 50 then average end) as num_50_59,
	count(case when average between 0 and 49 then average end) as num_0_49
	FROM assignment_percentages
	GROUP BY assignment_id
);
