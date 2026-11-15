# AWS Kinesis Data Streams - Beginner Tutorial

This guide provides a step-by-step tutorial for working with AWS Kinesis Data Streams.

## Prerequisites

1. AWS CLI installed and configured (or use AWS CloudShell)
2. Appropriate IAM permissions for Kinesis operations

**Note:** All commands in this tutorial can be run in AWS CloudShell, which provides a browser-based terminal with AWS CLI pre-installed. Simply open CloudShell from the AWS Console and start executing commands!

---

## Complete Tutorial: Create, Describe, Put, and View Records

Follow these steps in order to learn the basics of Kinesis Data Streams.

### Step 1: Create a Stream

First, create a new Kinesis stream:

```bash
aws kinesis create-stream \
  --stream-name data-mentoring-stream \
  --shard-count 1
```

This command creates a stream called `data-mentoring-stream` with 1 shard.

**What to expect:** The command completes silently on success.

### Step 2: Verify Your Stream (Describe)

Before pushing data, verify that your stream exists and check its status. **Important:** Wait a few seconds after creating the stream for it to become ACTIVE:

```bash
aws kinesis describe-stream \
  --stream-name data-mentoring-stream
```

This returns detailed information including:
- Stream ARN
- Stream status (should be `ACTIVE`)
- Shard count and details
- Retention period
- Encryption settings

**Expected output snippet:**
```json
{
    "StreamDescription": {
        "StreamName": "data-mentoring-stream",
        "StreamStatus": "ACTIVE",
        "Shards": [
            {
                "ShardId": "shardId-000000000000",
                ...
            }
        ]
    }
}
```

**Alternative:** Get just the key details:

```bash
aws kinesis describe-stream \
  --stream-name data-mentoring-stream \
  --query 'StreamDescription.{Name:StreamName,Status:StreamStatus,Shards:Shards}'
```

**Wait for ACTIVE status:** If the status is `CREATING`, wait a few seconds and check again:
```bash
aws kinesis describe-stream \
  --stream-name data-mentoring-stream \
  --query 'StreamDescription.StreamStatus' \
  --output text
```

### Step 3: Put a Record into the Stream

Now let's put a record (data) into your stream:

```bash
aws kinesis put-record \
  --stream-name data-mentoring-stream \
  --partition-key user1 \
  --data "user test" \
  --cli-binary-format raw-in-base64-out
```

**What each parameter means:**
- `--stream-name`: Name of your Kinesis stream
- `--partition-key`: Determines which shard the record goes to (records with same key go to same shard)
- `--data`: The actual data to send
- `--cli-binary-format`: Format for binary data (`raw-in-base64-out` for text)

**Expected response:**
```json
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "496426621362268672"
}
```

The `SequenceNumber` uniquely identifies this record in the shard.

**Important:** Wait 2-3 seconds after putting the record before trying to read it. This ensures the record is fully available in the stream.

### Step 4: View (Read) Records from the Stream

To retrieve the record you just wrote, follow these sub-steps. **Important:** Wait 2-3 seconds after Step 3 before proceeding.

#### 4a. Get the Shard ID

First, identify which shard(s) exist in your stream:

```bash
aws kinesis describe-stream \
  --stream-name data-mentoring-stream \
  --query 'StreamDescription.Shards[0].ShardId' \
  --output text
```

This returns the shard ID directly:
```
shardId-000000000000
```

#### 4b. Get a Shard Iterator

Get a shard iterator to start reading records. **Use TRIM_HORIZON to read from the beginning:**

```bash
aws kinesis get-shard-iterator \
  --stream-name data-mentoring-stream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query 'ShardIterator' \
  --output text
```

**Shard Iterator Types:**
- `TRIM_HORIZON`: Read from the oldest record (best for seeing all data) ⭐ **Use this for learning**
- `LATEST`: Read only new records from now on
- `AT_SEQUENCE_NUMBER`: Read from a specific sequence number
- `AFTER_SEQUENCE_NUMBER`: Read after a specific sequence number
- `AT_TIMESTAMP`: Read from a specific timestamp

**Expected response:** A long string starting with `AAAAAAAAAAE...`

**Important:** Copy this iterator immediately - shard iterators expire after 5 minutes!

#### 4c. Read the Records

Use the shard iterator from Step 4b to read records. **Replace `<YourShardIterator>` with the actual iterator:**

