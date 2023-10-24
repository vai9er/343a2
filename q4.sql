-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q4 CASCADE;


CREATE TABLE q4 (
	assignment_id integer NOT NULL,
	username varchar(25) NOT NULL,
	num_marked integer NOT NULL,
	num_not_marked integer NOT NULL,
	min_mark real DEFAULT NULL,
	max_mark real DEFAULT NULL
);

-- Calculate the total weight for each assignment
DROP VIEW IF EXISTS total_weight_per_assignment CASCADE;
CREATE VIEW total_weight_per_assignment AS
SELECT 
    assignment_id,
    SUM(weight) as total_weight
FROM 
    RubricItem 
GROUP BY 
    assignment_id;

-- Calculate the percentage grade for each group
DROP VIEW IF EXISTS percentage_grade_per_group CASCADE;
CREATE VIEW percentage_grade_per_group AS
SELECT 
    r.group_id,
    ag.assignment_id,
    r.mark/tw.total_weight * 100 as percentage_mark
FROM 
    Result r
JOIN 
    AssignmentGroup ag ON r.group_id = ag.group_id
JOIN 
    total_weight_per_assignment tw ON ag.assignment_id = tw.assignment_id;

-- Compute min and max grade for each grader per assignment
DROP VIEW IF EXISTS min_max_grade_per_grader CASCADE;
CREATE VIEW min_max_grade_per_grader AS
SELECT 
    gr.username,
    ag.assignment_id,
    MIN(pg.percentage_mark) as min_mark,
    MAX(pg.percentage_mark) as max_mark
FROM 
    Grader gr
JOIN 
    AssignmentGroup ag ON gr.group_id = ag.group_id
JOIN 
    percentage_grade_per_group pg ON pg.group_id = ag.group_id
GROUP BY 
    gr.username, ag.assignment_id;

-- Calculate the number of marked and unmarked groups for each grader per assignment
DROP VIEW IF EXISTS marked_unmarked_per_grader CASCADE;
CREATE VIEW marked_unmarked_per_grader AS
SELECT 
    gr.username,
    ag.assignment_id,
    COUNT(DISTINCT CASE WHEN r.group_id IS NOT NULL THEN ag.group_id END) as num_marked,
    COUNT(DISTINCT ag.group_id) - COUNT(DISTINCT r.group_id) as num_not_marked
FROM 
    Grader gr
JOIN 
    AssignmentGroup ag ON gr.group_id = ag.group_id
LEFT JOIN 
    Result r ON r.group_id = ag.group_id
GROUP BY 
    gr.username, ag.assignment_id;

-- Final table assembly
INSERT INTO q4
SELECT 
    mu.assignment_id,
    mu.username,
    mu.num_marked,
    mu.num_not_marked,
    mm.min_mark,
    mm.max_mark
FROM 
    marked_unmarked_per_grader mu
LEFT JOIN 
    min_max_grade_per_grader mm ON mu.username = mm.username AND mu.assignment_id = mm.assignment_id;