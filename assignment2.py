"""CSC343 Assignment 2

=== CSC343 Fall 2023 ===
Department of Computer Science,
University of Toronto

This code is provided solely for the personal and private use of
students taking the CSC343 course at the University of Toronto.
Copying for purposes other than this use is expressly prohibited.
All forms of distribution of this code, whether as given or with
any changes, are expressly prohibited.

Authors: Diane Horton and Marina Tawfik

All of the files in this directory and all subdirectories are:
Copyright (c) 2023

=== Module Description ===

This file contains the Markus class and some simple testing functions.
"""
import datetime as dt
import psycopg2 as pg
import psycopg2.extensions as pg_ext
import psycopg2.extras as pg_extras
from typing import Optional


class Markus:
    """A class that can work with data conforming to the schema in schema.ddl.

    === Instance Attributes ===
    connection: connection to a PostgreSQL database of Markus-related
        information.

    Representation invariants:
    - The database to which <connection> holds a reference conforms to the
      schema in schema.ddl.
    """
    connection: Optional[pg_ext.connection]

    def __init__(self) -> None:
        """Initialize this Markus instance, with no database connection
        yet.
        """
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        """Establish a connection to the database <dbname> using the
        username <username> and password <password>, and assign it to the
        instance attribute <connection>. In addition, set the search path
        to markus.

        Return True if the connection was made successfully, False otherwise.
        I.e., do NOT throw an error if making the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> # In this example, the connection cannot be made.
        >>> a2.connect("invalid", "nonsense", "incorrect")
        False
        """
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=markus"
            )
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        """Close this instance's connection to the database.

        Return True if closing the connection was successful, False otherwise.
        I.e., do NOT throw an error if closing the connection fails.

        >>> a2 = Markus()
        >>> # The following example will only work if you change the dbname
        >>> # and password to your own credentials.
        >>> a2.connect("csc343h-marinat", "marinat", "")
        True
        >>> a2.disconnect()
        True
        """
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    def checkAssignmentID(self, assignment: int) -> bool:
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(assignment_id) FROM Assignment WHERE assignment_id = %s", (assignment,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def get_groups_count(self, assignment: int) -> Optional[int]:
        """Return the number of groups defined for the assignment with
        ID <assignment>.

        Return None if the operation was unsuccessful i.e., do NOT throw
        an error.

        The operation is considered unsuccessful if <assignment> is an invalid
        assignment ID.

        Note: if <assignment> is a valid assignment ID but happens to have
        no groups defined, the operation is considered successful,
        with a returned count of 0.
        """
        try:
            with self.connection.cursor() as cur:
                if(self.checkAssignmentID(assignment)):
                    cur.execute("SELECT COUNT(*) FROM AssignmentGroup WHERE assignment_id = %s", (assignment,))
                    result = cur.fetchone()
                    return result[0] if result else 0
        except pg.Error as ex:
            return None

    def checkGroupID(self, group: int) -> bool:
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(group_id) FROM AssignmentGroup WHERE group_id = %s", (group,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def checkGrader(self, grader: str) -> bool:
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(username) FROM MarkusUser WHERE username = %s and type != 'student'", (grader,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def checkGraderAssigned(self, group: int) -> bool:
        # returns true if a grader is assigned
        # returns false if grader is not assigned
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(username) FROM Grader WHERE group_id = %s", (group,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def assign_grader(self, group: int, grader: str) -> bool:
        """Assign grader <grader> to the assignment group <group>, by updating
        the Grader table appropriately.

        If <group> has already been assigned a grader, update the Result table
        to reflect that the new grader is <grader>.

        Return True if the operation is successful, and False Otherwise.
        I.e., do NOT throw an error. If the operation is unsuccessful, no
        changes should be made to the database.

        The operation is considered unsuccessful if one or more of the following
        is True:
            * <group> is not a valid group ID i.e., it doesn't exist in the
              AssignmentGroup table.
            * <grader> is an invalid Markus username or is neither a
              TA nor an instructor.

        Note: if <grader> is already assigned to the assignment group <group>,
        the operation is considered to be successful.
        """
        try:
            # TODO: Implement this method
            with self.connection.cursor() as cur:
                # check if group and grader are valid
                if(self.checkGroupID(group) and self.checkGrader(grader)):
                    #if a grader is assigned to group
                    if(self.checkGraderAssigned(group)):
                        cur.execute("UPDATE grader SET username = %s WHERE group_id = %s", (grader, group))
                    else:
                    #if grader is not assigned to group
                        cur.execute("INSERT INTO grader (group_id, username) VALUES (%s, %s)", (group, grader))
                    self.connection.commit()
                    return True
                return False
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return False

    def checkusernameValid(self, username: str) -> bool:
        # returns true if a username is in markususers
        # returns false if a username is not in markususers
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(username) FROM MarkusUser WHERE username = %s", (username,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def checkuserpartofgroup(self, username: str) -> bool:
        # returns true if a username is part of group
        # returns false if username is not part of a group
        try:
            with self.connection.cursor() as cur:
                cur.execute("SELECT COUNT(username) FROM Membership WHERE username = %s", (username,))
                result = cur.fetchone()
                if result[0] >= 1:
                    return True
                else: return False
        except pg.Error as ex:
            return None

    def remove_student(self, username: str, date: dt.date) -> int:
        """Remove the student identified by <username> from all groups on
        assignments that have due date greater than (i.e., after) <date>.

        Return the number of groups the user was removed from, or -1 if the
        operation was unsuccessful, i.e. do NOT throw an error.

        The operation is considered unsuccessful if <username> is an invalid
        user or is not a student. Note: if <username> is a valid student but
        is not a member of any group, the operation is considered successful,
        but no deletion will occur.

        Make sure to delete any empty group(s) that result(s) from deleting the
        target memberships of <username>.

        Note: Compare the due date of an assignment on the precision of days.
        E.g., if <date> is 2023-09-01, an assignment due on 2023-09-01 23:59
        is not considered to be "after" that because it is not due on a later
        day.
        """
        try:
            # TODO: Implement this method
            with self.connection.cursor() as cur:
                # if username is invalid then return -1
                if(self.checkusernameValid(username)):
                    if(not self.checkuserpartofgroup(username)):
                        # if username is valid but not part of a group return 0
                        return 0
                    else:
                        # if username is valid and part of group(s) return number of deletions
                        find_query = "Select username, Membership.group_id From Assignment JOIN AssignmentGroup on Assignment.assignment_id = AssignmentGroup.assignment_id JOIN Membership on Membership.group_id = AssignmentGroup.group_id where ((Assignment.due_date - %s) > INTERVAL '1' day) and username = %s"
                        cur.execute(find_query, (date, username))
                        results = cur.fetchall()
                        num_deleted = 0

                        for row in results:
                            username, group_id = row
                            delete_query = "DELETE FROM Membership WHERE Membership.username = %s AND Membership.group_id = %s"
                            cur.execute(delete_query, (username, group_id))
                            num_deleted += 1
                        self.connection.commit()
                        # code is okay until here

                        #delete any AssigmentGroup that has no membership
                        empty_groups = "Select AssignmentGroup.group_id from AssignmentGroup WHERE AssignmentGroup.group_id NOT IN (Select group_id from Membership)"
                        cur.execute(empty_groups)
                        no_members = cur.fetchall()
                        for row in no_members:
                            group_id = row
                            print(group_id)
                            delete_query = "DELETE FROM AssignmentGroup Where AssignmentGroup.group_id = %s"
                            cur.execute(delete_query, (group_id))
                        self.connection.commit()
                        return num_deleted
                return -1
        except pg.Error as ex:
            # You may find it helpful to uncomment this line while debugging,
            # as it will show you all the details of the error that occurred:
            # raise ex
            return -1

    def create_groups(self, assignment_to_group: int, other_assignment: int, repo_prefix: str) -> bool:
        try:
            # Get the cursor
            cursor = self.connection.cursor()

            # Check if both assignments exist
            sql_check_assignments_exist = """
            SELECT EXISTS(SELECT 1 FROM Assignment WHERE assignment_id = %s),
                EXISTS(SELECT 1 FROM Assignment WHERE assignment_id = %s)
            """
            cursor.execute(sql_check_assignments_exist, (assignment_to_group, other_assignment))
            assignment_exists, other_assignment_exists = cursor.fetchone()
            if not (assignment_exists and other_assignment_exists):
                return False

            # Check if any groups have already been created for assignment_to_group
            sql_check_no_groups = """
            SELECT count(*) FROM AssignmentGroup WHERE assignment_id = %s
            """
            cursor.execute(sql_check_no_groups, (assignment_to_group,))
            if cursor.fetchone()[0] > 0:
                return False

            # Get the maximum number of people in a group for assignment_to_group
            cursor.execute("SELECT group_max FROM Assignment WHERE assignment_id = %s", (assignment_to_group,))
            group_max_record = cursor.fetchone()
            if group_max_record is None:
                return False
            group_max = group_max_record[0]

            # Get all the students in order of grades and alphabetical username
            sql_students_ordered = """
            SELECT mu.username
            FROM MarkusUser mu
            LEFT JOIN Membership m ON mu.username = m.username
            LEFT JOIN AssignmentGroup ag ON m.group_id = ag.group_id
            LEFT JOIN Result res ON ag.group_id = res.group_id
            WHERE mu.type = 'student' AND ag.assignment_id = %s
            ORDER BY res.mark DESC NULLS LAST, mu.username;
            """
            cursor.execute(sql_students_ordered, (other_assignment,))
            students = cursor.fetchall()

            # If there are no students, return True
            if not students:
                return True

            counter = 0
            group_id = None

            # Go through the students and assign them to groups
            for student in students:
                if counter == 0:
                    # Start a new group
                    cursor.execute("SELECT nextval('group_id_seq')")
                    group_id = cursor.fetchone()[0]
                    repo = f"{repo_prefix}/group_{group_id}"
                    cursor.execute(
                        "INSERT INTO AssignmentGroup (group_id, assignment_id, repo) VALUES (%s, %s, %s)",
                        (group_id, assignment_to_group, repo)
                    )

                # Add the student to the group
                cursor.execute(
                    "INSERT INTO Membership (username, group_id) VALUES (%s, %s)",
                    (student[0], group_id)
                )
                counter += 1

                # Check if this is the last student or if the group is at max capacity
                if counter == group_max or student == students[-1]:
                    counter = 0  # Reset counter for a new group

            # Commit the transaction
            self.connection.commit()
            return True

        except pg.Error as ex:
            # Rollback in case of error
            self.connection.rollback()
            # Uncomment the line below to see the error details during debugging
            # print(ex)
            return False

        finally:
            # Close the cursor
            cursor.close()


