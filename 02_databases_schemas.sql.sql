--Step 1 — Create a Database:
CREATE DATABASE my_first_db;

--Step 2 — Create a Schema inside it:
CREATE SCHEMA my_first_db.my_schema;

--Step 3 --Set context:
USE DATABASE my_first_db;
USE SCHEMA my_schema;

--Step 4 — Create a Table:
CREATE TABLE students(
    student_id NUMBER,
    student_name VARCHAR(100),
    age NUMBER,
    city VARCHAR(50),
    enrolled_date DATE
);

--Step 5 — Check if it was created:
SHOW TABLES;

--Step 6 — Insert some data:
INSERT INTO students VALUES (1, 'Sushma', 22, 'Bangalore', '2024-01-15');
INSERT INTO students VALUES (2, 'Rahul', 23, 'Chennai', '2024-02-20');
INSERT INTO students VALUES (3, 'Priya', 21, 'Mumbai', '2024-03-10');

--Step 7 — Query it:
SELECT * FROM students;