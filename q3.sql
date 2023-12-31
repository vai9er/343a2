-- Solo superior.

-- You must not change the next 2 lines or the table definition.
SET search_path TO markus;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
	assignment_id integer NOT NULL,
	description varchar(100) NOT NULL,
	num_solo integer NOT NULL,
	average_solo real NOT NULL,
	num_collaborators integer NOT NULL,
	average_collaborators real NOT NULL,
	average_students_per_group real NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS done_grading CASCADE;
DROP VIEW IF EXISTS solo CASCADE;
DROP VIEW IF EXISTS multi CASCADE;
DROP VIEW IF EXISTS solo_grades CASCADE;
DROP VIEW IF EXISTS multi_grades CASCADE;
DROP VIEW IF EXISTS solo_avg CASCADE;
DROP VIEW IF EXISTS multi_avg CASCADE;
DROP VIEW IF EXISTS superior_avg CASCADE;
DROP VIEW IF EXISTS answer_description CASCADE;
DROP VIEW IF EXISTS answer_num_solo CASCADE;
DROP VIEW IF EXISTS collab_helper CASCADE;
DROP VIEW IF EXISTS answer_num_collaberators CASCADE;
DROP VIEW IF EXISTS avg_by_group CASCADE;
DROP VIEW IF EXISTS answer_avg_collaberators CASCADE;
DROP VIEW IF EXISTS answer_avg_num_students_helper CASCADE;
DROP VIEW IF EXISTS answer_avg_num_students CASCADE;
-- finished grading assignments
-- assignment with solo AND multi-member groups
-- average per assignment for solo
-- average per assignment for groups
-- compare the solo vs groups


-- Define views for your intermediate steps here:
CREATE VIEW done_grading AS
select AG.assignment_id, AG.group_id
From AssignmentGroup AG
Where not exists (
	Select distinct group_id 
	From Result
	where Result.group_id = AG.group_id and Result.released = false
);

-- solo groups
Create View solo AS
select Membership.group_ID, done_grading.assignment_id
FROM done_grading JOIN Membership
ON done_grading.group_id = Membership.group_ID
Group By Membership.group_id, done_grading.assignment_id
Having COUNT(Membership.group_id) = 1;

--multi student groups
Create View multi AS
select done_grading.group_ID, done_grading.assignment_id
FROM done_grading JOIN Membership
ON done_grading.group_id = Membership.group_ID
Group By done_grading.group_id, assignment_id
Having COUNT(done_grading.group_id) > 1;

-- grades of solo students
Create View solo_grades AS
select solo.group_id, solo.assignment_id, Result.mark
from solo 
	JOIN Result
	ON solo.group_id = Result.group_ID
Where Result.released = true;

-- grades of multi student groups
Create View multi_grades AS
select multi.group_id, multi.assignment_id, Result.mark
from multi 
	JOIN Result
	ON multi.group_id = Result.group_ID
Where Result.released = true;

-- average mark of each solo worker
Create View solo_avg AS
select solo_grades.group_id, solo_grades.assignment_id, AVG(solo_grades.mark) as average_solo
from solo_grades
group by solo_grades.group_id, solo_grades.assignment_id;

-- average mark of each multi worker
Create View multi_avg AS
select multi_grades.group_id, multi_grades.assignment_id, AVG(multi_grades.mark) as average_mark
from multi_grades
group by multi_grades.group_id, multi_grades.assignment_id;

-- assignment_ids with superior solo avg
Create View superior_avg AS
select distinct solo_avg.assignment_id
from solo_avg join multi_avg
on solo_avg.assignment_id = multi_avg.assignment_id
where solo_avg.average_solo > multi_avg.average_mark;

-- gets description per superior assignment
Create View answer_description AS
select superior_avg.assignment_id, Assignment.description
from superior_avg join Assignment
on superior_avg.assignment_id = Assignment.assignment_id;

-- gets number of solo workers per superior assignment
Create View answer_num_solo AS 
select solo_avg.assignment_id, count(solo_avg.assignment_id) as num_solo
from solo_avg join superior_avg
on solo_avg.assignment_id = superior_avg.assignment_id
group by solo_avg.assignment_id;

-- gets solo average per superior assignment
Create View answer_average_solo AS 
select solo_avg.average_solo, solo_avg.assignment_id
from solo_avg join superior_avg
on solo_avg.assignment_id = superior_avg.assignment_id;

-- gets the number of collaborators per superior assignment
Create View collab_helper AS 
select superior_avg.assignment_id, count(Membership.username) as num_collaborators
from superior_avg join AssignmentGroup
	on superior_avg.assignment_id = AssignmentGroup.assignment_id
	join Membership
	on AssignmentGroup.group_id = Membership.group_id
group by superior_avg.assignment_id, AssignmentGroup.group_id
Having COUNT(AssignmentGroup.group_id) > 1;

Create View answer_num_collaberators AS 
select assignment_id, sum(num_collaborators) as num_collaborators
from collab_helper
group by assignment_id;

-- gets the group average
Create View avg_by_group as
select distinct multi_avg.group_id, multi_avg.assignment_id, sum(multi_avg.average_mark) as average_mark
from multi_avg
group by multi_avg.group_id, multi_avg.assignment_id;

-- gets the group average per suprior assignment
Create View answer_avg_collaberators AS 
select distinct avg_by_group.assignment_id, avg(avg_by_group.average_mark) as average_collaborators
from avg_by_group join superior_avg
on avg_by_group.assignment_id = superior_avg.assignment_id
group by avg_by_group.assignment_id;

-- gets the average number of multi student groups per superior assignment
Create View answer_avg_num_students_helper AS
select superior_avg.assignment_id, count(Membership.username) as group_count
from superior_avg join AssignmentGroup
	on superior_avg.assignment_id = AssignmentGroup.assignment_id
	join Membership
	on AssignmentGroup.group_id = Membership.group_id
group by superior_avg.assignment_id, AssignmentGroup.group_id;

Create View answer_avg_num_students AS
select assignment_id, avg(group_count) as average_students_per_group
from answer_avg_num_students_helper
group by assignment_id;


-- Your query that answers the question goes below the "insert into" line:

INSERT INTO q3(
	assignment_id, description, 
	num_solo, average_solo, 
	num_collaborators, average_collaborators, 
	average_students_per_group)
select 
	superior_avg.assignment_id, 
	answer_description.description, 
	answer_num_solo.num_solo, 
	answer_average_solo.average_solo,
	answer_num_collaberators.num_collaborators, 
	answer_avg_collaberators.average_collaborators, 
	answer_avg_num_students.average_students_per_group
from
	superior_avg join answer_description
	on superior_avg.assignment_id = answer_description.assignment_id
	join answer_num_solo
	on superior_avg.assignment_id = answer_num_solo.assignment_id
	join answer_num_collaberators
	on superior_avg.assignment_id = answer_num_collaberators.assignment_id
	join answer_avg_collaberators
	on superior_avg.assignment_id = answer_avg_collaberators.assignment_id
	join answer_avg_num_students
	on superior_avg.assignment_id = answer_avg_num_students.assignment_id
	join answer_average_solo
	on superior_avg.assignment_id = answer_average_solo.assignment_id;


