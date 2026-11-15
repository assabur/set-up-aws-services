-- Create Database and Table for Salary Data Parquet Files
-- This script creates a database and table to query the Parquet files created by the Lambda function

-- Step 1: Create a database for the salary data
CREATE DATABASE IF NOT EXISTS human_resources
COMMENT 'Database for employee salary analytics and reporting';

-- Step 2: Use the database
USE human_resources;

-- Step 2.5: Drop existing table if it exists (to avoid schema conflicts)
DROP TABLE IF EXISTS employee_salary_data_parquet;

-- Step 3: Create external table pointing to Parquet files in S3
CREATE EXTERNAL TABLE IF NOT EXISTS employee_salary_data_parquet (
  empid bigint COMMENT 'Employee ID',
  name string COMMENT 'Employee Name',
  gender string COMMENT 'Employee Gender',
  dateofbirth string COMMENT 'Date of Birth',
  age bigint COMMENT 'Employee Age',
  joindate string COMMENT 'Join Date',
  tenureinorginmonths bigint COMMENT 'Tenure in Organization (months)',
  grosspay bigint COMMENT 'Gross Pay Amount',
  netpay bigint COMMENT 'Net Pay Amount',
  deduction bigint COMMENT 'Deduction Amount',
  deductionpercentage double COMMENT 'Deduction Percentage',
  jobtitle string COMMENT 'Job Title',
  department string COMMENT 'Department'
)
COMMENT 'Employee salary data from CSV converted to Parquet format'
STORED AS PARQUET
LOCATION 's3://data-mentoring-dev-athena-bucket/refined/'
TBLPROPERTIES (
  'has_encrypted_data'='false',
  'parquet.compression'='SNAPPY'
);

-- Step 4: Verify table creation
SHOW TABLES;

-- Step 5: Check table schema
DESCRIBE employee_salary_data_parquet;

-- Step 6: Test queries
-- View sample records
SELECT * FROM employee_salary_data_parquet LIMIT 10;

-- Count total employees
SELECT COUNT(*) as total_employees FROM employee_salary_data_parquet;

-- Get unique departments
SELECT DISTINCT department FROM employee_salary_data_parquet ORDER BY department;

-- Average salary by department
SELECT 
  department, 
  COUNT(*) as employee_count,
  ROUND(AVG(grosspay), 2) as avg_gross_pay,
  ROUND(AVG(netpay), 2) as avg_net_pay,
  ROUND(AVG(deductionpercentage), 2) as avg_deduction_percentage
FROM employee_salary_data_parquet 
GROUP BY department 
ORDER BY avg_gross_pay DESC;

-- Top 10 highest paid employees
SELECT 
  name, 
  jobtitle, 
  department, 
  ROUND(grosspay, 2) as gross_pay,
  ROUND(netpay, 2) as net_pay
FROM employee_salary_data_parquet 
ORDER BY grosspay DESC 
LIMIT 10;

-- Salary distribution by gender
SELECT 
  gender,
  COUNT(*) as count,
  ROUND(AVG(grosspay), 2) as avg_gross_pay,
  ROUND(MIN(grosspay), 2) as min_gross_pay,
  ROUND(MAX(grosspay), 2) as max_gross_pay
FROM employee_salary_data_parquet 
GROUP BY gender;

-- Department with highest average salary
SELECT 
  department,
  ROUND(AVG(grosspay), 2) as avg_gross_pay
FROM employee_salary_data_parquet 
GROUP BY department 
ORDER BY avg_gross_pay DESC 
LIMIT 1;

-- Employees with highest deductions
SELECT 
  name,
  department,
  ROUND(grosspay, 2) as gross_pay,
  ROUND(deduction, 2) as deduction,
  ROUND(deductionpercentage, 2) as deduction_percentage
FROM employee_salary_data_parquet 
ORDER BY deductionpercentage DESC 
LIMIT 10;
