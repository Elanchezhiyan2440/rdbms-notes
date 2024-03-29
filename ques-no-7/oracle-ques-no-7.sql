--a. DDL to implement the schema:
CREATE TABLE CUSTOMER (
    CID NUMBER PRIMARY KEY,
    CNAME VARCHAR2(255) NOT NULL
);

CREATE TABLE BRANCH (
    BCODE NUMBER PRIMARY KEY,
    BNAME VARCHAR2(255) NOT NULL
);

CREATE TABLE ACCOUNT (
    ANO NUMBER PRIMARY KEY,
    ATYPE CHAR(1) CHECK (ATYPE IN ('S', 'C')),
    BALANCE NUMBER(10,2) NOT NULL,
    CID NUMBER,
    BCODE NUMBER,
    CONSTRAINT FK_CUSTOMER FOREIGN KEY (CID) REFERENCES CUSTOMER(CID),
    CONSTRAINT FK_BRANCH FOREIGN KEY (BCODE) REFERENCES BRANCH(BCODE)
);

CREATE TABLE TRANSACTION (
    TID NUMBER PRIMARY KEY,
    ANO NUMBER,
    TTYPE CHAR(1) CHECK (TTYPE IN ('D', 'W')),
    TTDATE DATE,
    TAMOUNT NUMBER(10,2) NOT NULL,
    CONSTRAINT FK_ACCOUNT FOREIGN KEY (ANO) REFERENCES ACCOUNT(ANO)
);

--b. Populate the database with a rich data set:

-- Insert data into CUSTOMER table
INSERT INTO CUSTOMER VALUES (1, 'Customer1');
INSERT INTO CUSTOMER VALUES (2, 'Customer2');

-- Insert data into BRANCH table
INSERT INTO BRANCH VALUES (101, 'Branch1');
INSERT INTO BRANCH VALUES (102, 'Branch2');

-- Insert data into ACCOUNT table
INSERT INTO ACCOUNT VALUES (201, 'S', 5000.00, 1, 101);
INSERT INTO ACCOUNT VALUES (202, 'C', 10000.00, 1, 102);
INSERT INTO ACCOUNT VALUES (203, 'S', 8000.00, 2, 101);

-- Insert data into TRANSACTION table
INSERT INTO TRANSACTION VALUES (301, 201, 'D', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 1000.00);
INSERT INTO TRANSACTION VALUES (302, 202, 'W', TO_DATE('2023-01-02', 'YYYY-MM-DD'), 500.00);
INSERT INTO TRANSACTION VALUES (303, 203, 'D', TO_DATE('2023-01-03', 'YYYY-MM-DD'), 2000.00);

--c. SQL query to list the details of customers who have a savings account and a current account:
SELECT DISTINCT C.CID, C.CNAME
FROM CUSTOMER C
JOIN ACCOUNT A1 ON C.CID = A1.CID AND A1.ATYPE = 'S'
JOIN ACCOUNT A2 ON C.CID = A2.CID AND A2.ATYPE = 'C';

--d.SQL query to list the details of branches and the number of accounts in each branch:
SELECT B.BCODE, B.BNAME, COUNT(A.ANO) AS NUM_ACCOUNTS
FROM BRANCH B
LEFT JOIN ACCOUNT A ON B.BCODE = A.BCODE
GROUP BY B.BCODE, B.BNAME;

--e.SQL query to list the details of branches where the number of accounts is less than the average number of accounts in all branches:
SELECT B.BCODE, B.BNAME, COUNT(A.ANO) AS NUM_ACCOUNTS
FROM BRANCH B
LEFT JOIN ACCOUNT A ON B.BCODE = A.BCODE
GROUP BY B.BCODE, B.BNAME
HAVING COUNT(A.ANO) < (SELECT AVG(COUNT(ANO)) FROM ACCOUNT GROUP BY BCODE);

--f. SQL query to list the details of customers who have performed three transactions on a day:
SELECT DISTINCT C.CID, C.CNAME
FROM CUSTOMER C
JOIN ACCOUNT A ON C.CID = A.CID
JOIN TRANSACTION T ON A.ANO = T.ANO
WHERE T.TTDATE IN (SELECT TTDATE FROM TRANSACTION GROUP BY TTDATE HAVING COUNT(TID) = 3);

--g.Create a view that will keep track of branch details and the number of accounts in each branch:
CREATE VIEW BranchAccountCount AS
SELECT B.BCODE, B.BNAME, COUNT(A.ANO) AS NUM_ACCOUNTS
FROM BRANCH B
LEFT JOIN ACCOUNT A ON B.BCODE = A.BCODE
GROUP BY B.BCODE, B.BNAME;

--h. Database trigger to not permit a customer to perform more than three transactions on a day:
CREATE OR REPLACE TRIGGER CheckTransactionLimit
BEFORE INSERT ON TRANSACTION
FOR EACH ROW
DECLARE
    TransactionCount NUMBER;
BEGIN
    SELECT COUNT(*) INTO TransactionCount
    FROM TRANSACTION
    WHERE ANO = :NEW.ANO AND TTDATE = :NEW.TTDATE;

    IF TransactionCount >= 3 THEN
        raise_application_error(-20001, 'Customer has reached the daily transaction limit.');
    END IF;
END;
/

--i. Database trigger to update the value of BALANCE in ACCOUNT table:
CREATE OR REPLACE TRIGGER UpdateAccountBalance
BEFORE INSERT ON TRANSACTION
FOR EACH ROW
BEGIN
    IF :NEW.TTYPE = 'D' THEN
        UPDATE ACCOUNT SET BALANCE = BALANCE + :NEW.TAMOUNT WHERE ANO = :NEW.ANO;
    ELSIF :NEW.TTYPE = 'W' THEN
        IF (SELECT ATYPE FROM ACCOUNT WHERE ANO = :NEW.ANO) = 'S' THEN
            UPDATE ACCOUNT SET BALANCE = BALANCE - :NEW.TAMOUNT WHERE ANO = :NEW.ANO AND BALANCE >= 2000.00;
        ELSIF (SELECT ATYPE FROM ACCOUNT WHERE ANO = :NEW.ANO) = 'C' THEN
            UPDATE ACCOUNT SET BALANCE = BALANCE - :NEW.TAMOUNT WHERE ANO = :NEW.ANO AND BALANCE >= 5000.00;
        ELSE
            raise_application_error(-20002, 'Invalid account type.');
        END IF;
    END IF;
END;
/
