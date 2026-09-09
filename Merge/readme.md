# MERGE in Snowflake

This folder contains notes and SQL practice for the `MERGE` statement in Snowflake.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- What is MERGE
- Why MERGE is needed
- Target table vs Source table
- `ON` condition
- Business key / MERGE key
- `WHEN MATCHED`
- `WHEN NOT MATCHED`
- UPSERT (UPDATE + INSERT)
- Conditional MERGE
- Conditional timestamp-based updates
- DELETE using MERGE
- Order of `WHEN MATCHED` conditions
- Deduplication before MERGE
- `ROW_NUMBER()` + `QUALIFY` with MERGE
- Deterministic deduplication (tie-breaking)
- Full load vs Incremental load
- Why MERGE is not the same as incremental loading
- Identifying incremental/changed records (CDC)
- Grain and MERGE
- Common MERGE mistakes
- Real-world MERGE use cases
- Interview questions and a final MERGE checklist

### `practice.sql`

Contains SQL queries for practicing:

- Basic UPSERT (UPDATE + INSERT)
- Conditional MERGE (matched + extra condition)
- Timestamp-based MERGE (prevent older data overwriting newer)
- DELETE using MERGE
- Combined DELETE + UPDATE + INSERT in one MERGE
- Source deduplication with `ROW_NUMBER()` + `QUALIFY`
- Deduplication before MERGE
- Deterministic deduplication using a tie-breaker column
- Incremental loading example
- Incremental MERGE
- Interview practice questions

## Folder Structure

```text
MERGE/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Key Concept

MERGE is commonly used to synchronize a target table with incoming source data.

Typical pattern:

```text
Source Data
     ↓
Deduplicate
     ↓
MERGE
     ↓
Target Table
```

A MERGE can:

- UPDATE existing records
- INSERT new records
- DELETE records when required

## Example

```sql
MERGE INTO customers AS target
USING customer_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status

WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, status)
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status
    );
```

## Real-World Use

MERGE is commonly used in data engineering pipelines for:

- Incremental loading
- Upserts
- CDC processing
- Data synchronization
- Dimension table updates
- Loading changed records into warehouse tables
