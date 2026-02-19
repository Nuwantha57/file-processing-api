-- Database Setup for Employee Upload API
-- Run this SQL in your PostgreSQL database

-- Create database (if not exists)
-- CREATE DATABASE employee_management;

-- Connect to employee_management database and run below:

-- Drop tables if exists
DROP TABLE IF EXISTS processing_status CASCADE;
DROP TABLE IF EXISTS dead_letter_queue CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

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

-- Create dead_letter_queue table for invalid records
CREATE TABLE dead_letter_queue (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    age INTEGER,
    error_message TEXT NOT NULL,
    file_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id, email, file_name)
);

-- Create index on file_name for faster lookups
CREATE INDEX idx_dlq_file_name ON dead_letter_queue(file_name);
CREATE INDEX idx_dlq_email ON dead_letter_queue(email);

-- Create processing_status table to track file upload batches
CREATE TABLE processing_status (
    id SERIAL PRIMARY KEY,
    correlation_id VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    total_files INTEGER DEFAULT 0,
    processed_files INTEGER DEFAULT 0,
    total_records INTEGER DEFAULT 0,
    valid_records INTEGER DEFAULT 0,
    total_valid INTEGER DEFAULT 0,
    total_invalid INTEGER DEFAULT 0,
    total_inserted INTEGER DEFAULT 0,
    invalid_records INTEGER DEFAULT 0,
    inserted_records INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Create index on correlation_id for faster lookups
CREATE INDEX idx_processing_status_corr_id ON processing_status(correlation_id);
CREATE INDEX idx_processing_status_status ON processing_status(status);

-- Sample data insert (based on your CSV format)
INSERT INTO employees (id, name, email, age) VALUES
(60, 'Alex Turner', 'alex.turner@example.com', 28),
(61, 'Emma Wilson', 'emma.wilson@example.com', 32),
(62, 'Liam Brown', 'liam.brown@example.com', 26);

-- Reset sequence to continue from max ID
SELECT setval('employees_id_seq', (SELECT MAX(id) FROM employees));

-- Verify data
SELECT * FROM employees;
SELECT * FROM dead_letter_queue;
SELECT * FROM processing_status;
