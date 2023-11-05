SET SEARCH_PATH TO markus;

-- Insert data into MarkusUser table
INSERT INTO MarkusUser(username, surname, firstname, type) 
VALUES
    ('student1', 'stud', 'stustu', 'student'),
    ('student2', 'stud', 'stustu', 'student'),
    ('student3', 'stud', 'stustu', 'student'),
    ('student4', 'stud', 'stustu', 'student'),
    ('student5', 'stud', 'stustu', 'student'),
    ('student6', 'stud', 'stustu', 'student'),
    ('student7', 'stud', 'stustu', 'student'),
    ('student8', 'stud', 'stustu', 'student'),
    ('t4someone', 't4so', 't4st4s', 'TA');

-- Insert data into Assignment table
INSERT INTO Assignment(assignment_id, description, due_date, group_min, group_max)
VALUES  
    (1, 'A1', '2023-10-01 11:00', 1, 3),
    (2, 'A2', '2023-10-02 11:00', 1, 2);

-- No data provided for Required table

-- Insert data into AssignmentGroup table
INSERT INTO AssignmentGroup(group_id, assignment_id, repo) 
VALUES
    (1, 1, 'git+group_1_1'),
    (2, 1, 'git+group_2_1'),
    (3, 1, 'git+group_3_1'),
    (4, 1, 'git+group_4_1'),
    (5, 1, 'git+group_5_1');

-- Insert data into Membership table
INSERT INTO Membership(username, group_id)
VALUES
    ('student1', 1),
    ('student2', 1),
    ('student3', 2),
    ('student4', 3),
    ('student5', 3),
    ('student6', 3),
    ('student7', 4),
    ('student8', 5);

-- Insert data into Submissions table
INSERT INTO Submissions(submission_id, file_name, username, group_id, submission_date)
VALUES
    (1, 'a1.txt', 'student1', 1, '2023-10-01 9:00'),
    (2, 'a1.txt', 'student3', 2, '2023-10-01 9:00'),
    (3, 'a1.txt', 'student4', 3, '2023-10-01 9:00'),
    (4, 'a1.txt', 'student7', 4, '2023-10-01 9:00'),
    (5, 'a1.txt', 'student8', 5, '2023-10-01 9:00');

-- Insert data into Grader table
INSERT INTO Grader(group_id, username)
VALUES
    (1, 't4someone'),
    (2, 't4someone'),
    (3, 't4someone'),
    (4, 't4someone'),
    (5, 't4someone');

-- Insert data into RubricItem table
INSERT INTO RubricItem(rubric_id, assignment_id, name, out_of, weight)
VALUES
    (1, 1, 'Criteria 1', 100, 100.0);

-- Insert data into Grade table
INSERT INTO Grade(group_id, rubric_id, grade)
VALUES
    (1, 1, 80.0),
    (2, 1, 71.0),
    (3, 1, 75.0),
    (4, 1, 70.0),
    (5, 1, 76.0);

-- Insert data into Result table
INSERT INTO Result(group_id, mark, released)
VALUES
    (1, 80.0, TRUE),
    (2, 71.0, TRUE),
    (3, 75.0, TRUE),
    (4, 70.0, TRUE),
    (5, 76.0, TRUE);
