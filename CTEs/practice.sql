-- =====================================================
-- COMMON TABLE EXPRESSIONS (CTE) - PRACTICE
-- =====================================================

-- =====================================================
-- TABLES USED FOR PRACTICE
-- =====================================================


-- CUSTOMERS TABLE
--
-- customer_id
-- customer_name
-- city


-- LOANS TABLE
--
-- loan_id
-- customer_id
-- loan_amount
-- status


-- TRANSACTIONS TABLE
--
-- transaction_id
-- customer_id
-- transaction_date
-- amount
-- status


-- =====================================================
-- TABLE RELATIONSHIPS
-- =====================================================

-- CUSTOMERS
-- customer_id
--      |
--      |
--      v
-- LOANS
-- customer_id


-- CUSTOMERS
-- customer_id
--      |
--      |
--      v
-- TRANSACTIONS
-- customer_id


-- =====================================================
-- CTE PRACTICE QUESTIONS AND SOLUTIONS
-- =====================================================


-- =====================================================
-- 1. BASIC CTE
-- Find employees whose salary is greater than 50000.
-- =====================================================

WITH high_salary_employees AS (
    SELECT *
    FROM employees
    WHERE salary > 50000
)

SELECT *
FROM high_salary_employees;


-- =====================================================
-- 2. FILTER APPROVED LOANS
-- Find approved loans whose amount is greater than 500000.
-- =====================================================

WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT *
FROM approved_loans
WHERE loan_amount > 500000;


-- =====================================================
-- 3. TOTAL APPROVED LOAN AMOUNT
-- Find customers whose total approved loan amount is
-- greater than 1000000.
-- =====================================================

WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
),

customer_totals AS (
    SELECT
        customer_id,
        SUM(loan_amount) AS total_loan_amount
    FROM approved_loans
    GROUP BY customer_id
)

SELECT *
FROM customer_totals
WHERE total_loan_amount > 1000000;


-- =====================================================
-- 4. COUNT APPROVED LOANS
-- Find how many approved loans each customer has.
-- =====================================================

WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT
    customer_id,
    COUNT(loan_id) AS approved_loans_count
FROM approved_loans
GROUP BY customer_id;


-- =====================================================
-- 5. TOTAL APPROVED LOAN AMOUNT PER CUSTOMER
-- =====================================================

WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT
    customer_id,
    SUM(loan_amount) AS total_approved_loan_amount
FROM approved_loans
GROUP BY customer_id;


-- =====================================================
-- 6. REAL-WORLD LOAN PROBLEM
--
-- Find customers who have more than one approved loan
-- AND whose total approved loan amount is greater than
-- 1000000.
--
-- Return:
-- customer_id
-- customer_name
-- approved_loans_count
-- total_approved_loan_amount
-- =====================================================


-- Thinking:
--
-- Step 1: Filter approved loans
-- Step 2: Group loans by customer
-- Step 3: Count approved loans
-- Step 4: Calculate total loan amount
-- Step 5: Filter based on count and total amount
-- Step 6: Join customers to get customer_name


WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
),

