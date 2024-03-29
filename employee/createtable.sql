--Employee 
--POSTGRES VERSION:

--Create tables:
CREATE TABLE DEPARTMENT(DCODE SMALLINT PIMARY KEY, DNAME VARCHAR(20));
CREATE TABLE EMPLOYEE(ENO BIGINT PRIMARY KEY, ENAME VARCHAR(20), DOB DATE, GENDER CHAR CHECK(GENDER IN ('M','F')), DOJ DATE, DESIGNATION VARCHAR(20), BASIC BIGINT, DCODE SMALLINT, FOREIGN KEY (DCODE) REFERENCES DEPARTMENT (DCODE), PAN VARCHAR(10));

--Create views:
CREATE VIEW DEPT_VIEW AS SELECT D.DCODE, D.DNAME, E.ENO, E.ENAME, E.DESIGNATION, E.BASIC FROM DEPARTMENT D, EMPLOYEE E WHERE D.DCODE = E.DCODE;