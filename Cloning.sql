USE WAREHOUSE compute_wh;

-- Step 1: See current truck data
SELECT truck_id, year 
FROM tasty_bytes.raw_pos.truck_dev 
LIMIT 5;

-- Step 2: Save timestamp
SET my_timestamp = CURRENT_TIMESTAMP();

-- Step 3: Corrupt the data
UPDATE tasty_bytes.raw_pos.truck_dev
SET year = 1024;

-- Step 4: Verify corruption
SELECT truck_id, year 
FROM tasty_bytes.raw_pos.truck_dev 
LIMIT 5;
-- All years show 1024

-- Step 5: Clone from before corruption
CREATE OR REPLACE TABLE tasty_bytes.raw_pos.truck_dev_restored
    CLONE tasty_bytes.raw_pos.truck_dev
    AT (TIMESTAMP => $my_timestamp);

-- Step 6: Verify restored data
SELECT truck_id, year 
FROM tasty_bytes.raw_pos.truck_dev_restored 
LIMIT 5;
-- Correct years

-- Step 7: Swap tables
ALTER TABLE tasty_bytes.raw_pos.truck_dev 
    RENAME TO tasty_bytes.raw_pos.truck_dev_corrupted;

ALTER TABLE tasty_bytes.raw_pos.truck_dev_restored 
    RENAME TO tasty_bytes.raw_pos.truck_dev;

-- Step 8: Verify fix
SELECT truck_id, year 
FROM tasty_bytes.raw_pos.truck_dev 
LIMIT 5;
-- All correct

-- Step 9: Cleanup
DROP TABLE tasty_bytes.raw_pos.truck_dev_corrupted;

