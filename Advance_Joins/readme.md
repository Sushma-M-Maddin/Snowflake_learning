# Advanced SQL Joins

This folder contains my learning and practice material for Advanced SQL Joins for Snowflake Data Engineering.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- What is a JOIN
- INNER JOIN
- LEFT JOIN
- Finding unmatched records
- SELF JOIN
- Employee-manager relationships
- Multiple JOINs
- Mixing JOIN types
- One-to-one relationships
- One-to-many relationships
- Many-to-many relationships
- JOIN row multiplication
- Understanding table grain
- Why JOINs can produce duplicate-looking rows
- How JOIN multiplication affects aggregations
- Aggregate before JOIN
- Deduplicate before JOIN
- Using `QUALIFY` before JOIN
- Using `EXISTS`
- Why `DISTINCT` is not always the solution
- JOIN debugging
- Checking row counts
- Checking JOIN-key uniqueness
- Debugging individual records
- Real-world banking JOIN scenarios
- Common JOIN mistakes
- Important interview concepts
- Interview questions and answers

### `practice.sql`

Contains SQL queries for practicing:

- INNER JOIN
- LEFT JOIN
- Finding customers without transactions
- SELF JOIN
- Employee-manager hierarchy
- Multiple JOINs
- Multiple LEFT JOINs
- Customer-order-product relationships
- Many-to-many row multiplication
- Incorrect aggregation caused by JOINs
- Aggregate-before-JOIN pattern
- Address deduplication
- `ROW_NUMBER()` + `QUALIFY` before JOIN
- `EXISTS`
- JOIN row-count debugging
- JOIN-key duplicate detection
- Debugging a single customer
- Real-world customer banking scenarios
- Practice problems
- Interview questions

## Folder Structure

```text
Advanced_Joins/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Topics Covered

- INNER JOIN
- LEFT JOIN
- SELF JOIN
- Multiple JOINs
- One-to-Many
- Many-to-Many
- Row Multiplication
- Grain
- Aggregate Before JOIN
- Deduplicate Before JOIN
- EXISTS
- JOIN Debugging
- Real-World Data Engineering Scenarios
- Interview Questions

## Learning Goal

The goal of this folder is to understand how JOINs behave beyond the basics — especially how row multiplication happens, why it's dangerous for aggregations, and how to debug and prevent it using grain, aggregation, deduplication, and `EXISTS`.
