# EMR Job Manager - Step Functions with Terraform

This project demonstrates how to deploy an **AWS Step Functions state machine** that orchestrates an **Amazon EMR** cluster using Terraform. The state machine creates an EMR cluster, runs two sample steps, and terminates the cluster. An **EventBridge (CloudWatch Events)** rule triggers the workflow **daily at 5 AM UTC**.

Perfect for learners who want to understand:
- Step Functions + EMR integration
- Infrastructure as Code with Terraform
- Scheduled workflows with EventBridge

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   EventBridge       │     │   Step Functions     │     │   Amazon EMR        │
│   Cron (5 AM UTC)   │────▶│   State Machine      │────▶│   Cluster           │
└─────────────────────┘     └──────────────────────┘     └─────────────────────┘
                                      │
                                      ├── Create EMR cluster
                                      ├── Run step 1 (ls)
                                      ├── Run step 2 (ls)
                                      └── Terminate cluster
```

## Prerequisites

Before you begin, ensure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```

2. **Terraform** installed (version >= 1.0)
   - Follow the official OS-specific install guide: https://developer.hashicorp.com/terraform/install

3. **AWS Account** with permissions to create:
   - IAM roles and policies
   - S3 buckets
   - Step Functions state machines
   - EventBridge rules
   - EMR clusters (requires EC2, EMR, and related service permissions)

## Project Structure

```
stepfunctions/
├── main.tf                           # Terraform resources (IAM, S3, state machine, EventBridge)
├── variables.tf                      # Input variables
├── outputs.tf                        # Output values
├── terraform.tf                      # Provider configuration
├── terraform.tfvars.example          # Example variables (copy to terraform.tfvars)
├── state-machine-definition.json.tpl # State machine ASL template (parameterized JSON)
├── EMRJobManagerStateMachine-*.asl.yaml  # Original exported definition (reference)
└── README.md                         # This file
```

## Quick Start

### Step 1: Navigate to the Project Directory

```bash
cd stepfunctions
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review the Plan

```bash
terraform plan
```

This will show all resources to be created:
- S3 bucket for EMR logs
- IAM roles (EMR service, EMR EC2, Step Functions, EventBridge)
- Step Functions state machine
- EventBridge rule for daily 5 AM trigger

### Step 4: Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment typically takes 1–2 minutes.

### Step 5: Verify

```bash
# View outputs
terraform output

# Check the state machine
aws stepfunctions describe-state-machine \
  --state-machine-arn $(terraform output -raw state_machine_arn)

# Manually trigger an execution (optional)
aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn)
```

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name for resource naming | `emr-job-manager` |
| `schedule_cron` | Cron expression for daily trigger | `cron(0 5 * * ? *)` (5 AM UTC) |
| `enable_schedule` | Enable EventBridge daily trigger | `true` |
| `cluster_name` | EMR cluster name | `ExampleCluster` |
| `emr_release_label` | EMR release | `emr-5.26.0` |
| `master_instance_type` | Master node instance type | `m5.xlarge` |
| `core_instance_type` | Core node instance type | `m5.xlarge` |

### Changing the Schedule

The default schedule is **5 AM UTC** daily. To use a different time:

| Desired Time (Local) | Cron Expression |
|----------------------|-----------------|
| 5 AM UTC | `cron(0 5 * * ? *)` |
| 5 AM US Eastern (EST) | `cron(0 10 * * ? *)` |
| 5 AM US Pacific (PST) | `cron(0 13 * * ? *)` |
| Midnight UTC | `cron(0 0 * * ? *)` |

Edit `terraform.tfvars` or pass `-var="schedule_cron=cron(0 10 * * ? *)"` when applying.

### Disabling the Schedule

To deploy without the daily trigger (e.g., for manual runs only):

```bash
terraform apply -var="enable_schedule=false"
```

## Running the State Machine

### Option 1: Wait for Schedule

The state machine runs automatically every day at the configured time (default 5 AM UTC).

### Option 2: Manual Trigger via AWS CLI

```bash
aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw state_machine_arn)
```

### Option 3: AWS Console

1. Go to **Step Functions** in the AWS Console
2. Select the state machine `emr-job-manager-state-machine`
3. Click **Start execution**
4. Leave the input as `{}` and click **Start execution**

## Monitoring

- **Step Functions Console**: View execution history, success/failure, and visual workflow
- **CloudWatch Logs**: EMR cluster logs are stored in the S3 bucket (`emr_logs_uri` output)
- **EventBridge**: Check rule invocations in CloudWatch metrics

```bash
# List recent executions
aws stepfunctions list-executions \
  --state-machine-arn $(terraform output -raw state_machine_arn) \
  --max-results 10
```

## Cost Considerations

⚠️ **Important**: EMR clusters incur costs for EC2 instances. This demo uses:
- 1x m5.xlarge master node
- 1x m5.xlarge core node

Each execution creates a new cluster, runs two simple steps (`ls`), and terminates. A single run typically takes 10–15 minutes. **Remember to run `terraform destroy` when you're done learning** to avoid ongoing charges.

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

Type `yes` when prompted. This deletes:
- State machine
- EventBridge rule
- IAM roles and policies
- S3 bucket and EMR logs

**Note**: Any EMR clusters that are still running must be terminated first. The state machine handles termination, but if an execution failed mid-run, check the EMR console for orphaned clusters.

## Troubleshooting

### "Access Denied" when Step Functions runs

- Ensure the Step Functions role has `elasticmapreduce:*` and `iam:PassRole` for the EMR roles
- Check that the EMR service role and EC2 instance profile exist and have the correct policies

### EventBridge not triggering

- Verify the rule exists: `aws events list-rules --name-prefix emr-job-manager`
- Check the rule's target: `aws events list-targets-by-rule --rule emr-job-manager-daily-trigger`
- Ensure the EventBridge role has `states:StartExecution` permission

### EMR cluster creation fails

- Confirm your account has EMR service limits (default is usually sufficient for dev)
- Verify the S3 bucket for logs exists and the EMR EC2 role can write to it
- Check that the instance types (`m5.xlarge`) are available in your region

### State machine uses JSONata/YAML format

The state machine definition uses AWS Step Functions' **JSONata** query language and **variables** (the `Assign` block). This is a newer feature. If you see validation errors, ensure you're using a recent AWS provider (>= 5.0) and that your AWS account supports these features.

## Next Steps

1. **Customize the EMR steps**: Edit `state-machine-definition.json.tpl` to run your own Hive queries or Spark jobs
2. **Add error handling**: Use `Catch` blocks for failed steps
3. **Integrate with Glue**: Trigger a Glue job instead of (or in addition to) EMR
4. **Add notifications**: Use SNS to alert on success/failure

## Additional Resources

- [Step Functions + EMR Integration](https://docs.aws.amazon.com/step-functions/latest/dg/connect-emr.html)
- [EventBridge Cron Expressions](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)
- [Terraform AWS Provider - Step Functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine)
