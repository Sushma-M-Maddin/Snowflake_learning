-- ============================================================
-- MERGE IN SNOWFLAKE
-- Practice SQL
-- ============================================================


-- ============================================================
-- 1. CREATE TARGET TABLE
-- ============================================================

CREATE OR REPLACE TABLE customers (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);


-- ============================================================
-- 2. INSERT INITIAL TARGET DATA
-- ============================================================

INSERT INTO customers
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi', 'ACTIVE', '2026-09-01 10:00:00'),
    (102, 'Priya', 'ACTIVE', '2026-09-01 11:00:00'),
    (103, 'Amit', 'ACTIVE', '2026-09-01 12:00:00');


-- Check target
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 3. CREATE SOURCE TABLE
-- ============================================================

CREATE OR REPLACE TABLE customer_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);


-- ============================================================
-- 4. INSERT SOURCE DATA
-- ============================================================

INSERT INTO customer_updates
    (customer_id, customer_name, status, updated_at)
VALUES
    (102, 'Priya Sharma', 'ACTIVE', '2026-09-02 10:00:00'),
    (104, 'Neha', 'ACTIVE', '2026-09-02 11:00:00');


-- ============================================================
-- 5. BASIC MERGE — UPDATE + INSERT
-- ============================================================

MERGE INTO customers AS target
USING customer_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status,
        updated_at
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status,
        source.updated_at
    );


-- Check result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 6. CONDITIONAL MERGE
-- Only update ACTIVE source records
-- ============================================================

CREATE OR REPLACE TABLE customer_updates_conditional (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_updates_conditional
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi Kumar', 'ACTIVE', '2026-09-03 10:00:00'),
    (102, 'Priya Updated', 'INACTIVE', '2026-09-03 11:00:00');


MERGE INTO customers AS target
USING customer_updates_conditional AS source
ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.status = 'ACTIVE'
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at;


-- Check result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 7. TIMESTAMP-BASED MERGE
-- Only update if source is newer
-- ============================================================

CREATE OR REPLACE TABLE customer_updates_timestamp (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_updates_timestamp
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi Old Data', 'ACTIVE', '2026-08-30 10:00:00'),
    (102, 'Priya New Data', 'ACTIVE', '2026-09-05 10:00:00');


MERGE INTO customers AS target
USING customer_updates_timestamp AS source
ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at;


-- Check result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 8. DELETE USING MERGE
-- ============================================================

CREATE OR REPLACE TABLE customer_status_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_status_updates
    (customer_id, customer_name, status, updated_at)
VALUES
    (103, 'Amit', 'DELETED', '2026-09-06 10:00:00');


MERGE INTO customers AS target
USING customer_status_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.status = 'DELETED'
THEN
    DELETE;


-- Check result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 9. CONDITIONAL DELETE + UPDATE + INSERT
-- ============================================================

CREATE OR REPLACE TABLE customer_full_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_full_updates
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi Final', 'ACTIVE', '2026-09-07 10:00:00'),
    (102, 'Priya Final', 'ACTIVE', '2026-09-07 11:00:00'),
    (104, 'Neha', 'DELETED', '2026-09-07 12:00:00'),
    (105, 'Sneha', 'ACTIVE', '2026-09-07 13:00:00');


MERGE INTO customers AS target
USING customer_full_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.status = 'DELETED'
THEN
    DELETE

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status,
        updated_at
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status,
        source.updated_at
    );


-- Check result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 10. SOURCE DEDUPLICATION
-- ============================================================

CREATE OR REPLACE TABLE customer_duplicate_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_duplicate_updates
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi First', 'ACTIVE', '2026-09-08 09:00:00'),
    (101, 'Ravi Latest', 'ACTIVE', '2026-09-08 12:00:00'),
    (102, 'Priya Latest', 'ACTIVE', '2026-09-08 13:00:00'),
    (102, 'Priya Older', 'ACTIVE', '2026-09-08 08:00:00');


-- View duplicates
SELECT *
FROM customer_duplicate_updates
ORDER BY customer_id, updated_at DESC;


-- ============================================================
-- 11. DEDUPLICATE USING ROW_NUMBER() + QUALIFY
-- Latest record wins
-- ============================================================

SELECT
    customer_id,
    customer_name,
    status,
    updated_at
FROM customer_duplicate_updates

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1

ORDER BY customer_id;


-- ============================================================
-- 12. DEDUPLICATION BEFORE MERGE
-- ============================================================

MERGE INTO customers AS target

USING (
    SELECT
        customer_id,
        customer_name,
        status,
        updated_at
    FROM customer_duplicate_updates

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1
) AS source

ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status,
        updated_at
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status,
        source.updated_at
    );


-- Check final result
SELECT *
FROM customers
ORDER BY customer_id;


-- ============================================================
-- 13. DETERMINISTIC DEDUPLICATION
-- Timestamp + event_id
-- ============================================================

CREATE OR REPLACE TABLE customer_event_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    updated_at TIMESTAMP,
    event_id INTEGER
);

INSERT INTO customer_event_updates
    (customer_id, customer_name, updated_at, event_id)
VALUES
    (106, 'Anita First', '2026-09-09 10:00:00', 500),
    (106, 'Anita Latest', '2026-09-09 10:00:00', 501);


SELECT
    customer_id,
    customer_name,
    updated_at,
    event_id
FROM customer_event_updates

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC, event_id DESC
) = 1;


-- ============================================================
-- 14. INCREMENTAL LOADING EXAMPLE
-- ============================================================

CREATE OR REPLACE TABLE incremental_customer_updates (
    customer_id INTEGER,
    customer_name VARCHAR,
    status VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO incremental_customer_updates
    (customer_id, customer_name, status, updated_at)
VALUES
    (101, 'Ravi Incremental', 'ACTIVE', '2026-09-10 09:00:00'),
    (107, 'Kiran', 'ACTIVE', '2026-09-10 10:00:00');


-- Example of filtering changed/new records
SELECT *
FROM incremental_customer_updates
WHERE updated_at > '2026-09-09 00:00:00';


-- ============================================================
-- 15. INCREMENTAL MERGE
-- ============================================================

MERGE INTO customers AS target

USING (
    SELECT *
    FROM incremental_customer_updates
    WHERE updated_at > '2026-09-09 00:00:00'

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1
) AS source

ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status,
        target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status,
        updated_at
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status,
        source.updated_at );


-- ============================================================
-- 16. INTERVIEW PRACTICE
-- ============================================================

-- Question 1:
-- Target:
-- 101 Ravi
-- 102 Priya
--
-- Source:
-- 102 Priya Sharma
-- 103 Amit
--
-- Write a MERGE that updates 102
-- and inserts 103.


-- Question 2:
-- Source contains multiple records for the same customer.
-- Write SQL that keeps only the latest record.


-- Question 3:
-- Write a MERGE that:
-- 1. Deletes records where source.status = 'DELETED'
-- 2. Updates other matched records
-- 3. Inserts unmatched records


-- Question 4:
-- Write a MERGE that only updates the target
-- when source.updated_at is newer than target.updated_at.


-- Question 5:
-- Explain the difference between:
--
-- MERGE
-- UPSERT
-- Incremental Loading
--
-- in your own words.


-- ============================================================
-- END OF MERGE PRACTICE
-- ============================================================
