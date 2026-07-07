-- Tables assignment: create and query test tables in TEST_DATABASE
-- Co-authored with CoCo
--Code to Run Before Hands-on Assignment
CREATE DATABASE test_database;
CREATE SCHEMA test_database.test_schema;

USE DATABASE test_database;
USE SCHEMA test_schema;

CREATE TABLE TEST_TABLE (
	TEST_NUMBER NUMBER,
	TEST_VARCHAR VARCHAR,
	TEST_BOOLEAN BOOLEAN,
	TEST_DATE DATE,
	TEST_VARIANT VARIANT,
	TEST_GEOGRAPHY GEOGRAPHY
);
INSERT INTO TEST_DATABASE.TEST_SCHEMA.TEST_TABLE
  VALUES
  (28, 'ha!', True, '2024-01-01', NULL, NULL);


--1.Question 1: Run the SHOW TABLES command. What value is in the “bytes” column for the test_table row?
SHOW TABLES;

--QUESTION 2: Create a new table in the TEST_DATABASE database and the TEST_SCHEMA schema called “test_table2” with one NUMBER column called TEST_NUMBER. Then insert the value 42 into it using the INSERT INTO command.
--Then use the SHOW TABLES command. What value is in the “bytes” column for the test_table2 row?

CREATE TABLE
test_table2(
TEST_NUMBER NUMBER
);
INSERT INTO TEST_DATABASE.TEST_SCHEMA.TEST_TABLE2 VALUES(42);
SHOW TABLES;

--VIEWS
--1. Question 1: Use the CREATE VIEW command to create a “truck_franchise” view of the following query:
--SELECT
--    t.*,
--    f.first_name AS franchisee_first_name,
--    f.last_name AS franchisee_last_name
--FROM tasty_bytes.raw_pos.truck t
--JOIN tasty_bytes.raw_pos.franchise f
--    ON t.franchise_id = f.franchise_id;

CREATE VIEW tasty_bytes.public.truck_franchise AS
    SELECT
    t.*,
    f.first_name AS franchisee_first_name,
    f.last_name AS franchisee_last_name
FROM tasty_bytes.raw_pos.truck t
JOIN tasty_bytes.raw_pos.franchise f
    ON t.franchise_id = f.franchise_id;

SELECT make 
FROM tasty_bytes.public.truck_franchise
WHERE franchisee_first_name = 'Sara'
AND franchisee_last_name = 'Nicholson';

--2. Use the DESCRIBE VIEW command to see information about the test_database.test_schema.truck_franchise view. What value is in the “type” column for TRUCK_ID?
-- Make sure test_database and test_schema exist
CREATE DATABASE IF NOT EXISTS test_database;
CREATE SCHEMA IF NOT EXISTS test_database.test_schema;

-- Create the view in correct location
CREATE OR REPLACE VIEW test_database.test_schema.truck_franchise AS
SELECT
    t.*,
    f.first_name AS franchisee_first_name,
    f.last_name AS franchisee_last_name
FROM tasty_bytes.raw_pos.truck t
JOIN tasty_bytes.raw_pos.franchise f
    ON t.franchise_id = f.franchise_id;
    
DESC VIEW test_database.test_schema.truck_franchise;

--3. Drop the truck_franchise view using the DROP VIEW command. What is the status message in Results?

DROP VIEW test_database.test_schema.truck_franchise;

--4. Run the CREATE OR REPLACE DYNAMIC TABLE command to create a “truck_franchise_dynamic” table and based it on the same SQL query, reproduced here:

CREATE DYNAMIC TABLE test_database.test_schema.truck_franchise_dynamic
TARGET_LAG = '1 hour'
    WAREHOUSE = compute_wh
AS
SELECT
    t.*,
    f.first_name AS franchisee_first_name,
    f.last_name AS franchisee_last_name
FROM tasty_bytes.raw_pos.truck t
JOIN tasty_bytes.raw_pos.franchise f
    ON t.franchise_id = f.franchise_id;

--Question 5: Use the CREATE DYNAMIC TABLE command to create a “nissan” view in the test_database database and the test_schema schema, based on this SQL query

CREATE OR REPLACE DYNAMIC TABLE test_database.test_schema.nissan
    TARGET_LAG = '5 minutes'
    WAREHOUSE = compute_wh
    AS
SELECT t.*
FROM tasty_bytes.raw_pos.truck t
WHERE t.make = 'Nissan';

SELECT COUNT(*) FROM test_database.test_schema.nissan;

--Drop the “nissan” dynamic table using the DROP DYNAMIC TABLE command. What is the status in the Results?
DROP DYNAMIC TABLE test_database.test_schema.nissan;

--SEMISTRUCTURES ASSIGNMENT

--Question 1: Use the DESCRIBE TABLE command to learn more about the “menu” table in the “raw_pos” schema in the “tasty_bytes” database. What is the value in the “type” column for the row associated with MENU_ITEM_HEALTH_METRICS_OBJ?

DESC TABLE tasty_bytes.raw_pos.menu;

--Use the TYPEOF function to check the underlying data type of MENU_ITEM_HEALTH_METRICS_OBJ. What is it?

SELECT TYPEOF(menu_item_health_metrics_obj) as datatype
FROM tasty_bytes.raw_pos.menu
LIMIT 1;