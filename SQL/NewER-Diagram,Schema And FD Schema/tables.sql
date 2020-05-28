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
    IDNR numeric(10)                NOT NULL,
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
    s_idnr numeric(10)                NOT NULL,
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
    STUDENT numeric(10)     NOT NULL,
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
    STUDENT numeric(10)         NOT NULL,
    COURSE VARCHAR(6)         NOT NULL,

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE Taken(
    STUDENT numeric(10)         NOT NULL,
    COURSE VARCHAR(6)         NOT NULL,
    GRADE CHAR                 NOT NULL,

    CHECK( GRADE IN ( 'U' ,'3' ,'4' ,'5')),

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES Courses(CODE)

);

CREATE TABLE WaitIngList(
    STUDENT numeric(10)        NOT NULL,
    COURSE VARCHAR(6)       NOT NULL,
    POSITION SERIAL           NOT NULL,

    UNIQUE (COURSE, POSITION),

    PRIMARY KEY (STUDENT, COURSE),

    FOREIGN KEY (STUDENT) REFERENCES Students(IDNR),
    FOREIGN KEY (COURSE) REFERENCES LimitedCourses(CODE)


);
