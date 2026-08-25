-- =========================================================
-- SQL WINDOW FRAMES PRACTICE
-- =========================================================

-- =========================================================
-- 1. CREATE SAMPLE TABLE
-- =========================================================

CREATE OR REPLACE TABLE transactions (
    transaction_id INT,
    customer_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO transactions VALUES
(1, 101, '2026-01-01', 100),
(2, 101, '2026-01-02', 200),
(3, 101, '2026-01-03', 300),
(4, 101, '2026-01-04', 400),
(5, 101, '2026-01-05', 500),
(6, 102, '2026-01-01', 150),
(7, 102, '2026-01-02', 250),
(8, 102, '2026-01-03', 350),
(9, 102, '2026-01-04', 450),
(10, 102, '2026-01-05', 550);

SELECT *
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 2. RUNNING TOTAL
-- First Row → Current Row
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 3. PREVIOUS ROW + CURRENT ROW
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS previous_and_current_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 4. PREVIOUS 2 ROWS + CURRENT ROW
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 5. 3-ROW MOVING AVERAGE
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS three_row_moving_average
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 6. 5-ROW MOVING AVERAGE
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS five_row_moving_average
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 7. CURRENT ROW + NEXT ROW
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
    ) AS current_and_next_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 8. PREVIOUS + CURRENT + NEXT ROW
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS centered_moving_average
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 9. CURRENT ROW + NEXT 2 ROWS
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
    ) AS current_and_next_two_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 10. REMAINING TOTAL
-- Current Row → Last Row
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS remaining_total
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 11. REMAINING AVERAGE
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,
    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS remaining_average
FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 12. ROWS VS RANGE
-- SAMPLE TABLE WITH DUPLICATE ORDER BY VALUES
-- =========================================================

CREATE OR REPLACE TABLE duplicate_amounts (
    id INT,
    amount INT
);

INSERT INTO duplicate_amounts VALUES
(1, 100),
(2, 100),
(3, 200),
(4, 300);


-- ROWS
-- Works based on physical row positions

SELECT
    id,
    amount,
    SUM(amount) OVER (
        ORDER BY amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rows_running_total
FROM duplicate_amounts
ORDER BY amount, id;


-- RANGE
-- Works based on ORDER BY values and peer rows

SELECT
    id,
    amount,
    SUM(amount) OVER (
        ORDER BY amount
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS range_running_total
FROM duplicate_amounts
ORDER BY amount, id;


-- =========================================================
-- 13. COMPARE ROWS AND RANGE TOGETHER
-- =========================================================

SELECT
    id,
    amount,

    SUM(amount) OVER (
        ORDER BY amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rows_running_total,

    SUM(amount) OVER (
        ORDER BY amount
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS range_running_total

FROM duplicate_amounts
ORDER BY amount, id;


-- =========================================================
-- 14. TIME-BASED RANGE WINDOW
-- LAST 7 DAYS
-- =========================================================

CREATE OR REPLACE TABLE daily_sales (
    sale_date DATE,
    amount INT
);

INSERT INTO daily_sales VALUES
('2026-01-01', 100),
('2026-01-02', 200),
('2026-01-05', 300),
('2026-01-08', 400),
('2026-01-10', 500),
('2026-01-15', 600);


SELECT
    sale_date,
    amount,
    SUM(amount) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL '7 DAYS' PRECEDING AND CURRENT ROW
    ) AS last_7_days_sales
FROM daily_sales
ORDER BY sale_date;


-- =========================================================
-- 15. LAST 30 DAYS AVERAGE
-- =========================================================

SELECT
    sale_date,
    amount,
    AVG(amount) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL '30 DAYS' PRECEDING AND CURRENT ROW
    ) AS last_30_days_average
FROM daily_sales
ORDER BY sale_date;


-- =========================================================
-- 16. LAST 3 ROWS VS LAST 3 DAYS
-- =========================================================

SELECT
    sale_date,
    amount,

    AVG(amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS last_3_rows_average,

    AVG(amount) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL '3 DAYS' PRECEDING AND CURRENT ROW
    ) AS last_3_days_average

FROM daily_sales
ORDER BY sale_date;


-- =========================================================
-- 17. PARTITION + WINDOW FRAME
-- =========================================================

SELECT
    customer_id,
    transaction_date,
    amount,

    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS customer_3_row_moving_average

FROM transactions
ORDER BY customer_id, transaction_date;


-- =========================================================
-- 18. PRACTICE QUESTIONS
-- =========================================================

-- Q1:
-- Calculate the running total of transaction amounts
-- for each customer.

-- Q2:
-- Calculate the total of the current transaction
-- and the previous 3 transactions.

-- Q3:
-- Calculate a 5-row moving average.

-- Q4:
-- Calculate the average using:
-- previous row + current row + next row.

-- Q5:
-- Calculate the remaining total from the current
-- transaction until the last transaction.

-- Q6:
-- Calculate the total transaction amount
-- from the previous 7 days.

-- Q7:
-- Compare ROWS and RANGE using duplicate values.

-- Q8:
-- For each customer, calculate a 3-row moving average.


-- =========================================================
-- END OF WINDOW FRAMES PRACTICE
-- =========================================================
