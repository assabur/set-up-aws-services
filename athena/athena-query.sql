-- 1) Create the database
CREATE DATABASE IF NOT EXISTS human_resources;

-- 2) Create the table
CREATE EXTERNAL TABLE IF NOT EXISTS human_resources.salary_data (
    EmpID                  STRING,
    Name                   STRING,
    Gender                 STRING,
    DateOfBirth            STRING,
    Age                    INT,
    JoinDate               STRING,
    TenureInOrgInMonths    INT,
    GrossPay               DOUBLE,
    NetPay                 DOUBLE,
    Deduction              DOUBLE,
    DeductionPercentage    DOUBLE,
    JobTitle               STRING,
    Department             STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ',',
    "quoteChar"     = '"'
)
STORED AS TEXTFILE
LOCATION 's3://data-mentoring-dev-athena-bucket/data/'
TBLPROPERTIES ('skip.header.line.count'='1');
