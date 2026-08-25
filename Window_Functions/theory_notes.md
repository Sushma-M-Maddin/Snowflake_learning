# SQL Window Functions — Complete Theory Notes

> Part 1 — Fundamentals: `OVER()`, `PARTITION BY`, `ORDER BY`, Aggregate Window Functions, Running Totals, `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `QUALIFY`, `LAG()`, `LEAD()`

## Table of Contents

1. [Why Do We Need Window Functions?](#1-why-do-we-need-window-functions)
2. [What Is a Window Function?](#2-what-is-a-window-function)
3. [The Most Important Concept](#3-the-most-important-concept)
4. [GROUP BY vs Window Functions](#4-group-by-vs-window-functions)
5. [What Does OVER() Mean?](#5-what-does-over-mean)
6. [Basic Window Function Syntax](#6-basic-window-function-syntax)
7. [Understanding PARTITION BY](#7-understanding-partition-by)
8. [PARTITION BY Does Not Collapse Rows](#8-partition-by-does-not-collapse-rows)
9. [How to Choose the PARTITION BY Column](#9-how-to-choose-the-partition-by-column)
10. [Common PARTITION BY Mistake](#10-common-partition-by-mistake)
11. [ORDER BY Inside a Window Function](#11-order-by-inside-a-window-function)
12. [Why ORDER BY Is Important](#12-why-order-by-is-important)
13. [PARTITION BY and ORDER BY Together](#13-partition-by-and-order-by-together)
14. [Window Functions and Aggregate Functions](#14-window-functions-and-aggregate-functions)
15. [SUM() as a Window Function](#15-sum-as-a-window-function)
16. [COUNT() as a Window Function](#16-count-as-a-window-function)
17. [AVG() as a Window Function](#17-avg-as-a-window-function)
18. [MIN() and MAX() as Window Functions](#18-min-and-max-as-window-functions)
19. [Running Total](#19-running-total)
20. [Why Running Totals Need ORDER BY](#20-why-running-totals-need-order-by)
21. [Running Total for Each Customer](#21-running-total-for-each-customer)
22. [Window Function Categories](#22-window-function-categories)
23. [ROW_NUMBER()](#23-row_number)
24. [ROW_NUMBER() Always Gives Unique Numbers](#24-row_number-always-gives-unique-numbers)
25. [ROW_NUMBER() with PARTITION BY](#25-row_number-with-partition-by)
26. [Finding the Latest Record Using ROW_NUMBER()](#26-finding-the-latest-record-using-row_number)
27. [Why PARTITION BY Is Important for Latest Record Problems](#27-why-partition-by-is-important-for-latest-record-problems)
28. [ROW_NUMBER() for Deduplication](#28-row_number-for-deduplication)
29. [Logical SQL Execution and Window Functions](#29-logical-sql-execution-and-window-functions)
30. [Why WHERE Cannot Filter ROW_NUMBER() Directly](#30-why-where-cannot-filter-row_number-directly)
31. [QUALIFY in Snowflake](#31-qualify-in-snowflake)
32. [WHERE vs HAVING vs QUALIFY](#32-where-vs-having-vs-qualify)
33. [Common Problem-Solving Pattern for Latest Record](#33-common-problem-solving-pattern-for-latest-record)
34. [RANK()](#34-rank)
35. [DENSE_RANK()](#35-dense_rank)
36. [ROW_NUMBER vs RANK vs DENSE_RANK](#36-row_number-vs-rank-vs-dense_rank)
37. [When to Use ROW_NUMBER()](#37-when-to-use-row_number)
38. [When to Use RANK()](#38-when-to-use-rank)
39. [When to Use DENSE_RANK()](#39-when-to-use-dense_rank)
40. [Important Top N Difference](#40-important-top-n-difference)
41. [PARTITION BY with Ranking Functions](#41-partition-by-with-ranking-functions)
42. [Top Employee in Each Department](#42-top-employee-in-each-department)
43. [How to Choose ROW_NUMBER, RANK, or DENSE_RANK](#43-how-to-choose-row_number-rank-or-dense_rank)
44. [LAG()](#44-lag)
45. [Why Is LAG() Useful?](#45-why-is-lag-useful)
46. [LAG() with PARTITION BY](#46-lag-with-partition-by)
47. [Calculating Difference Using LAG()](#47-calculating-difference-using-lag)
48. [LAG() Offset](#48-lag-offset)
49. [LAG() Default Value](#49-lag-default-value)
50. [LEAD()](#50-lead)
51. [LAG vs LEAD](#51-lag-vs-lead)
52. [Why ORDER BY Is Important for LAG and LEAD](#52-why-order-by-is-important-for-lag-and-lead)
53. [LAG and LEAD Real-World Uses](#53-lag-and-lead-real-world-uses)
54. [LAG Problem-Solving Pattern](#54-lag-problem-solving-pattern)
55. [Window Function Problem-Solving Framework](#55-window-function-problem-solving-framework)
56. [Interview Q&A — Part 1](#56-interview-qa--part-1)
57. [Part 1 Memory Map](#57-part-1-memory-map)
58. [Quick-Reference Cheat Sheet](#58-quick-reference-cheat-sheet) *(added)*
59. [Common Mistakes Checklist](#59-common-mistakes-checklist) *(added)*

---

## Topic Overview

Window Functions are used when we need to perform calculations across multiple related rows while still keeping the individual rows in the result.

This is the main idea of Window Functions:

> Calculate using multiple rows without collapsing the original rows.

Window Functions are extremely important in real-world SQL because many business problems require both:

- individual row-level details
- calculations based on related rows

For example:

- Show every employee along with the average salary of their department.
- Show every transaction along with the customer's total transaction amount.
- Find the latest transaction for every customer.
- Rank employees within each department.
- Compare the current transaction with the previous transaction.
- Calculate a running total.
- Find the next transaction.
- Find top N records for every group.
- Identify duplicate records.

Window Functions are commonly used in:

- Banking
- Finance
- E-commerce
- Data Analytics
- Reporting
- Customer Analytics
- HR Analytics
- Sales Analysis
- Data Engineering

---

## 1. Why Do We Need Window Functions?

Before understanding Window Functions, we need to understand the limitation of normal aggregate functions.

Consider this `transactions` table:

| transaction_id | customer_id | amount |
|---|---:|---:|
| 1 | 101 | 500 |
| 2 | 101 | 1000 |
| 3 | 101 | 700 |
| 4 | 102 | 2000 |

Suppose we want to calculate the total transaction amount.

```sql
SELECT SUM(amount) AS total_amount
FROM transactions;
```

Result:

| total_amount |
| -----------: |
|         4200 |

The calculation is correct — but we lost the original transaction rows. We cannot see transactions 1, 2, 3, 4 individually; only the final aggregated result.

Now suppose the business asks:

> Show every transaction along with the total transaction amount.

A normal aggregate query alone cannot give us the original rows and the total in the same straightforward result. This is where Window Functions become useful.

```sql
SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER () AS total_amount
FROM transactions;
```

Result:

| transaction_id | customer_id | amount | total_amount |
| -------------- | ----------: | -----: | -----------: |
| 1              |         101 |    500 |         4200 |
| 2              |         101 |   1000 |         4200 |
| 3              |         101 |    700 |         4200 |
| 4              |         102 |   2000 |         4200 |

The total is calculated using all rows, but the original rows remain visible. This is the core reason Window Functions exist.

---

## 2. What Is a Window Function?

A Window Function performs a calculation across a set of rows related to the current row **without collapsing those rows into a single result**.

The word "window" refers to the set of rows available to the function for calculation.

Basic structure:

```sql
FUNCTION_NAME(expression) OVER (...)
```

Examples:

```sql
SUM(amount) OVER ()
AVG(salary) OVER ()
COUNT(transaction_id) OVER ()
ROW_NUMBER() OVER ()
```

The `OVER()` clause tells SQL:

> Use this function as a Window Function and perform the calculation over a set of rows.

The `OVER()` clause is the key part of a Window Function.

---

## 3. The Most Important Concept

```text
GROUP BY
    =
