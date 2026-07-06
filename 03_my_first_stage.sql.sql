--Step 1 — Setup context
USE DATABASE my_first_db;
USE SCHEMA my_schema;
USE WAREHOUSE compute_wh;

--Step 2 — Create a table
CREATE OR REPLACE TABLE employees(
    emp_id      NUMBER,
    emp_name    VARCHAR(100),
    department  VARCHAR(100),
    salary      NUMBER,
    joining_date DATE

);

--confirming
SHOW TABLES;
DESC TABLE employees;

--Step 3 — Create a Named Stage
CREATE OR REPLACE STAGE my_first_stage;

--Step 4 — Check the stage was created
SHOW STAGES;

--Step 5 — See what's inside the stage
LIST @my_first_stage; --Will be empty right now — no files uploaded ye

--7. The COPY INTO Command — The Heart of Ingestion
--Once your file is in the stage, you load it into the table using: REFER TO WORD FILE FOR EXTRA EXPLAINATION
COPY INTO employees
FROM @my_first_stage/employee.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
);

