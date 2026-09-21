# Date & Time Functions

This folder contains my learning and practice material for Date & Time functions in Snowflake.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- `DATE` vs `TIMESTAMP`
- The three TIMESTAMP variants (`TIMESTAMP_NTZ`, `TIMESTAMP_LTZ`, `TIMESTAMP_TZ`)
- `CURRENT_DATE()` / `CURRENT_TIMESTAMP()`
- `DATEADD()`
- `DATEDIFF()`
- `DATE_TRUNC()`
- `EXTRACT()` / `DATE_PART()`
- `TO_DATE()` / `TO_TIMESTAMP()` / `TO_CHAR()`
- `DAYNAME()` / `DAYOFWEEK()` / `DAYOFYEAR()`
- Weeks, months, quarters, years
- Date-range filtering (half-open ranges)
- Why range filtering beats `DATE_TRUNC` equality for performance
- `LAST_DAY()`
- Age / duration / tenure calculations
- Combining date functions for periodic reporting
- Real-world use cases
- Common mistakes
- Interview questions and answers

### `practice.sql`

Contains SQL queries for practicing:

- Sample transactions table with realistic timestamps
- `CURRENT_DATE()` / `CURRENT_TIMESTAMP()`
- `DATEADD()` and `DATEDIFF()`, including per-row usage
- `DATE_TRUNC()` at multiple granularities
- `EXTRACT()` / `DATE_PART()`
- `DAYNAME()` / `DAYOFWEEK()` / `DAYOFYEAR()`
- Type conversions with explicit format masks
- `LAST_DAY()` at month/quarter/year level
- Half-open range filtering for a specific month
- Monthly aggregation
- Customer tenure calculation
- SLA / duration breach detection
- "Last 90 days" filtering
- Practice and interview questions

## Folder Structure

```text
Date_Time/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Mental Model

```text
DATEADD     → move a date forward/backward
DATEDIFF    → difference between two dates (end - start)
DATE_TRUNC  → beginning of a period (always rounds down)
EXTRACT / DATE_PART → pull out one component
LAST_DAY    → end of a period

NTZ → no timezone, stored/shown as typed
LTZ → stored as UTC, shown in session timezone
TZ  → stored as UTC + its own offset
```

## Practical Pattern

For filtering a specific month on a `TIMESTAMP` column, prefer a half-open range over `DATE_TRUNC` equality:

```sql
WHERE transaction_time >= '2026-09-01'
  AND transaction_time < '2026-10-01'
```

This is both more correct (no missed boundary rows) and more performant on large tables (allows pruning on the raw column).

## Learning Goal

The goal of this folder is to be comfortable manipulating, filtering, and aggregating dates and timestamps in Snowflake — including the timezone-variant gotchas that don't show up until you hit them in real data.