Calculates by grouping rows and collapses rows

WINDOW FUNCTION
    =
Calculates across rows while preserving the rows
```

Example data:

| transaction_id | customer_id | amount |
| -------------- | ----------: | -----: |
| 1              |         101 |    500 |
| 2              |         101 |   1000 |
| 3              |         101 |    700 |

Using `GROUP BY`:

```sql
SELECT
    customer_id,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY customer_id;
```

Result:

| customer_id | total_amount |
| ----------: | -----------: |
|         101 |         2200 |

The three transaction rows become one row.

Now using a Window Function:

```sql
SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    ) AS total_amount
FROM transactions;
```

Result:

| transaction_id | customer_id | amount | total_amount |
| -------------- | ----------: | -----: | -----------: |
| 1              |         101 |    500 |         2200 |
| 2              |         101 |   1000 |         2200 |
| 3              |         101 |    700 |         2200 |

All original rows remain visible; the calculation is simply added to the rows.

---

## 4. GROUP BY vs Window Functions

This is one of the most important interview topics.

### GROUP BY

`GROUP BY` creates groups and returns one result row per group.

```sql
SELECT
    customer_id,
    SUM(amount)
FROM transactions
GROUP BY customer_id;
```

Conceptually:

```text
All transaction rows
        ↓
