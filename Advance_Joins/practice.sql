-- ============================================================
-- ADVANCED SQL JOINS PRACTICE
-- Snowflake Data Engineering
-- ============================================================


-- ============================================================
-- 1. SAMPLE TABLES
-- ============================================================

CREATE OR REPLACE TABLE customers (
    customer_id INT,
    customer_name VARCHAR
);

INSERT INTO customers VALUES
(101, 'Ravi'),
(102, 'Priya'),
(103, 'Suresh'),
(104, 'Anil');


CREATE OR REPLACE TABLE transactions (
    transaction_id VARCHAR,
    customer_id INT,
    amount NUMBER(10,2)
);

INSERT INTO transactions VALUES
('T1', 101, 500),
('T2', 101, 300),
('T3', 102, 700),
('T4', 103, 200);


-- ============================================================
-- 2. INNER JOIN
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name,
    t.transaction_id,
    t.amount
FROM customers c
INNER JOIN transactions t
    ON c.customer_id = t.customer_id;


-- ============================================================
-- 3. LEFT JOIN
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name,
    t.transaction_id,
    t.amount
FROM customers c
LEFT JOIN transactions t
    ON c.customer_id = t.customer_id;


-- ============================================================
-- 4. FIND CUSTOMERS WITHOUT TRANSACTIONS
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN transactions t
    ON c.customer_id = t.customer_id
WHERE t.customer_id IS NULL;


-- ============================================================
-- 5. SELF JOIN
-- Employee → Manager
-- ============================================================

CREATE OR REPLACE TABLE employees (
    employee_id INT,
    employee_name VARCHAR,
    manager_id INT
);

INSERT INTO employees VALUES
(101, 'Ravi', NULL),
(102, 'Priya', 101),
(103, 'Amit', 101),
(104, 'Neha', 102);


SELECT
    e.employee_id,
    e.employee_name AS employee,
    m.employee_name AS manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id;


-- ============================================================
-- 6. MULTIPLE JOINS
-- ============================================================

CREATE OR REPLACE TABLE accounts (
    account_id VARCHAR,
    customer_id INT,
    account_type VARCHAR,
    branch_id VARCHAR
);

INSERT INTO accounts VALUES
('A1', 101, 'Savings', 'B1'),
('A2', 102, 'Current', 'B2'),
('A3', 103, 'Savings', 'B1');


CREATE OR REPLACE TABLE account_transactions (
    transaction_id VARCHAR,
    account_id VARCHAR,
    amount NUMBER(10,2)
);

INSERT INTO account_transactions VALUES
('AT1', 'A1', 5000),
('AT2', 'A1', 2000),
('AT3', 'A2', 8000),
('AT4', 'A3', 1000);


CREATE OR REPLACE TABLE branches (
    branch_id VARCHAR,
    branch_name VARCHAR
);

INSERT INTO branches VALUES
('B1', 'Hyderabad'),
('B2', 'Bangalore');


SELECT
    c.customer_name,
    a.account_type,
    t.transaction_id,
    t.amount,
    b.branch_name
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN account_transactions t
    ON a.account_id = t.account_id
JOIN branches b
    ON a.branch_id = b.branch_id;


-- ============================================================
-- 7. MULTIPLE LEFT JOINS
-- Keep all customers
-- ============================================================

SELECT
    c.customer_name,
    a.account_type,
    t.amount,
    b.branch_name
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
LEFT JOIN account_transactions t
    ON a.account_id = t.account_id
LEFT JOIN branches b
    ON a.branch_id = b.branch_id;


-- ============================================================
-- 8. CUSTOMER → ORDER → PRODUCT
-- ============================================================

CREATE OR REPLACE TABLE products (
    product_id INT,
    product_name VARCHAR,
    price NUMBER(10,2)
);

INSERT INTO products VALUES
(1, 'Laptop', 50000),
(2, 'Phone', 25000),
(3, 'Headphones', 5000);


CREATE OR REPLACE TABLE orders (
    order_id VARCHAR,
    customer_id INT,
    product_id INT
);

