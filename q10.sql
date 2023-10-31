    -- Set the search path and drop existing table if it exists.
    SET search_path TO markus;
    DROP TABLE IF EXISTS q10 CASCADE;
     
    -- Create q10 table.
    CREATE TABLE q10 (
      group_id bigint NOT NULL,
      mark real DEFAULT NULL,
      compared_to_average real DEFAULT NULL,
      status varchar(5) DEFAULT NULL
    );
     
    -- Drop previously used views.
    DROP VIEW IF EXISTS assignment_a1_groups CASCADE;
    DROP VIEW IF EXISTS a1_rubric_data CASCADE;
    DROP VIEW IF EXISTS a1_percentage_marks CASCADE;
    DROP VIEW IF EXISTS a1_avg_mark CASCADE;
     
    -- Create a view to list groups working on assignment A1.
    CREATE VIEW assignment_a1_groups AS
    SELECT 
        Assignment.assignment_id, 
        AssignmentGroup.group_id
    FROM 
        Assignment 
    JOIN 
        AssignmentGroup ON Assignment.assignment_id = AssignmentGroup.assignment_id 
    WHERE 
        Assignment.description = 'A1';
     
    -- View to capture the rubric data for A1.
    CREATE VIEW a1_rubric_data AS
    SELECT 
        Assignment.assignment_id, 
        SUM(RubricItem.out_of) as total_mark, 
        SUM(RubricItem.weight) as total_weight
    FROM 
        RubricItem 
    JOIN 
        Assignment ON RubricItem.assignment_id = Assignment.assignment_id 
    WHERE 
        Assignment.description = 'A1'
    GROUP BY 
        Assignment.assignment_id;
     
    -- View to calculate percentage marks for A1 groups.
    CREATE VIEW a1_percentage_marks AS
    SELECT 
        ag.group_id, 
        (r.mark / rd.total_weight) * 100 as mark
    FROM 
        assignment_a1_groups ag 
    LEFT JOIN 
        Result r ON ag.group_id = r.group_id 
    JOIN 
        a1_rubric_data rd ON ag.assignment_id = rd.assignment_id;
     
    -- View to capture the average mark of A1.
    CREATE VIEW a1_avg_mark AS
    SELECT 
        AVG(mark) as average_mark
    FROM 
        a1_percentage_marks;
     
    -- Insert into q10 using the data from the views.
    INSERT INTO q10
    SELECT 
        apm.group_id,
        apm.mark,
        apm.mark - avg_mark.average_mark as compared_to_average,
        CASE 
            WHEN apm.mark IS NULL THEN NULL
            WHEN apm.mark = avg_mark.average_mark THEN 'at'
            WHEN apm.mark > avg_mark.average_mark THEN 'above'
            ELSE 'below'
        END AS status
    FROM 
        a1_percentage_marks apm, 
        a1_avg_mark avg_mark;