```bash
aws kinesis get-records \
  --shard-iterator "<YourShardIterator>"
```

**Example with actual iterator:**
```bash
aws kinesis get-records \
  --shard-iterator "AAAAAAAAAAEUx4J..."
```

**Expected response:**
```json
{
    "Records": [
        {
            "SequenceNumber": "496426621362268672",
            "ApproximateArrivalTimestamp": 1234567890.0,
            "Data": "dXNlciB0ZXN0",
            "PartitionKey": "user1"
        }
    ],
    "NextShardIterator": "AAAAAAAAAAEF...",
    "MillisBehindLatest": 0
}
```

#### 4d. Decode the Data

The `Data` field is base64-encoded. To decode it and see your actual message:

```bash
echo "dXNlciB0ZXN0" | base64 -d
```

This will output: `user test`

**Or decode directly from the JSON response:**
```bash
aws kinesis get-records \
  --shard-iterator "<YourShardIterator>" | \
  jq -r '.Records[].Data' | \
  base64 -d
```

**Troubleshooting:** If you get an empty `Records` array:
1. Make sure you waited 2-3 seconds after putting the record
2. Verify you're using `TRIM_HORIZON` as the iterator type
3. Check that the stream status is `ACTIVE`
4. Try putting another record and reading again

---

## Putting It All Together: A Complete Script

Here's a complete script that does all the above steps and properly retrieves records:

```bash
#!/bin/bash

STREAM_NAME="data-mentoring-stream"

echo "Step 1: Creating stream..."
aws kinesis create-stream \
  --stream-name $STREAM_NAME \
  --shard-count 1

echo "Waiting for stream to become active (this may take 10-30 seconds)..."
# Wait until stream is ACTIVE
while true; do
  STATUS=$(aws kinesis describe-stream \
    --stream-name $STREAM_NAME \
    --query 'StreamDescription.StreamStatus' \
    --output text 2>/dev/null)
  
  if [ "$STATUS" == "ACTIVE" ]; then
    echo "Stream is now ACTIVE!"
    break
  elif [ "$STATUS" == "CREATING" ]; then
    echo "Stream is still CREATING, waiting 5 more seconds..."
    sleep 5
  else
    echo "Unexpected status: $STATUS"
    break
  fi
done

echo ""
echo "Step 2: Describing stream..."
aws kinesis describe-stream \
  --stream-name $STREAM_NAME \
  --query 'StreamDescription.{Name:StreamName,Status:StreamStatus,ShardCount:Shards | length(@)}'

echo ""
echo "Step 3: Putting a record..."
PUT_RESPONSE=$(aws kinesis put-record \
  --stream-name $STREAM_NAME \
  --partition-key "user1" \
  --data "Hello from Kinesis!" \
  --cli-binary-format raw-in-base64-out)

echo "Put record response:"
echo $PUT_RESPONSE | jq '.'

SEQUENCE_NUMBER=$(echo $PUT_RESPONSE | jq -r '.SequenceNumber')
SHARD_ID=$(echo $PUT_RESPONSE | jq -r '.ShardId')

echo ""
echo "Record written to Shard: $SHARD_ID"
echo "Sequence Number: $SEQUENCE_NUMBER"

echo ""
echo "Waiting 3 seconds for record to be available..."
sleep 3

echo ""
echo "Step 4a: Getting shard ID..."
SHARD_ID=$(aws kinesis describe-stream \
  --stream-name $STREAM_NAME \
  --query 'StreamDescription.Shards[0].ShardId' \
  --output text)

echo "Shard ID: $SHARD_ID"

echo ""
echo "Step 4b: Getting shard iterator..."
ITERATOR=$(aws kinesis get-shard-iterator \
  --stream-name $STREAM_NAME \
  --shard-id $SHARD_ID \
  --shard-iterator-type TRIM_HORIZON \
  --query 'ShardIterator' \
  --output text)

echo "Shard Iterator obtained (first 50 chars): ${ITERATOR:0:50}..."

echo ""
echo "Step 4c: Reading records..."
RECORDS_RESPONSE=$(aws kinesis get-records --shard-iterator $ITERATOR)

echo "Records response:"
echo $RECORDS_RESPONSE | jq '.'

echo ""
echo "Step 4d: Decoding record data..."
RECORD_COUNT=$(echo $RECORDS_RESPONSE | jq '.Records | length')
echo "Number of records retrieved: $RECORD_COUNT"

if [ "$RECORD_COUNT" -gt 0 ]; then
  echo ""
  echo "Decoded record data:"
  echo $RECORDS_RESPONSE | jq -r '.Records[] | .Data' | while read -r encoded_data; do
    if [ -n "$encoded_data" ]; then
      decoded_data=$(echo "$encoded_data" | base64 -d 2>/dev/null)
      echo "  Encoded: $encoded_data"
      echo "  Decoded: $decoded_data"
      echo ""
    fi
  done
else
  echo ""
  echo "⚠️  No records found. This might happen if:"
  echo "  1. The record wasn't written successfully"
  echo "  2. Not enough time passed after writing"
  echo "  3. The shard iterator expired"
  echo ""
  echo "Try putting another record and reading again."
fi
```

