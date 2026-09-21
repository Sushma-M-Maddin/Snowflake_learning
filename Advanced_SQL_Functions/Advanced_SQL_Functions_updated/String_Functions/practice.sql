-- ============================================================
-- STRING FUNCTIONS PRACTICE
-- Snowflake
-- ============================================================


-- ============================================================
-- 1. SAMPLE TABLE
-- ============================================================

CREATE OR REPLACE TABLE raw_customers (
    customer_id INT,
    full_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    employee_code VARCHAR
);

INSERT INTO raw_customers VALUES
(1, '   sushma maddin   ', 'sushma.maddin@gmail.com', '987-654-3210', 'EMP42'),
(2, 'RAHUL VERMA', 'rahul@yahoo.com', '(912) 345-6789', 'EMP7'),
(3, 'Priya   Sharma', 'priya.sharma@company.com', '912.345.6789', 'EMP1025');

SELECT * FROM raw_customers;


-- ============================================================
-- 2. CASE FUNCTIONS
-- ============================================================

SELECT UPPER('sushma');
SELECT LOWER('SNOWFLAKE');
SELECT INITCAP('sushma maddin');

-- Standardize names
SELECT
    customer_id,
    INITCAP(TRIM(full_name)) AS clean_name
FROM raw_customers;


-- ============================================================
-- 3. LENGTH
-- ============================================================

SELECT LENGTH('Snowflake');

-- Validate employee code length
SELECT
    employee_code,
    LENGTH(employee_code) AS code_length
FROM raw_customers;


-- ============================================================
-- 4. TRIM / LTRIM / RTRIM
-- ============================================================

SELECT TRIM('   Sushma Maddin   ');
SELECT LTRIM('   Sushma');
SELECT RTRIM('Sushma   ');

-- Trim a custom character
SELECT TRIM('---Sushma---', '-');


-- ============================================================
-- 5. SUBSTRING / LEFT / RIGHT
-- (Snowflake string positions are 1-indexed)
-- ============================================================

SELECT SUBSTRING('Snowflake', 1, 4);   -- 'Snow'
SELECT LEFT('ABCDEF', 3);              -- 'ABC'
SELECT RIGHT('ABCDEF', 3);             -- 'DEF'


-- ============================================================
-- 6. CONCAT vs CONCAT_WS — NULL HANDLING
-- ============================================================

SELECT CONCAT('Sushma', ' ', 'Maddin');
SELECT CONCAT_WS('-', 'EMP', 'BLR', '1025');

-- Demonstrate the NULL-handling difference
SELECT CONCAT('Sushma', NULL, 'Maddin') AS concat_result;      -- NULL
SELECT CONCAT_WS('-', 'EMP', NULL, '1025') AS concat_ws_result; -- 'EMP-1025'


-- ============================================================
-- 7. REPLACE
-- ============================================================

SELECT REPLACE('987-654-3210', '-', '');


-- ============================================================
-- 8. SPLIT_PART
-- ============================================================

SELECT SPLIT_PART('IND-BLR-2026-001', '-', 3);

-- Requesting a part beyond what exists returns '' (empty string)
SELECT SPLIT_PART('IND-BLR-2026-001', '-', 10) AS missing_part;


-- ============================================================
-- 9. POSITION / CHARINDEX
-- ============================================================

SELECT POSITION('@' IN 'rahul@yahoo.com');
SELECT CHARINDEX('@', 'rahul@yahoo.com');

-- Extract email domain using POSITION + SUBSTRING
SELECT
    email,
    SUBSTRING(email, POSITION('@' IN email) + 1) AS domain
FROM raw_customers;

-- Extract email domain using SPLIT_PART (simpler)
SELECT
    email,
    SPLIT_PART(email, '@', 2) AS domain
FROM raw_customers;


-- ============================================================
-- 10. LPAD / RPAD
-- ============================================================

SELECT LPAD('42', 6, '0');
SELECT RPAD('ABC', 6, 'X');

