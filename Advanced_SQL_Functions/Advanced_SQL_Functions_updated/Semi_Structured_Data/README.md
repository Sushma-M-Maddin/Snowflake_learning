# Semi-Structured Data in Snowflake

This folder contains my learning and practice material for semi-structured data (JSON/VARIANT) in Snowflake.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- Structured vs semi-structured data
- JSON
- `VARIANT`
- Accessing JSON fields with `:` (including nested paths)
- Casting extracted values with `::`
- `PARSE_JSON()`
- JSON arrays
- `FLATTEN()`
- `LATERAL FLATTEN()`
- FLATTEN output columns: `VALUE`, `INDEX`, `KEY`, `PATH`
- Flattening arrays of objects
- A complete small end-to-end workflow
- `OBJECT` and `ARRAY` types
- Checking types with `TYPEOF()`, `IS_ARRAY()`, `IS_OBJECT()`
- Missing key vs explicit NULL value
- Why `FLATTEN()` is a row-multiplier — and how that connects directly to JOIN row-multiplication and grain (see the Advanced_Joins folder)
- Nested arrays and `recursive => TRUE`
- Real-world ELT pattern (API → JSON → VARIANT → FLATTEN → relational rows)
- Common mistakes
- Interview questions and answers

### `practice.sql`

Contains SQL queries for practicing:

- Creating a `VARIANT` table and loading sample JSON (including a null field and a missing key)
- Reading top-level fields
- Missing key vs explicit null demonstration
- Flattening an array of objects (`accounts`)
- Flattening a simple array (`skills`)
- Correctly aggregating after a single `FLATTEN()`
- **Demonstrating** the row-multiplication problem when two arrays are flattened together
- The fix: flattening arrays separately instead of combining them
- Type-checking functions
- Full `FLATTEN()` output column walkthrough (`VALUE`/`INDEX`/`KEY`/`PATH`)
- A complete step-by-step workflow
- Practice and interview questions

## Folder Structure

```text
Semi_Structured_Data/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Mental Model

```text
JSON
  ↓
VARIANT
  ↓
customer_data:field
  ↓
If the field is an ARRAY
  ↓
FLATTEN()
  ↓
Separate rows
  ↓
f.value:field
```

## The Key Connection Worth Remembering

`FLATTEN()` multiplies rows the same way a one-to-many (or many-to-many) JOIN does. Flattening two independent arrays from the same row in one query produces the array-length **product**, exactly like directly joining two "many" tables — see the Advanced_Joins notes on grain and row multiplication for the full explanation of why this happens and how to avoid it.

## Real-World Pattern

A common ELT pattern is:

```text
API / Application
      ↓
JSON
      ↓
Snowflake staging
      ↓
VARIANT
      ↓
FLATTEN()
      ↓
Relational-style rows
      ↓
Analytics / reporting
```

## Learning Goal

The goal of this folder is to be comfortable storing, querying, and flattening semi-structured (JSON) data in Snowflake — and to recognize when a `FLATTEN()` is quietly multiplying rows the same way an unplanned JOIN would.
