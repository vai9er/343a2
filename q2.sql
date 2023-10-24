-- Set schema and table definition
SET search_path TO markus;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    grader_username varchar(25) NOT NULL,
    grader_name varchar(100) NOT NULL,
    average_mark_all_assignments real NOT NULL,
    mark_change_first_last real NOT NULL
);

-- Drop views
DROP VIEW IF EXISTS student_count_per_group CASCADE;
DROP VIEW IF EXISTS grades_per_assignment CASCADE;
DROP VIEW IF EXISTS grader_for_all_assignment CASCADE;
DROP VIEW IF EXISTS grader_for_ten_groups CASCADE;
DROP VIEW IF EXISTS consistent_increase_graders CASCADE;

-- 1. Calculate number of students in each group.
CREATE VIEW student_count_per_group AS
SELECT 
    group_id,
    COUNT(username) AS student_count
FROM Membership
GROUP BY group_id;

-- 2. Calculate the grades of groups per assignment per grader.
CREATE VIEW grades_per_assignment AS
SELECT 
    g.username AS grader_username,
    a.assignment_id,
    a.due_date,
    r.group_id,
    r.mark * s.student_count AS total_mark_for_students,
    s.student_count
FROM Grader g
JOIN AssignmentGroup ag ON g.group_id = ag.group_id
JOIN Assignment a ON a.assignment_id = ag.assignment_id
JOIN Result r ON r.group_id = ag.group_id
JOIN student_count_per_group s ON s.group_id = ag.group_id;

-- 3. Filter graders who have graded at least one group for every assignment.
CREATE VIEW grader_for_all_assignment AS
SELECT 
    grader_username
FROM grades_per_assignment
GROUP BY grader_username
HAVING COUNT(DISTINCT assignment_id) = (SELECT COUNT(*) FROM Assignment);

-- 4. Filter graders who have graded at least 10 groups on each assignment.
CREATE VIEW grader_for_ten_groups AS
SELECT 
    grader_username
FROM grades_per_assignment
GROUP BY grader_username, assignment_id
HAVING COUNT(group_id) >= 10;

-- 5. Filter graders whose grades have gone up consistently from assignment to assignment over time.
CREATE VIEW consistent_increase_graders AS
SELECT 
    grader_username
FROM (
    SELECT 
        grader_username,
        assignment_id,
        due_date,
        AVG(total_mark_for_students / student_count) AS avg_percentage,
        LAG(AVG(total_mark_for_students / student_count)) OVER (PARTITION BY grader_username ORDER BY due_date) AS prev_avg_percentage
    FROM grades_per_assignment
    GROUP BY grader_username, assignment_id, due_date
) AS t
WHERE avg_percentage >= COALESCE(prev_avg_percentage, 0)
GROUP BY grader_username
HAVING COUNT(assignment_id) = (SELECT COUNT(*) FROM Assignment);

-- Final insert using the aggregated data
INSERT INTO q2
SELECT
    g.grader_username,
    CONCAT(mu.firstname, ' ', mu.surname) AS grader_name,
    AVG(g.avg_percentage) AS average_mark_all_assignments,
    MAX(g.avg_percentage) - MIN(g.avg_percentage) AS mark_change_first_last
FROM (
    SELECT 
        grader_username,
        assignment_id,
        AVG(total_mark_for_students / student_count) AS avg_percentage
    FROM grades_per_assignment
    WHERE grader_username IN (SELECT grader_username FROM consistent_increase_graders)
    AND grader_username IN (SELECT grader_username FROM grader_for_all_assignment)
    AND grader_username IN (SELECT grader_username FROM grader_for_ten_groups)
    GROUP BY grader_username, assignment_id
) AS g
JOIN MarkusUser mu ON mu.username = g.grader_username
GROUP BY g.grader_username, mu.firstname, mu.surname;
