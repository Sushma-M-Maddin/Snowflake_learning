# Date & Time Functions — Theory Notes

## Table of Contents

1. [DATE vs TIMESTAMP](#1-date-vs-timestamp)
2. [The Three TIMESTAMP Variants in Snowflake](#2-the-three-timestamp-variants-in-snowflake)
3. [CURRENT_DATE() and CURRENT_TIMESTAMP()](#3-current_date-and-current_timestamp)
4. [DATEADD()](#4-dateadd)
5. [DATEDIFF()](#5-datediff)
6. [DATE_TRUNC()](#6-date_trunc)
7. [EXTRACT() and DATE_PART()](#7-extract-and-date_part)
8. [TO_DATE(), TO_TIMESTAMP(), TO_CHAR()](#8-to_date-to_timestamp-to_char)
9. [DAYNAME(), DAYOFWEEK(), DAYOFYEAR()](#9-dayname-dayofweek-dayofyear)
10. [Weeks, Months, Quarters, Years](#10-weeks-months-quarters-years)
11. [Date-Range Filtering](#11-date-range-filtering)
12. [Why Not WHERE DATE_TRUNC(...) = '2026-09-01'?](#12-why-not-where-date_trunc--2026-09-01)
13. [LAST_DAY()](#13-last_day)
14. [Age / Duration Calculations](#14-age--duration-calculations)
15. [Combining Date Functions](#15-combining-date-functions)
16. [Real-World Use Cases](#16-real-world-use-cases)
17. [Common Mistakes](#17-common-mistakes)
18. [Interview Questions](#18-interview-questions)
19. [Interview Mental Model](#19-interview-mental-model)

---

## 1. DATE vs TIMESTAMP

`DATE` stores a calendar date only:

```sql
'2026-09-21'
```

`TIMESTAMP` stores date **and** time:

```text
2026-09-21 10:30:45
```

Use `DATE` when time-of-day doesn't matter (e.g. a birth date, a due date). Use `TIMESTAMP` when event timing matters (e.g. when a transaction happened, when a record was last updated).

---

## 2. The Three TIMESTAMP Variants in Snowflake

Snowflake doesn't have just one `TIMESTAMP` type — it has three, and plain `TIMESTAMP` is really an alias for whichever one your session is configured to use (`TIMESTAMP_NTZ` by default).

| Type | Stores | Timezone behavior |
|---|---|---|
| `TIMESTAMP_NTZ` (No Time Zone) | "Wall-clock" time as typed, with no timezone attached | Never changes based on session timezone. This is the **default** for plain `TIMESTAMP`. |
| `TIMESTAMP_LTZ` (Local Time Zone) | UTC internally | Displayed converted to the *current session's* timezone — the same stored value can show differently to different sessions |
| `TIMESTAMP_TZ` (Time Zone) | UTC + an explicit timezone offset per row | Each row remembers its own offset, regardless of session |

```text
NTZ → what you typed, no timezone math, ever.
LTZ → stored as UTC, displayed in your session's timezone.
TZ  → stored as UTC + its own offset, always shown with that offset.
```

**Why this matters:** if you insert the same literal timestamp into an `NTZ` column and an `LTZ` column, and then change your session timezone, only the `LTZ` value's displayed time will shift. This is a common source of confusing "the data changed but I didn't touch it" bugs — it didn't change, only how it's displayed did.

---

## 3. CURRENT_DATE() and CURRENT_TIMESTAMP()

```sql
SELECT CURRENT_DATE();       -- today's date
SELECT CURRENT_TIMESTAMP();  -- today's date + current time
```

Both reflect the **session's** timezone setting — useful to know when debugging "off by a few hours" issues on `TIMESTAMP_LTZ` columns.

---

## 4. DATEADD()

Moves a date/time forward or backward.

```sql
DATEADD(part, value, date)
```

```sql
SELECT DATEADD(day, 7, '2026-09-21');     -- 7 days later
SELECT DATEADD(month, -1, '2026-09-21');  -- 1 month earlier
```

Positive values move forward; negative values move backward.

```text
DATEADD(day, 7, ...)    → +7 days
DATEADD(day, -7, ...)   → -7 days
DATEADD(month, 1, ...)  → +1 month
DATEADD(year, -2, ...)  → -2 years
```

---

## 5. DATEDIFF()

Calculates the difference between two dates/timestamps.

```sql
DATEDIFF(part, start_date, end_date)
```

```sql
SELECT DATEDIFF(day, '2026-09-01', '2026-09-21');  -- 20
```

> **Order matters.** `DATEDIFF(day, start, end)` gives `end - start`. If you accidentally swap the arguments, you get a negative number instead of an error — always sanity-check the sign.

---

## 6. DATE_TRUNC()

Returns the **beginning** of a specified period.

```sql
DATE_TRUNC('month', transaction_date)
```

For any date in September, this returns `2026-09-01` (the start of that month). It does **not** round to the nearest boundary — it always truncates *down* to the start of the period.

Useful for monthly/weekly/quarterly grouping:

```sql
DATE_TRUNC('week', transaction_date)
DATE_TRUNC('month', transaction_date)
DATE_TRUNC('quarter', transaction_date)
DATE_TRUNC('year', transaction_date)
```

---

## 7. EXTRACT() and DATE_PART()

Both get **one component** out of a date/time — they're functionally equivalent, just different syntax styles.

```sql
SELECT EXTRACT(year FROM transaction_date);
SELECT EXTRACT(month FROM transaction_date);
SELECT EXTRACT(day FROM transaction_date);

SELECT DATE_PART(year, transaction_date);   -- same result, different syntax
```

```text
EXTRACT()   → SQL-standard syntax: EXTRACT(part FROM date)
DATE_PART() → Snowflake-style syntax: DATE_PART(part, date)
```

Either is fine — pick one and stay consistent within a codebase.

---

## 8. TO_DATE(), TO_TIMESTAMP(), TO_CHAR()

**`TO_DATE()`** — converts a string (or timestamp) to `DATE`:

```sql
SELECT TO_DATE('2026-09-21');
```

**`TO_TIMESTAMP()`** — converts a string to `TIMESTAMP`:

```sql
SELECT TO_TIMESTAMP('2026-09-21 10:30:00');
```

**`TO_CHAR()`** — formats a date/timestamp **as text** (the reverse direction — SQL type → string):

```sql
SELECT TO_CHAR(transaction_date, 'YYYY-MM-DD');
```

```text
String → Date/Timestamp   → TO_DATE() / TO_TIMESTAMP()
Date/Timestamp → String   → TO_CHAR()
```

For non-standard string formats (e.g. `21-Sep-2026`), pass an explicit format mask as a second argument: `TO_DATE('21-Sep-2026', 'DD-Mon-YYYY')`. Without it, Snowflake guesses the format, which can silently misparse ambiguous strings like `01-02-2026`.

---

## 9. DAYNAME(), DAYOFWEEK(), DAYOFYEAR()

Useful for weekday-based analysis (e.g. "which day of the week has the most transactions?").

```sql
SELECT DAYNAME(transaction_date);     -- e.g. 'Mon'
SELECT DAYOFWEEK(transaction_date);   -- numeric day of week
SELECT DAYOFYEAR(transaction_date);   -- 1-366
```

> **Gotcha:** `DAYOFWEEK()` numbering conventions differ across databases (some start the week on Sunday = 0, others on Monday = 1). Always check what a given system returns before relying on the number directly — `DAYNAME()` is safer when you just need a human-readable label.

---

## 10. Weeks, Months, Quarters, Years

Date functions can work at different calendar granularities:

```sql
DATE_TRUNC('week', transaction_date)     -- start of that week
DATE_TRUNC('month', transaction_date)    -- start of that month
DATE_TRUNC('quarter', transaction_date)  -- start of that quarter
DATE_TRUNC('year', transaction_date)     -- start of that year
```

> **Week gotcha:** by default, Snowflake's `week` part follows the ISO standard, where weeks start on **Monday**. If your business reports run Sunday-to-Saturday, you may need `WEEK_START` session parameter adjustments or a custom calculation — don't assume "week" means what a US-style calendar app shows.

---

## 11. Date-Range Filtering

For a specific month on a `TIMESTAMP` column, prefer a **half-open range** over `DATE_TRUNC` equality or `BETWEEN`:

```sql
WHERE transaction_time >= '2026-09-01'
  AND transaction_time < '2026-10-01'
```

This avoids accidentally excluding rows that have a time component on the last day (`2026-09-30 23:59:59` is still `< 2026-10-01`, but would be excluded by `<= '2026-09-30'` if the row happens to have a later time than midnight) and works cleanly regardless of the column's precision.

---

## 12. Why Not WHERE DATE_TRUNC(...) = '2026-09-01'?

You *can* write:

```sql
WHERE DATE_TRUNC('month', transaction_time) = '2026-09-01'
```

but this applies a function to **every row** of the column before comparing, which can prevent Snowflake from using clustering/partition pruning efficiently on very large tables. The range-filter approach in §11 lets the engine prune on the raw column directly and is the generally preferred pattern in production pipelines.

```text
Correctness-wise: both work.
Performance-wise: range filtering scales better on large tables.
```

---

## 13. LAST_DAY()

Returns the **last day** of a period.

```sql
SELECT LAST_DAY('2026-09-21');  -- 2026-09-30
```

It can also be used for other periods such as quarters or years by passing a second argument:

```sql
SELECT LAST_DAY('2026-09-21', 'quarter');
SELECT LAST_DAY('2026-09-21', 'year');
```

Common use: finding month-end balances, generating end-of-period reports, or validating that a date falls within the current billing cycle.

---

## 14. Age / Duration Calculations

Use `DATEDIFF()` when you need a duration between two points in time.

```sql
SELECT DATEDIFF(day, start_date, end_date);
```

Common patterns:

```sql
-- Customer tenure in days
DATEDIFF(day, signup_date, CURRENT_DATE())

-- SLA breach check (more than 24 hours to resolve)
DATEDIFF(hour, opened_at, resolved_at) > 24

-- Age in years (approximate — see note below)
DATEDIFF(year, date_of_birth, CURRENT_DATE())
```

> **Note on "age in years":** `DATEDIFF(year, ...)` counts calendar-year boundaries crossed, not full 365-day years — someone born on `2000-12-31` and measured on `2026-01-01` would show `DATEDIFF(year, ...) = 26`, even though they're not yet 26. For precise age, compare month/day too, or use a dedicated age function if the dialect has one.

---

## 15. Combining Date Functions

Date functions are commonly combined in real transformations — most often `DATE_TRUNC` + `GROUP BY` for periodic aggregation:

```sql
SELECT
    DATE_TRUNC('month', transaction_time) AS transaction_month,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_time);
```

This is the standard shape for "transactions per month," "signups per week," "revenue per quarter," and similar reporting queries.

---

## 16. Real-World Use Cases

- **Monthly/weekly/quarterly reporting** — `DATE_TRUNC` + `GROUP BY`
- **SLA and turnaround-time monitoring** — `DATEDIFF(hour/minute, ...)` between two event timestamps
- **Cohort analysis** — grouping customers by `DATE_TRUNC('month', signup_date)` and tracking behavior over subsequent months
- **Incremental data loads** — filtering `WHERE updated_at > last_successful_load_time` (connects directly to the MERGE topic)
- **Data retention windows** — `WHERE event_date >= DATEADD(day, -90, CURRENT_DATE())` for "last 90 days" logic
- **Billing cycles** — `LAST_DAY()` for month-end close, `DATE_TRUNC('month', ...)` for cycle start

---

## 17. Common Mistakes

**Mistake 1 — Comparing dates as strings without casting**

```sql
WHERE transaction_date = '2026-09-21'
```

This usually works because Snowflake implicitly casts, but relying on implicit casting across different string formats (`'21-09-2026'` vs `'2026-09-21'`) can silently misparse. Cast explicitly with `TO_DATE()` when the format isn't the default ISO format.

**Mistake 2 — Using equality instead of a range for TIMESTAMP filtering**

```sql
WHERE transaction_time = '2026-09-21'   -- misses everything except exact midnight
```

A `TIMESTAMP` column rarely holds an exact midnight value — use a range (§11) instead.

**Mistake 3 — Forgetting DATEDIFF's argument order**

`DATEDIFF(day, a, b)` = `b - a`. Swapping `a` and `b` silently flips the sign — no error is thrown.

**Mistake 4 — Assuming DATEADD units are always singular/lowercase**

Snowflake accepts both `day`/`days`, `month`/`months`, etc., but mixing up a typo'd unit (e.g. `dy`) will error — always verify against the docs if unsure of a less common unit like `quarter` or `dayofweek`.

**Mistake 5 — Not accounting for TIMESTAMP_LTZ timezone shifts**

If a report's numbers look "off by a few hours" compared to what's expected, check whether the column is `TIMESTAMP_LTZ` and whether the session's timezone matches the business's expected reporting timezone (§2).

---

## 18. Interview Questions

**Q1. What is the difference between DATE and TIMESTAMP?**
`DATE` stores only the calendar date. `TIMESTAMP` stores date and time together.

**Q2. What are the three TIMESTAMP variants in Snowflake?**
`TIMESTAMP_NTZ` (no timezone, stores as typed), `TIMESTAMP_LTZ` (stored as UTC, displayed in session timezone), `TIMESTAMP_TZ` (stored as UTC + its own offset per row).

**Q3. What's the difference between DATEADD and DATEDIFF?**
`DATEADD` moves a date forward or backward by an interval. `DATEDIFF` calculates the difference between two dates in a given unit.

**Q4. What does DATE_TRUNC do?**
Returns the beginning of a specified period (month, week, quarter, year) for a given date — always rounds down, never up.

**Q5. Why prefer a range filter over DATE_TRUNC equality when filtering a TIMESTAMP column for a specific month?**
Range filtering (`>= start AND < next_start`) lets the query engine prune on the raw column efficiently; wrapping the column in a function for every row can hurt performance on large tables, and equality comparisons risk missing rows that aren't at an exact boundary.

**Q6. How would you calculate someone's tenure in days?**
```sql
DATEDIFF(day, start_date, CURRENT_DATE())
```

**Q7. What's the difference between EXTRACT() and DATE_PART()?**
They're functionally equivalent — `EXTRACT(part FROM date)` is SQL-standard syntax, `DATE_PART(part, date)` is Snowflake-style syntax for the same operation.

**Q8. How would you get monthly transaction counts?**
```sql
SELECT
    DATE_TRUNC('month', transaction_time) AS transaction_month,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY DATE_TRUNC('month', transaction_time);
```

---

## 19. Interview Mental Model

```text
DATEADD     → move a date forward/backward
DATEDIFF    → difference between two dates (end - start)
DATE_TRUNC  → beginning of a period (always rounds down)
EXTRACT / DATE_PART → pull out one component (year, month, day...)
LAST_DAY    → end of a period
TO_DATE / TO_TIMESTAMP → string → date/timestamp
TO_CHAR     → date/timestamp → string

NTZ → no timezone, stored/shown as typed
LTZ → stored as UTC, shown in session timezone
TZ  → stored as UTC + its own offset, always shown with that offset

Filtering a TIMESTAMP for a period → use a half-open range, not equality
```
