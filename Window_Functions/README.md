# SQL Window Functions

This folder contains my learning and practice material for SQL Window Functions in Snowflake, including a dedicated subfolder on Window Frames.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- What are Window Functions
- Why Window Functions are used
- How Window Functions work
- `OVER()`
- Aggregate Window Functions
- `PARTITION BY`
- `ORDER BY` in Window Functions
- Running Totals
- `ROW_NUMBER()`
- `RANK()`
- `DENSE_RANK()`
- `QUALIFY`
- `LAG()`
- `LEAD()`
- Logical Query Execution Order
- `WHERE` vs `QUALIFY`
- `GROUP BY` vs Window Functions
- `PARTITION BY` vs `GROUP BY`
- `ROW_NUMBER()` vs `RANK()` vs `DENSE_RANK()`
- Real-world use cases
- Common mistakes
- Important interview concepts
- Interview questions and answers

### `practice.sql`

Contains SQL queries for practicing:

- Basic `OVER()`
- Aggregate Window Functions
- `PARTITION BY`
- `ORDER BY`
- Running Totals
- `ROW_NUMBER()`
- `RANK()`
- `DENSE_RANK()`
- `QUALIFY`
- `LAG()`
- `LEAD()`
- Latest and first record problems
- Top N per group problems
- Ranking problems
- Previous and next value comparisons
- Duplicate record handling
- Department and customer-based calculations
- Real-world SQL problems
- Common interview questions

### `Window_Frames/`

A subfolder covering Window Frames in more depth, including its own `README.md`, `theory_notes.md`, and `practice.sql`. Topics covered there:

- What is a Window Frame
- `ROWS BETWEEN`
- `UNBOUNDED PRECEDING`, `N PRECEDING`, `CURRENT ROW`, `N FOLLOWING`, `UNBOUNDED FOLLOWING`
- Running totals and moving totals via frames
- Moving averages
- `ROWS` vs `RANGE`
- Time-based `RANGE` windows (last N days)
- `PARTITION BY` with Window Frames
- Common mistakes and interview questions

See `Window_Frames/README.md` for full details.

## Folder Structure

```text
Window_Functions/
│
├── README.md
├── theory_notes.md
├── practice.sql
│
└── Window_Frames/
    ├── README.md
    ├── theory_notes.md
    └── practice.sql
```

## Topics Covered

- `OVER()`
- `PARTITION BY`
- `ORDER BY`
- Running Totals
- `ROW_NUMBER()`
- `RANK()`
- `DENSE_RANK()`
- `QUALIFY`
- `LAG()`
- `LEAD()`
- Window Frames (`ROWS`, `RANGE`, moving averages, time-based windows)
- Real-World Use Cases
- Interview Questions

## Learning Goal

The goal of this folder is to understand SQL Window Functions clearly — from the basics of `OVER()` and `PARTITION BY` through ranking, `LAG`/`LEAD`, and Window Frames — and to practice solving real-world and interview-based SQL problems.