def setup(
    dbname: str, username: str, password: str, schema_path: str, data_path: str
) -> None:
    """Set up the testing environment for the database <dbname> using the
    username <username> and password <password> by importing the schema file
    at <schema_path> and the file containing the data at <data_path>.

    <schema_path> and <data_path> are the relative/absolute paths to the files
    containing the schema and the data respectively.
    """
    connection, cursor, schema_file, data_file = None, None, None, None
    try:
        connection = pg.connect(
            dbname=dbname, user=username, password=password,
            options="-c search_path=markus"
        )
        cursor = connection.cursor()

        schema_file = open(schema_path, "r")
        cursor.execute(schema_file.read())

        data_file = open(data_path, "r")
        cursor.execute(data_file.read())

        connection.commit()
    except Exception as ex:
        connection.rollback()
        raise Exception(f"Couldn't set up environment for tests: \n{ex}")
    finally:
        if cursor and not cursor.closed:
            cursor.close()
        if connection and not connection.closed:
            connection.close()
        if schema_file:
            schema_file.close()
        if data_file:
            data_file.close()


def test_get_groups_count() -> None:
    """Test method get_groups_count.
    """
    # TODO: Change the values of the following variables to connect to your
    #  own database:
    dbname = "csc343h-xiongkev"
    user = "xiongkev"
    password = ""

    # The following uses the relative paths to the schema file and the data file
    # we have provided. For your own tests, you will want to make your own data
    # files to use for testing.
    schema_file = "schema.ddl"
    data_file = "data.sql"

    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)

        # The following is an assert statement. It checks that the value for
        # connected is True. The message after the comma will be printed if
        # that is not the case (that is, if connected is False).
        # Use the same notation throughout your testing.
        assert connected, f"[Connect] Expected True | Got {connected}."

        # The following function call will set up the testing environment by
        # loading a fresh copy of the schema and the sample data we have
        # provided into your database. You can create more sample data files
        # and call the same function to load them into your database.
        setup(dbname, user, password, schema_file, data_file)

        # TODO: Test more methods here, or better yet, make more testing
        # functions, with each testing a different method, and call them from
        # the main block below.

        # ---------------------- Testing get_groups_count ---------------------#

        # Invalid assignment ID
        num = a2.get_groups_count(0)
        assert num is None, f"[Get Group Count] Expected: None. Got {num}."

        # Valid assignment ID. No groups recorded.
        num = a2.get_groups_count(3)
        assert num == 0, f"[Get Group Count] Expected: 0. Got {num}."

        # Valid assignment ID. Some groups recorded.
        num = a2.get_groups_count(2)
        assert num == 3, f"[Get Group Count] Expected: 3. Got {num}."

    finally:
        a2.disconnect()

