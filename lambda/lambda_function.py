import boto3
import pandas as pd
import os

# Initialize S3 client
s3 = boto3.client("s3")

def lambda_handler(event, context):
    """
    Lambda function to convert CSV files to Parquet format when uploaded to S3.
    
    Args:
        event: S3 event containing bucket and object information
        context: Lambda context object
        
    Returns:
        Dict containing status information
    """
    
    # 1. Extract file information from S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    print(f"Processing file: s3://{bucket}/{key}")

    # 2. Download CSV file from S3 (binary stream)
    obj = s3.get_object(Bucket=bucket, Key=key)

    # 3. Convert CSV to Parquet directly from the stream
    df = pd.read_csv(obj['Body'])

    # 4. Generate output file path
    parquet_key = "refined/"+key.replace(".csv", ".parquet")
    output_bucket = "data-mentoring-dev-athena-bucket"

    # 5. Save Parquet file to /tmp (Lambda's ephemeral storage)
    tmp_path = f"/tmp/{os.path.basename(parquet_key)}"
    df.to_parquet(tmp_path, engine="pyarrow", index=False)

    # 6. Upload converted file to S3
    s3.upload_file(tmp_path, output_bucket, parquet_key)

    print(f"File converted and saved to s3://{output_bucket}/{parquet_key}")

    return {"status": "success"}