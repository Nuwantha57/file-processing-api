@echo off
REM Connect to AWS RDS and setup database
REM Make sure PostgreSQL client (psql) is installed

echo Connecting to AWS RDS PostgreSQL...
echo.

REM Create database (connect to default postgres database first)
psql "host=database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com port=5432 dbname=postgres user=postgres password=nuwantha123@ sslmode=require" -c "CREATE DATABASE employee_management;"

echo.
echo Database created. Now running setup script...
echo.

REM Connect to employee_management and run setup script
psql "host=database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com port=5432 dbname=employee_management user=postgres password=nuwantha123@ sslmode=require" -f database-setup.sql

echo.
echo Setup complete! Verifying...
echo.

REM Verify table was created
psql "host=database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com port=5432 dbname=employee_management user=postgres password=nuwantha123@ sslmode=require" -c "\dt"
psql "host=database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com port=5432 dbname=employee_management user=postgres password=nuwantha123@ sslmode=require" -c "SELECT * FROM employees;"

echo.
echo Done! Your RDS database is ready.
pause
