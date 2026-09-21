# Semi-Structured Data in Snowflake — Theory Notes

## Table of Contents

1. [Structured vs Semi-Structured Data](#1-structured-vs-semi-structured-data)
2. [JSON](#2-json)
3. [VARIANT](#3-variant)
4. [Accessing JSON Fields](#4-accessing-json-fields)
5. [Casting Extracted Values](#5-casting-extracted-values)
6. [PARSE_JSON()](#6-parse_json)
7. [JSON Arrays](#7-json-arrays)
8. [FLATTEN()](#8-flatten)
9. [LATERAL FLATTEN()](#9-lateral-flatten)
10. [FLATTEN Output Columns](#10-flatten-output-columns)
11. [Array of Objects](#11-array-of-objects)
12. [Complete Small Workflow](#12-complete-small-workflow)
13. [OBJECT and ARRAY Types](#13-object-and-array-types)
14. [Checking Types — TYPEOF, IS_ARRAY, IS_OBJECT](#14-checking-types--typeof-is_array-is_object)
15. [Missing Key vs NULL Value](#15-missing-key-vs-null-value)
16. [FLATTEN Is a Row-Multiplier — Connecting to JOIN Grain](#16-flatten-is-a-row-multiplier--connecting-to-join-grain)
17. [Nested Arrays and recursive => TRUE](#17-nested-arrays-and-recursive--true)
18. [Real-World ELT Pattern](#18-real-world-elt-pattern)
19. [Common Mistakes](#19-common-mistakes)
20. [Interview Questions](#20-interview-questions)
21. [Interview Mental Model](#21-interview-mental-model)

---

## 1. Structured vs Semi-Structured Data

**Structured data** has a fixed table schema — every row has the same columns:

```text
customer_id | name   | city
101         | Sushma | Bangalore
```

**Semi-structured data** has structure, but that structure can **vary between records** — one record might have a field another doesn't, or a field might be nested differently. JSON is the most common example, but XML, Avro, and Parquet also fall into this category.

```text
Structured        → every row: same fixed columns
Semi-structured    → every row: structure can vary (nested, optional fields, arrays)
```

---

## 2. JSON

Example:

```json
{
  "customer_id": 101,
  "name": "Sushma",
  "address": {
    "city": "Bangalore",
    "pincode": 560001
  }
}
```

Notice the nesting — `address` is itself an object containing `city` and `pincode`. A relational table can't naturally represent this without either flattening it into fixed columns ahead of time or introducing a separate related table — which is exactly the problem `VARIANT` and `FLATTEN()` solve.

---

## 3. VARIANT

Snowflake's `VARIANT` data type can store semi-structured data as a single value.

```sql
CREATE TABLE customers (
    customer_id INT,
    customer_data VARIANT
);
```

The entire JSON object above can be stored as **one value** in the `customer_data` column — no need to define a rigid schema for every possible nested field up front.

---

## 4. Accessing JSON Fields

Use `:` to access fields inside a `VARIANT` value.

```sql
customer_data:name
customer_data:city
```

For nested objects, chain the `:`/`.` path:

```sql
customer_data:address.city
customer_data:address.pincode
```

This is Snowflake's semi-structured data **path syntax** — it lets you reach into nested structure without writing a JOIN or a separate parsing step.

---

## 5. Casting Extracted Values

Values extracted from a `VARIANT` column come back as `VARIANT` type themselves by default (even a number looks like `"101"` with quotes in output) — cast them to normal SQL types with `::`:

```sql
customer_data:name::STRING
customer_data:age::INT
customer_data:account.balance::NUMBER
```

> **Why this matters:** comparing or aggregating an un-cast `VARIANT` value can behave unexpectedly — `SUM(customer_data:account.balance)` may not work the way you expect until you cast it: `SUM(customer_data:account.balance::NUMBER)`.

---

## 6. PARSE_JSON()

For small examples, testing, or manually inserting JSON text, `PARSE_JSON()` converts JSON **text** into a semi-structured value that can be stored in a `VARIANT` column.

```sql
SELECT PARSE_JSON('{"name":"Sushma","age":23}');
```

Mental model:

```text
JSON text
   ↓
PARSE_JSON()
   ↓
VARIANT
```

In real ingestion pipelines, JSON commonly arrives through files or other sources and is loaded through Snowflake ingestion mechanisms such as stages and `COPY INTO` — where the JSON parsing into `VARIANT` happens automatically as part of the load, without you calling `PARSE_JSON()` manually. That ingestion workflow is a separate topic from what's covered here.

---

## 7. JSON Arrays

Example:

```json
{
  "skills": ["Java", "SQL", "Snowflake"]
}
```

An array contains **multiple elements** under a single key. Arrays are where semi-structured data starts to meaningfully diverge from a normal table row — one customer might have zero skills, another might have five, and a fixed-column table can't represent that naturally.

---

## 8. FLATTEN()

`FLATTEN()` expands elements of a semi-structured array (or object) into **separate rows**.

Common pattern:

```sql
SELECT
    f.value
FROM customers,
LATERAL FLATTEN(
    input => customer_data:skills
) f;
```

For:

```json
["Java", "SQL", "Snowflake"]
```

the flattened result is conceptually:

```text
INDEX | VALUE
0     | Java
1     | SQL
2     | Snowflake
```

One JSON array on one row became **three rows** — this is the core operation `FLATTEN()` performs, and it's important to notice this is structurally the same idea as a JOIN producing more rows than you started with (§16 below expands on this).

---

## 9. LATERAL FLATTEN()

A common pattern is:

```sql
FROM customers,
LATERAL FLATTEN(input => customer_data:accounts) f
```

Think of `LATERAL` as running the flatten operation **separately for each row** of the source table — each customer's array gets expanded independently, and the results are attached back to that customer's row.

Example:

```text
Customer 101 → [Java, SQL]
Customer 102 → [Python, Snowflake]
```

becomes:

```text
101 | Java
101 | SQL
102 | Python
102 | Snowflake
```

`LATERAL` is what lets `FLATTEN()` reference a column (`customer_data:skills`) from the *same* row in the outer query — an ordinary subquery can't do that.

---

## 10. FLATTEN Output Columns

`FLATTEN()` returns several useful columns per exploded row:

### VALUE

The actual element.

```sql
f.value
```

If the array element is itself an object, drill further into it:

```sql
f.value:order_id
f.value:amount
```

### INDEX

The position of an array element. **Snowflake array indexes start at 0**, matching most programming languages (unlike `SUBSTRING`/`POSITION`/`SPLIT_PART`, which are 1-indexed — this inconsistency is worth remembering).

```text
0 → first element
1 → second element
2 → third element
```

### KEY

The JSON property name, when flattening an **object** rather than an array.

For:

```json
{
  "name": "Sushma",
  "city": "Bangalore"
}
```

flattening this object gives keys `name` and `city`.

### PATH

The location/path of the element inside the semi-structured data — useful for debugging deeply nested structures or for recursive flattening (§17).

---

## 11. Array of Objects

The most common real-world shape: an array where each element is itself an object with multiple fields.

```json
{
  "customer_id": 101,
  "name": "Sushma",
  "accounts": [
    {
      "account_type": "SAVINGS",
      "balance": 50000
    },
    {
      "account_type": "CURRENT",
      "balance": 120000
    }
  ]
}
```

Query:

```sql
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name,
    f.index AS account_index,
    f.value:account_type::STRING AS account_type,
    f.value:balance::NUMBER AS balance
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:accounts
) f;
```

Result:

```text
customer_id | customer_name | account_index | account_type | balance
101         | Sushma        | 0             | SAVINGS      | 50000
101         | Sushma        | 1             | CURRENT      | 120000
```

The original JSON had **one customer row** with an `accounts` array. `FLATTEN()` produced **one row per account** — notice `customer_id` and `customer_name` repeat, exactly like a one-to-many JOIN.

---

## 12. Complete Small Workflow

**Step 1 — Create a table:**

```sql
CREATE OR REPLACE TABLE customer_raw (
    customer_data VARIANT
);
```

**Step 2 — Insert JSON:**

```sql
INSERT INTO customer_raw
SELECT PARSE_JSON('
{
  "customer_id": 101,
  "name": "Sushma",
  "accounts": [
    {
      "account_type": "SAVINGS",
      "balance": 50000
    },
    {
      "account_type": "CURRENT",
      "balance": 120000
    }
  ]
}
');
```

**Step 3 — Read top-level fields:**

```sql
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name
FROM customer_raw;
```

**Step 4 — Flatten the nested array:**

```sql
SELECT
    customer_data:customer_id::INT AS customer_id,
    customer_data:name::STRING AS customer_name,
    f.value:account_type::STRING AS account_type,
    f.value:balance::NUMBER AS balance
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data:accounts
) f;
```

---

## 13. OBJECT and ARRAY Types

Alongside `VARIANT`, Snowflake also has dedicated `OBJECT` and `ARRAY` types:

```text
VARIANT → can hold any semi-structured value (object, array, string, number, boolean, null)
OBJECT  → specifically a JSON-style key-value object
ARRAY   → specifically an ordered list of values
```

In practice, `VARIANT` is the most commonly used column type for ingested JSON, since incoming data's shape (object vs array vs scalar) isn't always known or fixed ahead of time. `OBJECT` and `ARRAY` are more often seen as the *result* of constructing semi-structured values inside a query (e.g. `OBJECT_CONSTRUCT()`, `ARRAY_CONSTRUCT()`) rather than as a storage column type for raw ingested data.

---

## 14. Checking Types — TYPEOF, IS_ARRAY, IS_OBJECT

Since a `VARIANT` column's content shape can vary row to row, Snowflake provides functions to check what's actually stored:

```sql
SELECT TYPEOF(customer_data:accounts);   -- 'ARRAY'
SELECT IS_ARRAY(customer_data:accounts); -- TRUE
SELECT IS_OBJECT(customer_data);         -- TRUE
```

Useful in data-quality checks on ingested JSON — e.g. verifying that a field expected to always be an array actually is one, before running a `FLATTEN()` on it (flattening a non-array value can silently produce different results than expected).

---

## 15. Missing Key vs NULL Value

An important distinction when working with semi-structured data that doesn't come up with regular tables:

```json
{ "name": "Sushma", "city": null }
```
vs
```json
{ "name": "Sushma" }
```

In the first record, `city` exists and is explicitly `null`. In the second, `city` doesn't exist at all. Both `customer_data:city` expressions return SQL `NULL` when queried — **Snowflake doesn't distinguish "explicitly null" from "key missing" through a plain `:` access** in the typical case. If that distinction matters for your business logic (e.g. "was this field ever collected?" vs "was it collected but empty?"), you may need `OBJECT_KEYS()` or similar to check for key presence explicitly, rather than relying on the extracted value being `NULL`.

---

## 16. FLATTEN Is a Row-Multiplier — Connecting to JOIN Grain

This is the single most important thing to internalize about `FLATTEN()`, and it connects directly to the JOIN/grain concepts from the Advanced Joins notes.

Recall from Advanced Joins: **a JOIN multiplies rows when one side has multiple matches** (one customer × many transactions → many rows). `FLATTEN()` does the exact same thing, just with an array instead of a second table:

```text
JOIN:    1 customer row × N matching transaction rows → N output rows
FLATTEN: 1 customer row × N array elements             → N output rows
```

If a customer has an `accounts` array (2 elements) **and** you separately flatten a `skills` array (3 elements) in the *same* query, you get the same many-to-many multiplication problem as joining two "many" tables directly:

```text
2 accounts × 3 skills = 6 rows for that one customer
```

This is exactly the many-to-many row-multiplication problem from Advanced Joins §17 — just triggered by two `FLATTEN()` calls instead of two JOINs. The same fix applies: don't flatten two independent arrays in the same query without first deciding what grain you actually need, and aggregate/separate the flattens if the combination isn't intended.

---

## 17. Nested Arrays and recursive => TRUE

For deeply nested JSON (an array inside an array, or several levels of nested objects), `FLATTEN()` supports a `recursive => TRUE` option to expand all levels in one call, along with a `mode` parameter to control whether it flattens objects, arrays, or both:

```sql
SELECT
    f.path,
    f.value
FROM customer_raw,
LATERAL FLATTEN(
    input => customer_data,
    recursive => TRUE
) f;
```

This is more advanced and less commonly needed than a single-level `FLATTEN()` — most real-world JSON payloads only need one or two explicit `FLATTEN()` calls chained together for their known nested arrays, rather than a fully recursive expansion.

---

## 18. Real-World ELT Pattern

A common Snowflake ELT (Extract-Load-Transform) pattern for semi-structured data:

```text
API / Application
      ↓
JSON
      ↓
Snowflake staging (raw VARIANT column)
      ↓
VARIANT
      ↓
FLATTEN() for arrays
      ↓
Relational-style rows
      ↓
Analytics / reporting tables
```

The idea: land the raw JSON as-is first (fast, flexible, no upfront schema decisions), then use `:` path access and `FLATTEN()` in downstream transformation queries to shape it into normal relational tables for BI tools and analysts who expect flat rows and columns.

---

## 19. Common Mistakes

**Mistake 1 — Forgetting to cast extracted values**

```sql
SELECT SUM(customer_data:account.balance)  -- may not behave as expected
```
Cast explicitly: `SUM(customer_data:account.balance::NUMBER)`.

**Mistake 2 — Forgetting LATERAL**

`FLATTEN()` needs `LATERAL` (or Snowflake's equivalent join-lateral syntax) to reference a column from the same row in the outer query. Omitting it, or trying to flatten a column that isn't visible in that scope, causes an error or unexpected results.

**Mistake 3 — Flattening two independent arrays in one query without thinking about grain**

As shown in §16, flattening two unrelated arrays from the same row in a single query multiplies rows exactly like a many-to-many JOIN — decide the required grain first, just as with regular JOINs.

**Mistake 4 — Treating "missing key" and "null value" as distinguishable via `:` access**

Both come back as SQL `NULL` through plain path access — don't assume a `NULL` result means the key was explicitly set to null, or vice versa (§15).

**Mistake 5 — Assuming array indexes are 1-based like SPLIT_PART**

`FLATTEN()`'s `INDEX` column is **0-based**, unlike `SPLIT_PART()`/`SUBSTRING()`/`POSITION()`, which are 1-based. Mixing these up across a query that uses both string functions and `FLATTEN()` is an easy off-by-one mistake.

---

## 20. Interview Questions

**Q1. What is the difference between structured and semi-structured data?**
Structured data has a fixed schema — every row has the same columns. Semi-structured data (like JSON) has structure, but it can vary between records — fields can be nested, optional, or contain arrays of varying length.

**Q2. What is VARIANT in Snowflake?**
A data type that can store semi-structured data (JSON, and similar formats) as a single column value, without requiring a fixed upfront schema.

**Q3. How do you access a field inside a VARIANT column?**
Using `:` path syntax, e.g. `customer_data:name`, and `.` for nested paths, e.g. `customer_data:address.city`.

**Q4. Why do you need to cast extracted VARIANT values?**
Because values extracted via `:` come back as `VARIANT` type by default, not a normal SQL type — casting with `::STRING`, `::INT`, `::NUMBER` etc. ensures correct comparisons, sorting, and aggregation.

**Q5. What does FLATTEN() do?**
It expands elements of a semi-structured array (or object) into separate rows — one input row with an N-element array becomes N output rows.

**Q6. Why is LATERAL used with FLATTEN()?**
`LATERAL` allows `FLATTEN()` to reference a column from the same row in the outer query, running the flatten operation separately for each row of the source table.

**Q7. What is the difference between VALUE, INDEX, KEY, and PATH in FLATTEN() output?**
`VALUE` is the actual array/object element. `INDEX` is the array position (0-based). `KEY` is the property name when flattening an object. `PATH` is the full location of the element within the semi-structured data.

**Q8. How can FLATTEN() cause the same row-multiplication problem as a JOIN?**
Flattening one array on a row multiplies that row's output the same way a one-to-many JOIN does. Flattening two independent arrays from the same row in one query produces the array-length product of both — the same many-to-many multiplication problem as directly joining two "many" tables.

---

## 21. Interview Mental Model

```text
VARIANT → stores semi-structured data
:       → accesses JSON fields
::      → casts extracted values to normal SQL types
FLATTEN → expands arrays/objects into rows
LATERAL → runs FLATTEN per row of the outer query

VALUE   → actual element
INDEX   → array position (0-based!)
KEY     → object property name
PATH    → location inside JSON

FLATTEN row multiplication ≈ JOIN row multiplication
  → think about grain before flattening more than one array at once
```
