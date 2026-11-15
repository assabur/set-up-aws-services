# CSV to Parquet Lambda Function with S3 and Athena

This project creates a complete data pipeline that automatically converts CSV files to Parquet format using AWS Lambda, stores them in S3, and enables querying with Athena.

## 🏗️ Architecture Overview

1. **S3 Bucket**: `data-mentoring-dev-landing-bucket` (source for CSV files)
2. **Lambda Function**: Converts CSV to Parquet and saves to `refined/` folder
3. **Destination Bucket**: `data-mentoring-dev-athena-bucket` (stores Parquet files)
4. **Athena Table**: Query the Parquet files for analytics

## 📁 Project Structure

```
lambda/
├── main.tf                      # S3 bucket Terraform configuration
├── variables.tf                 # Variable definitions (empty)
├── outputs.tf                   # Output definitions
├── lambda_function.py           # Lambda function code
├── salary-data.csv              # Sample salary data for testing
├── create_database_and_table.sql # SQL script for database and table creation
├── test_event.json              # Test event for Lambda function testing
└── README.md                   # This documentation
```

## 📊 Sample Data

The project includes a sample `salary-data.csv` file with employee salary information:

- **File**: `salary-data.csv`
- **Records**: ~1,800 employee records
- **Columns**: EmpID, Name, Gender, DateOfBirth, Age, JoinDate, TenureInOrgInMonths, GrossPay, NetPay, Deduction, DeductionPercentage, JobTitle, Department
- **Purpose**: Use this file to test the CSV to Parquet conversion pipeline

## 🚀 Step-by-Step Setup

### Step 1: Create S3 Bucket (if not exists)

1. **Initialize and apply Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Verify the bucket was created:**
   ```bash
   aws s3 ls s3://data-mentoring-dev-landing-bucket
   ```

### Step 2: Create Lambda Function

1. **Go to AWS Lambda Console:**
   - Navigate to AWS Lambda service
   - Click "Create function"

2. **Configure the function:**
   - **Function name**: `csv-to-parquet-converter`
   - **Runtime**: Python 3.9 or higher
   - **Architecture**: x86_64
   - **Execution role**: Create new role with basic Lambda permissions

3. **Set function timeout:**
   - Go to "Configuration" → "General configuration"
   - Click "Edit"
   - Set **Timeout** to: `15 minutes (900 seconds)`
   - Set **Memory** to: `512 MB` (or higher)

4. **Add required Lambda layers:**
   - Go to "Code" tab
   - Scroll down to "Layers" section
   - Click "Add a layer"
   - Choose "AWS layers"
   - Add the following layers:
     - **AWSSDKPandas-Python310** (for pandas and numpy)
     - **AWSSDKPandas-Python310-PyArrow** (for parquet support)
   - Click "Add" to attach the layers

5. **Add S3 permissions to Lambda role:**
   - Go to IAM → Roles
   - Find your Lambda execution role
   - Click "Add permissions" → "Attach policies"
   - Search and attach: `AmazonS3FullAccess`

6. **Upload the function code:**
   - In Lambda console, go to "Code" tab
   - Replace the default code with the content from `lambda_function.py`
   - Set **Handler** to: `lambda_function.lambda_handler`
   - Click "Deploy"

### Step 3: Configure S3 Trigger

1. **Add S3 trigger:**
   - In Lambda function, go to "Configuration" → "Triggers"
   - Click "Add trigger"
   - Select "S3" as source
   - Configure:
     - **Bucket**: `data-mentoring-dev-landing-bucket`
     - **Event types**: ObjectCreated (All)
     - **Prefix**: (leave empty)
     - **Suffix**: `.csv`

2. **Test the trigger:**
   - Upload a CSV file to `data-mentoring-dev-landing-bucket`
   - Check CloudWatch logs for processing status
   - Verify Parquet file appears in `data-mentoring-dev-athena-bucket/refined/`

### Step 4: Test the Pipeline

1. **Upload the sample salary data:**
   ```bash
   # Upload the included salary data CSV file
   aws s3 cp salary-data.csv s3://data-mentoring-dev-landing-bucket/
   ```

2. **Check the results:**
   ```bash
   # Check if Parquet file was created
   aws s3 ls s3://data-mentoring-dev-athena-bucket/refined/
   ```

3. **Verify Lambda execution:**
   - Go to CloudWatch → Log groups
   - Find your Lambda function logs
   - Check for "Processing file" and "File converted" messages

4. **Test Lambda function manually:**
   - Go to Lambda function console
   - Click "Test" button
   - Create a new test event
   - Copy and paste the contents of `test_event.json`
   - Click "Test" to run the function
   - Check the execution results and logs

### Step 5: Create Athena Database and Table

1. **Go to Athena Console:**
   - Navigate to AWS Athena service
   - Make sure you're in the correct region

2. **Run the SQL script:**
   - Copy and paste the contents of `create_database_and_table.sql`
   - Or upload the file and run it in Athena
   - This script will:
     - Create a database named `human_resources`
     - Create a table `employee_salary_data_parquet` pointing to Parquet files
     - Include comprehensive comments and metadata
     - Run several test queries