Group rows by customer
        ↓
Calculate SUM
        ↓
Return one row for each customer
```

The original rows are no longer individually visible.

### Window Function

```sql
SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    )
FROM transactions;
```

Conceptually:

```text
All transaction rows
        ↓
Keep every original row
        ↓
Create logical customer partitions
        ↓
Calculate the total inside each partition
        ↓
Attach the result to each row
```

The number of rows remains the same.

### Comparison

| GROUP BY                                | Window Function                                |
| ---------------------------------------- | ------------------------------------------------ |
| Groups rows                             | Creates a logical window for calculation         |
| Usually reduces rows                    | Preserves individual rows                        |
| One row per group                       | Can return every original row                    |
| Used for summary results                | Used for row-level and analytical calculations   |
| Aggregate result replaces detailed rows | Aggregate result can be added to detailed rows    |

---

## 5. What Does OVER() Mean?

`OVER()` is what defines the Window for the Window Function.

```sql
SUM(amount) OVER ()
```

When `OVER()` is empty, the Window includes **all rows in the current result set**.

| transaction_id | amount |
| -------------- | -----: |
| 1              |    500 |
| 2              |   1000 |
| 3              |    700 |

```sql
SELECT
    transaction_id,
    amount,
    SUM(amount) OVER () AS total_amount
FROM transactions;
```

Every row gets the total:

| transaction_id | amount | total_amount |
| -------------- | -----: | -----------: |
| 1              |    500 |         2200 |
| 2              |   1000 |         2200 |
| 3              |    700 |         2200 |

**Important:** `OVER()` does not mean every row is calculated independently. Instead: every row remains visible, while the function can look at the rows defined by the window.

---

## 6. Basic Window Function Syntax

```sql
FUNCTION_NAME(expression)
OVER (
    PARTITION BY column_name
    ORDER BY column_name
)
```

Not every part is mandatory. The simplest form:

```sql
FUNCTION_NAME(expression) OVER ()
```

With `PARTITION BY`:

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
)
```

With `ORDER BY`:

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
)
```

With both:

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
)
```

Window Frames can also be added (covered in Part 2):

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
    ROWS BETWEEN ...
)
```

Main structure:

```text
FUNCTION      → What calculation?
PARTITION BY  → For which entity should the calculation happen separately?
ORDER BY      → In what sequence should the rows be processed?
WINDOW FRAME  → Exactly which rows around the current row should be included?
```

---

## 7. Understanding PARTITION BY

`PARTITION BY` divides rows into logical groups for the Window Function.

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
)
```

| transaction_id | customer_id | amount |
| -------------- | ----------: | -----: |
| 1              |         101 |    500 |
| 2              |         101 |   1000 |
| 3              |         102 |    700 |
| 4              |         102 |    300 |

SQL logically treats the rows as separate partitions — Customer 101: `500 + 1000 = 1500`; Customer 102: `700 + 300 = 1000`.

Result:

| transaction_id | customer_id | amount | customer_total |
| -------------- | ----------: | -----: | -------------: |
| 1              |         101 |    500 |           1500 |
| 2              |         101 |   1000 |           1500 |
| 3              |         102 |    700 |           1000 |
| 4              |         102 |    300 |           1000 |

---

## 8. PARTITION BY Does Not Collapse Rows

`PARTITION BY` may look similar to `GROUP BY`, but they are not the same.

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
)
```

This does **NOT** mean "return only one row for each customer." It means "keep every row, but calculate the Window Function separately for each customer."

```text
PARTITION BY = Separate calculation groups
NOT
PARTITION BY = Collapse rows
```

---

## 9. How to Choose the PARTITION BY Column

Ask: **"For whom or for what should the calculation happen separately?"** That entity usually becomes the `PARTITION BY` column.

| Question | Think | PARTITION BY |
|---|---|---|
| Total transactions for each customer | Each customer separately | `customer_id` |
| Rank employees within each department | Each department separately | `department_id` |
| Running sales for each product | Each product separately | `product_id` |
| Latest salary record for every employee | Each employee separately | `employee_id` |

---

## 10. Common PARTITION BY Mistake

Suppose the question says: "Calculate a separate total for each customer."

A common mistake:

```sql
PARTITION BY transaction_id
```

This is wrong because `transaction_id` usually identifies one individual transaction. If every transaction has a unique ID, every partition contains only one row — the calculation will not produce a customer-level total.

Correct:

```sql
PARTITION BY customer_id
```

**Rule:** Do not choose the partition column based on which column looks important. Ask instead: *which entity should have its own separate calculation?*

---

## 11. ORDER BY Inside a Window Function

`ORDER BY` inside `OVER()` defines the sequence in which rows are considered by the Window Function.

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
)
```

