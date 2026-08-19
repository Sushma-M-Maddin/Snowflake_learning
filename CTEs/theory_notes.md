# Common Table Expressions (CTEs) - Theory Notes

# 1. What is a CTE?

CTE stands for **Common Table Expression**.

A CTE is a **temporary named query result** that is defined using the `WITH` clause and can be used within the SQL statement.

Basic syntax:

```sql
WITH cte_name AS (
    SELECT ...
    FROM ...
    WHERE ...
)

SELECT *
FROM cte_name;
```

Example:

```sql
WITH high_salary_employees AS (
    SELECT *
    FROM employees
    WHERE salary > 50000
)

SELECT *
FROM high_salary_employees;
```

In this example:

- `WITH` starts the CTE
- `high_salary_employees` is the CTE name
- The query inside the brackets creates an intermediate result
- The final query uses the CTE result

---

# 2. Why Do We Need CTEs?

Without CTEs, complex SQL queries can become difficult to read.

For example, a business requirement may require us to:

1. Filter data
2. Calculate totals
3. Calculate counts
4. Filter aggregated results
5. Join another table
6. Return the final result

A CTE allows us to divide the problem into logical steps.

```text
Raw Data
   ↓
Step 1 → Filter
   ↓
Step 2 → Aggregate
   ↓
Step 3 → Transform
   ↓
Step 4 → Join
   ↓
Final Result
```

Instead of writing everything in one large query, we can give meaningful names to each intermediate step.

Example:

```text
transactions
      ↓
successful_transactions
      ↓
transaction_summary
      ↓
final result
```

This improves:

- Readability
- Maintainability
- Debugging
- Understanding of complex queries

---

# 3. How to Think About a CTE

A simple way to remember:

> `WITH` means: First prepare something.

Example:

```sql
WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT *
FROM approved_loans;
```

The SQL is saying:

```text
First prepare approved loans
        ↓
Then use those approved loans
```

Another memory trick:

> **CTE = Temporary named step inside a SQL statement**

---

# 4. Basic CTE Syntax

```sql
WITH cte_name AS (
    SELECT columns
    FROM table_name
    WHERE condition
)

SELECT columns
FROM cte_name;
```

Example:

```sql
WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT *
FROM approved_loans;
```

---

# 5. Important Characteristics of a CTE

## 5.1 A CTE is Temporary

A CTE does not create a permanent table.

It is available only for the SQL statement where it is defined.

Example:

```sql
WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
)

SELECT *
FROM approved_loans;
```

After this statement finishes, the following will not work as a new statement:

```sql
SELECT *
FROM approved_loans;
```

because the CTE no longer exists.

### Memory Rule

```text
Permanent Table
→ Exists until dropped

CTE
→ Exists only within the SQL statement
```

---

## 5.2 A CTE is Named

A CTE should have a meaningful name.

Good examples:

```text
approved_loans
successful_transactions
customer_totals
transaction_summary
```

Bad examples:

```text
data1
temp
x
abc
```

A good CTE name should explain what the result contains.

---

## 5.3 A CTE Must Be Used

Creating a CTE does not automatically affect the final query.

Incorrect:

```sql
WITH high_salary_employees AS (
    SELECT *
    FROM employees
    WHERE salary > 50000
)

SELECT *
FROM employees;
```

This returns all employees because the final query uses:

```sql
FROM employees
```

Correct:

```sql
SELECT *
FROM high_salary_employees;
```

### Important Lesson

> A CTE must be used by the final query or another CTE.

---

# 6. Multiple CTEs

We can create multiple CTEs in one SQL statement.

```sql
WITH first_cte AS (
    ...
),

second_cte AS (
    ...
),

third_cte AS (
    ...
)

SELECT *
FROM third_cte;
```

### Important Rule

Use only one `WITH` keyword.

Incorrect:

```sql
WITH cte1 AS (
    ...
),

WITH cte2 AS (
    ...
)
```

Correct:

```sql
WITH cte1 AS (
    ...
),

cte2 AS (
    ...
)
```

Multiple CTEs are separated using commas.

---

# 7. CTE Pipeline

A CTE can use the result of a previously defined CTE.

Example:

```sql
WITH approved_loans AS (
    SELECT *
    FROM loans
    WHERE status = 'APPROVED'
),

customer_totals AS (
    SELECT
        customer_id,
        SUM(loan_amount) AS total_loan_amount
    FROM approved_loans
    GROUP BY customer_id
)

SELECT *
FROM customer_totals;
```

The flow is:

```text
LOANS
  ↓
Filter APPROVED loans
  ↓
approved_loans
  ↓
Calculate total loan amount per customer
  ↓
customer_totals
  ↓
Final Result
```

