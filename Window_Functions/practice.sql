-- ============================================================
-- SQL WINDOW FUNCTIONS - PRACTICE QUERIES
-- ============================================================
--
-- Topics Covered:
-- 1. OVER()
-- 2. Aggregate Window Functions
-- 3. PARTITION BY
-- 4. ORDER BY inside Window Functions
-- 5. Running Totals
-- 6. ROW_NUMBER()
-- 7. RANK()
-- 8. DENSE_RANK()
-- 9. QUALIFY
-- 10. LAG()
-- 11. LEAD()
--
-- Database: Snowflake
--
-- ============================================================
-- TABLES USED
-- ============================================================
--
-- CUSTOMERS
-- ----------
-- customer_id
-- customer_name
-- email
-- city
-- created_at
--
-- TRANSACTIONS
-- ------------
-- transaction_id
-- customer_id
-- amount
-- transaction_date
-- status
--
-- EMPLOYEES
-- ---------
-- employee_id
-- employee_name
-- department_id
-- salary
-- hire_date
--
-- SALES
-- -----
-- sale_id
-- product_id
-- customer_id
-- sale_date
-- sales_amount
--
-- ============================================================


-- ============================================================
-- 1. BASIC OVER()
-- ============================================================

-- 1. Find the total transaction amount while keeping
-- every individual transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER () AS total_transaction_amount
FROM transactions;


-- 2. Find the average transaction amount while keeping
-- every transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    AVG(amount) OVER () AS average_transaction_amount
FROM transactions;


-- 3. Find the total number of transactions while keeping
-- every transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    COUNT(transaction_id) OVER () AS total_transaction_count
FROM transactions;


-- 4. Show the maximum transaction amount along with
-- every transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    MAX(amount) OVER () AS highest_transaction_amount
FROM transactions;


-- 5. Show the minimum transaction amount along with
-- every transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    MIN(amount) OVER () AS lowest_transaction_amount
FROM transactions;


-- ============================================================
-- 2. PARTITION BY
-- ============================================================

-- 6. Find the total transaction amount for each customer
-- while keeping every transaction row.

SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_total_transaction_amount
FROM transactions;


-- 7. Count the total number of transactions made by
-- each customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    COUNT(transaction_id) OVER (
        PARTITION BY customer_id
    ) AS customer_transaction_count
FROM transactions;


-- 8. Find the average transaction amount for each customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    AVG(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_average_transaction_amount
FROM transactions;


-- 9. Find the highest transaction amount made by
-- each customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    MAX(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_highest_transaction
FROM transactions;


-- 10. Find the lowest transaction amount made by
-- each customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    MIN(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_lowest_transaction
FROM transactions;


-- ============================================================
-- 3. ORDER BY INSIDE WINDOW FUNCTIONS
-- ============================================================

-- 11. Display transactions in sequence and assign
-- a unique row number based on transaction date.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    ROW_NUMBER() OVER (
        ORDER BY transaction_date
    ) AS transaction_sequence
FROM transactions;


-- 12. Assign row numbers based on highest transaction amount.

SELECT
    transaction_id,
    customer_id,
    amount,
    ROW_NUMBER() OVER (
        ORDER BY amount DESC
    ) AS transaction_rank_number
FROM transactions;


-- ============================================================
-- 4. RUNNING TOTAL
-- ============================================================

-- 13. Calculate the running total of all transaction amounts
-- based on transaction date.

SELECT
    transaction_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        ORDER BY transaction_date
    ) AS running_total
FROM transactions;


-- 14. Calculate the running total separately for
-- each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS customer_running_total
FROM transactions;


-- 15. Calculate the running total of successful
-- transactions for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS successful_transaction_running_total
FROM transactions
WHERE status = 'SUCCESSFUL';


-- ============================================================
-- 5. ROW_NUMBER()
-- ============================================================

-- 16. Assign a unique row number to every employee
-- based on highest salary.

SELECT
    employee_id,
    employee_name,
    salary,
    ROW_NUMBER() OVER (
        ORDER BY salary DESC
    ) AS row_num
FROM employees;


-- 17. Assign row numbers to employees separately
-- within each department based on salary.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary,
    ROW_NUMBER() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS department_row_num
FROM employees;


-- 18. Find the latest transaction for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;


-- 19. Find the first transaction for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date ASC
) = 1;


-- 20. Find the highest-paid employee from each department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) = 1;


-- 21. Find the lowest-paid employee from each department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY department_id
    ORDER BY salary ASC
) = 1;


-- ============================================================
-- 6. ROW_NUMBER() AND DUPLICATE RECORDS
-- ============================================================

-- 22. Identify duplicate customer email records.