---

## Additional Commands

### List All Streams

```bash
aws kinesis list-streams
```

### Send JSON Data

```bash
aws kinesis put-record \
  --stream-name data-mentoring-stream \
  --partition-key user1 \
  --data '{"event":"login","user":"user1","timestamp":"2024-01-01T12:00:00Z"}' \
  --cli-binary-format raw-in-base64-out
```

### Send Multiple Records

```bash
for i in {1..5}; do
  aws kinesis put-record \
    --stream-name data-mentoring-stream \
    --partition-key "user$i" \
    --data "Event number $i" \
    --cli-binary-format raw-in-base64-out
done
```

---

## Common Errors and Solutions

### Error: Stream not found

**Problem:** The stream doesn't exist
**Solution:** Create the stream first (Step 1)
```bash
aws kinesis create-stream --stream-name data-mentoring-stream --shard-count 1
```

### Error: Permission denied

**Problem:** Missing IAM permissions
**Solution:** Verify your permissions with:
```bash
aws kinesis list-streams
```

### Error: Stream is still being created

**Problem:** Stream status is `CREATING`
**Solution:** Wait a few seconds, then check status:
```bash
aws kinesis describe-stream \
  --stream-name data-mentoring-stream \
  --query 'StreamDescription.StreamStatus'
```

### Error: No records returned when reading

**Problem:** Empty `Records` array when calling `get-records`
**Solutions:**
1. Wait 2-3 seconds after putting a record before reading
2. Make sure you're using `TRIM_HORIZON` as the iterator type (not `LATEST`)
3. Verify the record was written successfully (check the put-record response)
4. Ensure the stream status is `ACTIVE`
5. Try putting a new record and reading immediately after

### Error: ExpiredIteratorException

**Problem:** Shard iterator has expired
**Solution:** Shard iterators expire after 5 minutes. Get a new iterator:
```bash
aws kinesis get-shard-iterator \
  --stream-name data-mentoring-stream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query 'ShardIterator' \
  --output text
```

---

## Understanding Key Concepts

### Partition Keys

- Determines which shard in the stream the record goes to
- Records with the same partition key go to the same shard **in order**
- Choose keys that distribute data evenly
- **Good:** `user-123`, `session-456`, `order-789`
- **Bad:** Using the same key for everything

### Shards

- A shard is a uniquely identified sequence of data records in a stream
- More shards = higher throughput capacity
- Each shard supports up to 1,000 records per second for writes
- Each shard supports up to 2 MB per second for writes

### Sequence Numbers

- Each record gets a unique sequence number within its shard
- Used for ordering records
- Automatically assigned by Kinesis

---

## Best Practices

1. **Choose partition keys wisely** - Distribute data evenly across shards
2. **Monitor your data size** - Keep records under 1 MB (soft limit) or 2 MB (hard limit)
3. **Consider throughput** - Each shard has limits (1,000 records/sec, 2MB/sec)
4. **Enable CloudWatch** - Monitor your stream's health
5. **Use JSON** - Structure your data for easier processing later

---

## Clean Up

When you're done learning, clean up your resources:

```bash
# Delete the stream
aws kinesis delete-stream --stream-name data-mentoring-stream

# Wait a moment for deletion
sleep 5

# Verify it's deleted
aws kinesis list-streams
```

---

## References

- [AWS Kinesis Documentation](https://docs.aws.amazon.com/kinesis/)
- [AWS CLI Kinesis Commands](https://docs.aws.amazon.com/cli/latest/reference/kinesis/index.html)
- [Kinesis Data Streams Limits](https://docs.aws.amazon.com/streams/latest/dev/service-sizes-and-limits.html)
