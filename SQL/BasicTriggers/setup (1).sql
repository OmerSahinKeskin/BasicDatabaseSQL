CREATE TABLE Department(
    D_NAME TEXT NOT NULL,
    D_ABBREVIATIONS  TEXT NOT NULL,

    UNIQUE(D_ABBREVIATIONS),

    PRIMARY KEY (D_NAME)

);

CREATE TABLE Programs (
P_NAME TEXT NOT NULL,
p_abbreviations TEXT NOT NULL,

PRIMARY KEY (P_NAME)
);

CREATE TABLE Students(
    IDNR TEXT                NOT NULL,
    NAME TEXT                       NOT NULL,
    LOGIN TEXT                      NOT NULL,
    PROGRAM TEXT                    NOT NULL,
    UNIQUE(IDNR, PROGRAM),
    UNIQUE(LOGIN),

    PRIMARY KEY (IDNR),
    FOREIGN KEY (PROGRAM) REFERENCES Programs(P_NAME)
);

CREATE TABLE Branches(
    NAME TEXT            NOT NULL,
    PROGRAM TEXT         NOT NULL,

    PRIMARY KEY (NAME,PROGRAM)

);

CREATE TABLE StudentBelongsTo(
    s_idnr TEXT               NOT NULL,
    s_name TEXT                      NOT NULL,
    s_login  TEXT                      NOT NULL,
    P_NAME TEXT                     NOT NULL,
    B_NAME TEXT                     NOT NULL,

PRIMARY KEY(s_idnr, B_NAME, P_NAME),
FOREIGN KEY(B_NAME, P_NAME) REFERENCES Branches(NAME, PROGRAM),
FOREIGN KEY(s_idnr, P_NAME) REFERENCES Students(IDNR, PROGRAM)

);

CREATE TABLE Courses(
    CODE VARCHAR(6)                        NOT NULL,
    NAME TEXT                 UNIQUE       NOT NULL,
    CREDITS REAL                           NOT NULL,
    DEPARTMENT TEXT                        NOT NULL,

    PRIMARY KEY (CODE)

);