-- Zero-pad employee IDs
SELECT
    customer_id,
    LPAD(CAST(customer_id AS VARCHAR), 5, '0') AS padded_id
FROM raw_customers;


-- ============================================================
-- 11. REGEXP_REPLACE — PATTERN-BASED CLEANING
-- ============================================================

SELECT REGEXP_REPLACE('987-654-3210', '[^0-9]', '');
SELECT REGEXP_REPLACE('EMP@123#BLR!', '[^A-Za-z0-9]', '');

-- Clean all phone formats to digits-only, in one pass
SELECT
    phone,
    REGEXP_REPLACE(phone, '[^0-9]', '') AS digits_only
FROM raw_customers;


-- ============================================================
-- 12. REGEXP_LIKE / LIKE / ILIKE
-- ============================================================

-- Exact 10-digit phone check after cleaning
SELECT
    phone,
    REGEXP_REPLACE(phone, '[^0-9]', '') AS digits_only,
    REGEXP_LIKE(REGEXP_REPLACE(phone, '[^0-9]', ''), '^[0-9]{10}$') AS is_valid_phone
FROM raw_customers;

-- Case-insensitive name search
SELECT *
FROM raw_customers
WHERE full_name ILIKE '%priya%';


-- ============================================================
-- 13. REGEXP_SUBSTR
-- ============================================================

SELECT REGEXP_SUBSTR('Order #A1023 placed on 2026-09-21', '#[A-Z0-9]+') AS order_ref;


-- ============================================================
-- 14. STARTSWITH / ENDSWITH / CONTAINS
-- ============================================================

SELECT
    email,
    STARTSWITH(email, 'sushma') AS starts_with_sushma,
    ENDSWITH(email, '@gmail.com') AS is_gmail,
    CONTAINS(email, 'company') AS mentions_company
FROM raw_customers;


-- ============================================================
-- 15. COMPLETE CLEANING PIPELINE
-- ============================================================

SELECT
    customer_id,
    INITCAP(TRIM(full_name)) AS clean_name,
    LOWER(TRIM(email)) AS clean_email,
    SPLIT_PART(email, '@', 2) AS email_domain,
    REGEXP_REPLACE(phone, '[^0-9]', '') AS clean_phone,
    LPAD(CAST(customer_id AS VARCHAR), 5, '0') AS padded_customer_id
FROM raw_customers;


-- ============================================================
-- 16. PRACTICE QUESTIONS
-- ============================================================

-- Q1.
-- Remove hyphens from phone numbers.

-- Q2.
-- Extract the email domain after @.

-- Q3.
-- Extract the year from 'IND-BLR-2026-001'.

-- Q4.
-- Create a full name using CONCAT_WS from first_name,
-- middle_name (nullable), and last_name.

-- Q5.
-- Standardize an ID to five digits using LPAD.

-- Q6.
-- Clean a phone number to digits-only regardless of
-- whether it uses hyphens, spaces, dots, or parentheses.

-- Q7.
-- Validate that a cleaned phone number has exactly
-- 10 digits.

-- Q8.
-- Find all customers whose email is from gmail.com
-- using ENDSWITH.


-- ============================================================
-- 17. INTERVIEW PRACTICE
-- ============================================================

-- 1. What is the difference between CONCAT and CONCAT_WS
--    when a value is NULL?

-- 2. Are Snowflake string positions 0-indexed or 1-indexed?

-- 3. When would you use REGEXP_REPLACE instead of REPLACE?

-- 4. How would you extract the domain from an email address?

-- 5. What's the difference between LIKE and REGEXP_LIKE?

-- 6. What does SPLIT_PART return if you ask for a part
--    number beyond what exists?

-- 7. How would you zero-pad an ID to a fixed width?

-- 8. Why might a "full name" built with CONCAT() be
--    unexpectedly NULL?


-- ============================================================
-- END OF STRING FUNCTIONS PRACTICE
-- ============================================================