| transaction_date | amount |
| ----------------- | -----: |
| Jan 1              |    500 |
| Jan 5              |   1000 |
| Jan 10             |    700 |

Order: `Jan 1 → Jan 5 → Jan 10`. SQL can now perform ordered calculations.

---

## 12. Why ORDER BY Is Important

Some calculations depend on the order of rows: previous transaction, next transaction, latest transaction, first transaction, running total, ranking.

Example — "What is the previous transaction?" requires an order, usually `ORDER BY transaction_date`:

```text
Jan 1 → first
Jan 5 → previous is Jan 1
Jan 10 → previous is Jan 5
```

Without an appropriate order, the meaning of "previous" may not be correct.

---

## 13. PARTITION BY and ORDER BY Together

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
)
```

Step by step:

1. `PARTITION BY customer_id` → separate rows for each customer
2. `ORDER BY transaction_date` → order each customer's rows by date
3. `SUM(amount)` → perform the sum calculation

```text
For each customer
        ↓
Order their transactions by date
        ↓
Calculate the sum according to that order
```

This is the basic idea behind a customer-level running total.

---

## 14. Window Functions and Aggregate Functions

Normal aggregate functions — `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()` — can also be used as Window Functions simply by adding `OVER(...)`.

```text
Aggregate Function + OVER() = Window Function
```

---

## 15. SUM() as a Window Function

```sql
SELECT
    transaction_id,
    amount,
    SUM(amount) OVER () AS total_amount
FROM transactions;
```

Calculates the total of all transaction amounts while keeping every row.

**Customer Total:**

```sql
SELECT
    transaction_id,
    customer_id,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_total
FROM transactions;
```

Gives every row the total transaction amount for its customer (transaction amount + customer's total spending).

---

## 16. COUNT() as a Window Function

```sql
SELECT
    transaction_id,
    customer_id,
    COUNT(transaction_id) OVER (
        PARTITION BY customer_id
    ) AS customer_transaction_count
FROM transactions;
```

If customer 101 has three transactions, every row belonging to customer 101 shows `3` (individual transaction + total number of transactions by the customer).

---

## 17. AVG() as a Window Function

```sql
SELECT
    employee_id,
    department_id,
    salary,
    AVG(salary) OVER (
        PARTITION BY department_id
    ) AS department_average_salary
FROM employees;
```

Allows comparing every employee's salary with the average salary of their department.

---

## 18. MIN() and MAX() as Window Functions

```sql
MAX(amount) OVER (PARTITION BY customer_id)
```
→ For every transaction row, show the highest transaction amount made by that customer.

```sql
MIN(salary) OVER (PARTITION BY department_id)
```
→ For every employee row, show the minimum salary in that department.

Useful when comparing an individual row against the min/max value in its group.

---

## 19. Running Total

A Running Total is a cumulative total.

| transaction_date | amount |
| ----------------- | -----: |
| Jan 1              |    500 |
| Jan 5              |   1000 |
| Jan 10             |    700 |

We want:

| transaction_date | amount | running_total |
| ----------------- | -----: | -------------: |
| Jan 1              |    500 |            500 |
| Jan 5              |   1000 |           1500 |
| Jan 10             |    700 |           2200 |

```sql
SELECT
    transaction_date,
    amount,
    SUM(amount) OVER (
        ORDER BY transaction_date
    ) AS running_total
FROM transactions;
```

Conceptually: `500` → `500 + 1000 = 1500` → `500 + 1000 + 700 = 2200`. The running total keeps accumulating.

---

## 20. Why Running Totals Need ORDER BY

A Running Total depends on sequence. Amounts `500, 1000, 700` → running total `500, 1500, 2200`. But if the order is `700, 500, 1000` → running total becomes `700, 1200, 2200`.

The final total is the same, but the **intermediate** running totals differ. A Running Total requires a meaningful order — usually `ORDER BY transaction_date`, or `month`, `created_at`, `transaction_id`, depending on the business requirement.

---

## 21. Running Total for Each Customer

```sql
SELECT
    customer_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
    ) AS running_total
FROM transactions;
```

```text
Customer 101 → order transactions → calculate running total
Customer 102 → order transactions → calculate running total
```

Each customer's running total starts independently.

---

## 22. Window Function Categories

### Aggregate Window Functions
`SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()` — totals, averages, counts, min/max values, running totals.

### Ranking Functions
`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()` — numbering rows, ranking records, finding latest records, top N records, identifying duplicates.

### Value Functions
`LAG()`, `LEAD()` — previous/next values, comparing current and previous/next rows, calculating change over time.

---

## 23. ROW_NUMBER()

`ROW_NUMBER()` assigns a unique sequential number to every row.

```sql
ROW_NUMBER() OVER (
    ORDER BY column_name
)
```

```sql
SELECT
    transaction_id,
    amount,
    ROW_NUMBER() OVER (
        ORDER BY amount DESC
    ) AS row_num
