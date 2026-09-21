# String Functions — Theory Notes

## Table of Contents

1. [UPPER() / LOWER() / INITCAP()](#1-upper--lower--initcap)
2. [LENGTH()](#2-length)
3. [TRIM() / LTRIM() / RTRIM()](#3-trim--ltrim--rtrim)
4. [SUBSTRING()](#4-substring)
5. [LEFT() / RIGHT()](#5-left--right)
6. [CONCAT()](#6-concat)
7. [CONCAT_WS()](#7-concat_ws)
8. [NULL Handling in Concatenation](#8-null-handling-in-concatenation)
9. [REPLACE()](#9-replace)
10. [SPLIT_PART()](#10-split_part)
11. [POSITION() / CHARINDEX()](#11-position--charindex)
12. [LPAD() / RPAD()](#12-lpad--rpad)
13. [REGEXP_REPLACE()](#13-regexp_replace)
14. [REGEXP_LIKE() and Pattern Matching with LIKE/ILIKE](#14-regexp_like-and-pattern-matching-with-likeilike)
15. [REGEXP_SUBSTR()](#15-regexp_substr)
16. [STARTSWITH() / ENDSWITH() / CONTAINS()](#16-startswith--endswith--contains)
17. [Choosing REPLACE vs REGEXP_REPLACE](#17-choosing-replace-vs-regexp_replace)
18. [Real-World Use Cases](#18-real-world-use-cases)
19. [Common Mistakes](#19-common-mistakes)
20. [Interview Questions](#20-interview-questions)
21. [Function Comparison Table](#21-function-comparison-table)

---

## 1. UPPER() / LOWER() / INITCAP()

Change the case of text.

```sql
SELECT UPPER('sushma');   -- SUSHMA
SELECT LOWER('SUSHMA');   -- sushma
SELECT INITCAP('sushma maddin');  -- Sushma Maddin
```

`INITCAP()` capitalizes the first letter of each word — useful for standardizing names or titles that arrive in inconsistent casing (`SUSHMA MADDIN`, `sushma maddin`, `Sushma maddin` → all become `Sushma Maddin`).

Case functions are also essential for **case-insensitive comparisons and deduplication**: `'Sushma'` and `'sushma'` are different strings to a plain `=` comparison, but `UPPER(a) = UPPER(b)` treats them as the same.

---

## 2. LENGTH()

Returns the number of characters in a string.

```sql
SELECT LENGTH('Snowflake');  -- 9
```

Common use: validating that an ID or code has the expected number of characters (`WHERE LENGTH(employee_code) = 6`), or flagging suspiciously short/long free-text fields during data quality checks.

---

## 3. TRIM() / LTRIM() / RTRIM()

`TRIM()` removes leading **and** trailing spaces:

```sql
SELECT TRIM('   Sushma Maddin   ');  -- 'Sushma Maddin'
```

`LTRIM()` / `RTRIM()` remove spaces from only the left or right side:

```sql
SELECT LTRIM('   Sushma');   -- 'Sushma'
SELECT RTRIM('Sushma   ');   -- 'Sushma'
```

All three accept an **optional second argument** specifying which characters to trim — not just spaces:

```sql
SELECT TRIM('---Sushma---', '-');  -- 'Sushma'
```

This is useful for cleaning up data with padding characters other than whitespace (e.g. leading zeros represented as `-`, or stray quote characters from a CSV export).

---

## 4. SUBSTRING()

Extracts a portion of a string.

```sql
SUBSTRING(string, start, length)
```

```sql
SELECT SUBSTRING('Snowflake', 1, 4);  -- 'Snow'
```

> **Important: Snowflake string positions are 1-indexed, not 0-indexed.** `SUBSTRING('Snowflake', 1, 4)` starts at the *first* character. Passing `0` as the start position is treated the same as `1` in Snowflake (unlike some other languages where index 0 means "before the string" or errors) — but don't rely on that; always think in 1-based terms to avoid off-by-one mistakes when porting logic from Python or Java.

`SUBSTR()` is a common alias for the same function.

---

## 5. LEFT() / RIGHT()

Get characters from the beginning or end of a string.

```sql
SELECT LEFT('ABCDEF', 3);   -- 'ABC'
SELECT RIGHT('ABCDEF', 3);  -- 'DEF'
```

These are shorthand for the most common `SUBSTRING()` cases — "give me the first N characters" or "give me the last N characters" — without having to calculate a start position.

---

## 6. CONCAT()

Combines strings together.

```sql
SELECT CONCAT('Sushma', ' ', 'Maddin');  -- 'Sushma Maddin'
```

---

## 7. CONCAT_WS()

Combines values **using a separator** — `WS` means "With Separator."

```sql
SELECT CONCAT_WS('-', 'EMP', 'BLR', '1025');
```

Result:

```text
EMP-BLR-1025
```

The separator is only placed *between* values, not before the first or after the last — so you don't need to manually manage trailing/leading separators the way you would with repeated `CONCAT()` calls.

---

## 8. NULL Handling in Concatenation

This is a subtle but important difference between `CONCAT()` and `CONCAT_WS()`.

**`CONCAT()`** — if *any* argument is `NULL`, the entire result is `NULL` in most SQL engines (Snowflake's `CONCAT()` follows this too):

```sql
SELECT CONCAT('Sushma', NULL, 'Maddin');  -- NULL
```

**`CONCAT_WS()`** — silently **skips** `NULL` arguments instead of nulling the whole result:

```sql
SELECT CONCAT_WS('-', 'EMP', NULL, '1025');  -- 'EMP-1025'
```

> **This is a common real-world gotcha:** building a "full name" field with `CONCAT(first_name, ' ', middle_name, ' ', last_name)` silently produces `NULL` for every row where `middle_name` is missing — even though first and last name are present. `CONCAT_WS()` (or `COALESCE()` on the nullable pieces) avoids this trap.

---

## 9. REPLACE()

Replaces **exact** matching text — no patterns, just literal substring matching.

```sql
SELECT REPLACE('987-654-3210', '-', '');
```

Result:

```text
9876543210
```

Use `REPLACE()` when the exact value to replace is known and fixed (a literal character, a specific word). For anything pattern-based, you need `REGEXP_REPLACE()` (§13).

---

## 10. SPLIT_PART()

Splits a string using a delimiter and returns a selected part (1-indexed).

```sql
SPLIT_PART(string, delimiter, part_number)
```

```sql
SELECT SPLIT_PART('IND-BLR-2026-001', '-', 3);  -- '2026'
```

Mental model:

```text
IND | BLR | 2026 | 001
 1     2      3      4
```

> **Gotcha:** if `part_number` exceeds the number of actual parts, `SPLIT_PART()` returns an **empty string**, not an error and not `NULL`. Don't assume a non-null/non-empty result means the split succeeded as expected — validate the part count separately if it matters (e.g. `ARRAY_SIZE(SPLIT(string, delimiter))`).

---

## 11. POSITION() / CHARINDEX()

Finds where text first occurs (1-indexed; returns `0` if not found).

```sql
SELECT POSITION('@' IN 'rahul@yahoo.com');  -- 6
```

`CHARINDEX()` is an equivalent function with argument order reversed:

```sql
SELECT CHARINDEX('@', 'rahul@yahoo.com');  -- 6
```

Mental model: **`POSITION` → "Where is it?"**

Common use: extracting an email domain —

```sql
SELECT SUBSTRING(email, POSITION('@' IN email) + 1)
FROM users;
```

---

## 12. LPAD() / RPAD()

`LPAD()` adds characters to the **left** until the target length is reached:

```sql
SELECT LPAD('42', 6, '0');  -- '000042'
```

`RPAD()` adds characters to the **right**:

```sql
SELECT RPAD('ABC', 6, 'X');  -- 'ABCXXX'
```

Common use: zero-padding numeric IDs to a fixed width (`EMP00042` instead of `EMP42`), or right-padding for fixed-width file exports.

> **Note:** if the input string is already *longer* than the target length, both functions **truncate** it rather than leaving it unchanged — `LPAD('123456', 4, '0')` returns `'1234'`, not `'123456'`. Always check that your target length is a safe upper bound for the data.

---

## 13. REGEXP_REPLACE()

Replaces text matching a **regular-expression pattern** — not just an exact string.

Example: keep only digits (strip everything else out of a phone number):

```sql
SELECT REGEXP_REPLACE('987-654-3210', '[^0-9]', '');
```

Result:

```text
9876543210
```

Useful patterns:

```text
[0-9]          → digits
[A-Za-z]       → letters
[A-Za-z0-9]    → letters and numbers
[^A-Za-z0-9]   → anything except letters/numbers
\s             → whitespace
```

Use regex when the cleaning rule is **pattern-based** (any digit, any non-alphanumeric character); use plain `REPLACE()` when an exact literal replacement is enough — regex is more powerful but also more expensive to evaluate at scale.

---

## 14. REGEXP_LIKE() and Pattern Matching with LIKE/ILIKE

For **matching** (not replacing) text against a pattern:

**`LIKE`** — simple wildcard matching, case-sensitive:

```sql
WHERE email LIKE '%@gmail.com'
```

`%` matches any sequence of characters, `_` matches exactly one character.

**`ILIKE`** — same as `LIKE` but case-**in**sensitive:

```sql
WHERE customer_name ILIKE '%sushma%'
```

**`REGEXP_LIKE()`** — full regular-expression matching, for patterns `LIKE` can't express:

```sql
SELECT * FROM users
WHERE REGEXP_LIKE(phone, '^[0-9]{10}$');  -- exactly 10 digits
```

```text
LIKE / ILIKE   → simple wildcards (%, _), fast, limited
REGEXP_LIKE    → full regex, more powerful, slightly more expensive
```

---

## 15. REGEXP_SUBSTR()

**Extracts** the portion of a string that matches a pattern (as opposed to `REGEXP_REPLACE`, which replaces it, or `REGEXP_LIKE`, which just tests true/false).

```sql
SELECT REGEXP_SUBSTR('Order #A1023 placed', '#[A-Z0-9]+');  -- '#A1023'
```

Useful when you need to pull a structured token (an order ID, a reference code) out of an unstructured text field.

---

## 16. STARTSWITH() / ENDSWITH() / CONTAINS()

Readable, intention-revealing alternatives to `LIKE '%...%'` patterns:

```sql
SELECT STARTSWITH(email, 'admin');       -- TRUE/FALSE
SELECT ENDSWITH(email, '@company.com');  -- TRUE/FALSE
SELECT CONTAINS(description, 'urgent');  -- TRUE/FALSE
```

These are equivalent to `LIKE 'admin%'`, `LIKE '%@company.com'`, and `LIKE '%urgent%'` respectively, but easier to read in a `WHERE` clause and harder to typo (no stray `%` placement mistakes).

---

## 17. Choosing REPLACE vs REGEXP_REPLACE

| Situation | Use |
|---|---|
| Replace one exact, known substring | `REPLACE()` |
| Replace anything matching a category (digits, letters, whitespace) | `REGEXP_REPLACE()` |
| Just check if a pattern exists (true/false) | `REGEXP_LIKE()` or `LIKE`/`ILIKE` |
| Extract the matching portion itself | `REGEXP_SUBSTR()` |
| Simple prefix/suffix/substring existence check | `STARTSWITH()` / `ENDSWITH()` / `CONTAINS()` |

---

## 18. Real-World Use Cases

- **Standardizing names/categories** — `UPPER()`/`INITCAP()` + `TRIM()` before storing or joining on them
- **Cleaning phone numbers** — `REGEXP_REPLACE(phone, '[^0-9]', '')` to strip formatting before validation
- **Parsing emails** — `SPLIT_PART(email, '@', 2)` for domain, `POSITION('@' IN email)` for manual extraction
- **Parsing structured IDs** — `SPLIT_PART('IND-BLR-2026-001', '-', n)` for composite key fields
- **Creating formatted identifiers** — `CONCAT_WS('-', region, city, sequence)` for generated codes
- **Zero-padding sequence numbers** — `LPAD(CAST(id AS STRING), 5, '0')` for display-friendly IDs
- **Removing unwanted characters from raw/scraped data** — `REGEXP_REPLACE()` with a category pattern
- **Case-insensitive matching/deduplication** — `UPPER(a) = UPPER(b)` or `ILIKE`

---

## 19. Common Mistakes

**Mistake 1 — Assuming 0-indexing**

`SUBSTRING()`, `POSITION()`, and `SPLIT_PART()` are all **1-indexed** in Snowflake. Porting logic from a 0-indexed language (Python, Java arrays) without adjusting the index is a common source of off-by-one bugs.

**Mistake 2 — CONCAT() silently returning NULL**

Building a combined field with `CONCAT()` where any single piece can be `NULL` nulls the *entire* result. Use `CONCAT_WS()` or wrap nullable pieces in `COALESCE(x, '')` first.

**Mistake 3 — Using REPLACE() when the rule is actually pattern-based**

`REPLACE(phone, '-', '')` only removes hyphens — it won't catch spaces, parentheses, or dots also present in messier real-world phone data. If the cleaning rule is "remove anything that isn't a digit," use `REGEXP_REPLACE(phone, '[^0-9]', '')` instead of chaining multiple `REPLACE()` calls.

**Mistake 4 — Forgetting case sensitivity in comparisons**

`WHERE customer_name = 'sushma'` won't match `'Sushma'`. Either normalize both sides with `UPPER()`/`LOWER()`, or use `ILIKE` for pattern-based matching.

**Mistake 5 — Assuming SPLIT_PART() errors on a missing part**

Requesting a part number beyond what exists returns an **empty string**, not an error or `NULL` — code that checks `IS NULL` to detect a missing part will silently miss this case; check for `= ''` too, or validate the split count upfront.

---

## 20. Interview Questions

**Q1. What is the difference between CONCAT() and CONCAT_WS()?**
`CONCAT()` joins strings directly and returns `NULL` if any argument is `NULL`. `CONCAT_WS()` joins with a separator and skips `NULL` arguments instead of nulling the whole result.

**Q2. Are Snowflake string functions 0-indexed or 1-indexed?**
1-indexed. `SUBSTRING()`, `POSITION()`, and `SPLIT_PART()` all start counting from 1, not 0.

**Q3. When would you use REGEXP_REPLACE() instead of REPLACE()?**
When the text to remove/replace is a *category* or *pattern* (all digits, all non-alphanumeric characters) rather than one specific known literal string.

**Q4. How would you extract the domain from an email address?**
```sql
SELECT SPLIT_PART(email, '@', 2) FROM users;
```

**Q5. What's the difference between LIKE and REGEXP_LIKE?**
`LIKE` supports only simple wildcards (`%`, `_`) and is faster for simple cases. `REGEXP_LIKE` supports full regular expressions for more complex pattern matching.

**Q6. What happens if you request a SPLIT_PART() index beyond the number of parts?**
It returns an empty string, not `NULL` and not an error.

**Q7. How would you zero-pad an employee ID to 5 digits?**
```sql
SELECT LPAD(CAST(employee_id AS STRING), 5, '0') FROM employees;
```

**Q8. Why might a "full name" column built with CONCAT() have unexpected NULLs?**
Because if any one input (e.g. a missing middle name) is `NULL`, `CONCAT()` returns `NULL` for the whole result — `CONCAT_WS()` or `COALESCE()` avoids this.

---

## 21. Function Comparison Table

```text
UPPER / LOWER / INITCAP → change case
TRIM / LTRIM / RTRIM    → remove surrounding characters (default: spaces)
SUBSTRING / LEFT / RIGHT → extract a portion of text
CONCAT                  → combine text (NULL-poisoning)
CONCAT_WS               → combine text with a separator (NULL-safe)
REPLACE                 → exact literal replacement
REGEXP_REPLACE           → pattern-based replacement
REGEXP_LIKE / LIKE / ILIKE → pattern matching (true/false)
REGEXP_SUBSTR            → extract the matching portion
SPLIT_PART                → get one delimiter-separated part
POSITION / CHARINDEX      → find a position
LPAD / RPAD                → add padding to reach a target length
STARTSWITH / ENDSWITH / CONTAINS → readable prefix/suffix/substring checks
```