customer_loan_summary AS (
    SELECT
        customer_id,
        COUNT(loan_id) AS approved_loans_count,
        SUM(loan_amount) AS total_approved_loan_amount
    FROM approved_loans
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    cls.approved_loans_count,
    cls.total_approved_loan_amount
FROM customers c
JOIN customer_loan_summary cls
    ON c.customer_id = cls.customer_id
WHERE cls.approved_loans_count > 1
  AND cls.total_approved_loan_amount > 1000000;


-- =====================================================
-- 7. TRANSACTION SUMMARY
--
-- Find customers whose total successful transaction
-- amount is greater than 500000.
--
-- Also return only customers who have made more than
-- 5 successful transactions.
-- =====================================================


-- Thinking:
--
-- Step 1: Filter successful transactions
-- Step 2: Group by customer
-- Step 3: Calculate SUM(amount)
-- Step 4: Calculate COUNT(transaction_id)
-- Step 5: Apply both conditions


WITH successful_transactions AS (
    SELECT *
    FROM transactions
    WHERE status = 'SUCCESSFUL'
),

transaction_summary AS (
    SELECT
        customer_id,
        SUM(amount) AS total_transaction_amount,
        COUNT(transaction_id) AS successful_transaction_count
    FROM successful_transactions
    GROUP BY customer_id
)

SELECT *
FROM transaction_summary
WHERE total_transaction_amount > 500000
  AND successful_transaction_count > 5;


-- =====================================================
-- 8. TOTAL SUCCESSFUL TRANSACTION AMOUNT PER CUSTOMER
-- =====================================================

WITH successful_transactions AS (
    SELECT *
    FROM transactions
    WHERE status = 'SUCCESSFUL'
),

customer_transaction_totals AS (
    SELECT
        customer_id,
        SUM(amount) AS total_successful_amount
    FROM successful_transactions
    GROUP BY customer_id
)

SELECT *
FROM customer_transaction_totals;


-- =====================================================
-- 9. COUNT SUCCESSFUL TRANSACTIONS PER CUSTOMER
-- =====================================================

WITH successful_transactions AS (
    SELECT *
    FROM transactions
    WHERE status = 'SUCCESSFUL'
)

SELECT
    customer_id,
    COUNT(transaction_id) AS successful_transaction_count
FROM successful_transactions
GROUP BY customer_id;


-- =====================================================
-- 10. FINAL CTE PRACTICE PROBLEM
--
-- Find customers who have completed more than 3
-- successful transactions and whose total successful
-- transaction amount is greater than 500000.
--
-- Return:
-- customer_id
-- customer_name
-- successful_transaction_count
-- total_successful_amount
-- =====================================================


-- Thinking:
--
-- Step 1: Filter successful transactions
-- Step 2: Group by customer_id
-- Step 3: Calculate SUM(amount)
-- Step 4: Calculate COUNT(transaction_id)
-- Step 5: Join CUSTOMERS table
-- Step 6: Apply final conditions


WITH successful_transactions AS (
    SELECT *
    FROM transactions
    WHERE status = 'SUCCESSFUL'
),

transaction_summary AS (
    SELECT
        customer_id,
        SUM(amount) AS total_successful_amount,
        COUNT(transaction_id) AS successful_transaction_count
    FROM successful_transactions
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    ts.successful_transaction_count,
    ts.total_successful_amount
FROM customers c
JOIN transaction_summary ts
    ON c.customer_id = ts.customer_id
WHERE ts.total_successful_amount > 500000
  AND ts.successful_transaction_count > 3;


-- =====================================================
-- DEBUGGING PRACTICE
-- =====================================================


-- BROKEN QUERY:
--
-- WITH approved_loans AS (
--     SELECT *
--     FROM loans
--     WHERE status = 'APPROVED'
-- ),
--
-- customer_totals AS (
--     SELECT
--         customer_id,
--         SUM(loan_amount) AS total_loan_amount
--     FROM approved_loans
--     GROUP BY loan_id
-- )
--
-- SELECT *
-- FROM customer_totals
-- WHERE loan_amount > 1000000;


-- MISTAKE 1:
-- The requirement asks for total loan amount per customer.
--
-- Incorrect:
-- GROUP BY loan_id
--
-- Correct:
-- GROUP BY customer_id


-- MISTAKE 2:
-- After aggregation, the output column is:
--
-- SUM(loan_amount) AS total_loan_amount
--
-- Therefore:
--
-- Incorrect:
-- WHERE loan_amount > 1000000
--
-- Correct:
-- WHERE total_loan_amount > 1000000


-- CORRECT QUERY:

WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
),

customer_totals AS (
    SELECT
        customer_id,
        SUM(loan_amount) AS total_loan_amount
    FROM approved_loans
    GROUP BY customer_id
)

SELECT *
FROM customer_totals
WHERE total_loan_amount > 1000000;


-- =====================================================
-- MY COMMON MISTAKES WHILE LEARNING CTES
-- =====================================================


-- 1. GROUPING BY THE WRONG COLUMN
--
-- Requirement:
-- Total amount for each customer
--
-- Incorrect:
-- GROUP BY transaction_id
--
-- Correct:
-- GROUP BY customer_id


-- 2. USING THE WRONG COLUMN AFTER AGGREGATION
--
-- Incorrect:
-- WHERE amount > 500000
--
-- Correct:
-- WHERE total_transaction_amount > 500000


-- 3. MISSING COMMA BETWEEN COLUMNS
--
-- Incorrect:
--
-- SELECT
--     customer_id,
--     SUM(amount) AS total_amount
--     COUNT(transaction_id) AS transaction_count
--
-- Correct:
--
-- SELECT
--     customer_id,
--     SUM(amount) AS total_amount,
--     COUNT(transaction_id) AS transaction_count


-- 4. CTE NAME MISMATCH
--
-- Created:
-- customer_totals
--
-- Used:
-- custmer_totals
--
-- Always check spelling carefully.


-- 5. COLUMN ALIAS MISMATCH
--
-- Created:
-- SUM(amount) AS total_transaction_amount
--
-- Used later:
-- total_successful_amount
--
-- Use the correct alias consistently.


-- 6. INCORRECT JOIN KEY
--
-- Incorrect:
-- ON c.customer_id = ts.transaction_id
--
-- Correct:
-- ON c.customer_id = ts.customer_id
--
-- Join using the related common column.


-- =====================================================
-- FINAL PROBLEM-SOLVING TEMPLATE
-- =====================================================

-- Before writing a complex CTE query, ask:
--
-- 1. What data do I need?
--
-- 2. What should I filter?
--
-- 3. What should I calculate?
--
-- 4. What should I GROUP BY?
--
-- 5. What conditions should be applied?
--
-- 6. Do I need to JOIN another table?
--
-- 7. What columns should be returned?


-- Common CTE pattern:
--
-- WITH filtered_data AS (
--     SELECT *
--     FROM table_name
--     WHERE condition
-- ),
--
-- summary AS (
--     SELECT
--         grouping_column,
--         aggregate_function(column)
--     FROM filtered_data
--     GROUP BY grouping_column
-- )
--
-- SELECT *
-- FROM summary
-- WHERE aggregate_condition;