3. **Alternative - Manual creation:**
   - Create database: `CREATE DATABASE IF NOT EXISTS human_resources;`
   - Use database: `USE human_resources;`
   - Create table with the schema from the SQL file

4. **Verify the setup:**
   - Check that the table appears in the database
   - Run a test query: `SELECT COUNT(*) FROM employee_salary_data_parquet;`
   - Verify data is accessible from the Parquet files

5. **Sample queries included in the SQL file:**
   - Basic data exploration
   - Salary analytics by department
   - Gender-based salary analysis
   - Top earners identification
   - Deduction analysis

## 🔧 Lambda Function Code

The Lambda function (`lambda_function.py`) includes:

- **Event Processing**: Extracts file information from S3 events
- **Stream Processing**: Reads CSV directly from S3 stream
- **Format Conversion**: Converts CSV to Parquet using pandas/pyarrow
- **Organized Storage**: Saves files in `refined/` folder
- **Error Handling**: Basic logging and status reporting

### Required Dependencies

The function requires the following AWS Lambda layers:
- **AWSSDKPandas-Python310**: Provides pandas and numpy libraries
- **AWSSDKPandas-Python310-PyArrow**: Provides pyarrow for Parquet support

These layers must be attached to the Lambda function for the imports to work properly.

## 📊 Monitoring and Troubleshooting

### CloudWatch Logs

You can monitor your Lambda function execution through CloudWatch logs:

1. **Access CloudWatch Logs:**
   - Go to AWS CloudWatch service
   - Click "Logs" → "Log groups"
   - Find: `/aws/lambda/csv-to-parquet-converter`

2. **What to look for:**
   - **Processing messages**: "Processing file: s3://bucket/file.csv"
   - **Success messages**: "File converted and saved to s3://bucket/refined/file.parquet"
   - **Error messages**: Any exceptions or failures
   - **Execution details**: Duration, memory usage, billing duration

3. **Log Streams:**
   - Each Lambda execution creates a new log stream
   - Click on a log stream to see detailed execution logs
   - Use the search bar to filter for specific messages

4. **Real-time Monitoring:**
   - Logs appear in real-time during function execution
   - Refresh the page to see new log entries
   - Use the "Live tail" feature for real-time log streaming

### Common Issues
1. **Permission errors**: Ensure Lambda role has S3FullAccess
2. **Timeout errors**: Increase Lambda timeout to 15 minutes
3. **Memory errors**: Increase Lambda memory allocation
4. **File not found**: Check S3 bucket names and file paths
5. **Import errors**: Ensure AWS Lambda layers are attached:
   - **AWSSDKPandas-Python310** (for pandas and numpy)
   - **AWSSDKPandas-Python310-PyArrow** (for parquet support)
6. **Parquet schema errors**: If you get "Malformed Parquet file" or type mismatch errors:
   - **Root cause**: Pandas infers numeric columns as INT64 (bigint) instead of DOUBLE
   - **Common affected columns**: empid, age, tenureinorginmonths, grosspay, netpay, deduction
   - **Solution**: Use `bigint` for integer columns and `double` only for decimal columns
   - **Prevention**: The updated SQL file uses the correct data types that match pandas output
   - **If errors persist**: Check the actual Parquet file schema using AWS Glue or inspect the file directly

### Useful Commands
```bash
# Check S3 bucket contents
aws s3 ls s3://data-mentoring-dev-landing-bucket/
aws s3 ls s3://data-mentoring-dev-athena-bucket/refined/

# Check Lambda function logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/csv-to-parquet-converter

# Get recent log events
aws logs filter-log-events --log-group-name /aws/lambda/csv-to-parquet-converter --start-time $(date -d '1 hour ago' +%s)000

# Test Lambda function with test event
aws lambda invoke --function-name csv-to-parquet-converter --payload file://test_event.json response.json

# View test response
cat response.json

# Inspect Parquet file schema (if you have pyarrow installed locally)
python3 -c "
import pyarrow.parquet as pq
import boto3
s3 = boto3.client('s3')
obj = s3.get_object(Bucket='data-mentoring-dev-athena-bucket', Key='refined/salary-data.parquet')
table = pq.read_table(obj['Body'])
print('Parquet Schema:')
print(table.schema)
"
```

### Test Event File

The project includes `test_event.json` which simulates an S3 event for testing:

- **Bucket**: `data-mentoring-dev-landing-bucket`
- **File**: `salary-data.csv`
- **Event Type**: ObjectCreated:Put
- **Usage**: Test the Lambda function without uploading actual files

## 🧹 Cleanup

To destroy the infrastructure:

```bash
# Destroy S3 bucket (be careful - this deletes all data!)
terraform destroy

# Delete Lambda function
aws lambda delete-function --function-name csv-to-parquet-converter
```

## 📋 Expected Results

After completing all steps:

1. ✅ S3 bucket `data-mentoring-dev-landing-bucket` created
2. ✅ Lambda function `csv-to-parquet-converter` deployed
3. ✅ S3 trigger configured for CSV files
4. ✅ CSV files automatically converted to Parquet
5. ✅ Parquet files stored in `refined/` folder
6. ✅ Athena table created and queryable


**Happy Data Processing! 🚀**