### Important Rule

A later CTE can use an earlier CTE.

```text
CTE 1
  ↓
CTE 2
  ↓
CTE 3
  ↓
Final Query
```

---

# 8. CTE with Aggregation

CTEs are often useful when we need to aggregate data.

Common aggregate functions:

```text
SUM()
COUNT()
AVG()
MIN()
MAX()
```

Example requirement:

> Find the total transaction amount for each customer.

```sql
SELECT
    customer_id,
    SUM(amount)
FROM transactions
GROUP BY customer_id;
```

The business requirement says:

> Total amount for each customer

Therefore:

```text
What are we calculating?
→ Total amount

For whom?
→ Each customer
```

So:

```sql
SUM(amount)
GROUP BY customer_id
```

### Important Thinking Rule

> The `GROUP BY` column depends on the level at which the business wants the result.

Examples:

```text
Total per customer
→ GROUP BY customer_id

Total per department
→ GROUP BY department_id

Total per month
→ GROUP BY month

Total per product
→ GROUP BY product_id
```

---

# 9. Filtering Before and After Aggregation

Consider the requirement:

> Find customers whose successful transaction amount is greater than 500000.

The logic is:

```text
Step 1
Filter successful transactions

        ↓

Step 2
Calculate total transaction amount per customer

        ↓

Step 3
Keep customers whose total is greater than 500000
```

Example:

```sql
WITH successful_transactions AS (
    SELECT *
    FROM transactions
    WHERE status = 'SUCCESSFUL'
),

transaction_summary AS (
    SELECT
        customer_id,
        SUM(amount) AS total_successful_amount
    FROM successful_transactions
    GROUP BY customer_id
)

SELECT *
FROM transaction_summary
WHERE total_successful_amount > 500000;
```

### Key Idea

Row-level filtering:

```sql
WHERE status = 'SUCCESSFUL'
```

Aggregate-level filtering:

```sql
WHERE total_successful_amount > 500000
```

The second filter works on the result produced after aggregation.

---

# 10. CTE with JOIN

A CTE can also be joined with another table.

Example:

```sql
WITH transaction_summary AS (
    SELECT
        customer_id,
        SUM(amount) AS total_amount
    FROM transactions
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    ts.total_amount
FROM customers c
JOIN transaction_summary ts
    ON c.customer_id = ts.customer_id;
```

The relationship is:

```text
CUSTOMERS
customer_id
     ↓
     ↓
TRANSACTION_SUMMARY
customer_id
```

### Important Rule

Join tables using the related common column.

Always ask:

> What column connects these two datasets?

---

# 11. CTE vs Subquery

## Subquery

A subquery is often suitable when the logic is simple.

Example:

```sql
SELECT *
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
);
```

This query is short and readable.

---

## CTE

A CTE is useful when there are multiple logical steps.

```sql
WITH step1 AS (
    ...
),

step2 AS (
    ...
)

SELECT *
FROM step2;
```

---

## Which One Should I Use?

There is no rule that says CTE is always better.

Use the approach that makes the query easier to understand and maintain.

### Simple logic

Subquery can be concise.

### Multiple logical steps

CTEs can improve readability.

### Interview Answer

> Neither is universally better. For a simple query, I may use a subquery because it is concise and readable. For complex queries with multiple logical steps, I prefer CTEs because they improve readability and maintainability.

---

# 12. How to Solve a Real-World CTE Problem

Do not immediately start writing SQL.

First understand the business requirement.

Use this process:

```text
Business Requirement
        ↓
1. What data do I need?
        ↓
2. What should I filter?
        ↓
3. What should I calculate?
        ↓
4. What should I GROUP BY?
        ↓
5. What conditions should be applied?
        ↓
6. Do I need another table?
        ↓
7. What columns should I return?
        ↓
Write SQL
```

---

# 13. Example of Real-World Problem Decomposition

## Requirement

Find customers who:

- Have more than one approved loan
- Have a total approved loan amount greater than 1000000
- Return customer details

## Step-by-Step Thinking

```text
Step 1
Get approved loans

        ↓

Step 2
Group the approved loans by customer

        ↓

Step 3
Count the number of approved loans

        ↓

Step 4
Calculate the total approved loan amount

        ↓

Step 5
Keep customers with more than one approved loan

        ↓

Step 6
Keep customers with total approved loan amount greater than 1000000

        ↓

Step 7
Join the CUSTOMERS table to get customer details
```

Then convert the steps into CTEs.

---

# 14. Common CTE Pattern

A common real-world pattern is:

```text
CTE 1
→ Filter data

CTE 2
→ Aggregate data

CTE 3
→ Perform another transformation if needed

Final Query
→ Join tables
→ Apply final conditions
→ Return required columns
```

