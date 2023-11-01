    -- Never solo by choice.

    -- You must not change the next 2 lines or the table definition.
    SET search_path TO markus;
    DROP TABLE IF EXISTS q8 CASCADE;

    CREATE TABLE q8 (
        username varchar(25) NOT NULL,
        group_average real NOT NULL,
        solo_average real DEFAULT NULL
    );

    -- Identify students who have submitted at least one file for every assignment
    DROP VIEW IF EXISTS students_with_submissions CASCADE;
    CREATE VIEW students_with_submissions AS
    SELECT
        m.username
    FROM
        Membership m
    JOIN
        Submissions s ON m.username = s.username AND m.group_id = s.group_id
    JOIN
        AssignmentGroup ag ON m.group_id = ag.group_id
    GROUP BY
        m.username
    HAVING
        COUNT(DISTINCT ag.assignment_id) = (SELECT COUNT(*) FROM Assignment);

    -- Identify groups that are multi-member
    DROP VIEW IF EXISTS multi_member_groups CASCADE;
    CREATE VIEW multi_member_groups AS
    SELECT
        ag.group_id,
        ag.assignment_id
    FROM
        AssignmentGroup ag
    JOIN
        Membership m ON ag.group_id = m.group_id
    GROUP BY
        ag.group_id, ag.assignment_id
    HAVING
        COUNT(m.username) > 1;

    -- Identify students who have always been in multi-member groups for group assignments
    DROP VIEW IF EXISTS students_in_multi_member_groups CASCADE;
    CREATE VIEW students_in_multi_member_groups AS
    SELECT
        m.username
    FROM
        Membership m
    JOIN
        multi_member_groups mmg ON m.group_id = mmg.group_id
    GROUP BY
        m.username
    HAVING
        COUNT(DISTINCT mmg.assignment_id) = (SELECT COUNT(DISTINCT assignment_id) FROM multi_member_groups);

    -- Calculate average grades for group assignments
    DROP VIEW IF EXISTS group_assignment_avg_grades CASCADE;
    CREATE VIEW group_assignment_avg_grades AS
    SELECT
        m.username,
        AVG(r.mark) as group_avg
    FROM
        Membership m
    JOIN
        AssignmentGroup ag ON m.group_id = ag.group_id
    JOIN
        Result r ON ag.group_id = r.group_id
    JOIN
        multi_member_groups mmg ON ag.group_id = mmg.group_id
    GROUP BY
        m.username;

    -- Calculate average grades for solo assignments
    DROP VIEW IF EXISTS solo_assignment_avg_grades CASCADE;
    CREATE VIEW solo_assignment_avg_grades AS
    SELECT
        m.username,
        AVG(r.mark) as solo_avg
    FROM
        Membership m
    JOIN
        AssignmentGroup ag ON m.group_id = ag.group_id
    JOIN
        Result r ON ag.group_id = r.group_id
    WHERE
        NOT EXISTS (SELECT 1 FROM multi_member_groups mmg WHERE ag.group_id = mmg.group_id)
    GROUP BY
        m.username;

    -- Insert the final results into q8
    INSERT INTO q8 (username, group_average, solo_average)
    SELECT
        s.username,
        COALESCE(g.group_avg, 0) as group_average,
        so.solo_avg as solo_average
    FROM
        students_with_submissions s
    LEFT JOIN
        group_assignment_avg_grades g ON s.username = g.username
    LEFT JOIN
        solo_assignment_avg_grades so ON s.username = so.username
    WHERE
        s.username IN (SELECT username FROM students_in_multi_member_groups);
