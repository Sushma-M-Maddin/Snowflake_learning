# MERGE — Theory Notes

## Table of Contents

1. [What is MERGE?](#1-what-is-merge)
2. [Why Do We Need MERGE?](#2-why-do-we-need-merge)
3. [Basic MERGE Syntax](#3-basic-merge-syntax)
4. [Target vs Source](#4-target-vs-source)
5. [ON Condition](#5-on-condition)
6. [Business Key / MERGE Key](#6-business-key--merge-key)
7. [WHEN MATCHED](#7-when-matched)
8. [WHEN NOT MATCHED](#8-when-not-matched)
9. [UPSERT](#9-upsert)
10. [Complete UPDATE + INSERT Example](#10-complete-update--insert-example)
11. [Conditional MERGE](#11-conditional-merge)
12. [Conditional Timestamp Update](#12-conditional-timestamp-update)
13. [DELETE Using MERGE](#13-delete-using-merge)
14. [Order of WHEN MATCHED Conditions](#14-order-of-when-matched-conditions)
15. [Deduplication Before MERGE](#15-deduplication-before-merge)
16. [ROW_NUMBER() + QUALIFY Before MERGE](#16-row_number--qualify-before-merge)
17. [Complete Deduplication + MERGE](#17-complete-deduplication--merge)
18. [Deterministic Deduplication](#18-deterministic-deduplication)
19. [Incremental Loading](#19-incremental-loading)
20. [Incremental Load](#20-incremental-load)
21. [MERGE Is Not the Same as Incremental Loading](#21-merge-is-not-the-same-as-incremental-loading)
22. [Identifying Incremental Records](#22-identifying-incremental-records)
23. [Grain and MERGE](#23-grain-and-merge)
24. [Common MERGE Mistakes](#24-common-merge-mistakes)
25. [Real-World MERGE Use Cases](#25-real-world-merge-use-cases)
26. [MERGE Mental Model](#26-merge-mental-model)
27. [Interview Questions](#27-interview-questions)
28. [Final MERGE Checklist](#28-final-merge-checklist)
29. [Key Takeaways](#29-key-takeaways)

---

## 1. What is MERGE?

`MERGE` is a SQL statement used to synchronize a target table with a source dataset. It lets us perform different actions depending on whether a source record already exists in the target.

A MERGE can perform:

- UPDATE
- INSERT
- DELETE

based on matching conditions.

**Basic idea:**

```text
Source
  ↓
Compare with Target
  ↓
Is there a match?
  ├── Yes → UPDATE / DELETE
  └── No  → INSERT
```

---

## 2. Why Do We Need MERGE?

Suppose we have a customer table:

| customer_id | customer_name | status |
| ----------- | -------------- | ------ |
| 101         | Ravi           | ACTIVE |
| 102         | Priya          | ACTIVE |
| 103         | Amit           | ACTIVE |

A new source contains:

| customer_id | customer_name | status |
| ----------- | -------------- | ------ |
| 102         | Priya Sharma   | ACTIVE |
| 104         | Neha           | ACTIVE |

We want: Customer 102 → UPDATE, Customer 104 → INSERT.

Without MERGE, we might need separate UPDATE and INSERT statements. MERGE lets us handle both operations together, in one statement.

---

## 3. Basic MERGE Syntax

```sql
MERGE INTO target_table AS target
USING source_table AS source
ON target.key = source.key

WHEN MATCHED THEN
    UPDATE SET
        target.column1 = source.column1,
        target.column2 = source.column2

WHEN NOT MATCHED THEN
    INSERT (column1, column2)
    VALUES (source.column1, source.column2);
```

---

## 4. Target vs Source

**Target** — the table that will be modified:

```sql
MERGE INTO customers AS target
```

The target can receive updates, inserts, and deletes.

**Source** — contains the incoming data:

```sql
USING customer_updates AS source
```

The source can be a table, a view, a query, or a subquery:

```sql
USING (
    SELECT *
    FROM customer_updates
) AS source
```

---

## 5. ON Condition

The `ON` condition determines whether a source record matches a target record.

```sql
ON target.customer_id = source.customer_id
```

If `target.customer_id = source.customer_id`, the record is considered matched. Otherwise, it is not matched.

---

## 6. Business Key / MERGE Key

The column used in the `ON` condition is extremely important.

```sql
ON target.customer_id = source.customer_id
```

Here `customer_id` is the **MERGE key**. It should represent the business identity of the record. Examples:

```text
customer_id
account_id
product_id
employee_id
order_id
```

Choosing the wrong key can cause incorrect updates or duplicate records.

---

## 7. WHEN MATCHED

`WHEN MATCHED` runs when a source record matches a target record.

```sql
WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name
```

Target: `101 | Ravi`. Source: `101 | Ravi Kumar`. After MERGE: `101 | Ravi Kumar`.

---

## 8. WHEN NOT MATCHED

`WHEN NOT MATCHED` handles source records that don't exist in the target.

```sql
WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name)
    VALUES (
        source.customer_id,
        source.customer_name
    );
```

Target: `101 | Ravi`. Source: `102 | Priya`. Since 102 doesn't exist in the target, it's inserted.

Result:

| customer_id | customer_name |
| ----------- | -------------- |
| 101         | Ravi           |
| 102         | Priya          |

---

## 9. UPSERT

UPSERT means **UPDATE + INSERT**. MERGE is commonly used to implement an UPSERT.

```sql
MERGE INTO customers AS target
USING customer_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status
    );
```

```text
If customer exists     → UPDATE
If customer doesn't exist → INSERT
```

---

## 10. Complete UPDATE + INSERT Example

Target:

| customer_id | customer_name | status |
| ----------- | -------------- | ------ |
| 101         | Ravi           | ACTIVE |
| 102         | Priya          | ACTIVE |
| 103         | Amit           | ACTIVE |

Source:

| customer_id | customer_name | status |
| ----------- | -------------- | ------ |
| 102         | Priya Sharma   | ACTIVE |
| 104         | Neha           | ACTIVE |

```sql
MERGE INTO customers AS target
USING customer_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status
    );
```

Result:

| customer_id | customer_name | status |
| ----------- | -------------- | ------ |
| 101         | Ravi           | ACTIVE |
| 102         | Priya Sharma   | ACTIVE |
| 103         | Amit           | ACTIVE |
| 104         | Neha           | ACTIVE |

---

## 11. Conditional MERGE

We don't always want to update every matched record — we can add a condition.

```sql
WHEN MATCHED
    AND source.status = 'ACTIVE'
THEN
    UPDATE SET
        target.customer_name = source.customer_name;
```

Only source records with `status = 'ACTIVE'` will update the target.

---

## 12. Conditional Timestamp Update

A common real-world scenario: preventing older data from overwriting newer data.

Target: `101 | updated_at = 2026-09-10`. Source: `101 | updated_at = 2026-09-09`. The source record is older — we should not overwrite the newer target record.

```sql
WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.updated_at = source.updated_at;
```

```text
Source newer?
     │
 ┌───┴───┐
Yes      No
 ↓        ↓
UPDATE   Ignore
```

---

## 13. DELETE Using MERGE

MERGE can also delete records.

```sql
WHEN MATCHED
    AND source.status = 'DELETED'
THEN
    DELETE
```

Complete example:

```sql
MERGE INTO customers AS target
USING customer_updates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.status = 'DELETED'
THEN
    DELETE

WHEN MATCHED THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.status = source.status

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        status
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.status
    );
```

---

## 14. Order of WHEN MATCHED Conditions

```sql
WHEN MATCHED
    AND source.status = 'DELETED'
THEN DELETE

WHEN MATCHED THEN
    UPDATE ...
```

**The more specific condition should come first.** Why? Because a general `WHEN MATCHED` can match all matched records — so specific conditions must be evaluated before the general fallback catches everything.

```text
Specific condition
       ↓
General condition
```

---

## 15. Deduplication Before MERGE

One of the most important MERGE concepts.

Suppose the source contains:

| customer_id | customer_name | updated_at |
| ----------- | -------------- | ---------- |
| 101         | Ravi           | 2026-09-08 |
| 101         | Ravi Kumar     | 2026-09-09 |

Two source records exist for the same `customer_id = 101`. If our MERGE key is `customer_id`, we now have multiple source records for the same key — ambiguous for MERGE. We first need to decide which record should win.

A common business rule: **latest record wins**.

---

## 16. ROW_NUMBER() + QUALIFY Before MERGE

We can deduplicate the source using `ROW_NUMBER()` and `QUALIFY`.

```sql
USING (
    SELECT
        customer_id,
        customer_name,
        updated_at
    FROM customer_updates
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1
) AS source
```

Result:

| customer_id | customer_name | updated_at |
| ----------- | -------------- | ---------- |
| 101         | Ravi Kumar     | 2026-09-09 |

Now there is only one source record per customer.

---

## 17. Complete Deduplication + MERGE

```sql
MERGE INTO customers AS target

USING (
    SELECT
        customer_id,
        customer_name,
        updated_at
    FROM customer_updates

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) = 1
) AS source

ON target.customer_id = source.customer_id

WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN
    UPDATE SET
        target.customer_name = source.customer_name,
        target.updated_at = source.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        customer_name,
        updated_at
    )
    VALUES (
        source.customer_id,
        source.customer_name,
        source.updated_at
    );
```

Pipeline:

```text
Source
  ↓
ROW_NUMBER()
  ↓
QUALIFY
  ↓
One row per MERGE key
  ↓
MERGE
  ↓
Target
```

---

## 18. Deterministic Deduplication

Suppose two records have the exact same timestamp:

| customer_id | updated_at       | event_id |
| ----------- | ---------------- | -------- |
| 101         | 2026-09-09 10:00 | 500      |
| 101         | 2026-09-09 10:00 | 501      |

Ordering only by `ORDER BY updated_at DESC` doesn't give a reliable tie-breaker. Add a second sort key:

```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC, event_id DESC
) = 1
```

This gives a deterministic result every time the query runs.

---

## 19. Incremental Loading

MERGE is commonly used in incremental data pipelines.

**Full Load** — processes all records every time:

```text
Source
  ↓
All records
  ↓
Target
```

---

## 20. Incremental Load

An incremental load processes only **new records + changed records**.

```text
Operational Database
        ↓
New / Changed Data
        ↓
Staging
        ↓
Deduplication
        ↓
MERGE
        ↓
Target
```

This is usually more efficient than repeatedly processing the entire dataset.

---

## 21. MERGE Is Not the Same as Incremental Loading

Important distinction: **incremental loading** is a data-loading *strategy*. **MERGE** is a SQL *mechanism* used to apply changes.

MERGE does not automatically know which records changed — the pipeline first needs to identify new records, changed records, and deleted records. Then MERGE applies those changes.

---

## 22. Identifying Incremental Records

One simple approach: use an `updated_at` column.

```sql
WHERE updated_at > last_successful_load_time
```

Another approach is CDC (Change Data Capture). A simplified Snowflake architecture:

```text
Source Table
     ↓
Stream
     ↓
Changed Records
     ↓
Task
     ↓
MERGE
     ↓
Target Table
```

---

## 23. Grain and MERGE

Grain means: **what does one row represent?**

```text
One row = one customer
```
or
```text
One row = one transaction
```

If our target grain is "one row per customer," and we MERGE using `customer_id`, then the source should normally contain one row per `customer_id` **before** the MERGE. If it contains multiple rows per customer, deduplicate or aggregate first (see §15–18).

---

## 24. Common MERGE Mistakes

**Mistake 1 — Wrong ON condition**

Bad:
```sql
ON target.customer_name = source.customer_name
```
If customer names are not unique, this can cause incorrect matching. Prefer a reliable business key:
```sql
ON target.customer_id = source.customer_id
```

**Mistake 2 — Not Deduplicating Source**

Source: `101, 101, 102, 103`. If the MERGE expects one row per customer, deduplicate first.

**Mistake 3 — Using the Wrong Business Key**

Always ask: "What uniquely identifies this business record?" before designing the MERGE.

**Mistake 4 — Allowing Older Data to Overwrite Newer Data**

Use conditions such as `AND source.updated_at > target.updated_at` when the business requirement is "latest update wins."

**Mistake 5 — Blindly Using DISTINCT**

`DISTINCT` removes identical rows — it does not necessarily select the *correct* record. For example:

```text
101 | Ravi       | 2026-09-08
101 | Ravi Kumar | 2026-09-09
```

These rows are different — `DISTINCT` will keep both. If the requirement is "latest record wins," use `ROW_NUMBER() + QUALIFY` with an appropriate ordering rule instead.

---

## 25. Real-World MERGE Use Cases

**Customer Data:** new customer → INSERT; existing customer → UPDATE; deleted customer → DELETE.

**Product Data:** new product → INSERT; price change → UPDATE; discontinued product → UPDATE/DELETE.

**Banking Data:** new account → INSERT; account update → UPDATE; closed account → UPDATE/DELETE.

**CDC Pipelines:** INSERT event → INSERT; UPDATE event → UPDATE; DELETE event → DELETE.

---

## 26. MERGE Mental Model

```text
MERGE
  │
  ├── ON → How do I identify a match?
  │
  ├── MATCHED
  │     ├── UPDATE
  │     └── DELETE
  │
  └── NOT MATCHED
        └── INSERT
```

For a production-style pipeline:

```text
Source
  ↓
Filter changed records
  ↓
Deduplicate
  ↓
Validate business key
  ↓
MERGE
  ↓
Target
```

---

## 27. Interview Questions

**Q1. What is MERGE?**
MERGE is a SQL statement used to synchronize a target table with a source dataset. It can perform UPDATE, INSERT, and DELETE operations depending on whether records match.

**Q2. What is UPSERT?**
UPSERT means UPDATE + INSERT — existing records are updated and new records are inserted.

**Q3. What is the purpose of the ON condition?**
The `ON` condition determines how source records are matched with target records, e.g. `ON target.customer_id = source.customer_id`.

**Q4. What is the difference between WHEN MATCHED and WHEN NOT MATCHED?**
```text
WHEN MATCHED     → source record exists in target → usually UPDATE or DELETE
WHEN NOT MATCHED → source record does not exist in target → usually INSERT
```

**Q5. Why should we deduplicate the source before MERGE?**
If multiple source records have the same MERGE key, they can create ambiguity or incorrect results. We should first apply the required business rule (e.g. "latest record wins") using `ROW_NUMBER() + QUALIFY`.

**Q6. How do you keep only the latest source record?**
```sql
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY updated_at DESC
) = 1
```

**Q7. How can MERGE delete records?**
```sql
WHEN MATCHED
    AND source.status = 'DELETED'
THEN DELETE
```

**Q8. How do you prevent older data from overwriting newer data?**
Use a timestamp condition:
```sql
WHEN MATCHED
    AND source.updated_at > target.updated_at
THEN UPDATE ...
```

**Q9. Is MERGE the same as incremental loading?**
No. MERGE is a mechanism for applying changes. Incremental loading is a strategy for processing only new or changed data.

**Q10. What should you check before writing a MERGE?**
Target table grain, source table grain, business/MERGE key, source duplicates, update rules, insert rules, delete rules, timestamp/version logic, incremental filtering requirements.

---

## 28. Final MERGE Checklist

```text
✓ What is my target table?
✓ What is my source?
✓ What is the business key?
✓ What defines a match?
✓ What should happen when matched?
✓ What should happen when not matched?
✓ Are deletes required?
✓ Does the source contain duplicates?
✓ Which source record should win?
✓ Do I need timestamp/version checking?
✓ Is this part of an incremental pipeline?
✓ What is the expected grain of the final target?
```

---

## 29. Key Takeaways

```text
MERGE         → Compare source with target
MATCHED       → UPDATE / DELETE
NOT MATCHED   → INSERT
UPSERT        → UPDATE + INSERT
Deduplication → ROW_NUMBER() + QUALIFY + Business rule

Incremental Loading:
New/Changed records → MERGE → Target
```

**Most Important Concept:** the most important part of MERGE is not memorizing the syntax. Understand:

```text
Business Key
     ↓
Matching Logic
     ↓
Source Grain
     ↓
Business Rule
     ↓
UPDATE / INSERT / DELETE
```
