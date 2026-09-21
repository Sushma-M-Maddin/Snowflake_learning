# String Functions

This folder contains my learning and practice material for String functions in Snowflake.

## Folder Contents

### `theory_notes.md`

Contains detailed theory notes covering:

- `UPPER()` / `LOWER()` / `INITCAP()`
- `LENGTH()`
- `TRIM()` / `LTRIM()` / `RTRIM()` (including custom trim characters)
- `SUBSTRING()` / `LEFT()` / `RIGHT()`
- `CONCAT()` / `CONCAT_WS()`
- NULL handling differences between `CONCAT()` and `CONCAT_WS()`
- `REPLACE()`
- `SPLIT_PART()`
- `POSITION()` / `CHARINDEX()`
- `LPAD()` / `RPAD()`
- `REGEXP_REPLACE()`
- `REGEXP_LIKE()`, `LIKE`, `ILIKE`
- `REGEXP_SUBSTR()`
- `STARTSWITH()` / `ENDSWITH()` / `CONTAINS()`
- Choosing `REPLACE` vs `REGEXP_REPLACE`
- Real-world use cases
- Common mistakes (1-indexing, NULL-poisoning, case sensitivity)
- Interview questions and answers
- Full function comparison table

### `practice.sql`

Contains SQL queries for practicing:

- Sample raw/messy customer data
- Case standardization (`UPPER`/`LOWER`/`INITCAP` + `TRIM`)
- Length validation
- Trimming, including custom characters
- Extracting substrings
- `CONCAT` vs `CONCAT_WS` NULL-handling demo
- Exact replacement with `REPLACE()`
- `SPLIT_PART()`, including the missing-part edge case
- Email domain extraction (`POSITION` and `SPLIT_PART` approaches)
- Zero-padding IDs with `LPAD()`
- Pattern-based cleaning with `REGEXP_REPLACE()`
- Pattern matching with `REGEXP_LIKE`, `LIKE`, `ILIKE`
- `REGEXP_SUBSTR()` extraction
- `STARTSWITH()` / `ENDSWITH()` / `CONTAINS()`
- A complete end-to-end data-cleaning pipeline query
- Practice and interview questions

## Folder Structure

```text
String_Functions/
├── README.md
├── theory_notes.md
└── practice.sql
```

## Mental Model

```text
UPPER / LOWER / INITCAP  → change case
TRIM / LTRIM / RTRIM      → remove surrounding characters
SUBSTRING / LEFT / RIGHT   → extract text
CONCAT                      → combine text (NULL-poisoning)
CONCAT_WS                    → combine text with separator (NULL-safe)
REPLACE                       → exact literal replacement
REGEXP_REPLACE                 → pattern-based replacement
LIKE / ILIKE / REGEXP_LIKE      → pattern matching (true/false)
SPLIT_PART                       → extract a delimiter-separated part
POSITION / CHARINDEX               → find where text occurs
LPAD / RPAD                         → add padding
```

## Key Gotcha to Remember

Snowflake string positions (`SUBSTRING`, `POSITION`, `SPLIT_PART`) are **1-indexed**, not 0-indexed — the most common source of off-by-one bugs when porting logic from Python or Java.

## Data Engineering Use Cases

- Standardizing names and categories
- Cleaning phone numbers
- Parsing emails and composite IDs
- Creating formatted identifiers
- Removing unwanted characters from raw data
- Case-insensitive matching and deduplication