def test_assign_grader() -> None:
    dbname = "csc343h-xiongkev"
    user = "xiongkev"
    password = ""
    schema_file = "schema.ddl"
    data_file = "data.sql"

    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)
        assert connected, f"[Connect] Expected True | Got {connected}."
        setup(dbname, user, password, schema_file, data_file)

        non_grader = a2.assign_grader(1, 'xyz')
        print("assigning non-existant grader: %s", non_grader)
        non_group = a2.assign_grader(6, 't2another')
        print("assigning non-existant group: %s", non_group)
        non_both = a2.assign_grader(6, 'xyz')
        print("assigning non-existant group: %s", non_both)

        valid_assign = a2.assign_grader(1, 't2another')
        print("assigning non-existant group: %s", valid_assign)

    finally:
        a2.disconnect()

def test_remove_student() -> None:
    dbname = "csc343h-xiongkev"
    user = "xiongkev"
    password = ""
    schema_file = "schema.ddl"
    data_file = "data.sql"

    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)
        assert connected, f"[Connect] Expected True | Got {connected}."
        setup(dbname, user, password, schema_file, data_file)


        invalid_name = a2.remove_student('skdjfnsdjkfn', '2000-10-01 9:00')
        print("removing invalid name should be -1: ", invalid_name)
        remove_epoch = a2.remove_student('solostudent', '2000-10-01 9:00')
        print("removing valid student since epoch: %s", remove_epoch)

    finally:
        a2.disconnect()

def test_create_groups() -> None:
    dbname = "csc343h-xiongkev"
    user = "xiongkev"
    password = ""
    schema_file = "schema.ddl"
    data_file = "dataRstudent.sql"

    a2 = Markus()
    try:
        connected = a2.connect(dbname, user, password)
        assert connected, f"[Connect] Expected True | Got {connected}."
        setup(dbname, user, password, schema_file, data_file)


        testy = a2.create_groups(2, 1, 'test1')
        print("test1: ", testy)

    finally:
        a2.disconnect()

if __name__ == "__main__":
    # Un comment-out the next two lines if you would like to run the doctest
    # examples (see ">>>" in the methods connect and disconnect)
    # import doctest
    # doctest.testmod()
    # a2 = Markus()
    # a2.assign_grader(1, 't2another')
    # test_get_groups_count()
    test_create_groups()
