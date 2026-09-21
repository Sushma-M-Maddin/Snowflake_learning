-- ============================================================
-- DATE & TIME FUNCTIONS PRACTICE
-- Snowflake
-- ============================================================


-- ============================================================
-- 1. SAMPLE TABLE
-- ============================================================

CREATE OR REPLACE TABLE transactions (
    transaction_id INT,
    customer_id INT,
    transaction_time TIMESTAMP_NTZ,
    amount NUMBER(10,2)
);

INSERT INTO transactions VALUES
(1, 101, '2026-08-15 09:15:00', 500),
(2, 101, '2026-08-28 14:30:00', 300),
(3, 101, '2026-09-05 11:00:00', 700),
(4, 102, '2026-09-10 08:45:00', 200),
(5, 102, '2026-09-21 10:30:45', 900),
(6, 103, '2026-09-30 23:55:00', 400),
(7, 103, '2026-10-01 00:05:00', 600);

SELECT *
FROM transactions
ORDER BY transaction_time;


-- ============================================================
-- 2. CURRENT DATE / TIMESTAMP
-- ============================================================

SELECT CURRENT_DATE();
SELECT CURRENT_TIMESTAMP();


-- ============================================================
-- 3. DATEADD — MOVE FORWARD / BACKWARD
-- ============================================================

SELECT DATEADD(day, 7, '2026-09-21');
SELECT DATEADD(month, -1, '2026-09-21');
SELECT DATEADD(year, 1, '2026-09-21');


-- ============================================================
-- 4. DATEDIFF — DIFFERENCE
-- ============================================================

SELECT DATEDIFF(day, '2026-09-01', '2026-09-21') AS days_between;

-- Per-row example: days since transaction
SELECT
    transaction_id,
    transaction_time,
    DATEDIFF(day, transaction_time, CURRENT_DATE()) AS days_since_transaction
FROM transactions
ORDER BY transaction_time;


-- ============================================================
-- 5. DATE_TRUNC — BEGINNING OF PERIOD
-- ============================================================

SELECT DATE_TRUNC('month', '2026-09-21'::DATE);
SELECT DATE_TRUNC('week', '2026-09-21'::DATE);
SELECT DATE_TRUNC('quarter', '2026-09-21'::DATE);
SELECT DATE_TRUNC('year', '2026-09-21'::DATE);


-- ============================================================
-- 6. EXTRACT() AND DATE_PART()
-- ============================================================

SELECT EXTRACT(year FROM '2026-09-21'::DATE);
SELECT EXTRACT(month FROM '2026-09-21'::DATE);
SELECT EXTRACT(day FROM '2026-09-21'::DATE);

SELECT DATE_PART(year, '2026-09-21'::DATE);
SELECT DATE_PART(month, '2026-09-21'::DATE);


-- ============================================================
-- 7. DAYNAME / DAYOFWEEK / DAYOFYEAR
-- ============================================================

SELECT
    transaction_id,
    transaction_time,
    DAYNAME(transaction_time) AS day_name,
    DAYOFWEEK(transaction_time) AS day_of_week,
    DAYOFYEAR(transaction_time) AS day_of_year
FROM transactions
ORDER BY transaction_time;


-- ============================================================
-- 8. TYPE CONVERSIONS — TO_DATE / TO_TIMESTAMP / TO_CHAR
-- ============================================================

SELECT TO_DATE('2026-09-21');
SELECT TO_TIMESTAMP('2026-09-21 10:30:00');
SELECT TO_CHAR('2026-09-21'::DATE, 'YYYY-MM-DD');
SELECT TO_CHAR('2026-09-21'::DATE, 'DD-Mon-YYYY');

-- Explicit format mask for a non-default string format
SELECT TO_DATE('21-Sep-2026', 'DD-Mon-YYYY');


-- ============================================================
-- 9. LAST_DAY
-- ============================================================

SELECT LAST_DAY('2026-09-21'::DATE);                 -- last day of month
SELECT LAST_DAY('2026-09-21'::DATE, 'quarter');       -- last day of quarter
SELECT LAST_DAY('2026-09-21'::DATE, 'year');          -- last day of year


