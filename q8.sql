-- Set the search path to the markus schema
SET search_path TO markus;

-- Drop the table q8 if it already exists
DROP TABLE IF EXISTS q8 CASCADE;

-- Create the q8 table
CREATE TABLE q8 (
	username varchar(25) NOT NULL,
	group_average real NOT NULL,
	solo_average real DEFAULT NULL
);

-- Drop views if they already exist
DROP VIEW IF EXISTS AssignmentsWithGroups CASCADE;
DROP VIEW IF EXISTS StudentSubmissionCounts CASCADE;
DROP VIEW IF EXISTS MultiMemberGroups CASCADE;
DROP VIEW IF EXISTS AvgGrades CASCADE;

-- Create a view that lists assignments that allow groups
CREATE VIEW AssignmentsWithGroups AS
SELECT assignment_id
FROM Assignment
WHERE group_max > 1;

-- Create a view that counts submissions per student per assignment
CREATE VIEW StudentSubmissionCounts AS
SELECT S.username, AG.assignment_id, COUNT(S.submission_id) AS submission_count
FROM Submissions S
JOIN AssignmentGroup AG ON S.group_id = AG.group_id
GROUP BY S.username, AG.assignment_id;

-- Create a view that identifies students who are in multi-member groups for assignments that allow it
CREATE VIEW MultiMemberGroups AS
SELECT M.username, AG.assignment_id
FROM Membership M
JOIN AssignmentGroup AG ON M.group_id = AG.group_id
JOIN AssignmentsWithGroups A ON AG.assignment_id = A.assignment_id
GROUP BY M.username, AG.assignment_id
HAVING COUNT(M.username) > 1;

-- Create a view that calculates average grades
CREATE VIEW AvgGrades AS
SELECT R.group_id, (R.mark / RI.weight_sum) * 100 AS average_grade
FROM Result R
JOIN (
	SELECT assignment_id, SUM(weight) AS weight_sum
	FROM RubricItem
	GROUP BY assignment_id
) RI ON R.group_id = RI.assignment_id;

-- Insert the required data into the q8 table
WITH GroupAssignments AS (
	SELECT username
	FROM StudentSubmissionCounts S
	JOIN AssignmentsWithGroups A ON S.assignment_id = A.assignment_id
	GROUP BY S.username
	HAVING COUNT(S.username) = (SELECT COUNT(*) FROM AssignmentsWithGroups)
),
SoloAssignments AS (
	SELECT username
	FROM StudentSubmissionCounts
	WHERE assignment_id NOT IN (SELECT assignment_id FROM AssignmentsWithGroups)
	GROUP BY username
	HAVING COUNT(username) = (SELECT COUNT(*) FROM Assignment WHERE group_max = 1)
)
SELECT G.username,
	   AVG(GA.average_grade) AS group_average,
	   AVG(SA.average_grade) AS solo_average
FROM GroupAssignments G
LEFT JOIN MultiMemberGroups MMG ON G.username = MMG.username
LEFT JOIN AvgGrades GA ON MMG.group_id = GA.group_id
LEFT JOIN SoloAssignments SA ON G.username = SA.username
GROUP BY G.username;
