# File Processing API - Employee Data Upload System

## Overview
MuleSoft application that processes CSV files containing employee data and stores them in AWS RDS PostgreSQL database. The application validates data, handles duplicates, and provides upload status tracking.

## Architecture
- **Runtime**: MuleSoft 4.10.1 with Java 17
- **Database**: AWS RDS PostgreSQL
- **Deployment**: CloudHub (us-east-2 region, 0.1 vCores)
- **Processing**: Asynchronous batch processing with validation and error handling

## CloudHub Deployment
- **Application URL**: https://file-processing-rds-api-vfup2v.5sc6y6-2.usa-e2.cloudhub.io
- **Region**: us-east-2 (US East Ohio)
- **Worker Size**: 0.1 vCores (Micro)

## Database Configuration

### RDS PostgreSQL Connection
- **Host**: database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com
- **Port**: 5432
- **Database**: employee_management
- **User**: postgres

### Database Schema

#### employees Table
```sql
CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### dead_letter_queue Table
```sql
CREATE TABLE dead_letter_queue (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    age INTEGER,
    error_message TEXT,
    file_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

🔒 **Authentication Required**: All endpoints require Client ID & Secret authentication headers.

### 1. Upload CSV Files
**POST** `/upload-files`

**Authentication Headers** (Required):
- `client_id`: `file-processing-api-client-2026`
- `client_secret`: Your secret key (set in CloudHub secure properties)

**Request**:
- **Content-Type**: `multipart/form-data`
- **Body**: Upload one or multiple CSV files

**CSV Format**:
```csv
id,name,email,age
1,John Doe,john.doe@example.com,30
2,Jane Smith,jane.smith@example.com,25
```

**Response (Success - 202 Accepted)**:
```json
{
  "status": "ACCEPTED",
  "message": "Files queued for asynchronous processing",
  "correlationId": "34052b6d-30f7-4d94-8933-0279a084a2c5",
  "filesQueued": 2,
  "timestamp": "2026-02-11T03:29:08Z"
}
```

**Response (Authentication Failed - 401 Unauthorized)**:
```json
{
  "status": "UNAUTHORIZED",
  "errorCode": 401,
  "message": "Authentication failed. Invalid or missing client credentials.",
  "error": "Valid client_id and client_secret headers are required",
  "correlationId": "xyz-789",
  "timestamp": "2026-02-11T10:31:00Z"
}
```

### 2. Check Upload Status
**GET** `/upload-status?correlationId={correlationId}`

**Query Parameters**:
- `correlationId` (required): The correlation ID returned from the upload request

**Example**:
```
GET /upload-status?correlationId=1401263a-1819-4c09-b6fa-2cd8a277d803
```

**Response**:
```json
{
  "status": "Success",
  "totalRecords": 150,
  "totalInvalidRecords": 5,
  "timestamp": "2026-02-11T03:30:15Z"
}
```

**Status Code**: `200 OK`

## Data Processing Flow

### 1. File Upload (Async)
- Receives CSV files via HTTP multipart
- Returns correlation ID immediately (202 Accepted)
- Queues files for background processing

### 2. Validation Rules
- **ID**: Required, must be numeric
- **Name**: Required, 2-100 characters
- **Email**: Required, valid email format, unique in database
- **Age**: Optional, must be 18-120 if provided

### 3. Duplicate Handling
- **File-level duplicates**: Keeps first occurrence, marks rest as invalid
- **Database duplicates**: Checks existing emails, skips duplicates
- **ID conflicts**: Uses `ON CONFLICT (id) DO NOTHING` strategy

### 4. Error Handling
- Invalid records stored in `dead_letter_queue` table
- Errors logged with filename and correlation ID
- Batch insert retries 3 times with 2-second delays

## Testing Guide

### Using Postman

#### Test 1: Upload CSV File
1. Create new POST request to:
   ```
   https://file-processing-rds-api-vfup2v.5sc6y6-2.usa-e2.cloudhub.io/upload-files
   ```

2. Set **Headers**:
   | Key | Value |
   |-----|-------|
   | `client_id` | `file-processing-api-client-2026` |
   | `client_secret` | `your-secret-key-here` |

3. Set **Body** → **form-data**:
   - Key: `file` (change type to File)
   - Value: Select your CSV file

4. Click **Send**

5. Expected Response (202):
   ```json
   {
     "status": "ACCEPTED",
     "message": "Files queued for asynchronous processing",
     "correlationId": "abc-123-xyz",
     "filesQueued": 1,
     "timestamp": "2026-02-11T10:30:00Z"
   }
   ```

#### Test 2: Check Status
1. Copy the `correlationId` from the upload response

2. Create new GET request to:
   ```
   https://file-processing-rds-api-vfup2v.5sc6y6-2.usa-e2.cloudhub.io/upload-status?correlationId=YOUR_CORRELATION_ID
   ```
   
   Example:
   ```
   https://file-processing-rds-api-vfup2v.5sc6y6-2.usa-e2.cloudhub.io/upload-status?correlationId=1401263a-1819-4c09-b6fa-2cd8a277d803
   ```

3. Click **Send**

4. Expected Response (200):
   ```json
   {
     "status": "Success",
     "totalRecords": 100,
     "totalInvalidRecords": 2
   }
   ```

### Sample CSV Files

#### Valid Data (test-valid.csv)
```csv
id,name,email,age
101,Alice Johnson,alice.j@example.com,28
102,Bob Williams,bob.w@example.com,35
103,Carol Davis,carol.d@example.com,42
```

#### Mixed Data (test-mixed.csv)
```csv
id,name,email,age
201,Valid User,valid@example.com,30
202,Invalid Age,test@example.com,200
,Missing ID,noid@example.com,25
204,Bad Email,notanemail,30
```

## Verify Data in Database

### Query Employee Records
```sql
SELECT * FROM employee_management.employees 
ORDER BY created_at DESC 
LIMIT 10;
```

### Check Invalid Records
```sql
SELECT * FROM employee_management.dead_letter_queue 
ORDER BY created_at DESC 
LIMIT 10;
```

### Count Statistics
```sql
-- Total employees
SELECT COUNT(*) FROM employee_management.employees;

-- Failed records
SELECT COUNT(*) FROM employee_management.dead_letter_queue;

-- Records by file
SELECT file_name, COUNT(*) 
FROM employee_management.dead_letter_queue 
GROUP BY file_name;
```

## Configuration Files

### config-prod.yaml (CloudHub)
```yaml
http.port: "8081"
db.host: "database-1.c3qei6o6u3a5.eu-north-1.rds.amazonaws.com"
db.port: "5432"
db.name: "employee_management"
db.user: "postgres"
db.password: "zAeRymF2S5"
```

### pom.xml Key Settings
- **Packaging**: mule-application
- **Runtime**: 4.10.1
- **PostgreSQL Driver**: 42.7.7 (shared library)
- **CloudHub Deployment**: Configured for us-east-2

## Deployment Process

### Via CloudHub Web Interface
1. Build application:
   ```powershell
   mvn clean package -DskipTests
   ```

2. Upload JAR file:
   - Go to Anypoint Platform → Runtime Manager
   - Click "Deploy Application"
   - Upload: `target\file-processing-api-1.0.0-mule-application.jar`
   - Configure: Region (us-east-2), Worker (0.1 vCores)
   - Click "Deploy"

3. Wait 2-3 minutes for deployment

4. Verify: Application status shows "Started"

## Monitoring & Logs

### CloudHub Logs
- View logs in Runtime Manager → Applications → file-processing-rds-api → Logs
- Key log messages:
  - `[INFO] [WORKER] Records Inserted` - Successful inserts
  - `[ERROR] [WORKER] File Processing Error` - Processing failures
  - `[INFO] [WORKER] All Files Processed` - Completion status

### Common Log Patterns
```
[INFO] Records Inserted | FileName: test.csv | Count: 50
[INFO] DLQ Insert Completed | FileName: test.csv | RecordsInserted: 5
[ERROR] File Processing Error | FileName: test.csv | Error: ...
```

## Troubleshooting

### Issue: 404 Not Found
**Solution**: Verify `http.port: "8081"` is set in config-prod.yaml

### Issue: Database Connection Failed
**Solution**: Check RDS security group allows CloudHub IP ranges

### Issue: No Data Inserted
**Solution**: 
- Check CloudHub logs for errors
- Verify table name is `employees` (not `records`)
- Confirm column names: `id`, `name`, `email`, `age`

### Issue: All Records Failed Validation
**Solution**: 
- Check CSV format matches exactly: `id,name,email,age`
- Ensure no extra spaces or special characters
- Verify email format is valid

### Issue: Duplicate Email Errors
**Solution**: 
- Application automatically skips database duplicates
- Check `dead_letter_queue` for file-level duplicates

## Project Structure
```
file-processing-api/
├── pom.xml                          # Maven configuration
├── mule-artifact.json               # Mule artifact metadata
├── src/
│   └── main/
│       ├── mule/
│       │   └── file-processing-api.xml   # Main flow configuration
│       └── resources/
│           ├── config-prod.yaml     # CloudHub configuration
│           ├── config-dev.yaml      # Local config (disabled)
│           ├── log4j2.xml          # Logging configuration
│           └── application-types.xml
└── target/
    └── file-processing-api-1.0.0-mule-application.jar
```

## Key Features
✅ **Client ID & Secret Authentication** - API secured with header-based credentials  
✅ Asynchronous CSV file processing  
✅ Data validation with detailed error messages  
✅ Duplicate detection (file-level and database-level)  
✅ Dead letter queue for failed records  
✅ Batch insert with retry mechanism  
✅ PostgreSQL array parameter handling  
✅ Correlation ID for request tracking  
✅ Status endpoint for monitoring  
✅ CloudHub secure properties for sensitive data  

## Security Notes
🔒 **Production Ready**: The API is secured with Client ID & Secret authentication  
🔒 **Secure Storage**: All secrets stored as encrypted CloudHub properties  
🔒 **Access Control**: Only authorized clients with valid credentials can access endpoints  
🔒 **Audit Logging**: All authentication attempts logged with IP addresses  

See [SECURITY.md](SECURITY.md) for complete security configuration guide.

## Important Notes
- Application uses **config-prod.yaml** in production (CloudHub)
- Sensitive credentials stored as **CloudHub secure properties** (encrypted)
- API requires authentication headers for all requests
- Processing is **asynchronous** (202 response)  

## Performance
- **Batch Size**: Processes records in batches for efficiency
- **Retry Logic**: 3 attempts with 2-second delays
- **Async Processing**: Non-blocking uploads return immediately
- **Database**: Uses bulk insert for better performance

## Security Notes
- HTTP endpoint is not secured (development mode)
- Database credentials stored in config-prod.yaml
- For production: Enable HTTPS and implement authentication
- Consider using secure properties for sensitive data

## Support
- Check CloudHub logs for detailed error messages
- Use correlation ID to trace specific requests
- Query `dead_letter_queue` table for failed records
- Monitor database connection pool in CloudHub metrics

---

**Last Updated**: February 11, 2026  
**Version**: 1.0.0  
**Runtime**: MuleSoft 4.10.1