FROM transactions;
```

| transaction_id | amount | row_num |
| -------------- | -----: | ------: |
| 1              |   1000 |       1 |
| 2              |    700 |       2 |
| 3              |    500 |       3 |

---

## 24. ROW_NUMBER() Always Gives Unique Numbers

| employee | salary |
| -------- | -----: |
| A        | 100000 |
| B        |  90000 |
| C        |  90000 |
| D        |  70000 |

```sql
ROW_NUMBER() OVER (ORDER BY salary DESC)
```

| employee | salary | row_number |
| -------- | -----: | ---------: |
| A        | 100000 |          1 |
| B        |  90000 |          2 |
| C        |  90000 |          3 |
| D        |  70000 |          4 |

Even though B and C have the same salary, they receive different row numbers — `ROW_NUMBER()` always assigns unique sequential numbers.

---

## 25. ROW_NUMBER() with PARTITION BY

```sql
ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
)
```

| customer_id | transaction_date | row_number |
| ----------: | ----------------- | ---------: |
|         101 | Jan 1              |          1 |
|         101 | Jan 5              |          2 |
|         101 | Jan 10             |          3 |
|         102 | Jan 2              |          1 |
|         102 | Jan 8              |          2 |

The numbering restarts for each customer.

---

## 26. Finding the Latest Record Using ROW_NUMBER()

```sql
SELECT
    customer_id,
    transaction_id,
    transaction_date,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS row_num
FROM transactions;
```

Why descending order? Because "latest date" = highest/latest value → `ORDER BY transaction_date DESC`. The latest transaction receives `row_num = 1`.

In Snowflake:

```sql
SELECT
    customer_id,
    transaction_id,
    transaction_date
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;
```

This returns the latest transaction for each customer.

---

## 27. Why PARTITION BY Is Important for Latest Record Problems

Without partitioning:

```sql
ROW_NUMBER() OVER (
    ORDER BY transaction_date DESC
)
```

This numbers all transactions **globally** — the requirement is "latest transaction for each customer," so we need `PARTITION BY customer_id`. Now each customer gets their own numbering.

```text
For each customer   → PARTITION BY customer_id
Latest               → ORDER BY date DESC
Only the latest row  → ROW_NUMBER() = 1
```

---

## 28. ROW_NUMBER() for Deduplication

| customer_id | email           | created_at |
| ----------: | --------------- | ---------- |
|           1 | test@email.com  | Jan 1      |
|           2 | test@email.com  | Jan 5      |

Keep only the latest record:

```sql
SELECT *
FROM customers
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY email
    ORDER BY created_at DESC
) = 1;
```

```text
Same email → one partition → order by latest date → row 1 → keep only row 1
```

A very common real-world use case.

---

## 29. Logical SQL Execution and Window Functions

```text
FROM → WHERE → GROUP BY → HAVING → SELECT → Window Functions → QUALIFY → ORDER BY
```

Most important concept:

```text
WHERE happens before Window Function results
QUALIFY happens after Window Function results
```

This explains why we cannot directly use `WHERE` with a Window Function alias in the same query level.

---

## 30. Why WHERE Cannot Filter ROW_NUMBER() Directly

```sql
SELECT
    customer_id,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date DESC
    ) AS row_num
FROM transactions
WHERE row_num = 1;   -- ❌ does not work
```

`WHERE` is evaluated before the `row_num` Window Function result is available:

```text
WHERE wants to filter → but ROW_NUMBER() has not been calculated yet → row_num does not exist at that stage
```

This is why we need `QUALIFY` or a subquery/CTE.

---

## 31. QUALIFY in Snowflake

`QUALIFY` filters Window Function results.

```sql
SELECT
    customer_id,
    transaction_id,
    transaction_date
