-- =========================================================
-- SQL QUALIFY PRACTICE
-- =========================================================


-- =========================================================
-- 1. CREATE SAMPLE TRANSACTIONS TABLE
-- =========================================================

CREATE OR REPLACE TABLE transactions (
    transaction_id INT,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO transactions VALUES
(1, 101, '2026-01-01', 100),
(2, 101, '2026-01-05', 500),
(3, 101, '2026-01-10', 300),
(4, 101, '2026-01-15', 700),
(5, 102, '2026-01-02', 200),
(6, 102, '2026-01-08', 800),
(7, 102, '2026-01-12', 400),
(8, 102, '2026-01-20', 600);

SELECT *
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 2. ROW_NUMBER()
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS row_num

FROM transactions
ORDER BY customer_id, transaction_date DESC;


-- =========================================================
-- 3. QUALIFY = 1
-- Latest transaction per customer
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;


-- =========================================================
-- 4. TOP 2 TRANSACTIONS PER CUSTOMER
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 2;


-- =========================================================
-- 5. TOP 3 TRANSACTIONS PER CUSTOMER
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 3;


-- =========================================================
-- 6. LOWEST TRANSACTION PER CUSTOMER
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount ASC
) = 1;


-- =========================================================
-- 7. CREATE CUSTOMER TABLE FOR DEDUPLICATION
-- =========================================================

CREATE OR REPLACE TABLE customer_data (
    customer_id INT,
    name VARCHAR,
    city VARCHAR,
    updated_at TIMESTAMP
);

INSERT INTO customer_data VALUES
(101, 'Sushma', 'Bangalore', '2026-08-01 10:00:00'),
(101, 'Sushma', 'Hyderabad', '2026-08-05 10:00:00'),
(102, 'Rahul', 'Chennai', '2026-08-02 11:00:00'),
(103, 'Priya', 'Delhi', '2026-08-03 09:00:00'),
(103, 'Priya', 'Mumbai', '2026-08-07 09:00:00');

SELECT *
FROM customer_data
ORDER BY customer_id, updated_at;


-- =========================================================
-- 8. DEDUPLICATION
-- Keep latest record for each customer
-- =========================================================

SELECT
    customer_id,
    name,
    city,
    updated_at
FROM customer_data
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;


-- =========================================================
-- 9. RANK() WITH QUALIFY
-- =========================================================

CREATE OR REPLACE TABLE employees (
    employee_id INT,
    employee_name VARCHAR,
    department VARCHAR,
    salary DECIMAL(10,2)
);

INSERT INTO employees VALUES
(1, 'A', 'IT', 100000),
(2, 'B', 'IT', 90000),
(3, 'C', 'IT', 90000),
(4, 'D', 'IT', 80000),
(5, 'E', 'HR', 70000),
(6, 'F', 'HR', 60000),
(7, 'G', 'HR', 60000),
(8, 'H', 'HR', 50000);

SELECT
    employee_id,
    employee_name,
    department,
    salary,

    RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS salary_rank

FROM employees;


-- =========================================================
-- 10. TOP 3 USING RANK()
-- =========================================================

SELECT
    employee_id,
    employee_name,
    department,
    salary
FROM employees
QUALIFY RANK() OVER (
    PARTITION BY department
    ORDER BY salary DESC
) <= 3;


-- =========================================================
-- 11. DENSE_RANK() WITH QUALIFY
-- =========================================================

SELECT
    employee_id,
    employee_name,
    department,
    salary
FROM employees
QUALIFY DENSE_RANK() OVER (
    PARTITION BY department
    ORDER BY salary DESC
) <= 3;


-- =========================================================
-- 12. LAG() WITH QUALIFY
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,

    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS previous_amount

FROM transactions

QUALIFY previous_amount IS NOT NULL;


-- =========================================================
-- 13. LEAD() WITH QUALIFY
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,

    LEAD(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS next_amount

FROM transactions

QUALIFY next_amount IS NOT NULL;


-- =========================================================
-- 14. CURRENT vs PREVIOUS TRANSACTION
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,

    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS previous_amount,

    amount -
    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS difference

FROM transactions

QUALIFY previous_amount IS NOT NULL;


-- =========================================================
-- 15. LATEST RECORD PER CUSTOMER
-- WITH ROW_NUMBER ALIAS
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS rn

FROM transactions

QUALIFY rn = 1;


-- =========================================================
-- 16. TOP 2 PER CUSTOMER WITH ROW NUMBER
-- =========================================================

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY amount DESC
    ) AS rn

FROM transactions

QUALIFY rn <= 2;


-- =========================================================
-- 17. COMPARE ROW_NUMBER, RANK, DENSE_RANK
-- =========================================================

SELECT
    employee_id,
    employee_name,
    department,
    salary,

    ROW_NUMBER() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS row_number_result,

    RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS rank_result,

    DENSE_RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS dense_rank_result

FROM employees
ORDER BY department, salary DESC;


-- =========================================================
-- 18. PRACTICE QUESTIONS
-- =========================================================

-- Q1:
-- Find the latest transaction for each customer
-- using QUALIFY and ROW_NUMBER().


-- Q2:
-- Find the top 2 highest transactions for each customer.


-- Q3:
-- Find the lowest transaction for each customer.


-- Q4:
-- Find the top 3 highest-paid employees in each department.


-- Q5:
-- Deduplicate customer_data and keep the latest
-- updated record for every customer.


-- Q6:
-- Find all transactions that have a previous
-- transaction for the same customer.


-- Q7:
-- Find all transactions that have a next
-- transaction for the same customer.


-- Q8:
-- Compare ROW_NUMBER(), RANK(), and DENSE_RANK()
-- for employees within each department.


-- Q9:
-- Find the top 3 salary ranks per department
-- using RANK().


-- Q10:
-- Find the top 3 distinct salary levels per department
-- using DENSE_RANK().


-- =========================================================
-- 19. INTERVIEW PRACTICE
-- =========================================================

-- Interview Question 1:
-- Why can we not use WHERE to filter
-- a ROW_NUMBER() result at the same query level?


-- Interview Question 2:
-- What is the difference between WHERE,
-- HAVING, and QUALIFY?


-- Interview Question 3:
-- How would you find the latest record
-- for each customer?


-- Interview Question 4:
-- How would you find the top 3 products
-- in every category?


-- Interview Question 5:
-- How would you deduplicate data while
-- keeping the latest record?


-- Interview Question 6:
-- Why is LIMIT not suitable for Top-N per group?


-- Interview Question 7:
-- What happens if the PARTITION BY column
-- is incorrect?


-- Interview Question 8:
-- What is the difference between ROW_NUMBER(),
-- RANK(), and DENSE_RANK() when used with QUALIFY?


-- =========================================================
-- END OF QUALIFY PRACTICE
-- =========================================================