SELECT
    customer_id,
    customer_name,
    email,
    created_at,
    ROW_NUMBER() OVER (
        PARTITION BY email
        ORDER BY created_at DESC
    ) AS row_num
FROM customers;


-- 23. Keep only the latest customer record for
-- each duplicate email.

SELECT
    customer_id,
    customer_name,
    email,
    created_at
FROM customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY email
    ORDER BY created_at DESC
) = 1;


-- 24. Identify duplicate records where row number
-- is greater than 1.

SELECT
    customer_id,
    customer_name,
    email,
    created_at
FROM customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY email
    ORDER BY created_at DESC
) > 1;


-- ============================================================
-- 7. RANK()
-- ============================================================

-- 25. Rank employees based on salary.

SELECT
    employee_id,
    employee_name,
    salary,
    RANK() OVER (
        ORDER BY salary DESC
    ) AS salary_rank
FROM employees;


-- 26. Rank employees by salary within each department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary,
    RANK() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS department_salary_rank
FROM employees;


-- 27. Find the highest-paid employees in every department.
-- RANK() allows all employees with the same highest salary
-- to be returned.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY RANK() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) = 1;


-- 28. Find the top 3 ranked employees based on salary.

SELECT
    employee_id,
    employee_name,
    salary,
    RANK() OVER (
        ORDER BY salary DESC
    ) AS salary_rank
FROM employees
QUALIFY RANK() OVER (
    ORDER BY salary DESC
) <= 3;


-- ============================================================
-- 8. DENSE_RANK()
-- ============================================================

-- 29. Assign dense ranks to employees based on salary.

SELECT
    employee_id,
    employee_name,
    salary,
    DENSE_RANK() OVER (
        ORDER BY salary DESC
    ) AS salary_dense_rank
FROM employees;


-- 30. Assign dense ranks within each department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary,
    DENSE_RANK() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS department_salary_dense_rank
FROM employees;


-- 31. Find employees belonging to the top 3
-- distinct salary levels.

SELECT
    employee_id,
    employee_name,
    salary
FROM employees
QUALIFY DENSE_RANK() OVER (
    ORDER BY salary DESC
) <= 3;


-- ============================================================
-- 9. ROW_NUMBER() VS RANK() VS DENSE_RANK()
-- ============================================================

-- 32. Compare all three ranking functions.

SELECT
    employee_id,
    employee_name,
    salary,

    ROW_NUMBER() OVER (
        ORDER BY salary DESC
    ) AS row_number_value,

    RANK() OVER (
        ORDER BY salary DESC
    ) AS rank_value,

    DENSE_RANK() OVER (
        ORDER BY salary DESC
    ) AS dense_rank_value

FROM employees;


-- ============================================================
-- 10. QUALIFY
-- ============================================================

-- 33. Find the top 2 highest-paid employees
-- from every department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) <= 2;


-- 34. Find the latest 3 transactions for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) <= 3;


-- 35. Find the top 2 transaction amounts
-- for each customer.

SELECT
    transaction_id,
    customer_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 2;


-- ============================================================
-- 11. LAG()
-- ============================================================

-- 36. Find the previous transaction amount.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LAG(amount) OVER (
        ORDER BY transaction_date
    ) AS previous_transaction_amount
FROM transactions;


-- 37. Find the previous transaction amount
-- separately for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS previous_transaction_amount
FROM transactions;


-- 38. Calculate the difference between the current
-- transaction amount and the previous transaction amount.

SELECT
    transaction_id,
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
    ) AS amount_difference

FROM transactions;


-- 39. Find the transaction amount from two transactions ago.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LAG(amount, 2) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS two_transactions_previous_amount
FROM transactions;


-- 40. Use a default value of 0 when there is
-- no previous transaction.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LAG(amount, 1, 0) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS previous_amount
FROM transactions;


-- ============================================================
-- 12. LEAD()
-- ============================================================

-- 41. Find the next transaction amount.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LEAD(amount) OVER (
        ORDER BY transaction_date
    ) AS next_transaction_amount
FROM transactions;