FROM transactions
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date DESC
) = 1;
```

```text
FROM → get rows
Window Function → calculate ROW_NUMBER()
QUALIFY → keep only ROW_NUMBER() = 1
```

Extremely useful in Snowflake.

---

## 32. WHERE vs HAVING vs QUALIFY

| Clause | Filters |
|---|---|
| `WHERE` | Individual rows, before grouping and Window Function calculations (e.g. `WHERE status = 'SUCCESSFUL'`) |
| `HAVING` | Grouped aggregate results (e.g. `HAVING SUM(amount) > 500000`) |
| `QUALIFY` | Window Function results (e.g. `QUALIFY ROW_NUMBER() OVER (...) = 1`) |

```text
WHERE   → filter normal rows
HAVING  → filter GROUP BY results
QUALIFY → filter Window Function results
```

---

## 33. Common Problem-Solving Pattern for Latest Record

Question: "Find the latest transaction for every customer."

1. **Identify the entity** → every customer → `PARTITION BY customer_id`
2. **Identify what "latest" means** → latest transaction date → `ORDER BY transaction_date DESC`
3. **Identify the Window Function** → need one unique first row → `ROW_NUMBER()`
4. **Keep the first row** → `ROW_NUMBER() = 1`

Final logic: `PARTITION BY customer_id → ORDER BY transaction_date DESC → ROW_NUMBER() = 1 → QUALIFY`

---

## 34. RANK()

`RANK()` assigns a rank based on the order of values. Unlike `ROW_NUMBER()`, equal values receive the same rank.

| employee | salary |
| -------- | -----: |
| A        |    100 |
| B        |     90 |
| C        |     90 |
| D        |     70 |

```sql
RANK() OVER (ORDER BY salary DESC)
```

| employee | salary | rank |
| -------- | -----: | ---: |
| A        |    100 |    1 |
| B        |     90 |    2 |
| C        |     90 |    2 |
| D        |     70 |    4 |

Rank 3 is skipped because two rows occupy rank 2. This is how standard ranking works.

---

## 35. DENSE_RANK()

`DENSE_RANK()` also gives the same rank to equal values — but does not leave gaps.

```sql
DENSE_RANK() OVER (ORDER BY salary DESC)
```

| employee | salary | dense_rank |
| -------- | -----: | ---------: |
| A        |    100 |          1 |
| B        |     90 |          2 |
| C        |     90 |          2 |
| D        |     70 |          3 |

No gap: `1, 2, 2, 3`.

---

## 36. ROW_NUMBER vs RANK vs DENSE_RANK

For values `100, 90, 90, 70`:

| Function | Result |
|---|---|
| `ROW_NUMBER()` | `1, 2, 3, 4` — every row gets a unique number |
| `RANK()` | `1, 2, 2, 4` — same values share rank; gaps appear after ties |
| `DENSE_RANK()` | `1, 2, 2, 3` — same values share rank; no gaps |

---

## 37. When to Use ROW_NUMBER()

Use when every row needs a unique sequence number:

- Latest record per customer
- Deduplication
- Selecting exactly one record
- Sequential numbering / pagination
- Selecting one latest employee record
- Keeping one row from duplicate groups

---

## 38. When to Use RANK()

Use when equal values should share the same rank and ranking positions should reflect ties (e.g. competition ranking — two people finishing second means there's no third place: `1st, 2nd, 2nd, 4th`).

---

## 39. When to Use DENSE_RANK()

Use when equal values should share the same rank but gaps should not appear (`1, 2, 2, 3`). Useful for top salary levels, top product categories, distinct rank levels, N highest distinct values.

---

## 40. Important Top N Difference

"Top 3 employees based on salary":

```sql
QUALIFY ROW_NUMBER() OVER (ORDER BY salary DESC) <= 3   -- always exactly 3 rows
QUALIFY RANK()       OVER (ORDER BY salary DESC) <= 3   -- can return MORE than 3 rows (ties)
QUALIFY DENSE_RANK() OVER (ORDER BY salary DESC) <= 3   -- returns all rows in top 3 distinct salary ranks
```

This distinction is important in interviews.

---

## 41. PARTITION BY with Ranking Functions

```sql
RANK() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
)
```

```text
Department IT      → rank employees by salary
Department HR       → rank employees by salary
Department Finance  → rank employees by salary
```

The ranking restarts for every department.

---

## 42. Top Employee in Each Department

Problem: "Find the highest-paid employee in each department."

```text
Each department  → PARTITION BY department_id
Highest salary    → ORDER BY salary DESC
First row         → ROW_NUMBER() = 1
```

```sql
SELECT
    employee_id,
    department_id,
    salary