-- ============================================================
-- 10. SPECIFIC-MONTH FILTER — HALF-OPEN RANGE
-- ============================================================

SELECT *
FROM transactions
WHERE transaction_time >= '2026-09-01'
  AND transaction_time < '2026-10-01'
ORDER BY transaction_time;

-- Compare: this catches transaction_id 6 (Sep 30, 23:55) correctly,
-- while transaction_id 7 (Oct 1, 00:05) is correctly excluded.


-- ============================================================
-- 11. MONTHLY AGGREGATION
-- ============================================================

SELECT
    DATE_TRUNC('month', transaction_time) AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_time)
ORDER BY transaction_month;


-- ============================================================
-- 12. CUSTOMER TENURE / AGE-STYLE CALCULATION
-- ============================================================

CREATE OR REPLACE TABLE customers (
    customer_id INT,
    customer_name VARCHAR,
    signup_date DATE
);

INSERT INTO customers VALUES
(101, 'Ravi', '2025-01-15'),
(102, 'Priya', '2025-06-20'),
(103, 'Amit', '2026-03-10');

SELECT
    customer_id,
    customer_name,
    signup_date,
    DATEDIFF(day, signup_date, CURRENT_DATE()) AS tenure_days,
    DATEDIFF(month, signup_date, CURRENT_DATE()) AS tenure_months
FROM customers
ORDER BY signup_date;


-- ============================================================
-- 13. SLA / DURATION EXAMPLE
-- ============================================================

CREATE OR REPLACE TABLE support_tickets (
    ticket_id INT,
    opened_at TIMESTAMP_NTZ,
    resolved_at TIMESTAMP_NTZ
);

INSERT INTO support_tickets VALUES
(1, '2026-09-10 09:00:00', '2026-09-10 15:00:00'),
(2, '2026-09-11 08:00:00', '2026-09-12 11:00:00'),
(3, '2026-09-12 10:00:00', '2026-09-12 10:45:00');

SELECT
    ticket_id,
    opened_at,
    resolved_at,
    DATEDIFF(hour, opened_at, resolved_at) AS resolution_hours,
    DATEDIFF(hour, opened_at, resolved_at) > 24 AS sla_breached
FROM support_tickets
ORDER BY ticket_id;


-- ============================================================
-- 14. LAST 90 DAYS FILTER
-- ============================================================

SELECT *
FROM transactions
WHERE transaction_time >= DATEADD(day, -90, CURRENT_DATE())
ORDER BY transaction_time;


-- ============================================================
-- 15. PRACTICE QUESTIONS
-- ============================================================

-- Q1.
-- Return all transactions from September 2026 using a
-- half-open range filter.

-- Q2.
-- Return monthly transaction count and total amount.

-- Q3.
-- Calculate each customer's tenure in days as of today.

-- Q4.
-- Find support tickets that breached a 24-hour SLA.

-- Q5.
-- Return the day name and day of week for each transaction.

-- Q6.
-- Find the last day of the quarter for '2026-09-21'.

-- Q7.
-- Return transactions from the last 90 days.

-- Q8.
-- Convert the string '21-Sep-2026' into a DATE value.


-- ============================================================
-- 16. INTERVIEW PRACTICE
-- ============================================================

-- 1. What is the difference between DATE and TIMESTAMP?

-- 2. What is the difference between TIMESTAMP_NTZ,
--    TIMESTAMP_LTZ, and TIMESTAMP_TZ?

-- 3. Why can DATEDIFF return a negative number?

-- 4. Why is a range filter preferred over DATE_TRUNC
--    equality when filtering a TIMESTAMP column?

-- 5. What does DATE_TRUNC('month', date) return for
--    any date in that month?

-- 6. How would you calculate someone's tenure in days?

-- 7. What's the difference between EXTRACT() and
--    DATE_PART()?

-- 8. Why might a TIMESTAMP_LTZ column appear to show
--    different times to different users?


-- ============================================================
-- END OF DATE & TIME PRACTICE
-- ============================================================
