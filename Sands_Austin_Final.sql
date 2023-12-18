/*
File:   Sands_Austin_Final.sql
Author: Austin Sands
Date:   04/24/2022
Purpose: This file is for my final presentation for course CSCI-N311 Spring 2022.
The code requires my midterm database enable to properly run
*/

/* #8 */
-- create a package for inspection management.

CREATE OR REPLACE PACKAGE INSP_MANAGEMENT
AS
    FUNCTION fn_create_insp_job( aircraft IN CHAR, fix_emp IN NUMBER, insp_id IN NUMBER) RETURN NUMBER;
    PROCEDURE sp_complete_insp( insp_id IN NUMBER, emp_id IN NUMBER);
END INSP_MANAGEMENT;
/

CREATE OR REPLACE PACKAGE BODY INSP_MANAGEMENT
AS
/* #6 1/2, #1*/

-- create inspection job function. This function will take an aircraft, employee number, and inspection id
-- and generate the information needed to create a maintenance job for a completed inspection
-- and then automatically create said job. 
-- DROP FUNCTION fn_create_insp_job;
FUNCTION fn_create_insp_job( aircraft IN CHAR, fix_emp IN NUMBER, insp_id IN NUMBER) 
RETURN NUMBER 
IS
new_jcn NUMBER(9);
find_desc VARCHAR(80);
fix_desc VARCHAR(80);

BEGIN

    -- set find_desc with inspection information
    find_desc := 'INSPECTION ' || insp_id || ' DUE.';
    
    -- set fix_desc with inspection information
    fix_desc := 'INSPECTION ' || insp_id || ' COMPLIED WITH.';

    -- insert a mainteance job into MAINTENANCE table with inspection info
    INSERT INTO MAINTENANCE(AIRCRAFT, FIND_MECHANIC, FIND_DATE, ERROR_DESC, FIX_MECHANIC, FIX_DATE, FIX_DESC) 
        VALUES (aircraft, fix_emp, SYSDATE, find_desc, fix_emp, SYSDATE, fix_desc);
    
    -- get newly created job control number from new job
    SELECT JOB_CONTROL_NUMBER INTO new_jcn  FROM MAINTENANCE
        WHERE FIX_DATE = SYSDATE AND FIX_DESC = fix_desc;
    
    RETURN(new_jcn);
END fn_create_insp_job;


/* #7 1/2 procedure, #4 2/2 User Created and system defined exceptions, #2 if/else , #1 variables  */

-- complete inspection procedure. This procedure will take an inspection ID and 
-- employee ID and update the inspection schedule. If the inspection is not 
-- actually due, will throw an error.
-- DROP PROCEDURE sp_complete_insp;
PROCEDURE sp_complete_insp( insp_id IN NUMBER, emp_id IN NUMBER) 
AS
    aircraft CHAR(6);
    current_date DATE;
    due_date DATE;
    not_due_error EXCEPTION;
    
BEGIN
    
    -- set current date using SYSDATE
    current_date := TO_DATE(SYSDATE, 'DD-MM-YYYY');
    
    -- get aircraft from inspection schedule and store in variable
    SELECT AIRCRAFT INTO aircraft FROM INSPECTION_SCHEDULE
        WHERE INSPECTION_ID = insp_id;
        
    
    -- get due date from inspection schedule
    SELECT DATE_NEXT_INSP INTO due_date FROM INSPECTION_SCHEDULE
        WHERE INSPECTION_ID = insp_id;
        
    
    -- check if inspection due date is later than current date
    IF (TO_DATE(due_date, 'DD-MM-YYYY') > current_date) THEN
    
        -- if date not after due_date, then raise error
        RAISE not_due_error;
    ELSE
    
        -- if date after due date, allow inspection log, update INSPECTION_SCHEDULE
        UPDATE INSPECTION_SCHEDULE
            SET DATE_LAST_INSP = current_date
            WHERE INSPECTION_ID = insp_id;
           
        -- create an entry in the MAINTENANCE table with CREATE_INSP_JOB function and output to DBMS the JCN for job
        DBMS_OUTPUT.PUT_LINE('JOB FOR INSPECTION ' || insp_id || ' CREATED. JCN IS ' ||  fn_create_insp_job(aircraft, emp_id, insp_id));
        
    END IF;
    
EXCEPTION
    
-- catches no data when inps_id isn't found in schedule
WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('NO INSPECTION FOUND WITH ID: ' || insp_id);
    