FROM employees
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY department_id
    ORDER BY salary DESC
) = 1;
```

**Important:** if multiple employees share the highest salary and all should be returned, `ROW_NUMBER()` may not be appropriate — use `RANK()` or `DENSE_RANK()` instead, depending on the requirement.

---

## 43. How to Choose ROW_NUMBER, RANK, or DENSE_RANK

Ask: "If two values are equal, what should happen?"

| Requirement | Use |
|---|---|
| Exactly one row should be selected | `ROW_NUMBER()` |
| Equal values share rank; gaps acceptable | `RANK()` |
| Equal values share rank; no gaps | `DENSE_RANK()` |

---

## 44. LAG()

`LAG()` accesses a value from a previous row.

```sql
LAG(column_name) OVER (ORDER BY column_name)
```

| transaction_date | amount |
| ----------------- | -----: |
| Jan 1              |    100 |
| Jan 5              |    150 |
| Jan 10             |    200 |

| transaction_date | amount | previous_amount |
| ----------------- | -----: | --------------: |
| Jan 1              |    100 |            NULL |
| Jan 5              |    150 |              100 |
| Jan 10             |    200 |              150 |

For each row: current row → look backward → get the previous row's value.

---

## 45. Why Is LAG() Useful?

Useful when comparing the current row with a previous row: current vs previous month's sales, current vs previous transaction, salary growth, customer spending changes, detecting increases/decreases, stock price comparisons.

---

## 46. LAG() with PARTITION BY

```sql
LAG(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
)
```

```text
Customer 101 → order transactions → look at previous transaction
Customer 102 → order transactions → look at previous transaction
```

The first transaction for every customer has no previous transaction inside its partition → `NULL` is normally returned.

---

## 47. Calculating Difference Using LAG()

| date | sales |
| ---- | ----: |
| Jan  |   100 |
| Feb  |   150 |
| Mar  |   120 |

```sql
SELECT
    sales_date,
    sales,
    LAG(sales) OVER (
        ORDER BY sales_date
    ) AS previous_sales
FROM monthly_sales;
```

Difference = `Current - Previous`. February: `150 - 100 = 50`. March: `120 - 150 = -30`.

The correct mental formula is **Current − Previous**, not the reverse, unless the business requirement specifically asks for it.

---

## 48. LAG() Offset

Default `LAG(amount)` = value one row before. `LAG(amount, 2)` = value two rows before.

| month | sales |
| ----- | ----: |
| Jan   |   100 |
| Feb   |   150 |
| Mar   |   200 |
| Apr   |   250 |

```sql
LAG(sales, 2) OVER (ORDER BY month)
```

| month | sales | two_months_previous |
| ----- | ----: | -------------------: |
| Jan   |   100 |                 NULL |
| Feb   |   150 |                 NULL |
| Mar   |   200 |                  100 |
| Apr   |   250 |                  150 |

---

## 49. LAG() Default Value

Normally `NULL` is returned if no previous row exists. A default value can be provided:

```sql
LAG(amount, 1, 0) OVER (
    ORDER BY transaction_date
)
```

```text
Get previous amount → if no previous row exists → return 0
```

**Important:** don't automatically replace `NULL` with `0` unless `0` is logically meaningful for the business case.

---

## 50. LEAD()

`LEAD()` accesses a value from a future/next row.

```sql
LEAD(column_name) OVER (ORDER BY column_name)
```

| transaction_date | amount | next_amount |
| ----------------- | -----: | ----------: |
| Jan 1              |    100 |         150 |
| Jan 5              |    150 |         200 |
| Jan 10             |    200 |        NULL |

`LEAD()` looks forward.

---

## 51. LAG vs LEAD

```text
LAG()  → looks backward → previous row
LEAD() → looks forward  → next row
```

For row 2 in `100, 150, 200`: `LAG = 100`, `Current = 150`, `LEAD = 200`.

---

## 52. Why ORDER BY Is Important for LAG and LEAD

"Previous" and "next" only make sense based on some order.

```sql
LAG(amount) OVER (ORDER BY transaction_date)  -- previous according to date
LAG(amount) OVER (ORDER BY amount)             -- previous according to amount order
```

The function is the same; the meaning changes based on `ORDER BY`. This is extremely important.

---

## 53. LAG and LEAD Real-World Uses

| Domain | Use case |
|---|---|
| Banking | Detecting unusual changes, comparing transaction patterns, analyzing spending behavior |
| Sales | Growth calculation, decline analysis, month-over-month comparison |
| Stock Data | Price movement, increase/decrease analysis |
| HR | Salary growth, promotion analysis |

---

## 54. LAG Problem-Solving Pattern

Question: "Compare each customer's current transaction amount with their previous transaction amount."

1. **Who is calculated separately?** → each customer → `PARTITION BY customer_id`
2. **What defines "previous"?** → transaction date → `ORDER BY transaction_date`
3. **Which value?** → previous amount → `LAG(amount)`

```text
For each customer → order transactions by date → look one row backward → get the previous amount
```

---

## 55. Window Function Problem-Solving Framework

1. **Do I need to keep the individual rows?** → if yes, think Window Function.
2. **What calculation or comparison do I need?** → total, average, count, min, max, rank, previous value, next value.
3. **Should the calculation happen separately for an entity?** → if yes, `PARTITION BY` (for each customer? employee? department? product?).
4. **Does sequence matter?** → if yes, `ORDER BY` (based on date? amount? salary? score?).
5. **Do I need to filter the Window Function result?** → in Snowflake, `QUALIFY`.

---

## 56. Interview Q&A — Part 1

**What is a Window Function?**
A Window Function performs calculations across a set of related rows while preserving the individual rows in the result.

**What does OVER() do?**
It defines the window, or set of rows, over which the Window Function performs its calculation.

**Difference between GROUP BY and Window Functions?**
`GROUP BY` groups and collapses rows into one row per group. Window Functions calculate across related rows while preserving the original rows.

**What does PARTITION BY do?**
Divides rows into logical groups so the Window Function can perform calculations separately within each group.

**Does PARTITION BY collapse rows?**
No — it creates logical partitions for calculation while preserving the individual rows.

**What does ORDER BY do inside OVER()?**
Defines the sequence in which rows are considered by the Window Function.

**Why is ORDER BY important?**
Required when the calculation depends on sequence — running totals, ranking, previous/next values, latest records.

**What is ROW_NUMBER()?**
Assigns a unique sequential number to every row based on the specified ordering.

**What happens when there are ties in ROW_NUMBER()?**
Each row still receives a different unique number.

**Difference between ROW_NUMBER, RANK, and DENSE_RANK?**
`ROW_NUMBER()`: `1,2,3,4` (unique even for ties). `RANK()`: `1,2,2,4` (same rank for ties, with gaps). `DENSE_RANK()`: `1,2,2,3` (same rank for ties, no gaps).

**What is LAG()?**
Returns a value from a previous row based on the specified ordering.

**What is LEAD()?**
Returns a value from a following row based on the specified ordering.

**What is QUALIFY in Snowflake?**
Filters results after Window Functions are calculated.

**Why can't WHERE filter a Window Function result directly?**
Because `WHERE` is logically evaluated before the Window Function result is available.

---

## 57. Part 1 Memory Map

```text
WINDOW FUNCTION
        |
        v
      OVER()
        |
        +-----------------------+
        |                       |
        v                       v
