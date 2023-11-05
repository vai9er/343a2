SET SEARCH_PATH TO markus;


INSERT INTO 
	MarkusUser(username, surname, firstname, type) 
VALUES
	('snapes', 'Severus', 'Snape', 'TA'),
	('lupinr4', 'Remus', 'Lupin', 'TA'),
	('dumbledore', 'Albus', 'Dumbledore', 'instructor'),
	('mcGonagall', 'Minerva', 'McGonagall', 'instructor');


INSERT INTO 
	Assignment(assignment_id, description, due_date, group_min, group_max)
VALUES
	(1, 'A1', '2023-10-10 23:59', 1, 1),
	(2, 'A2', '2023-11-13 23:59', 1, 3),
	(3, 'A3', '2023-12-05 23:59', 1, 2),
	(4, 'A4', '2020-11-13 23:59', 1, 1);