CREATE TABLE Prerequisite(
    COURSE TEXT NOT NULL,
    PREREQUISITE TEXT NOT NULL,

    PRIMARY KEY (COURSE),

    FOREIGN KEY (PREREQUISITE) REFERENCES Courses(CODE),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE OfferedPrograms(
    D_NAME TEXT NOT NULL,
    P_NAME TEXT NOT NULL,

    PRIMARY KEY (D_NAME),

    FOREIGN KEY (P_NAME) REFERENCES Programs(P_NAME),
    FOREIGN KEY (D_NAME) REFERENCES department(D_NAME)


);

CREATE TABLE OfferedCourses(
    COURSE TEXT NOT NULL,
    D_NAME TEXT NOT NULL,

    PRIMARY KEY (D_NAME, COURSE),
    FOREIGN KEY (D_NAME) REFERENCES department(D_NAME),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE LimitedCourses(
    CODE VARCHAR(6)        UNIQUE      NOT NULL,
    CAPACITY INT                       NOT NULL,

    PRIMARY KEY (CODE) ,

    FOREIGN KEY  (CODE) REFERENCES Courses(CODE)

);

CREATE TABLE StudentBranches(
    STUDENT TEXT     NOT NULL,
    BRANCH TEXT             NOT NULL,
    PROGRAM TEXT            NOT NULL,

    PRIMARY KEY (STUDENT),

    FOREIGN KEY (STUDENT, PROGRAM) REFERENCES Students(IDNR, PROGRAM),
    FOREIGN KEY (BRANCH, PROGRAM) REFERENCES Branches(NAME, PROGRAM)

);

CREATE TABLE Classifications(
    NAME TEXT               NOT NULL,

      PRIMARY KEY (NAME)
);

CREATE TABLE Classified(
    COURSE VARCHAR(6)             NOT NULL,
    CLASSIFICATION TEXT           NOT NULL,

    PRIMARY KEY (COURSE, CLASSIFICATION),

    FOREIGN KEY (COURSE) REFERENCES Courses(CODE),
    FOREIGN KEY (CLASSIFICATION) REFERENCES Classifications(NAME)

);

CREATE TABLE MandatoryProgram(
    COURSE VARCHAR(6)            NOT NULL,
    PROGRAM TEXT                 NOT NULL,

    PRIMARY KEY (COURSE, PROGRAM),

    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE MandatoryBranch(
    COURSE VARCHAR(6)           NOT NULL,
    BRANCH TEXT         NOT NULL,
    PROGRAM TEXT          NOT NULL,

    PRIMARY KEY (COURSE, BRANCH, PROGRAM),

    FOREIGN KEY (COURSE) REFERENCES Courses(CODE),
    FOREIGN KEY  (BRANCH, PROGRAM) REFERENCES Branches(NAME, PROGRAM)

);

CREATE TABLE RecommendedBranch(
    COURSE VARCHAR(6)          NOT NULL,
    BRANCH TEXT       NOT NULL,
    PROGRAM TEXT       NOT NULL,

    PRIMARY KEY (COURSE, BRANCH, PROGRAM),

    FOREIGN KEY (COURSE) REFERENCES Courses(CODE),
    FOREIGN KEY (BRANCH, PROGRAM) REFERENCES Branches(NAME, PROGRAM)

);

CREATE TABLE Registered(
    STUDENT TEXT        NOT NULL,
    COURSE VARCHAR(6)         NOT NULL,

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE Taken(
    STUDENT TEXT         NOT NULL,
    COURSE VARCHAR(6)         NOT NULL,
    GRADE CHAR                 NOT NULL,

    CHECK( GRADE IN ( 'U' ,'3' ,'4' ,'5')),

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE WaitIngList(
    STUDENT TEXT        NOT NULL,
    COURSE VARCHAR(6)       NOT NULL,
    POSITION INT           NOT NULL,

    UNIQUE (COURSE, POSITION),

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES LimitedCourses(CODE)


);

CREATE VIEW  BasicInformation
AS SELECT  IDNR, NAME, LOGIN, Students.PROGRAM, BRANCH
FROM       Students
LEFT JOIN  StudentBranches
ON         Students.IDNR = StudentBranches.STUDENT;

CREATE VIEW       FinishedCourses
AS SELECT         Taken.student, Taken.course, Taken.grade, Courses.credits
FROM              Taken
LEFT JOIN         Courses
ON                TAKEN.COURSE = Courses.CODE;

CREATE VIEW    PassedCourses
AS SELECT      student, course, Courses.CREDITS
FROM           Taken
LEFT JOIN      Courses
ON             TAKEN.COURSE = Courses.CODE
WHERE GRADE NOT LIKE '%U%';

CREATE VIEW Registrations
AS SELECT   Registered.STUDENT, Registered.COURSE, 'registered' AS STATUS FROM Registered
UNION
SELECT      WaitIngList.STUDENT, WaitIngList.COURSE,'waiting' AS STATUS FROM WaitIngList;

CREATE VIEW UnreadMandatory AS
SELECT StudentBranches.student, mandatorybranch.course
FROM
StudentBranches JOIN mandatorybranch
ON StudentBranches.program = mandatorybranch.program AND StudentBranches.BRANCH = mandatorybranch.BRANCH
UNION
SELECT students.idnr, mandatoryprogram.course
FROM
students JOIN mandatoryprogram
ON Students.PROGRAM = mandatoryprogram.program
EXCEPT
SELECT PassedCourses.student, PassedCourses.course
FROM PassedCourses;

CREATE VIEW PathToGraduation AS
    WITH
    totalCredits AS (SELECT PassedCourses.student, SUM(PassedCourses.CREDITS) AS totalCredits FROM PassedCourses
         GROUP BY PassedCourses.student),
    mandatoryLeft AS (SELECT UnreadMandatory.student, count(unreadmandatory.student) AS mandatoryLeft from UnreadMandatory
         GROUP BY UnreadMandatory.student),
    mathCredits AS (select PassedCourses.student, SUM(passedcourses.credits) AS mathCredits from PassedCourses
        left outer join Classified on PassedCourses.course = Classified.COURSE
        where CLASSIFICATION = 'math'
         GROUP BY PassedCourses.student, passedcourses.credits),
    researchCredits AS (select PassedCourses.student, SUM(passedcourses.credits) AS researchCredits from PassedCourses
        left outer join Classified on PassedCourses.course = Classified.COURSE
        where CLASSIFICATION = 'research'
         GROUP BY PassedCourses.student, passedcourses.credits),
    seminarCourses AS (select PassedCourses.student, passedcourses.credits, COUNT(PassedCourses.CREDITS) AS seminarcourses from PassedCourses
        left outer join Classified on PassedCourses.course = Classified.COURSE
        where CLASSIFICATION = 'seminar'
        GROUP BY PassedCourses.student, passedcourses.credits),
    recommended AS (select passedcourses.student, passedcourses.course, PassedCourses.CREDITS from PassedCourses
        intersect
        select StudentBranches.student, recommendedbranch.course, Courses.credits from StudentBranches
        left outer join recommendedbranch on StudentBranches.BRANCH = RecommendedBranch.BRANCH AND StudentBranches.PROGRAM = RecommendedBranch.PROGRAM
        LEFT OUTER JOIN Courses on RecommendedBranch.COURSE = Courses.CODE)
    SELECT IDNR AS student,
        COALESCE(totalCredits,0) AS totalCredits,
        COALESCE(mandatoryLeft,0) AS mandatoryLeft,
        COALESCE(mathCredits,0) AS mathCredits,
        COALESCE(researchCredits,0) AS researchCredits ,
        COALESCE(seminarCourses,0) AS seminarCourses,
        CASE WHEN BOOL(totalCredits >= 100 AND COALESCE(mandatoryLeft,0) = 0 AND COALESCE(mathCredits,0) >= 20 AND COALESCE(researchCredits,0) >= 10 AND count(seminarcourses) >= 1 AND recommended.CREDITS >= 10) THEN TRUE ELSE FALSE END AS qualified
        FROM students
    left outer join totalCredits on IDNR = totalCredits.student
    left outer join mandatoryLeft on IDNR = mandatoryLeft.student
    left outer join mathCredits on IDNR = mathCredits.student
    left outer join researchCredits on IDNR = researchCredits.student
    left outer join seminarCourses on IDNR = seminarCourses.student
    LEFT OUTER JOIN recommended ON IDNR = recommended.student
    GROUP BY IDNR, totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, recommended.CREDITS
    order by IDNR asc;

CREATE VIEW CourseQueuePositions AS
SELECT WaitIngList.COURSE AS course, WaitIngList.STUDENT AS student, WaitIngList.POSITION AS place
FROM WaitingList;



INSERT INTO Department VALUES ('Dep1', 'DN1');
INSERT INTO Department VALUES ('Dep2', 'DN"');

INSERT INTO Programs VALUES ('Prog1', 'DATA');
INSERT INTO Programs VALUES ('Prog2', 'ELEKTRO');


INSERT INTO Branches VALUES ('B1','Prog1');
INSERT INTO Branches VALUES ('B2','Prog1');
INSERT INTO Branches VALUES ('B1','Prog2');

INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');

INSERT INTO StudentBelongsTo VALUES ('1111111111','N1','ls1','Prog1','B1');
INSERT INTO StudentBelongsTo VALUES ('2222222222','N2','ls2','Prog1','B1');
INSERT INTO StudentBelongsTo VALUES ('3333333333','N3','ls3','Prog2','B1');
INSERT INTO StudentBelongsTo VALUES ('4444444444','N4','ls4','Prog1','B2');
INSERT INTO StudentBelongsTo VALUES ('5555555555','Nx','ls5','Prog2','B1');
INSERT INTO StudentBelongsTo VALUES ('6666666666','Nx','ls6','Prog2','B1');

INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dep1');
INSERT INTO Courses VALUES ('CCC222','C2',20,'Dep1');
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dep1');
INSERT INTO Courses VALUES ('CCC444','C4',40,'Dep1');
INSERT INTO Courses VALUES ('CCC555','C5',50,'Dep1');

INSERT INTO Prerequisite VALUES ('CCC333', 'CCC111');
INSERT INTO Prerequisite VALUES ('CCC555', 'CCC444');
INSERT INTO Prerequisite VALUES ('CCC222', 'CCC111');

INSERT INTO LimitedCourses VALUES ('CCC222',1);
INSERT INTO LimitedCourses VALUES ('CCC333',2);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');


INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B1','Prog2');
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC555', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');

INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC333','5');
INSERT INTO Taken VALUES('5555555555','CCC444','5');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');