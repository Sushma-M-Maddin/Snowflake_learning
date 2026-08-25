# SQL Window Frames

## Table of Contents

1. [What is a Window Frame?](#1-what-is-a-window-frame)
2. [Window Frame Syntax](#2-window-frame-syntax)
3. [Window Frame Boundaries](#3-window-frame-boundaries)
4. [UNBOUNDED PRECEDING](#4-unbounded-preceding)
5. [CURRENT ROW](#5-current-row)
6. [N PRECEDING](#6-n-preceding)
7. [N FOLLOWING](#7-n-following)
8. [UNBOUNDED FOLLOWING](#8-unbounded-following)
9. [Common Window Frame Patterns](#9-common-window-frame-patterns)
10. [Moving Window](#10-moving-window)
11. [Moving Average](#11-moving-average)
12. [How to Calculate an N-Row Moving Average](#12-how-to-calculate-an-n-row-moving-average)
13. [ROWS vs RANGE](#13-rows-vs-range)
14. [ROWS](#14-rows)
15. [RANGE](#15-range)
16. [Easy Memory Trick for ROWS vs RANGE](#16-easy-memory-trick-for-rows-vs-range)
17. [When to Use ROWS](#17-when-to-use-rows)
18. [When RANGE Can Be Useful](#18-when-range-can-be-useful)
19. [ROWS vs RANGE Real-World Meaning](#19-rows-vs-range-real-world-meaning)
20. [DENSE_RANK vs RANGE](#20-dense_rank-vs-range)
21. [Last N Rows vs Last N Days](#21-last-n-rows-vs-last-n-days)
22. [Time-Based RANGE Window](#22-time-based-range-window)
23. [Previous 30 Days](#23-previous-30-days)
24. [Last 7 Rows vs Last 7 Days](#24-last-7-rows-vs-last-7-days)
25. [Common Window Frame Examples](#25-common-window-frame-examples)
26. [PARTITION BY with Window Frames](#26-partition-by-with-window-frames)
27. [PARTITION vs WINDOW FRAME](#27-partition-vs-window-frame)
28. [Important Interview Concepts](#28-important-interview-concepts)
29. [Common Mistakes](#29-common-mistakes)
30. [Interview Questions](#30-interview-questions)
31. [Quick Revision](#31-quick-revision)

---

## 1. What is a Window Frame?

A Window Frame defines the specific set of rows that should be used for a calculation for each current row.

A Window Function can have:

- A partition
- An order
- A frame

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

The components have different purposes:

```text
PARTITION BY → Divides rows into groups.
ORDER BY     → Defines the sequence of rows inside each group.
WINDOW FRAME → Defines exactly which rows participate in the calculation for the current row.
```

Example — amounts `100, 200, 300, 400`. If the current row is `300`, the frame determines whether SQL should use `100, 200, 300` or `200, 300` or `100, 200, 300, 400`. This is the purpose of a Window Frame.

---

## 2. Window Frame Syntax

General syntax:

```sql
ROWS BETWEEN <START> AND <END>
```

The frame has two boundaries:

```text
START → Where SQL starts selecting rows.
END   → Where SQL stops selecting rows.
```

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

Means: start 2 rows before the current row, end at the current row.

---

## 3. Window Frame Boundaries

The major boundaries are:

```text
UNBOUNDED PRECEDING
N PRECEDING
CURRENT ROW
N FOLLOWING
UNBOUNDED FOLLOWING
```

The logical order:

```text
UNBOUNDED PRECEDING

3 PRECEDING
2 PRECEDING
1 PRECEDING

CURRENT ROW

1 FOLLOWING
2 FOLLOWING
3 FOLLOWING

UNBOUNDED FOLLOWING
```

---

## 4. UNBOUNDED PRECEDING

`UNBOUNDED PRECEDING` means: **start from the first row of the partition.**

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Means: start from the first row and continue until the current row.

| Amount |
| -----: |
|    100 |
|    200 |
|    300 |
|    400 |

Frames:

```text
Current Row = 100 → [100]
Current Row = 200 → [100, 200]
Current Row = 300 → [100, 200, 300]
Current Row = 400 → [100, 200, 300, 400]
```

Commonly used for running totals, cumulative totals, cumulative averages:

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS running_total
```

---

## 5. CURRENT ROW

`CURRENT ROW` means: **the row currently being calculated.**

```sql
ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
```

Means: previous row + current row.

| Amount |
| -----: |
|    100 |
|    200 |
|    300 |

For current row `300`: `[200, 300]`.

---

## 6. N PRECEDING

`N PRECEDING` means: **N rows before the current row.**

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

Means: previous 2 rows + current row.

Data: `100, 200, 300, 400, 500`

Frames:

```text
Current = 100 → [100]
Current = 200 → [100, 200]
Current = 300 → [100, 200, 300]
Current = 400 → [200, 300, 400]
Current = 500 → [300, 400, 500]
```

This creates a moving 3-row window. Common uses: moving averages, moving totals, recent transaction analysis.

---

## 7. N FOLLOWING

`N FOLLOWING` means: **N rows after the current row.**

```sql
ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
```

Means: current row + next row.

Data: `100, 200, 300, 400`

Frames:

```text
Current = 100 → [100, 200]
Current = 200 → [200, 300]
Current = 300 → [300, 400]
Current = 400 → [400]
```

---

## 8. UNBOUNDED FOLLOWING

`UNBOUNDED FOLLOWING` means: **continue until the last row of the partition.**

```sql
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
```

Means: start at the current row and include all remaining rows.

Data: `100, 200, 300, 400`

Frames:

```text
Current = 100 → [100, 200, 300, 400]
Current = 200 → [200, 300, 400]
Current = 300 → [300, 400]
Current = 400 → [400]
```

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
) AS remaining_total
```

Used for: remaining balance, future sales calculations, remaining payments, remaining workload calculations.

---

## 9. Common Window Frame Patterns

| Pattern | Frame | Meaning |
|---|---|---|
| Running Total | `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | First row → Current row |
| Previous Row + Current Row | `ROWS BETWEEN 1 PRECEDING AND CURRENT ROW` | Previous row + Current row |
| Previous 2 Rows + Current Row | `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` | Previous 2 rows + Current row |
| Previous + Current + Next | `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | Previous row + Current row + Next row |
| Current Row + Next 2 Rows | `ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING` | Current row + Next 2 rows |
| Remaining Total | `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING` | Current row → Last row |

---

## 10. Moving Window

A moving window changes as the current row moves.

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

Data: `100, 200, 300, 400, 500`

Frames:

```text
[100]
[100, 200]
[100, 200, 300]
[200, 300, 400]
[300, 400, 500]
```

The frame moves forward with the current row — this is why it's called a moving window.

---

## 11. Moving Average

A common use of Window Frames is a moving average.

```sql
AVG(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
) AS moving_average
```

This means: previous 2 rows + current row → a 3-row moving average.

| Amount | Rows Used     | Moving Average |
| -----: | ------------- | -------------: |
|    100 | 100           |            100 |
|    200 | 100, 200      |            150 |
|    300 | 100, 200, 300 |            200 |
|    400 | 200, 300, 400 |            300 |
|    500 | 300, 400, 500 |            400 |

---

## 12. How to Calculate an N-Row Moving Average

If the requirement says "3-row moving average":

```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

Because `2 previous rows + current row = 3 rows`.

If the requirement says "5-row moving average":

```sql
ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
```

Because `4 previous rows + current row = 5 rows`.

**General rule:**

```text
N-row moving window = N - 1 preceding rows + current row
```

---

## 13. ROWS vs RANGE

`ROWS` and `RANGE` are different types of Window Frames. The most important difference:

```text
ROWS  → Based on physical row positions.
RANGE → Based on the ORDER BY value and peer rows.
```

---

## 14. ROWS

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

| Physical Row | Amount |
| ------------ | -----: |
| 1            |    100 |
| 2            |    100 |
| 3            |    200 |
| 4            |    300 |

Using `ROWS`:

```text
Row 1 → [100] = 100
Row 2 → [100, 100] = 200
Row 3 → [100, 100, 200] = 400
Row 4 → [100, 100, 200, 300] = 700
```

Even though the first two rows have the same value, they are processed as separate physical rows.

```text
ROWS → Each row position matters.
```

---

## 15. RANGE

```sql
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Same data:

| Physical Row | Amount |
| ------------ | -----: |
| 1            |    100 |
| 2            |    100 |
| 3            |    200 |
| 4            |    300 |

The two `100` rows have the same `ORDER BY` value — they are peer rows.

Using `RANGE`:

```text
First 100  → [100, 100] = 200
Second 100 → [100, 100] = 200
200        → [100, 100, 200] = 400
300        → [100, 100, 200, 300] = 700
```

```text
RANGE → Equal ORDER BY values can be treated as peers.
```

---

## 16. Easy Memory Trick for ROWS vs RANGE

```text
ROWS  → Row Position
RANGE → Ordered Value
```

Or:

```text
ROWS  → How many rows?
RANGE → Which ORDER BY values?
```

---

## 17. When to Use ROWS

Use `ROWS` when individual records matter:

- Running balance after each transaction
- Last 5 transactions
- Moving average of previous 7 records
- Previous 3 transactions
- Row-by-row calculations

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

For transaction-level calculations, `ROWS` is commonly useful because each transaction is treated individually.

---

## 18. When RANGE Can Be Useful

`RANGE` can be useful when the business meaning is based on the value used in `ORDER BY`.

Example: multiple transactions on the same date.

| Transaction | Date  | Amount |
| ----------- | ----- | -----: |
| T1          | Jan 1 |    100 |
| T2          | Jan 1 |    200 |
| T3          | Jan 2 |    300 |

If the requirement is "show cumulative sales up to each reporting date," transactions with the same date can logically represent the same point in the cumulative calculation. `RANGE` can treat rows with the same ordered value as peers.

---

## 19. ROWS vs RANGE Real-World Meaning

Business question: "What was the running total after every transaction?" → use a row-based frame, `ROWS`, because every transaction matters individually.

Business question: "What was the cumulative total up to each date or ordered value?" → value-based `RANGE` semantics can be useful because rows with the same ordered value can share the same calculation boundary.

---

## 20. DENSE_RANK vs RANGE

Both can deal with equal values, but they perform different jobs.

`DENSE_RANK()` — assigns the same rank to equal values:

```text
100 → Rank 1
100 → Rank 1
90  → Rank 2
```

`RANGE` — can treat equal `ORDER BY` values as peer rows inside a calculation frame:

```text
100
100
```

Both rows can be included together depending on the frame.

```text
DENSE_RANK() → Assigns a rank.
RANGE        → Defines which rows participate in a calculation.
```

---

## 21. Last N Rows vs Last N Days

These are not the same.

**Last 7 Rows:**

```sql
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
```

Means: previous 6 rows + current row = 7 records. It does not matter whether those records happened today or across 6 months — `ROWS` only counts records.

**Last 7 Days:** based on actual dates, not the number of records. Example: current date = Jan 20 → look at Jan 13 → Jan 20. There could be 2 transactions or 2000 transactions depending on how much data exists during that period.

---

## 22. Time-Based RANGE Window

In Snowflake, a time-based `RANGE` frame can be used with an interval.

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    RANGE BETWEEN INTERVAL '7 DAYS' PRECEDING AND CURRENT ROW
) AS last_7_days_sales
```

Meaning: start 7 days before the current row's date, end at the current row's date. This does not mean 7 rows — it means include rows whose ordered date values fall within the defined 7-day range.

---

## 23. Previous 30 Days

If the business asks to calculate the average transaction amount from the previous 30 days, use a time-based range:

```sql
AVG(amount) OVER (
    ORDER BY transaction_date
    RANGE BETWEEN INTERVAL '30 DAYS' PRECEDING AND CURRENT ROW
)
```

Do **not** use:

```sql
ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
```

because that means "previous 29 transaction rows + current row = 30 records," not "previous 30 calendar days."

---

## 24. Last 7 Rows vs Last 7 Days

```text
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW                    → Last 7 records
RANGE BETWEEN INTERVAL '7 DAYS' PRECEDING AND CURRENT ROW   → Rows within the specified 7-day date range
```

The number of rows in the `RANGE` window can be 2, 10, 100, or 1000 — it depends on how many records occurred during that time period.

---

## 25. Common Window Frame Examples

**Running Total:**

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**3-Row Moving Average:**

```sql
AVG(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)
```

**Previous + Current + Next:**

```sql
AVG(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
)
```

**Remaining Total:**

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
)
```

**Last 7 Days Total:**

```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    RANGE BETWEEN INTERVAL '7 DAYS' PRECEDING AND CURRENT ROW
)
```

---

## 26. PARTITION BY with Window Frames

Window Frames can be used together with `PARTITION BY`.

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS customer_running_total
```

Execution idea:

```text
Step 1 → Separate rows by customer_id.
Step 2 → Order transactions by transaction_date inside each customer.
Step 3 → For each current row, apply the window frame.
Step 4 → Calculate the result.
```

The frame applies inside each partition.

---

## 27. PARTITION vs WINDOW FRAME

These are different concepts.

```text
PARTITION    → Complete group of related rows.
WINDOW FRAME → Specific rows inside that group used for the current calculation.
```

`PARTITION BY customer_id` might contain, for Customer 1: `100, 200, 300, 400`.

If the frame is `ROWS BETWEEN 1 PRECEDING AND CURRENT ROW`, for current row `300` the complete partition is `100, 200, 300, 400`, but the frame used for the calculation is only `200, 300`.

---

## 28. Important Interview Concepts

**What is a Window Frame?**
A Window Frame defines the specific range of rows used by a Window Function for the calculation of each current row.

**What is the difference between PARTITION BY and Window Frame?**
`PARTITION BY` divides rows into groups. A Window Frame defines which rows inside that group participate in the calculation for the current row.

**What is the difference between ROWS and RANGE?**
`ROWS` is physical row-based. `RANGE` is `ORDER BY` value-based and can treat equal ordered values as peers.

**What is a moving average?**
A moving average calculates an average over a changing window of recent rows or values, e.g. `AVG(amount) OVER (ORDER BY transaction_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`.

**How do you calculate a running total?**
```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**How do you calculate the last 5 transactions?**
```sql
ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
```

**How do you calculate the previous 30 days?**
Use a time-based range rather than simply counting rows:
```sql
RANGE BETWEEN INTERVAL '30 DAYS' PRECEDING AND CURRENT ROW
```

---

## 29. Common Mistakes

**Mistake 1: Confusing ROWS with Days**
`ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` does not mean "last 7 days" — it means "last 7 rows."

**Mistake 2: Forgetting the Current Row**
`ROWS BETWEEN 4 PRECEDING AND CURRENT ROW` contains 4 previous rows + 1 current row = 5 rows.

**Mistake 3: Confusing PARTITION with Frame**
`PARTITION ≠ WINDOW FRAME`. Partition is the complete group; frame is specific rows from that group.

**Mistake 4: Using RANGE Without Understanding Peer Rows**
Duplicate values in the `ORDER BY` column can affect the result — equal ordered values can be peers under `RANGE` semantics.

**Mistake 5: Assuming ORDER BY Alone Always Means Row-by-Row Calculation**
If duplicate values exist, the frame behavior matters. For explicit row-by-row calculations, use an explicit `ROWS` frame when appropriate.

---

## 30. Interview Questions

**Q1. What is a Window Frame?**
A Window Frame defines the specific range of rows that a Window Function uses for the calculation of the current row.

**Q2. What is the difference between ROWS and RANGE?**
`ROWS` works based on physical row positions, while `RANGE` works based on the ordered values and can treat rows with the same `ORDER BY` value as peers.

**Q3. How do you calculate a running total?**
```sql
SUM(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Q4. How do you calculate a 3-row moving average?**
```sql
AVG(amount) OVER (
    ORDER BY transaction_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)
```

**Q5. What does UNBOUNDED PRECEDING mean?**
Start from the first row of the partition.

**Q6. What does CURRENT ROW mean?**
The row currently being calculated.

**Q7. What does UNBOUNDED FOLLOWING mean?**
Continue from the current position until the last row of the partition.

**Q8. What is the difference between last 7 rows and last 7 days?**
Last 7 rows means 7 physical records. Last 7 days means all records that fall within the specified 7-day time period.

**Q9. What is a moving window?**
A moving window is a Window Frame that changes as the current row moves through the ordered dataset.

**Q10. What is the difference between a partition and a frame?**
A partition is the complete group of rows. A frame is the specific subset of rows inside that group used for the current calculation.

---

## 31. Quick Revision

```text
WINDOW FRAME        → Defines which rows participate in a calculation.
ROWS                 → Physical row positions.
RANGE                → ORDER BY values and peer rows.
UNBOUNDED PRECEDING  → First row.
N PRECEDING          → N rows before.
CURRENT ROW          → Current row.
N FOLLOWING          → N rows after.
UNBOUNDED FOLLOWING  → Last row.
Running Total        → UNBOUNDED PRECEDING TO CURRENT ROW.
Moving Average        → Previous N rows + Current row.
Last N Rows          → ROWS.
Last N Days          → Time-based RANGE.
```

## Final Summary

Window Frames provide control over exactly which rows participate in a Window Function calculation.

The most important concepts:

```text
PARTITION BY  → Which group?
ORDER BY      → In what sequence?
WINDOW FRAME  → Which specific rows should be included?
```

Always identify the business requirement first:

```text
Individual records?              → ROWS
Equal ORDER BY values / value-based behavior? → RANGE
Previous N records?              → ROWS with PRECEDING
Previous N days?                 → Time-based RANGE
```
