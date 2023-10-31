    -- Set the search path.
    SET search_path TO markus;
     
    -- Drop the table if it exists.
    DROP TABLE IF EXISTS q1 CASCADE;
     
    -- Create the q1 table.
    CREATE TABLE q1 (
      assignment_id integer NOT NULL,
      average_mark_percent real DEFAULT NULL,
      num_80_100 integer NOT NULL,
      num_60_79 integer NOT NULL,
      num_50_59 integer NOT NULL,
      num_0_49 integer NOT NULL
    );
     
    -- Drop views if they exist.
    DROP VIEW IF EXISTS assign_weights CASCADE;
    DROP VIEW IF EXISTS assignment_grades CASCADE;
    DROP VIEW IF EXISTS assignment_percentages CASCADE;
     
    -- Create the assignment_grades view.
    CREATE VIEW assignment_grades AS  
    SELECT a.assignment_id, ag.group_id, r.mark
    FROM Assignment a
    LEFT JOIN AssignmentGroup ag ON a.assignment_id = ag.assignment_id
    LEFT JOIN Result r ON ag.group_id = r.group_id;
     
    -- Create the assign_weights view.
    CREATE VIEW assign_weights AS
    SELECT ri.assignment_id, sum(ri.out_of) as total, sum(ri.weight) as weights
    FROM RubricItem ri
    GROUP BY ri.assignment_id;
     
    -- Create the assignment_percentages view.
    CREATE VIEW assignment_percentages AS
    SELECT ag.assignment_id, ag.group_id, (ag.mark / aw.weights) * 100 as average
    FROM assignment_grades ag
    LEFT JOIN assign_weights aw ON ag.assignment_id = aw.assignment_id;
     
    -- Insert into q1 table.
    INSERT INTO q1(
      SELECT 
        ap.assignment_id,
        AVG(ap.average) as average_mark_percent,
        COUNT(NULLIF(ap.average BETWEEN 80 AND 100, FALSE)) as num_80_100,
        COUNT(NULLIF(ap.average BETWEEN 60 AND 79, FALSE)) as num_60_79,
        COUNT(NULLIF(ap.average = 50, FALSE)) as num_50_59,
        COUNT(NULLIF(ap.average BETWEEN 0 AND 49, FALSE)) as num_0_49
      FROM assignment_percentages ap
      GROUP BY ap.assignment_id
    );