-- catches an error that the inspection trying to be completed is not actually due. 
-- In aircraft maintenance, it is important to not complete maintenance before it is necessary
-- so this exception works to ensure this doesn't happen.
WHEN not_due_error THEN
    DBMS_OUTPUT.PUT_LINE('INSPECTION ' || insp_id || ' IS NOT DUE.');
    
END sp_complete_insp;

END INSP_MANAGEMENT;
/

SELECT * FROM INSPECTION_SCHEDULE;

-- test procedure and function
-- test exception handling
EXECUTE INSP_MANAGEMENT.sp_complete_insp(6000, 10007);
EXECUTE INSP_MANAGEMENT.sp_complete_insp(6008, 10007);

SELECT * FROM INSPECTION_SCHEDULE;

-- test proper operation
EXECUTE INSP_MANAGEMENT.sp_complete_insp(6004, 10007);

SELECT * FROM INSPECTION_SCHEDULE;
SELECT * FROM MAINTENANCE;

/* #5 1/2 update trigger */
-- create trigger on MAINTENANCE update to ensure that if fix_mechanic is added
-- a fix_date and fix_desc is added as well.

CREATE OR REPLACE TRIGGER MAINTENANCE_BEF_UPD_ROW
    BEFORE UPDATE OF FIX_MECHANIC, FIX_DATE, FIX_DESC ON MAINTENANCE
    FOR EACH ROW
DECLARE
    empty_fix EXCEPTION;
    null_column VARCHAR(15);
    new_mech NUMBER;
    new_date DATE;
    new_desc VARCHAR(280);
BEGIN

    -- get values from updated fix_mechanic, fix_date, and fix_desc
    new_mech := :NEW.FIX_MECHANIC;
    new_date := :NEW.FIX_DATE;
    new_desc := :NEW.FIX_DESC;

    -- check updated rows for NULL fix_mechanic, date, or description
    IF (new_mech IS NULL) THEN
        -- set null_column for exception handling
        null_column := 'FIX MECHANIC';
        
        RAISE empty_fix;
    ELSIF (new_date IS NULL) THEN
        -- set null_column for exception handling
        null_column := 'FIX DATE';
        
        RAISE empty_fix;
    ELSIF (new_desc IS NULL) THEN
        -- set null_column for exception handling
        null_column := 'FIX DESCRIPTION';
        
        RAISE empty_fix;
    END IF;
    
EXCEPTION
WHEN empty_fix THEN
    DBMS_OUTPUT.PUT_LINE('NULL VALUE ENTERED IN ' || null_column);
    
    RAISE_APPLICATION_ERROR (-20001, 'NULL_VALUE');
    
END;
/

-- test MAINTENANCE_BEF_UPD_ROW
UPDATE MAINTENANCE
    SET FIX_DESC = 'THIS SHOULD NOT WORK'
    WHERE JOB_CONTROL_NUMBER = 202200004; 

UPDATE MAINTENANCE
    SET FIX_DESC = 'THIS SHOULD WORK',
        FIX_MECHANIC = 10007,
        FIX_DATE = SYSDATE
    WHERE JOB_CONTROL_NUMBER = 202200004; 
    
SELECT * FROM MAINTENANCE;

/* #1 loop and variables, #3 uses cursor to get records, #7 2/2 procedure */

-- create table to hold old maintenance activites as copy of maintenance
DROP TABLE LOG_MAINTENANCE;
CREATE TABLE LOG_MAINTENANCE AS SELECT * FROM MAINTENANCE WHERE 1=0;

-- create table to hold old orders as copy of ORDER_PARTS
DROP TABLE LOG_ORDERS;
CREATE TABLE LOG_ORDERS AS SELECT * FROM ORDER_PARTS WHERE 1=0;

-- this procedure takes a number as a parameter and offsets the SYSDATE by that 
-- many days previously. It uses this number as a cutoff date. All fixed mainteance 
-- jobs before this cutoff will be removed from maintenance table and added to 
-- log_maintenance table.
CREATE OR REPLACE PROCEDURE sp_clean_maintenance (day_difference NUMBER)
AS
    CURSOR jcn_cursor IS
        SELECT JOB_CONTROL_NUMBER FROM MAINTENANCE;
    
    CURSOR order_cursor IS 
        SELECT ORDER_NUMBER FROM ORDER_PARTS;
    
    jcn NUMBER;
    order_num NUMBER;
    order_jcn NUMBER;
    cutoff_date DATE;
    current_fix_date DATE;
        