INSERT INTO orders VALUES
('O1', 101, 1),
('O2', 101, 2),
('O3', 102, 3);


SELECT
    c.customer_name,
    o.order_id,
    p.product_name,
    p.price
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN products p
    ON o.product_id = p.product_id;


-- ============================================================
-- 9. MANY-TO-MANY ROW MULTIPLICATION
-- ============================================================

CREATE OR REPLACE TABLE customer_tags (
    customer_id INT,
    tag VARCHAR
);

INSERT INTO customer_tags VALUES
(101, 'Premium'),
(101, 'Frequent'),
(102, 'New');


SELECT
    c.customer_id,
    o.order_id,
    ct.tag
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN customer_tags ct
    ON c.customer_id = ct.customer_id
ORDER BY c.customer_id, o.order_id;


-- Customer 101:
-- 2 orders × 2 tags = 4 rows


-- ============================================================
-- 10. DEMONSTRATE INCORRECT AGGREGATION
-- ============================================================

CREATE OR REPLACE TABLE demo_transactions (
    transaction_id VARCHAR,
    customer_id INT,
    amount NUMBER(10,2)
);

INSERT INTO demo_transactions VALUES
('T1', 101, 100),
('T2', 101, 200);


-- Correct total = 300

SELECT
    customer_id,
    SUM(amount) AS correct_total
FROM demo_transactions
GROUP BY customer_id;


-- Joining tags can multiply the transaction rows.

SELECT
    t.customer_id,
    SUM(t.amount) AS multiplied_total
FROM demo_transactions t
JOIN customer_tags ct
    ON t.customer_id = ct.customer_id
GROUP BY t.customer_id;


-- For customer 101 this can return 600 instead of 300.


-- ============================================================
-- 11. FIX: AGGREGATE BEFORE JOIN
-- ============================================================

WITH transaction_summary AS (
    SELECT
        customer_id,
        SUM(amount) AS total_amount
    FROM demo_transactions
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    ts.total_amount
FROM customers c
LEFT JOIN transaction_summary ts
    ON c.customer_id = ts.customer_id;


-- ============================================================
-- 12. CUSTOMER ADDRESS HISTORY
-- ============================================================

CREATE OR REPLACE TABLE customer_addresses (
    customer_id INT,
    address VARCHAR,
    updated_at DATE
);

INSERT INTO customer_addresses VALUES
(101, 'Hyderabad', '2026-01-01'),
(101, 'Bangalore', '2026-02-01'),
(102, 'Chennai', '2026-01-05'),
(103, 'Delhi', '2026-01-10'),
(103, 'Mumbai', '2026-03-01');


-- ============================================================
-- 13. DEDUPLICATE BEFORE JOIN
-- Keep latest address
-- ============================================================

SELECT
    customer_id,
    address,
    updated_at
FROM customer_addresses
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;


-- ============================================================
-- 14. JOIN WITH LATEST ADDRESS ONLY
-- ============================================================

WITH latest_address AS (
    SELECT
        customer_id,
        address,
        updated_at
    FROM customer_addresses
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1
)

SELECT
    c.customer_id,
    c.customer_name,
    la.address,
    la.updated_at
FROM customers c
LEFT JOIN latest_address la
    ON c.customer_id = la.customer_id;


-- ============================================================
-- 15. EXISTS
-- Customers having at least one tag
-- ============================================================

SELECT
    c.customer_id,
    c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM customer_tags ct
    WHERE ct.customer_id = c.customer_id
);


-- ============================================================
-- 16. DEBUGGING - CHECK STARTING ROW COUNT
-- ============================================================

SELECT COUNT(*) AS customer_rows
FROM customers;


-- ============================================================
-- 17. DEBUGGING - COUNT AFTER FIRST JOIN
-- ============================================================

SELECT COUNT(*) AS rows_after_account_join
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id;


-- ============================================================
-- 18. DEBUGGING - COUNT AFTER ANOTHER JOIN
-- ============================================================

