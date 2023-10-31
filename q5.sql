    -- Set search path and drop the existing table if it exists.
    SET search_path TO markus;
    DROP TABLE IF EXISTS q5 CASCADE;
     
    -- Create q5 table.
    CREATE TABLE q5 (
      assignment_id integer NOT NULL,
      username varchar(25) NOT NULL,
      num_assigned integer NOT NULL
    );
     
    -- Drop previously used views.
    DROP VIEW IF EXISTS grader_assignment_counts CASCADE;
    DROP VIEW IF EXISTS assignment_discrepancies CASCADE;
    DROP VIEW IF EXISTS affected_assignments CASCADE;
     
    -- Create a view for the count of groups assigned to each grader for every assignment.
    CREATE VIEW grader_assignment_counts AS 
    SELECT 
        Assignment.assignment_id, 
        grader.username, 
        COUNT(AssignmentGroup.group_id) as num_assigned
    FROM 
        Assignment 
    JOIN AssignmentGroup ON Assignment.assignment_id = AssignmentGroup.assignment_id 
    JOIN GRADER ON AssignmentGroup.group_id = grader.group_id
    GROUP BY 
        Assignment.assignment_id, grader.username;
     
    -- View to capture the range difference in assignments for each assignment.
    CREATE VIEW assignment_discrepancies AS
    SELECT 
        assignment_id,
        MAX(num_assigned) - MIN(num_assigned) as range_diff
    FROM 
        grader_assignment_counts
    GROUP BY 
        assignment_id;
     
    -- View for assignments affected by a range discrepancy over 10.
    CREATE VIEW affected_assignments AS
    SELECT 
        assignment_id
    FROM 
        assignment_discrepancies
    WHERE 
        range_diff > 10;
     
    -- Insert into q5 using the data from the views.
    INSERT INTO q5
    SELECT 
        gac.assignment_id,
        gac.username,
        gac.num_assigned
    FROM 
        grader_assignment_counts gac
    WHERE 
        gac.assignment_id IN (SELECT assignment_id FROM affected_assignments);