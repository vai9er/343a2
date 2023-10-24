-- Steady work.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6 (
	group_id integer NOT NULL,
	first_file varchar(25) DEFAULT NULL,
	first_time timestamp DEFAULT NULL,
	first_submitter varchar(25) DEFAULT NULL,
	last_file varchar(25) DEFAULT NULL,
	last_time timestamp DEFAULT NULL,
	last_submitter varchar(25) DEFAULT NULL,
	elapsed_time interval DEFAULT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS a1_groups CASCADE;
DROP VIEW IF EXISTS a1_sub CASCADE;
DROP VIEW IF EXISTS first_sub CASCADE;
DROP VIEW IF EXISTS last_sub CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW a1_groups AS
SELECT AssignmentGroup.group_id
FROM Assignment JOIN AssignmentGroup on assignment.assignment_id = AssignmentGroup.assignment_id
WHERE description = 'A1';

-- All a1 submissions
CREATE VIEW a1_subs AS
select submissions.group_id, username, file_name, submission_date
FROM a1_groups JOIN SUbmissions ON a1_groups.group_id = submissions.group_id
;

-- First submission of every group
CREATE VIEW first_sub AS
select group_id, file_name as first_file, min(submission_date) as first_time, username as first_submitter
FROM a1_subs
GROUP BY group_id, username, file_name;

-- Last submission of every group
CREATE VIEW last_sub AS
select group_id, file_name as last_file, max(submission_date) as last_time, username as last_submitter
FROM a1_subs
WHERE submission_date = (
	select max(submission_date)
	FROM a1_subs as a
	WHERE a.group_id = a1_subs.group_id
) 
GROUP BY group_id, username, file_name;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6 (
	select first_sub.group_id, first_file, first_time, first_submitter, last_file, last_time, last_submitter, last_time - first_time as Interval
	FROM first_sub JOIN last_sub ON first_sub.group_id = last_sub.group_id
);