Example:

```text
TRANSACTIONS
      ↓
Filter SUCCESSFUL
      ↓
successful_transactions
      ↓
SUM + COUNT per customer
      ↓
transaction_summary
      ↓
JOIN CUSTOMERS
      ↓
Final Result
```

---

# 15. Common Mistakes I Made While Learning

## Mistake 1: Grouping by the Wrong Column

Requirement:

> Find the total loan amount for each customer.

Incorrect:

```sql
GROUP BY loan_id;
```

Correct:

```sql
GROUP BY customer_id;
```

### Lesson

Always identify the level of the result.

---

## Mistake 2: Using the Wrong Column After Aggregation

Example:

```sql
SUM(loan_amount) AS total_loan_amount
```

Incorrect:

```sql
WHERE loan_amount > 1000000;
```

Correct:

```sql
WHERE total_loan_amount > 1000000;
```

### Lesson

After aggregation, check which columns the CTE produces.

---

## Mistake 3: Missing a Comma Between Selected Columns

Incorrect:

```sql
SELECT
    customer_id,
    SUM(amount) AS total_amount
    COUNT(transaction_id) AS transaction_count
```

Correct:

```sql
SELECT
    customer_id,
    SUM(amount) AS total_amount,
    COUNT(transaction_id) AS transaction_count
```

---

## Mistake 4: CTE Name Mismatch

Created:

```sql
customer_totals
```

Used:

```sql
custmer_totals
```

### Lesson

CTE names must match exactly.

---

## Mistake 5: Column Alias Mismatch

Created:

```sql
SUM(amount) AS total_transaction_amount
```

Used later:

```sql
total_successful_amount
```

### Lesson

Use the correct alias consistently.

---

## Mistake 6: Incorrect JOIN Key

Incorrect:

```sql
ON c.customer_id = ts.transaction_id
```

Correct:

```sql
ON c.customer_id = ts.customer_id
```

### Lesson

Identify the column relationship before writing the JOIN.

---

## Mistake 7: Using Tables Not Required by the Question

Sometimes the requirement only needs:

```text
TRANSACTIONS
```

but additional tables such as:

```text
CUSTOMERS
```

are unnecessary.

### Lesson

Use only the tables and columns required by the business requirement.

---

# 16. CTE Debugging Checklist

When a query does not work, check:

```text
1. Is the CTE name correct?

2. Is there only one WITH keyword?

3. Are multiple CTEs separated by commas?

4. Is the CTE using the correct previous CTE?

5. Am I grouping by the correct business entity?

6. Are aggregation functions correct?

7. Are aggregation aliases used correctly?

8. Does the final WHERE use a column that exists?

9. Am I joining using the correct related columns?

10. Are string values inside quotes?

11. Does the final query actually use the CTE?
```

---

# 17. Interview Questions and Answers

## Q1. What is a CTE?

A CTE, or Common Table Expression, is a temporary named query result defined using the `WITH` clause. It is scoped to the SQL statement and helps organize complex queries into logical steps.

---

## Q2. Why do we use CTEs?

CTEs improve readability and maintainability by breaking complex queries into smaller logical steps.

---

## Q3. Is a CTE a permanent table?

No. A CTE is a temporary named query result scoped to the SQL statement.

---

## Q4. Can one CTE use another CTE?

Yes. A later CTE can use a previously defined CTE within the same `WITH` clause.

---

## Q5. Can multiple CTEs be defined in one query?

Yes.

```sql
WITH cte1 AS (
    ...
),

cte2 AS (
    ...
)

SELECT *
FROM cte2;
```

---

## Q6. How are multiple CTEs separated?

Multiple CTEs are separated using commas.

---

## Q7. Can a CTE replace a subquery?

Sometimes. Both can be used to create intermediate query results. CTEs are often preferred when multiple logical steps improve readability.

---

## Q8. CTE vs Subquery?

For simple queries, a subquery can be concise and readable. For complex queries with multiple logical steps, CTEs can improve readability and maintainability.

---

## Q9. When would you use a CTE?

I would use a CTE when a query has multiple logical steps such as filtering, aggregation, transformation, or joining, and using named intermediate results makes the query easier to understand.

---

# 18. Key Takeaway

The best mental model for CTEs is:

```text
Business Requirement
        ↓
Break the problem into logical steps
        ↓
CTE 1 → Filter
        ↓
CTE 2 → Aggregate
        ↓
CTE 3 → Transform
        ↓
Join if required
        ↓
Apply final conditions
        ↓
Return required result
```

> **CTE = A temporary named query result used to organize complex SQL into logical and readable steps.**