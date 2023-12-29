--ORACLE VERSION:
--a
[CREATE TABLE STAFF (
    STAFFNO NUMBER PRIMARY KEY,
    NAME VARCHAR2(255) NOT NULL,
    DOB DATE,
    GENDER CHAR(1) CHECK (GENDER IN ('M', 'F')),
    DOJ DATE,
    DESIGNATION VARCHAR2(255),
    BASIC_PAY NUMBER(10, 2),
    DEPTNO NUMBER,
    CONSTRAINT fk_deptno FOREIGN KEY (DEPTNO) REFERENCES DEPT(DEPTNO)
);

CREATE TABLE DEPT (
    DEPTNO NUMBER PRIMARY KEY,
    NAME VARCHAR2(255) NOT NULL
);

CREATE TABLE SKILL (
    SKILL_CODE NUMBER PRIMARY KEY,
    DESCRIPTION VARCHAR2(255),
    CHARGE_OUTRATE NUMBER(10, 2)
);

CREATE TABLE STAFF_SKILL (
    STAFFNO NUMBER,
    SKILL_CODE NUMBER,
    PRIMARY KEY (STAFFNO, SKILL_CODE),
    CONSTRAINT fk_staff FOREIGN KEY (STAFFNO) REFERENCES STAFF(STAFFNO),
    CONSTRAINT fk_skill FOREIGN KEY (SKILL_CODE) REFERENCES SKILL(SKILL_CODE)
);

CREATE TABLE PROJECT (
    PROJECTNO NUMBER PRIMARY KEY,
    PNAME VARCHAR2(255) NOT NULL,
    START_DATE DATE,
    END_DATE DATE,
    BUDGET NUMBER(15, 2),
    PROJECT_MANAGER VARCHAR2(255),
    STAFFNO NUMBER,
    CONSTRAINT fk_staffno_project FOREIGN KEY (STAFFNO) REFERENCES STAFF(STAFFNO)
);

CREATE TABLE WORKS (
    STAFFNO NUMBER,
    PROJECTNO NUMBER,
    DATE_WORKED_ON DATE,
    IN_TIME TIMESTAMP,
    OUT_TIME TIMESTAMP,
    PRIMARY KEY (STAFFNO, PROJECTNO, DATE_WORKED_ON),
    CONSTRAINT fk_staffno_works FOREIGN KEY (STAFFNO) REFERENCES STAFF(STAFFNO),
    CONSTRAINT fk_projectno_works FOREIGN KEY (PROJECTNO) REFERENCES PROJECT(PROJECTNO)
); ]

--b
[Populating the Database:
Use INSERT INTO statements to add data to each table. ]

--c
[SELECT DEPTNO, COUNT(STAFFNO) AS NUM_OF_STAFF
FROM STAFF
GROUP BY DEPTNO; ]

--d
[SELECT *
FROM STAFF
WHERE BASIC_PAY < (SELECT AVG(BASIC_PAY) FROM STAFF); ]

--e
[SELECT D.*
FROM DEPT D
JOIN (
    SELECT DEPTNO, COUNT(STAFFNO) AS NUM_OF_STAFF
    FROM STAFF
    GROUP BY DEPTNO
    HAVING COUNT(STAFFNO) > 5
) S ON D.DEPTNO = S.DEPTNO; ]

--f
[SELECT S.*
FROM STAFF S
JOIN (
    SELECT STAFFNO, COUNT(SKILL_CODE) AS NUM_OF_SKILLS
    FROM STAFF_SKILL
    GROUP BY STAFFNO
    HAVING COUNT(SKILL_CODE) > 3
) SS ON S.STAFFNO = SS.STAFFNO; ]

--g
[SELECT S.*
FROM STAFF S
JOIN STAFF_SKILL SS ON S.STAFFNO = SS.STAFFNO
JOIN SKILL SK ON SS.SKILL_CODE = SK.SKILL_CODE
WHERE SK.CHARGE_OUTRATE > 60; ]

--h
[CREATE OR REPLACE VIEW DepartmentSummary AS
SELECT D.DEPTNO, D.NAME AS DEPT_NAME, COUNT(S.STAFFNO) AS NUM_OF_EMPLOYEES, SUM(S.BASIC_PAY) AS TOTAL_BASIC_PAY
FROM DEPT D
LEFT JOIN STAFF S ON D.DEPTNO = S.DEPTNO
GROUP BY D.DEPTNO, D.NAME; ]

--i
[CREATE OR REPLACE TRIGGER check_works_limit
BEFORE INSERT ON WORKS
FOR EACH ROW
DECLARE
    projects_count INT;
BEGIN
    SELECT COUNT(PROJECTNO)
    INTO projects_count
    FROM WORKS
    WHERE STAFFNO = :NEW.STAFFNO AND DATE_WORKED_ON = :NEW.DATE_WORKED_ON;

    IF projects_count >= 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Staff is not allowed to work on more than three projects in a day');
    END IF;
END;
/ ]

--j
[CREATE OR REPLACE PROCEDURE INCR(staff_num IN NUMBER, increment_amount IN NUMBER)
IS
    current_basic_pay NUMBER;
BEGIN
    SELECT BASIC_PAY INTO current_basic_pay
    FROM STAFF
    WHERE STAFFNO = staff_num;

    IF current_basic_pay IS NOT NULL THEN
        UPDATE STAFF
        SET BASIC_PAY = BASIC_PAY + increment_amount
        WHERE STAFFNO = staff_num;
        DBMS_OUTPUT.PUT_LINE('Basic pay updated successfully');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Staff has basic pay null');
        RAISE_APPLICATION_ERROR(-20002, 'No such staff number');
    END IF;
END;
/ ]