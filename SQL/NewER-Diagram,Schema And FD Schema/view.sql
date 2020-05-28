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