BEGIN
    -- set cuttoff date
    cutoff_date := TO_DATE(SYSDATE - day_difference, 'DD-MM-YYYY');
    
    -- open the JCN cursor
    OPEN jcn_cursor;
    
    LOOP
        -- fetch next row and exit when no next row found
        FETCH jcn_cursor INTO jcn;
        EXIT WHEN jcn_cursor%NOTFOUND;
        
        
        --get fix_date from current record
        SELECT TO_DATE(FIX_DATE, 'DD-MM-YYYY') INTO current_fix_date FROM MAINTENANCE 
            WHERE JOB_CONTROL_NUMBER = jcn;
        
        
        -- if fix_date in row is before cutoff date, then copy row to LOG_MAINTENANCE
        -- and delete from MAINTENANCE
        IF (current_fix_date < cutoff_date AND current_fix_date IS NOT NULL) THEN
            
            -- copy row into log_maintenance
            INSERT INTO LOG_MAINTENANCE SELECT * FROM MAINTENANCE
                WHERE JOB_CONTROL_NUMBER = jcn;
            
            -- move and delete any orders that may exist as children of this job
            INSERT INTO LOG_ORDERS SELECT * FROM ORDER_PARTS
                WHERE ORDER_JOB = jcn;
                
            -- delete order from ORDER_PARTS
            DELETE FROM ORDER_PARTS WHERE ORDER_JOB = jcn;
            
            -- delete row from maintenance
            DELETE FROM MAINTENANCE WHERE JOB_CONTROL_NUMBER = jcn;
            
        END IF;
    
    END LOOP;

    -- close cursor after loop complete
    CLOSE jcn_cursor;

END;
/

SELECT * FROM MAINTENANCE;

-- test procedure
EXECUTE sp_clean_maintenance(70);

SELECT * FROM MAINTENANCE;

/* #5 2/2 INSERT TRIGGER*/

-- create a table to hold job counts by day
DROP TABLE DAILY_JOB_COUNT;
CREATE TABLE DAILY_JOB_COUNT(
    JOB_COUNT NUMBER,
    LOG_DATE DATE
);

-- an insert trigger to track how many jobs have been created each day
CREATE OR REPLACE TRIGGER MAINTENANCE_AFT_INS_ROW
    AFTER INSERT ON MAINTENANCE
    FOR EACH ROW

DECLARE
    job_count NUMBER;
    previous_count NUMBER;
    
BEGIN

    
    -- get count of log entries for the day
    SELECT COUNT(*) INTO previous_count FROM DAILY_JOB_COUNT
        WHERE TO_DATE(LOG_DATE, 'DD-MM-YYYY') = TO_DATE(SYSDATE, 'DD-MM-YYYY');
        
        --DBMS_OUTPUT.PUT_LINE(current_date);
    
    -- check if already a log for the day
    IF (previous_count > 0) THEN
     -- if job count for day already exists, update
        -- get count jobs created today
        SELECT JOB_COUNT INTO job_count FROM DAILY_JOB_COUNT
            WHERE TO_DATE(LOG_DATE, 'DD-MM-YYYY') = TO_DATE(SYSDATE, 'DD-MM-YYYY');
        
        UPDATE DAILY_JOB_COUNT
            SET JOB_COUNT = job_count + 1
            WHERE TO_DATE(LOG_DATE, 'DD-MM-YYYY') = TO_DATE(SYSDATE, 'DD-MM-YYYY');
    ELSE
        -- if not then start job count at 1
        INSERT INTO DAILY_JOB_COUNT VALUES(1, SYSDATE);
    END IF;

END;
/
    
-- insert rows to test
INSERT INTO MAINTENANCE(AIRCRAFT, FIND_MECHANIC, FIND_DATE, ERROR_DESC) VALUES ('912459', 10019, DATE '2022-02-23', 'TEST RECORD.');
INSERT INTO MAINTENANCE(AIRCRAFT, FIND_MECHANIC, FIND_DATE, ERROR_DESC) VALUES ('912459', 10019, DATE '2022-02-23', 'TEST RECORD.');
INSERT INTO MAINTENANCE(AIRCRAFT, FIND_MECHANIC, FIND_DATE, ERROR_DESC) VALUES ('912459', 10019, DATE '2022-02-23', 'TEST RECORD.');
-- check DAILY_JOB_COUNT
SELECT * FROM DAILY_JOB_COUNT;
-- insert rows to test
INSERT INTO MAINTENANCE(AIRCRAFT, FIND_MECHANIC, FIND_DATE, ERROR_DESC) VALUES ('912459', 10019, DATE '2022-02-23', 'TEST RECORD.');
-- check DAILY_JOB_COUNT
SELECT * FROM DAILY_JOB_COUNT;