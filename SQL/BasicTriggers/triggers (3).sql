CREATE FUNCTION Register_New_Students() RETURNS TRIGGER AS $$
    BEGIN
        IF(new.Student) IN (SELECT Student FROM Registrations WHERE Registrations.course = New.course AND Registrations.STUDENT = new.STUDENT) THEN
            RAISE EXCEPTION 'Student already registered';
        END IF;
        IF(EXISTS (SELECT Course FROM Prerequisite WHERE Prerequisite.Course = new.Course)) THEN
            IF(SELECT Count(PREREQUISITE) FROM Prerequisite WHERE Prerequisite.Course = new.Course AND Prerequisite.PREREQUISITE NOT IN (SELECT course FROM PassedCourses WHERE student = NEW.student )) THEN
            RAISE EXCEPTION 'Student have not done all Prerequisite courses';
             END IF;
        END IF;
        IF(new.Student) in (SELECT Student FROM PassedCourses where PassedCourses.Course = new.Course AND PassedCourses.student = new.STUDENT) THEN
            RAISE EXCEPTION 'Student already passed the course';
         END IF;
        IF (EXISTS (SELECT Student FROM WaitingList WHERE WaitingList.Student = New.Student AND WaitIngList.COURSE = New.COURSE)) THEN
            RAISE EXCEPTION 'Student already in WaitingList';
        END IF;

        IF NOT(new.COURSE) IN (SELECT CODE FROM LimitedCourses WHERE LimitedCourses.CODE = new.COURSE) THEN
            INSERT INTO Registered(STUDENT, COURSE) VALUES (new.STUDENT, new.COURSE);
            RAISE NOTICE 'REGISTERED TO THE COURSE';
        ELSE
        IF(new.COURSE) IN (SELECT CODE FROM LimitedCourses WHERE LimitedCourses.CODE = new.course) THEN
            IF NOT ((SELECT count(student) FROM Registered WHERE Registered.course = NEW.course) >= (SELECT CAPACITY FROM LimitedCourses WHERE LimitedCourses.CODE = NEW.course)) THEN
                INSERT INTO registered(STUDENT, COURSE) VALUES (new.student, new.course);
                RAISE NOTICE 'Student added to course';
            ELSE
                INSERT INTO WaitIngList(STUDENT, COURSE, POSITION) VALUES (new.student, new.course, (SELECT COUNT(POSITION) FROM WaitIngList WHERE WaitIngList.COURSE = new.COURSE) + 1);
                RAISE NOTICE 'Student added to WaitIngList';
            END IF;
        END IF;
        END IF;
        RETURN new;
        END;
        $$ LANGUAGE plpgsql;

CREATE TRIGGER Register_New_Students
  INSTEAD OF INSERT
  ON Registrations
  FOR EACH ROW
  EXECUTE PROCEDURE Register_New_Students();

CREATE OR REPLACE FUNCTION Remove_student() RETURNS TRIGGER AS $$
    BEGIN
        IF(EXISTS (SELECT Student FROM Registered WHERE Registered.STUDENT = old.Student AND Registered.COURSE = old.Course)) THEN
        DELETE FROM Registered where Registered.STUDENT = old.Student AND Registered.COURSE = old.Course;
            RAISE NOTICE 'STUDENT HAS BEEN REMOVED';
        IF(SELECT POSITION FROM WaitIngList WHERE WaitIngList.COURSE = old.COURSE AND (POSITION = 1)) THEN
            IF NOT ((SELECT count(student) FROM Registered WHERE Registered.course = old.course) >= (SELECT CAPACITY FROM LimitedCourses WHERE LimitedCourses.CODE = old.course)) THEN
            INSERT INTO Registered(STUDENT, COURSE) VALUES ((SELECT STUDENT FROM WaitIngList WHERE WaitIngList.COURSE = old.COURSE AND (WaitIngList.POSITION = 1)), old.COURSE);
            DELETE FROM WaitIngList WHERE old.COURSE = WaitIngList.COURSE AND (WaitIngList.POSITION = 1);
            RAISE NOTICE 'NEW STUDENT HAS BEEN REGISTERED TO THE COURSE';
            UPDATE WaitingList SET POSITION = POSITION - 1
              WHERE course = old.course AND POSITION != 1;
            RAISE NOTICE 'WAITING LIST UPDATED';
        END IF;
            ELSE
        RAISE NOTICE 'COURSE FULL';
        END IF;
        ELSE
         IF(EXISTS(SELECT WaitIngList.STUDENT FROM WaitIngList WHERE WaitIngList.STUDENT = old.STUDENT AND old.COURSE = WaitIngList.COURSE)) THEN
             DELETE FROM Waitinglist WHERE WaitIngList.STUDENT = old.STUDENT AND old.COURSE = WaitIngList.COURSE;
             RAISE NOTICE 'THE STUDENT HAS BEEN REMOVED FROM TO THE QUEUE';
                UPDATE WaitIngList SET POSITION = POSITION - 1 WHERE COURSE = old.COURSE AND POSITION != 1;

           END IF;
         END IF;
       RETURN old;
       END;
 $$ LANGUAGE plpgsql;

CREATE TRIGGER Remove_Student
  INSTEAD OF delete
  ON Registrations
  FOR EACH ROW
  EXECUTE PROCEDURE Remove_student();