SELECT COUNT(*) AS rows_after_transaction_join
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN account_transactions t
    ON a.account_id = t.account_id;


-- ============================================================
-- 19. DEBUGGING - CHECK DUPLICATES IN JOIN KEY
-- ============================================================

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM customer_addresses
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 20. DEBUGGING - CHECK ACCOUNT_ID UNIQUENESS
-- ============================================================

SELECT
    account_id,
    COUNT(*) AS row_count
FROM accounts
GROUP BY account_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 21. DEBUG ONE CUSTOMER
-- ============================================================

SELECT
    c.customer_id,
    t.transaction_id,
    a.address
FROM customers c
JOIN demo_transactions t
    ON c.customer_id = t.customer_id
JOIN customer_addresses a
    ON c.customer_id = a.customer_id
WHERE c.customer_id = 101;


-- Customer 101:
-- 2 transactions × 2 addresses = 4 rows


-- ============================================================
-- 22. REAL-WORLD BANKING SCENARIO
--
-- Requirement:
-- One row per customer with:
-- customer name
-- total transaction amount
-- latest address
-- ============================================================

WITH transaction_summary AS (

    SELECT
        customer_id,
        SUM(amount) AS total_transaction_amount
    FROM demo_transactions
    GROUP BY customer_id

),

latest_address AS (

    SELECT
        customer_id,
        address,
        updated_at
    FROM customer_addresses
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1

)

SELECT
    c.customer_id,
    c.customer_name,
    ts.total_transaction_amount,
    la.address AS latest_address
FROM customers c
LEFT JOIN transaction_summary ts
    ON c.customer_id = ts.customer_id
LEFT JOIN latest_address la
    ON c.customer_id = la.customer_id;


-- ============================================================
-- 23. PRACTICE QUESTIONS
-- ============================================================

-- Q1.
-- Return all customers who have at least one transaction.


-- Q2.
-- Return all customers including customers without transactions.


-- Q3.
-- Find customers who have never made a transaction.


-- Q4.
-- Display every employee and their manager.


-- Q5.
-- Return customer name, account type,
-- transaction amount and branch name.


-- Q6.
-- Return customer name, order ID,
-- product name and product price.


-- Q7.
-- A customer has 4 transactions and 3 addresses.
-- How many rows can a direct JOIN produce?
-- Explain why.


-- Q8.
-- Find customers that have more than one address record.


-- Q9.
-- Deduplicate addresses and keep only
-- the latest address per customer.


-- Q10.
-- Calculate transaction totals before joining
-- them to the customer table.


-- Q11.
-- Use EXISTS to return customers that have
-- at least one customer_tags record.


-- Q12.
-- Build one row per customer containing:
-- customer name
-- total transaction amount
-- latest address


-- ============================================================
-- 24. INTERVIEW PRACTICE QUESTIONS
-- ============================================================

-- 1. What is the difference between
--    INNER JOIN and LEFT JOIN?

-- 2. What is a SELF JOIN?

-- 3. Give a real-world use case for SELF JOIN.

-- 4. Can a LEFT JOIN return more rows
--    than the left table? Why?

-- 5. What is a one-to-many relationship?

-- 6. What is a many-to-many relationship?

-- 7. Why can JOINs multiply rows?

-- 8. What is grain in Data Engineering?

-- 9. Why can JOIN multiplication cause
--    incorrect SUM or COUNT results?

-- 10. Why is DISTINCT not always the correct
--     solution for duplicate-looking JOIN rows?

-- 11. When would you aggregate before a JOIN?

-- 12. When would you deduplicate before a JOIN?

-- 13. When would you use EXISTS instead of JOIN?

-- 14. Your query should return 10,000 customers
--     but returns 50,000 rows after a JOIN.
--     How would you debug it?

-- 15. How would you check whether a JOIN key
--     is unique?

-- 16. How do you identify which JOIN is
--     multiplying rows?

-- 17. Why should you define the final grain
--     before writing complex JOINs?


-- ============================================================
-- END OF ADVANCED JOINS PRACTICE
-- ============================================================