-- 42. Find the next transaction amount
-- separately for each customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LEAD(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS next_transaction_amount
FROM transactions;


-- 43. Calculate the difference between the next
-- transaction amount and current transaction amount.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LEAD(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS next_amount,

    LEAD(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) - amount AS next_amount_difference

FROM transactions;


-- 44. Find the transaction amount two transactions ahead.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    LEAD(amount, 2) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS two_transactions_ahead_amount
FROM transactions;


-- ============================================================
-- 13. REAL-WORLD PRACTICE QUESTIONS
-- ============================================================

-- 45. Find every transaction along with the customer's
-- total transaction amount.

SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_total_amount
FROM transactions;


-- 46. Find every transaction along with the customer's
-- total number of transactions.

SELECT
    transaction_id,
    customer_id,
    amount,
    COUNT(transaction_id) OVER (
        PARTITION BY customer_id
    ) AS total_customer_transactions
FROM transactions;


-- 47. Find the latest successful transaction for
-- every customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount
FROM transactions
WHERE status = 'SUCCESSFUL'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;


-- 48. Find customers whose latest transaction
-- amount is greater than 100000.

SELECT
    customer_id,
    transaction_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1
AND amount > 100000;


-- 49. Find the top 3 largest transactions for
-- each customer.

SELECT
    transaction_id,
    customer_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 3;


-- 50. Find customers whose current transaction
-- is greater than their previous transaction.

WITH transaction_comparison AS (
    SELECT
        transaction_id,
        customer_id,
        transaction_date,
        amount,

        LAG(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_amount

    FROM transactions
)

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    previous_amount
FROM transaction_comparison
WHERE amount > previous_amount;


-- 51. Find transactions where the amount decreased
-- compared to the previous transaction.

WITH transaction_comparison AS (
    SELECT
        transaction_id,
        customer_id,
        transaction_date,
        amount,

        LAG(amount) OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date
        ) AS previous_amount

    FROM transactions
)

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    previous_amount,
    amount - previous_amount AS amount_change
FROM transaction_comparison
WHERE amount < previous_amount;


-- 52. Find the difference between each employee's
-- salary and the average salary of their department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary,

    AVG(salary) OVER (
        PARTITION BY department_id
    ) AS department_average_salary,

    salary -
    AVG(salary) OVER (
        PARTITION BY department_id
    ) AS salary_difference_from_department_average

FROM employees;


-- 53. Find employees earning more than their
-- department's average salary.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary,
    AVG(salary) OVER (
        PARTITION BY department_id
    ) AS department_average_salary
FROM employees
QUALIFY salary >
    AVG(salary) OVER (
        PARTITION BY department_id
    );


-- 54. Find every transaction along with the highest
-- transaction amount made by that customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    MAX(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_highest_transaction
FROM transactions;


-- 55. Find transactions that are equal to the
-- highest transaction amount of their customer.

SELECT
    transaction_id,
    customer_id,
    amount,
    MAX(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_highest_transaction
FROM transactions
QUALIFY amount =
    MAX(amount) OVER (
        PARTITION BY customer_id
    );


-- 56. Find the first and latest transaction
-- for every customer.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date ASC
    ) AS first_transaction_row,

    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS latest_transaction_row

FROM transactions;


-- ============================================================
-- 14. IMPORTANT INTERVIEW PRACTICE
-- ============================================================

-- 57. Find the second highest salary.

SELECT
    employee_id,
    employee_name,
    salary
FROM employees
QUALIFY DENSE_RANK() OVER (
    ORDER BY salary DESC
) = 2;


-- 58. Find the second highest salary from
-- every department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY DENSE_RANK() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) = 2;


-- 59. Find the top 3 highest-paid employees
-- from each department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) <= 3;


-- 60. Find all employees belonging to the
-- highest salary rank in every department.

SELECT
    employee_id,
    employee_name,
    department_id,
    salary
FROM employees
QUALIFY RANK() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) = 1;


-- 61. Find customers with more than one transaction
-- and show every individual transaction.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,
    COUNT(transaction_id) OVER (
        PARTITION BY customer_id
    ) AS customer_transaction_count
FROM transactions
QUALIFY COUNT(transaction_id) OVER (
    PARTITION BY customer_id
) > 1;


-- 62. Find each customer's latest transaction
-- along with their total number of transactions.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    amount,

    COUNT(transaction_id) OVER (
        PARTITION BY customer_id
    ) AS total_customer_transactions

FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;


-- ============================================================
-- END OF WINDOW FUNCTIONS PRACTICE
-- ============================================================


-- QUICK REVISION
--
-- Keep original rows + calculate across rows:
-- FUNCTION() OVER ()
--
-- Calculate separately for each entity:
-- PARTITION BY entity_id
--
-- Sequence matters:
-- ORDER BY column
--
-- Running Total:
-- SUM(column) OVER (
--     PARTITION BY ...
--     ORDER BY ...
-- )
--
-- Latest record:
-- ROW_NUMBER() OVER (
--     PARTITION BY ...
--     ORDER BY date DESC
-- )
--
-- Filter Window Function:
-- QUALIFY
--
-- Previous row:
-- LAG()
--
-- Next row:
-- LEAD()
--
-- Unique numbering:
-- ROW_NUMBER()
--
-- Ranking with gaps:
-- RANK()
--
-- Ranking without gaps:
-- DENSE_RANK()
--
-- ============================================================