-- Drop existing tables (to avoid ORA-00955 errors)
DROP TABLE Applications CASCADE CONSTRAINTS;
DROP TABLE JobOffers CASCADE CONSTRAINTS;
DROP TABLE Companies CASCADE CONSTRAINTS;
DROP TABLE Students CASCADE CONSTRAINTS;

-- Students Table
CREATE TABLE Students (
    StudentID      NUMBER PRIMARY KEY,
    FullName       VARCHAR2(100),
    Department     VARCHAR2(50),
    CGPA           NUMBER(3,2),
    Email          VARCHAR2(100),
    Phone          VARCHAR2(15)
);

-- Companies Table
CREATE TABLE Companies (
    CompanyID      NUMBER PRIMARY KEY,
    CompanyName    VARCHAR2(100),
    Industry       VARCHAR2(50),
    ContactEmail   VARCHAR2(100)
);

-- JobOffers Table
CREATE TABLE JobOffers (
    JobID          NUMBER PRIMARY KEY,
    CompanyID      NUMBER REFERENCES Companies(CompanyID),
    RoleTitle      VARCHAR2(100),
    MinCGPA        NUMBER(3,2),
    PackageLPA     NUMBER(5,2)
);

-- Applications Table
CREATE TABLE Applications (
    ApplicationID  NUMBER PRIMARY KEY,
    StudentID      NUMBER REFERENCES Students(StudentID),
    JobID          NUMBER REFERENCES JobOffers(JobID),
    ApplicationDate DATE DEFAULT SYSDATE
);

-- Insert Students
INSERT INTO Students VALUES (1, 'Ravi Kumar', 'CSE', 8.5, 'ravi@uni.edu', '1234567898');
INSERT INTO Students VALUES (2, 'Anita Sharma', 'ECE', 7.8, 'anita@uni.edu', '9876543212');
INSERT INTO Students VALUES (3, 'Rahul Verma', 'IT', 6.5, 'rahul@uni.edu', '9087654321');

-- Insert Companies
INSERT INTO Companies VALUES (101, 'Infosys', 'IT Services', 'hr@infosys.com');
INSERT INTO Companies VALUES (102, 'TCS', 'IT Consulting', 'hr@tcs.com');
INSERT INTO Companies VALUES (103, 'Amazon', 'E-Commerce', 'hr@amazon.com');

-- Insert Job Offers
INSERT INTO JobOffers VALUES (1001, 101, 'Software Engineer', 7.0, 6.5);
INSERT INTO JobOffers VALUES (1002, 102, 'System Analyst', 6.5, 5.8);
INSERT INTO JobOffers VALUES (1003, 103, 'Cloud Intern', 8.0, 8.0);

COMMIT;

-- Procedure to register a new student
CREATE OR REPLACE PROCEDURE RegisterStudent (
    p_StudentID   NUMBER,
    p_FullName    VARCHAR2,
    p_Department  VARCHAR2,
    p_CGPA        NUMBER,
    p_Email       VARCHAR2,
    p_Phone       VARCHAR2
)
IS
BEGIN
    INSERT INTO Students VALUES (p_StudentID, p_FullName, p_Department, p_CGPA, p_Email, p_Phone);
    DBMS_OUTPUT.PUT_LINE('Student Registered Successfully: ' || p_FullName);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: Student ID already exists.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Procedure to register a new company
CREATE OR REPLACE PROCEDURE RegisterCompany (
    p_CompanyID   NUMBER,
    p_CompanyName VARCHAR2,
    p_Industry    VARCHAR2,
    p_Email       VARCHAR2
)
IS
BEGIN
    INSERT INTO Companies VALUES (p_CompanyID, p_CompanyName, p_Industry, p_Email);
    DBMS_OUTPUT.PUT_LINE('Company Registered Successfully: ' || p_CompanyName);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: Company ID already exists.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

EXEC RegisterStudent(4, 'Sneha Patil', 'CSE', 8.9, 'sneha@uni.edu', '9998887771');
EXEC RegisterCompany(104, 'Wipro', 'Consulting', 'hr@wipro.com');

EXEC RegisterStudent(8, 'Sahel', 'CSE', 8.1, 'sahel@uni.edu', '8998887771');
EXEC RegisterCompany(105, 'cigna', 'Developer', 'hr@cigna.com');

CREATE OR REPLACE FUNCTION CheckEligibility (
p_StudentID NUMBER,
p_JobID NUMBER
)
RETURN VARCHAR2
IS
v_CGPA NUMBER;
v_MinCGPA NUMBER;
BEGIN
SELECT CGPA INTO v_CGPA FROM Students WHERE StudentID = p_StudentID;
SELECT MinCGPA INTO v_MinCGPA FROM JobOffers WHERE JobID = p_JobID;

IF v_CGPA >= v_MinCGPA THEN
RETURN 'Eligible';
ELSE
RETURN 'Not Eligible';
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
RETURN 'Invalid Student or Job ID';
WHEN OTHERS THEN
RETURN 'Error: ' || SQLERRM;
END;
/

-- Example usage:
SELECT CheckEligibility(1, 1003) AS Eligibility FROM DUAL;

CREATE OR REPLACE TRIGGER PreventDuplicateApplication
BEFORE INSERT ON Applications
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Applications
    WHERE StudentID = :NEW.StudentID AND JobID = :NEW.JobID;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Duplicate application not allowed.');
    END IF;
END;
/

-- Test the trigger
INSERT INTO Applications VALUES (1, 1, 1001, SYSDATE);  -- First insert allowed
--INSERT INTO Applications VALUES (2, 1, 1001, SYSDATE);  -- Second insert blocked

CREATE OR REPLACE VIEW Student_Applications_View AS
SELECT s.FullName,
       s.Department,
       c.CompanyName,
       j.RoleTitle,
       a.ApplicationDate
FROM Applications a
JOIN Students s ON a.StudentID = s.StudentID
JOIN JobOffers j ON a.JobID = j.JobID
JOIN Companies c ON j.CompanyID = c.CompanyID;

CREATE MATERIALIZED VIEW Company_Recruitment_Summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT c.CompanyName,
       COUNT(a.ApplicationID) AS TotalApplications,
       AVG(s.CGPA) AS AvgStudentCGPA
FROM Applications a
JOIN Students s ON a.StudentID = s.StudentID
JOIN JobOffers j ON a.JobID = j.JobID
JOIN Companies c ON j.CompanyID = c.CompanyID
GROUP BY c.CompanyName;

-- View all students
SELECT * FROM Students;

-- View all companies
SELECT * FROM Companies;

-- Check student eligibility
SELECT CheckEligibility(2, 1002) FROM DUAL;

-- View dashboard summaries
SELECT * FROM Student_Applications_View;
SELECT * FROM Company_Recruitment_Summary;
