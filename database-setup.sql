-- Database Setup for Employee Upload API
-- Run this SQL in your PostgreSQL database

-- Create database (if not exists)
-- CREATE DATABASE employee_management;

-- Connect to employee_management database and run below:

-- Drop table if exists
DROP TABLE IF EXISTS employees;

-- Create employees table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    age INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX idx_employees_email ON employees(email);

-- Sample data insert (based on your CSV format)
INSERT INTO employees (id, name, email, age) VALUES
(60, 'Alex Turner', 'alex.turner@example.com', 28),
(61, 'Emma Wilson', 'emma.wilson@example.com', 32),
(62, 'Liam Brown', 'liam.brown@example.com', 26);

-- Reset sequence to continue from max ID
SELECT setval('employees_id_seq', (SELECT MAX(id) FROM employees));

-- Verify data
SELECT * FROM employees;
