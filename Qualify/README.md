# SQL QUALIFY

This folder contains my learning and practice material for SQL `QUALIFY` in Snowflake.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- What is `QUALIFY`
- Why `QUALIFY` is used
- `WHERE` vs `HAVING` vs `QUALIFY`
- Logical Query Execution Order
- Why `WHERE` cannot directly filter Window Function results
- `QUALIFY` with `ROW_NUMBER()`
- Latest transaction per customer
- Top-N per group
- Deduplication using `ROW_NUMBER()` + `QUALIFY`
- `QUALIFY` with `RANK()`
- `QUALIFY` with `DENSE_RANK()`
- `QUALIFY` with `LAG()`
- `QUALIFY` with `LEAD()`
- `QUALIFY` vs Subqueries
- `QUALIFY` vs `LIMIT`
- Business keys and duplicate identification
- Real-world Snowflake Data Engineering use cases
- Common mistakes
- Important interview concepts
- Interview questions and answers

### `practice.sql`

Contains SQL queries for practicing:

- `ROW_NUMBER()` with `QUALIFY`
- Latest record per customer
- Top 2 per group
- Top 3 per group
- Lowest record per group
- Deduplication
- `RANK()` with `QUALIFY`
- `DENSE_RANK()` with `QUALIFY`
- `LAG()` with `QUALIFY`
- `LEAD()` with `QUALIFY`
- Current vs previous transaction
- Latest record using an alias
- Top-N using `ROW_NUMBER()`
- Comparing `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`
- Real-world SQL problems
- Interview practice questions

## Folder Structure

```text
QUALIFY/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Topics Covered

- `QUALIFY`
- `WHERE` vs `HAVING` vs `QUALIFY`
- Logical Query Execution Order
- `ROW_NUMBER()`
- `RANK()`
- `DENSE_RANK()`
- `LAG()`
- `LEAD()`
- Latest Record
- Top-N per Group
- Deduplication
- Business Keys
- Real-world Snowflake SQL
- Interview Questions

## Learning Goal

The goal of this folder is to understand how `QUALIFY` works in Snowflake, learn how to filter Window Function results, and practice common Data Engineering patterns such as latest-record selection, Top-N per group, and deduplication.
