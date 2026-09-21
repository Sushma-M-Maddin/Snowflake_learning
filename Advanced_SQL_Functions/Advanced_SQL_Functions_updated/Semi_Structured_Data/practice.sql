-- ============================================================
-- SEMI-STRUCTURED DATA IN SNOWFLAKE
-- Practice SQL
-- ============================================================


-- ============================================================
-- 1. CREATE A VARIANT TABLE
-- ============================================================

CREATE OR REPLACE TABLE customer_raw (
    customer_data VARIANT
);


-- ============================================================
-- 2. INSERT JSON FOR PRACTICE
-- ============================================================

INSERT INTO customer_raw
SELECT PARSE_JSON('
{
  "customer_id": 101,
  "name": "Sushma",
  "city": "Bangalore",
  "accounts": [
    {
      "account_type": "SAVINGS",
      "balance": 50000
    },
    {
      "account_type": "CURRENT",
      "balance": 120000
    }
  ],
  "skills": ["Java", "SQL", "Snowflake"]
}
');

INSERT INTO customer_raw
SELECT PARSE_JSON('
{
  "customer_id": 102,
  "name": "Rahul",
  "city": null,
  "accounts": [
    {
      "account_type": "SAVINGS",
      "balance": 15000
    }
  ],
  "skills": ["Python", "Snowflake"]
}
');

SELECT * FROM customer_raw;


-- ============================================================
-- 3. READ DIRECT (TOP-LEVEL) FIELDS
-- ============================================================

SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name,
    customer_data:city::STRING AS city
FROM customer_raw;


-- ============================================================
-- 4. MISSING KEY VS NULL VALUE
-- ============================================================

-- Both come back as SQL NULL through plain path access
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:city AS city_raw,   -- explicit null for customer 102
    customer_data:country AS country_raw  -- key doesn't exist at all
FROM customer_raw;


-- ============================================================
-- 5. FLATTEN ACCOUNTS
-- ============================================================

SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name,
    f.index AS account_index,
    f.value:account_type::STRING AS account_type,
    f.value:balance::NUMBER AS balance
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:accounts
) f
ORDER BY customer_id, account_index;


-- ============================================================
-- 6. FLATTEN SKILLS
-- ============================================================

SELECT
    customer_data:customer_id::INT AS customer_id,
    f.index AS skill_index,
    f.value::STRING AS skill
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:skills
) f
ORDER BY customer_id, skill_index;


-- ============================================================
-- 7. AGGREGATE AFTER FLATTEN — CORRECT BALANCE TOTAL
-- ============================================================

-- One FLATTEN only — safe, no row multiplication problem
SELECT
    customer_data:customer_id::INT AS customer_id,
    SUM(f.value:balance::NUMBER) AS total_balance
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:accounts
) f
GROUP BY customer_data:customer_id::INT;


-- ============================================================
-- 8. DEMONSTRATE ROW MULTIPLICATION
-- Flattening TWO arrays from the same row in one query
-- ============================================================

-- Customer 101 has 2 accounts and 3 skills.
-- Flattening both together produces 2 x 3 = 6 rows for that customer,
-- exactly like a many-to-many JOIN (see Advanced_Joins notes).

SELECT
    customer_data:customer_id::INT AS customer_id,
    a.value:account_type::STRING AS account_type,
    s.value::STRING AS skill
FROM customer_raw,
LATERAL FLATTEN(input => customer_data:accounts) a,
LATERAL FLATTEN(input => customer_data:skills) s
ORDER BY customer_id;


-- ============================================================
-- 9. FIX: FLATTEN SEPARATELY, DON'T COMBINE
-- ============================================================

-- Accounts and skills are independent facts about the customer.
-- Query them separately instead of combining in one FLATTEN'd result.

-- Accounts only
SELECT
    customer_data:customer_id::INT AS customer_id,
    a.value:account_type::STRING AS account_type,
    a.value:balance::NUMBER AS balance
FROM customer_raw,
LATERAL FLATTEN(input => customer_data:accounts) a;

-- Skills only
SELECT
    customer_data:customer_id::INT AS customer_id,
    s.value::STRING AS skill
FROM customer_raw,
LATERAL FLATTEN(input => customer_data:skills) s;


-- ============================================================
-- 10. TYPE-CHECKING FUNCTIONS
-- ============================================================

SELECT
    customer_data:customer_id::INT AS customer_id,
    TYPEOF(customer_data:accounts) AS accounts_type,
    IS_ARRAY(customer_data:accounts) AS accounts_is_array,
    IS_OBJECT(customer_data) AS root_is_object
FROM customer_raw;


-- ============================================================
-- 11. FLATTEN OUTPUT COLUMNS — VALUE / INDEX / KEY / PATH
-- ============================================================

SELECT
    f.index,
    f.value,
    f.key,
    f.path
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:skills
) f;


-- ============================================================
-- 12. COMPLETE SMALL WORKFLOW (STEP BY STEP)
-- ============================================================

-- Step 1: table
CREATE OR REPLACE TABLE customer_raw_demo (
    customer_data VARIANT
);

-- Step 2: insert
INSERT INTO customer_raw_demo
SELECT PARSE_JSON('
{
  "customer_id": 201,
  "name": "Anita",
  "accounts": [
    { "account_type": "SAVINGS", "balance": 30000 },
    { "account_type": "CURRENT", "balance": 90000 }
  ]
}
');

-- Step 3: read top-level fields
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name
FROM customer_raw_demo;

-- Step 4: flatten accounts
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name,
    f.value:account_type::STRING AS account_type,
    f.value:balance::NUMBER AS balance
FROM customer_raw_demo,
LATERAL FLATTEN(
    input => customer_data:accounts
) f;


-- ============================================================
-- 13. PRACTICE QUESTIONS
-- ============================================================

-- Q1.
-- Extract customer_id as INT and customer_name as STRING
-- from customer_raw.

-- Q2.
-- Flatten accounts and return account_type and balance
-- for every customer.

-- Q3.
-- Flatten skills and return the array position and skill
-- for every customer.

-- Q4.
-- Calculate the total balance per customer using
-- SUM() after flattening accounts.

-- Q5.
-- Explain why flattening both accounts and skills
-- in a single query for the same customer produces
-- more rows than expected.

-- Q6.
-- Explain the difference between f.value and f.index.

-- Q7.
-- Explain why LATERAL is required with FLATTEN().

-- Q8.
-- Check whether customer_data:accounts is actually
-- an array using IS_ARRAY().


-- ============================================================
-- 14. INTERVIEW PRACTICE
-- ============================================================

-- 1. What is the difference between structured and
--    semi-structured data?

-- 2. What is VARIANT used for?

-- 3. How do you access a nested field inside a
--    VARIANT column?

-- 4. Why do extracted VARIANT values need to be cast?

-- 5. What does FLATTEN() do, conceptually?

-- 6. Why is LATERAL used together with FLATTEN()?

-- 7. Is the INDEX column from FLATTEN() 0-based or
--    1-based? How does that compare to SPLIT_PART()?

-- 8. How can FLATTEN() cause the same row-multiplication
--    problem as a many-to-many JOIN?


-- ============================================================
-- END OF SEMI-STRUCTURED DATA PRACTICE
-- ============================================================