PARTITION BY                ORDER BY
        |                       |
        v                       v
Separate calculation       Define row sequence
for each entity
        |
        v
Choose Function
        |
        +-------------------+
        |                   |
        v                   v
Aggregate Functions     Ranking Functions
        |                   |
        v                   v
SUM()                  ROW_NUMBER()
AVG()                  RANK()
COUNT()                DENSE_RANK()
MIN()
MAX()
        |
        v
Value Functions
        |
        +---------+
        |         |
        v         v
      LAG()     LEAD()
        |
        v
Previous / Next Row Analysis
```

---

## 58. Quick-Reference Cheat Sheet

| Goal | Pattern |
|---|---|
| Total across all rows, keep rows | `SUM(col) OVER ()` |
| Total per group, keep rows | `SUM(col) OVER (PARTITION BY grp)` |
| Running total | `SUM(col) OVER (ORDER BY date_col)` |
| Running total per group | `SUM(col) OVER (PARTITION BY grp ORDER BY date_col)` |
| Unique row numbering | `ROW_NUMBER() OVER (ORDER BY col)` |
| Latest record per group | `ROW_NUMBER() OVER (PARTITION BY grp ORDER BY date_col DESC) = 1` (via `QUALIFY`) |
| Deduplicate rows | `ROW_NUMBER() OVER (PARTITION BY dedup_key ORDER BY tiebreak DESC) = 1` |
| Ranking with gaps on ties | `RANK() OVER (ORDER BY col DESC)` |
| Ranking without gaps on ties | `DENSE_RANK() OVER (ORDER BY col DESC)` |
| Compare to previous row | `LAG(col) OVER (ORDER BY date_col)` |
| Compare to next row | `LEAD(col) OVER (ORDER BY date_col)` |
| Filter a window function result (Snowflake) | `QUALIFY <window_fn> ...` |

---

## 59. Common Mistakes Checklist

- ❌ Using `PARTITION BY` on a column that is already unique per row (e.g. `transaction_id`) when a group-level total is needed → partitions collapse to one row each, defeating the purpose.
- ❌ Forgetting `ORDER BY` on running totals, `LAG()`/`LEAD()`, or "latest record" queries — the result becomes order-dependent and unreliable.
- ❌ Trying to filter a window function alias directly in `WHERE` — `WHERE` runs before window functions are evaluated. Use `QUALIFY` (Snowflake) or wrap in a subquery/CTE elsewhere.
- ❌ Assuming `ROW_NUMBER()` and `RANK()` are interchangeable for "top N" queries — `RANK()`/`DENSE_RANK()` can return more than N rows when there are ties; `ROW_NUMBER()` always returns exactly N.
- ❌ Replacing `NULL` from `LAG()`/`LEAD()` with `0` without checking whether `0` is business-meaningful.
- ❌ Confusing `PARTITION BY` (keeps all rows, separate calculation per group) with `GROUP BY` (collapses rows into one per group).
