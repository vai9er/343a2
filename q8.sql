-- Never solo by choice.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8 (
	username varchar(25) NOT NULL,
	group_average real NOT NULL,
	solo_average real DEFAULT NULL
);

-- Identify Assignments with Solo and Group Options
DROP VIEW IF EXISTS assignment_type CASCADE;
CREATE VIEW assignment_type AS 
SELECT 
    assignment_id,
    CASE 
        WHEN group_max = 1 THEN 'solo'
        ELSE 'group'
    END as assignment_type
FROM Assignment;

-- Identify Students in Multi-Member Groups
DROP VIEW IF EXISTS students_in_groups CASCADE;
CREATE VIEW students_in_groups AS 
SELECT 
    m.username, 
    ag.assignment_id
FROM 
    Membership m
JOIN 
    AssignmentGroup ag ON m.group_id = ag.group_id
JOIN 
    assignment_type at ON ag.assignment_id = at.assignment_id
WHERE 
    at.assignment_type = 'group'
GROUP BY 
    m.username, ag.assignment_id
HAVING 
    COUNT(m.username) > 1;

-- Identify Students with Submissions for Every Assignment
DROP VIEW IF EXISTS students_with_all_submissions CASCADE;
CREATE VIEW students_with_all_submissions AS
SELECT
    s.username
FROM
    Submissions s
JOIN
    Assignment a ON s.assignment_id = a.assignment_id
GROUP BY
    s.username
HAVING
    COUNT(DISTINCT a.assignment_id) = (SELECT COUNT(*) FROM Assignment);

-- Calculate Average Grades
DROP VIEW IF EXISTS average_grades CASCADE;
CREATE VIEW average_grades AS 
SELECT 
    swas.username,
    AVG(CASE WHEN at.assignment_type = 'group' THEN r.mark ELSE NULL END) as group_average,
    AVG(CASE WHEN at.assignment_type = 'solo' THEN r.mark ELSE NULL END) as solo_average
FROM 
    students_with_all_submissions swas
JOIN 
    students_in_groups sig ON swas.username = sig.username
JOIN 
    Membership m ON sig.username = m.username
JOIN 
    AssignmentGroup ag ON m.group_id = ag.group_id
JOIN 
    Result r ON ag.group_id = r.group_id
JOIN 
    assignment_type at ON ag.assignment_id = at.assignment_id
GROUP BY 
    swas.username;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q8
SELECT 
    a.username,
    a.group_average,
    a.solo_average
FROM 
    average_grades a;
