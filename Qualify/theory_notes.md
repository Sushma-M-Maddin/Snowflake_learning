# SQL QUALIFY

## Table of Contents

1. [What is QUALIFY?](#1-what-is-qualify)
2. [Why do we need QUALIFY?](#2-why-do-we-need-qualify)
3. [WHERE vs QUALIFY](#3-where-vs-qualify)
4. [WHERE vs HAVING vs QUALIFY](#4-where-vs-having-vs-qualify)
5. [Logical Difference](#5-logical-difference)
6. [Latest Transaction per Customer](#6-latest-transaction-per-customer)
7. [Why ORDER BY DESC?](#7-why-order-by-desc)
8. [Top-N per Group](#8-top-n-per-group)
9. [Top 1 per Group](#9-top-1-per-group)
10. [Top 3 per Group](#10-top-3-per-group)
11. [Deduplication](#11-deduplication)
12. [Deduplication Pattern](#12-deduplication-pattern)
13. [What Defines a Duplicate?](#13-what-defines-a-duplicate)
14. [QUALIFY with RANK()](#14-qualify-with-rank)
15. [QUALIFY with DENSE_RANK()](#15-qualify-with-dense_rank)
16. [QUALIFY with LAG()](#16-qualify-with-lag)
17. [QUALIFY with LEAD()](#17-qualify-with-lead)
18. [QUALIFY vs Subquery](#18-qualify-vs-subquery)
19. [Top-N vs LIMIT](#19-top-n-vs-limit)
20. [Real-World Applications](#20-real-world-applications)
21. [Common Pattern: Latest Record](#21-common-pattern-latest-record)
22. [Common Pattern: Top-N](#22-common-pattern-top-n)
23. [Common Pattern: Deduplication](#23-common-pattern-deduplication)
24. [Important Interview Questions](#24-important-interview-questions)
25. [Common Mistakes](#25-common-mistakes)
26. [Interview Mental Model](#26-interview-mental-model)
27. [Final Revision](#27-final-revision)

---

## 1. What is QUALIFY?

`QUALIFY` is used to filter the results of Window Functions.

The easiest way to remember it:

```text
WHERE   → Filters individual rows.
HAVING  → Filters groups created by GROUP BY.
QUALIFY → Filters Window Function results.
```

```sql
SELECT
    customer_id,
    transaction_date,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS row_num
FROM transactions
QUALIFY row_num = 1;
```

This means:

1. Divide transactions by customer.
2. Order each customer's transactions from latest to oldest.
3. Assign row numbers.
4. Keep only row number 1.

Therefore, we get the latest transaction for each customer.

---

## 2. Why do we need QUALIFY?

A common problem is filtering a Window Function result. For example:

```sql
ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
)
```

We want `row_number = 1`. We cannot normally do:

```sql
WHERE row_num = 1
```

because `WHERE` is evaluated before the Window Function result is available. This is why Snowflake provides `QUALIFY`.

---

## 3. WHERE vs QUALIFY

`WHERE` filters rows before Window Functions are calculated:

```sql
SELECT *
FROM transactions
WHERE amount > 100;
```

This filters the original rows.

`QUALIFY` filters after the Window Function has been calculated:

```sql
SELECT
    customer_id,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY amount DESC
    ) AS rn
FROM transactions
QUALIFY rn = 1;
```

The logical idea:

```text
FROM
  ↓
WHERE
  ↓
GROUP BY
  ↓
HAVING
  ↓
Window Functions
  ↓
QUALIFY
  ↓
ORDER BY
  ↓
LIMIT
```

---

## 4. WHERE vs HAVING vs QUALIFY

| Clause | Filters | Example | Meaning |
|---|---|---|---|
| `WHERE` | Individual rows | `WHERE amount > 100` | Keep rows where amount is greater than 100. |
| `HAVING` | Groups after `GROUP BY` | `GROUP BY customer_id HAVING SUM(amount) > 1000` | Keep customers whose total amount is greater than 1000. |
| `QUALIFY` | Window Function results | `QUALIFY ROW_NUMBER() OVER (...) = 1` | Keep rows where the Window Function result is 1. |

---

## 5. Logical Difference

```text
WHERE           → Row filter
GROUP BY        → Group rows
HAVING          → Group filter
WINDOW FUNCTION → Calculate across rows
QUALIFY         → Window-result filter
```

---

## 6. Latest Transaction per Customer

| customer_id | transaction_date | amount |
| ----------- | ----------------- | -----: |
| 101         | 2026-01-01        |    100 |
| 101         | 2026-01-05        |    200 |
| 101         | 2026-01-10        |    150 |
| 102         | 2026-01-02        |    500 |
| 102         | 2026-01-08        |    700 |

Requirement: get the latest transaction for each customer.

```sql
SELECT
    customer_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;
```

Result:

| customer_id | transaction_date | amount |
| ----------- | ----------------- | -----: |
| 101         | 2026-01-10        |    150 |
| 102         | 2026-01-08        |    700 |

---

## 7. Why ORDER BY DESC?

We want the latest transaction, so `ORDER BY transaction_date DESC` puts the newest transaction first:

```text
2026-01-10 → 1
2026-01-05 → 2
2026-01-01 → 3
```

Then `QUALIFY row_number = 1` keeps the latest transaction.

---

## 8. Top-N per Group

`QUALIFY` is extremely useful for Top-N problems.

Requirement: get the top 3 transactions for each customer.

```sql
SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 3;
```

The pattern:

```text
PARTITION BY   → Define the group.
ORDER BY DESC  → Put the highest values first.
ROW_NUMBER()   → Number the rows.
QUALIFY <= N   → Keep the top N.
```

---

## 9. Top 1 per Group

Requirement: get the highest transaction for every customer.

```sql
SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) = 1;
```

---

## 10. Top 3 per Group

```sql
SELECT
    customer_id,
    transaction_id,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 3;
```

---

## 11. Deduplication

`QUALIFY` is commonly used to remove duplicate records.

| customer_id | name   | updated_at |
| ----------- | ------ | ---------- |
| 101         | Sushma | 2026-08-01 |
| 101         | Sushma | 2026-08-05 |
| 102         | Rahul  | 2026-08-02 |
| 103         | Priya  | 2026-08-03 |
| 103         | Priya  | 2026-08-07 |

Requirement: keep only the latest record for each customer.

```sql
SELECT
    customer_id,
    name,
    updated_at
FROM customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;
```

Result:

| customer_id | name   | updated_at |
| ----------- | ------ | ---------- |
| 101         | Sushma | 2026-08-05 |
| 102         | Rahul  | 2026-08-02 |
| 103         | Priya  | 2026-08-07 |

---

## 12. Deduplication Pattern

```text
Identify business key
        ↓
PARTITION BY business key
        ↓
Decide which record should be kept
        ↓
ORDER BY timestamp DESC
        ↓
ROW_NUMBER()
        ↓
QUALIFY = 1
```

```sql
SELECT *
FROM customer_data
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;
```

---

## 13. What Defines a Duplicate?

This is a very important Data Engineering concept. Do not automatically assume `PARTITION BY customer_id` is always correct — you need to understand the business key.

For example, suppose `customer_id`, `product_id`, and `transaction_date` together identify a unique transaction. Then:

```sql
PARTITION BY
    customer_id,
    product_id,
    transaction_date
```

may be appropriate.

The question to ask: **which columns define a duplicate according to the business requirement?**

---

## 14. QUALIFY with RANK()

`QUALIFY` is not limited to `ROW_NUMBER()`.

```sql
SELECT
    employee_id,
    department,
    salary,
    RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS salary_rank
FROM employees
QUALIFY salary_rank <= 3;
```

This keeps employees whose salary rank is within the top 3 in each department.

---

## 15. QUALIFY with DENSE_RANK()

```sql
SELECT
    employee_id,
    department,
    salary,
    DENSE_RANK() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS salary_rank
FROM employees
QUALIFY salary_rank <= 3;
```

This handles ties differently from `ROW_NUMBER()` and `RANK()`:

```text
ROW_NUMBER() → Every row gets a unique number.
RANK()       → Ties share rank and gaps can occur.
DENSE_RANK() → Ties share rank and no gaps occur.
```

---

## 16. QUALIFY with LAG()

`QUALIFY` can also filter based on navigation Window Functions.

```sql
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
```

This removes the first transaction for each customer because it has no previous transaction.

---

## 17. QUALIFY with LEAD()

```sql
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
```

This removes the last transaction for each customer because it has no next transaction.

---

## 18. QUALIFY vs Subquery

Before `QUALIFY`, we could solve the latest-record problem with a subquery:

```sql
SELECT *
FROM (
    SELECT
        customer_id,
        transaction_date,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY transaction_date DESC
        ) AS rn
    FROM transactions
)
WHERE rn = 1;
```

With `QUALIFY`:

```sql
SELECT
    customer_id,
    transaction_date,
    amount
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;
```

The `QUALIFY` version is shorter and easier to read.

---

## 19. Top-N vs LIMIT

`LIMIT` does not solve Top-N per group.

```sql
SELECT *
FROM transactions
ORDER BY amount DESC
LIMIT 3;
```

This gives the top 3 rows from the **entire table**. It does **not** give top 3 for Customer 101, top 3 for Customer 102, top 3 for Customer 103, etc.

For Top-N per group, use:

```text
PARTITION BY + ROW_NUMBER() + QUALIFY
```

---

## 20. Real-World Applications

`QUALIFY` is useful for:

- Latest record per customer
- Latest transaction
- Top-N products per category
- Top-N employees per department
- Deduplication
- Latest CDC record
- Selecting the current version of a record
- Filtering ranking results
- Filtering `LAG`/`LEAD` results
- Data quality processing
- Incremental data processing

---

## 21. Common Pattern: Latest Record

```sql
SELECT *
FROM customer_data
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;
```

---

## 22. Common Pattern: Top-N

```sql
SELECT *
FROM sales
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY category
    ORDER BY sales_amount DESC
) <= 3;
```

---

## 23. Common Pattern: Deduplication

```sql
SELECT *
FROM source_data
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY business_key
    ORDER BY updated_at DESC
) = 1;
```

---

## 24. Important Interview Questions

**What is QUALIFY?**
`QUALIFY` is used to filter the results of Window Functions.

**Why can't WHERE be used directly with ROW_NUMBER()?**
Because `WHERE` is evaluated before the Window Function result is calculated. `QUALIFY` is evaluated after Window Functions, so it can filter their results.

**What is the difference between WHERE, HAVING and QUALIFY?**
`WHERE` filters rows. `HAVING` filters groups. `QUALIFY` filters Window Function results.

**How do you find the latest transaction for each customer?**
```sql
SELECT *
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;
```

**How do you find the top 3 transactions per customer?**
```sql
SELECT *
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY amount DESC
) <= 3;
```

**How do you remove duplicate records while keeping the latest?**
```sql
SELECT *
FROM customer_data
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1;
```

---

## 25. Common Mistakes

**Mistake 1: Using WHERE for Window Function results**

Incorrect:
```sql
WHERE row_num = 1
```
when `row_num` is created by a Window Function in the same query level. Use:
```sql
QUALIFY row_num = 1
```

**Mistake 2: Using GROUP BY for Top-N per Group**

`GROUP BY` collapses rows into groups. Window Functions preserve the original rows. For Top-N per group, use `ROW_NUMBER() + PARTITION BY + QUALIFY`.

**Mistake 3: Using LIMIT for Top-N per Group**

`LIMIT 3` returns only 3 rows from the overall result — it does not return 3 rows for every group.

**Mistake 4: Wrong PARTITION BY**

If you use `PARTITION BY employee_id`, every employee becomes their own group. For "Top 3 employees per department," you need `PARTITION BY department`.

**Mistake 5: Wrong ORDER BY Direction**

```text
Latest record       → ORDER BY updated_at DESC
Oldest record        → ORDER BY updated_at ASC
Highest salary        → ORDER BY salary DESC
Lowest salary          → ORDER BY salary ASC
```

---

## 26. Interview Mental Model

When you hear **"Latest record per group"**, think:

```text
PARTITION BY group
        ↓
ORDER BY date DESC
        ↓
ROW_NUMBER()
        ↓
QUALIFY = 1
```

When you hear **"Top N per group"**, think:

```text
PARTITION BY group
        ↓
ORDER BY metric DESC
        ↓
ROW_NUMBER()
        ↓
QUALIFY <= N
```

When you hear **"Deduplicate and keep latest"**, think:

```text
PARTITION BY business key
        ↓
ORDER BY updated_at DESC
        ↓
ROW_NUMBER()
        ↓
QUALIFY = 1
```

---

## 27. Final Revision

```text
QUALIFY      → Filters Window Function results.
WHERE        → Filters rows.
HAVING       → Filters groups.

ROW_NUMBER() → Useful for unique ordering.
RANK()       → Ties share rank; gaps can occur.
DENSE_RANK() → Ties share rank; no gaps.

Top-N per group   → PARTITION BY + ORDER BY + ROW_NUMBER() + QUALIFY
Latest record     → ORDER BY date DESC + QUALIFY = 1
Deduplication     → PARTITION BY business key + ORDER BY updated_at DESC + QUALIFY = 1
```

## Most Important QUALIFY Pattern

```sql
SELECT *
FROM table_name
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY business_key
    ORDER BY updated_at DESC
) = 1;
```

This pattern is extremely important for Snowflake Data Engineering.
