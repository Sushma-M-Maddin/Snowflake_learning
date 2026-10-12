--Restaurant application generates this order:

-- Order ID:       1001
-- Customer ID:    501
-- Restaurant ID:  25
-- Amount:         ₹450
-- Status:         DELIVERED
-- Order Date:     2026-09-28

--Goal => Restaurant application -> Snowflake

--1. COPY INTO = Batch file Loading
====================================================================
-- Suppose RestaurantIQ doesn't need every order immediately.

-- Every night, the application generates a CSV file:

-- orders_2026_09_28.csv

-- Contents:

-- order_id,customer_id,restaurant_id,amount,status,order_date
-- 1001,501,25,450,DELIVERED,2026-09-28
-- 1002,502,30,700,DELIVERED,2026-09-28
-- 1003,503,25,300,CANCELLED,2026-09-28

-- The file is uploaded to Amazon S3:
-- Restaurant Application
--         ↓
-- orders_2026_09_28.csv
--         ↓
--        S3

--STEP 01 : Create the table
CREATE TABLE orders(
    order_id NUMBER,
    customer_id NUMBER,
    restaurant_id NUMBER,
    amount NUMBER(10,2),
    status VARCHAR,
    order_date DATE
);
--STEP 02 : Create a stage(stage gives snowflake a location from whcih it can access the files)

-- S3
--  ↓
-- orders_2026_09_28.csv
--  ↓
-- External Stage

--Example : 
CREATE STAGE orders_stage
URL = 's3://restaurant-data/orders/';

--STEP 03 : Load the file
COPY INTO orders
FROM @orders_stage
FILE FORMAT(
    TYPE = CSV,
    SKIP_HEADER = 1
);
--Snowflake reads the file and loads the rows

--STEP 04 :
SELECT * FROM orders;

--RESULT : 
-- | order_id | customer_id | restaurant_id | amount | status    | order_date |
-- | -------: | ----------: | ------------: | -----: | --------- | ---------- |
-- |     1001 |         501 |            25 |    450 | DELIVERED | 2026-09-28 |
-- |     1002 |         502 |            30 |    700 | DELIVERED | 2026-09-28 |
-- |     1003 |         503 |            25 |    300 | CANCELLED | 2026-09-28 |


--Why this is called batch loading?
--Because we are laoding a group / batch of records at once.

--When would you use it?
--For workload such as every hour, every night, every dat, every week where immediate ingestion is not necessary

--2. Snowpipe = Continous file loading

-- RestaurantIQ says:

-- "We receive order files throughout the day. We don't want to wait until midnight."

-- Suppose files arrive:

-- 10:00 → orders_001.csv
-- 10:05 → orders_002.csv
-- 10:12 → orders_003.csv
-- 10:18 → orders_004.csv
-- ...

-- You don't want someone manually running: COPY INTO orders.... on every time new file arrives that's where Snowpipe comes in.

--Snowpipe flow :
-- Application
--      ↓
-- CSV/JSON files
--      ↓
--     S3
--      ↓
--   Snowpipe
--      ↓
-- Snowflake table

--The main idea is : When new files arrive, Snowpipe continously ingests them into Snowflake.
--For Example :
-- 10:00
-- orders_001.csv
--      ↓
-- Snowpipe
--      ↓
-- Snowflake

-- 10:05
-- orders_002.csv
--      ↓
-- Snowpipe
--      ↓
-- Snowflake

-- 10:12
-- orders_003.csv
--      ↓
-- Snowpipe
--      ↓
-- Snowflake

--STEP 01 : Create the table
CREATE TABLE orders(
    order_id NUMBER,
    customer_id NUMBER,
    restaurant_id NUMBER,
    amount NUMBER(10,2),
    status VARCHAR
);
--STEP 02 : Create a file format
CREATE FILE FORMAT orders_csv_format
TYPE = CSV
SKIP_HEADER=1;
--This tells snowflake that incoming files are CSV files and the first row contains column headers

--STEP 03:
--Suppose if our files are in : s3://restaurant-data/orders/

--We are creating an external stage:
CREATE STAGE orders_stage
URL ='s3://restaurant-data/orders/';
--IN real production setup, you'd normally use storage integration/appropriate cloud authentication rather than putting cloud credentials dierectly in SQL.

--STEP 04 : Create the snowpipe
CREATE PIPE orders_pipe 
AS
COPY INTO orders 
FROM orders_stage
FILE_FORMAT(
    FORMAT_NAME = 'orders_csv_format'
);

--But wait how does Snowpipe know that a new file arrived 
    --There are two broad pieces:
        --1. File arrives
        --2. Snowfalke gets notified
        --3. Snowpipe process the file
--For cloud storage this can be cloud event notifications.

--Snowpipe, there are two main mechanism for notifying the new staged files.
    --1. Automating Snowpipe using cloud messaging
    --2. Calling Snowpipe REST endpoints

--1. Automating Snowpipe using cloud messaging(event driven approach)

--Example: S3
-- Suppose
    -- S3 bucket
    --    │
    --    ├── orders_001.csv
    --    ├── orders_002.csv
    --    └── orders_003.csv

-- A new file arrives:

-- orders_004.csv

-- S3 generates an event saying essentially:

-- "A new object was created."

-- That event goes through the configured cloud messaging/notification mechanism.

        --         S3
        --          │
        --   New file arrives
        --          │
        --          ↓
        --   ObjectCreated event
        --          │
        --          ↓
        -- Cloud notification
        --          │
        --          ↓
        -- Notification queue
        --          │
        --          ↓
        --      Snowpipe
        --          │
        --          ↓
        --   ORDERS table

-- Snowpipe polls the event notifications from a queue."

-- That means Snowpipe doesn't necessarily receive a direct phone-call-like notification.
--Instead : 
-- S3
--  ↓
-- Event
--  ↓
-- Queue
--  ↓
-- Snowpipe checks/polls queue
--  ↓
-- Finds new file information
--  ↓
-- Loads file

-- The queue contains information such as:

-- New file:
-- s3://restaurant-data/orders/orders_004.csv

-- Snowpipe uses that information to know what file needs to be loaded.

--2. Calling Snowpipe REST endpoints:
--Here the application tells Snowpipe about the files.

-- Suppose your application uploads:

-- orders_004.csv

-- to the stage.

-- Your application then calls Snowpipe's REST endpoint and says, essentially:

-- "Snowpipe, I have a file called orders_004.csv. Please check the stage and load it."

-- Application
--      │
--      │ REST API request
--      │ "orders_004.csv"
--      ↓
-- Snowpipe REST endpoint
--      │
--      ↓
-- Snowpipe queue
--      │
--      ↓
-- Snowflake table

-- Calling Snowpipe REST endpoints

-- Your client application calls a public REST endpoint with the name of a pipe object and a list of data filenames. If new data files matching the list are discovered in the stage referenced by the pipe object, they are queued for loading. Snowflake-provided compute resources load data from the queue into a Snowflake table based on parameters defined in the pipe.

