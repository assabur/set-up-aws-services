# Set up AWS services

Hands-on labs for learning how to deploy and use AWS services for data engineering. This repository contains Terraform configurations, Python/PySpark scripts, SQL queries, and step-by-step guides.

Each directory is a separate lab with its own README. Run labs independently: there is no repository-wide Terraform deployment at the root.

## Labs

| Directory | Goal | Implementation |
| --- | --- | --- |
| [learn-terraform-get-started-aws](learn-terraform-get-started-aws/README.md) | Get started with Terraform by creating an S3 bucket with encryption and public access blocking. | Terraform |
| [athena](athena/README.md) | Store data in S3 and query it with Athena using SQL. | Terraform and SQL |
| [emr](emr/README.md) | Run PySpark processing on EMR and write Parquet files to S3. | Terraform, Python, and shell |
| [glue](glue/README.md) | Configure a Glue ETL job and its data catalog. | Terraform and PySpark |
| [lambda](lambda/README.md) | Build a CSV-to-Parquet conversion pipeline using Lambda, S3, and Athena. | Terraform for the source bucket, Python, and manual setup |
| [kinesis/kinesis-datastreams](kinesis/kinesis-datastreams/README.md) | Create a stream, send events, and read records. | AWS CLI or CloudShell |
| [lakeformation](lakeformation/README.md) | Apply row-level and column-level access controls to a table. | AWS Console |
| [quicksight](quicksight/README.md) | Prepare an S3/Glue/Athena data lake and create QuickSight visualizations. | Terraform and QuickSight setup |
| [redshift](redshift/README.md) | Deploy Redshift Serverless with an S3 staging bucket. | Terraform |
| [stepfunctions](stepfunctions/README.md) | Orchestrate an EMR cluster using Step Functions and EventBridge. | Terraform and a workflow definition |

## Prerequisites

- An AWS account with permissions appropriate for the selected lab.
- Git, Terraform, and AWS CLI for labs that use them.
- An authenticated AWS session in your terminal.
- The required sample datasets, prepared locally.

Terraform constraints and provider versions vary between directories. Check the lab's `terraform` blocks before initialization; some require Terraform 1.10 or later.

## Run a Terraform lab

Clone the repository and open the selected lab, for example the introductory S3 lab:

```bash
git clone https://github.com/assabur/set-up-aws-services.git
cd set-up-aws-services/learn-terraform-get-started-aws
```

Check your AWS identity and available tools:

```bash
aws sts get-caller-identity
terraform version
```

Read the lab's README, then adjust the region, bucket names, variables, and file paths for your environment. S3 bucket names must be globally unique.

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Review the plan before confirming resource creation. Each lab explains its data uploads, SQL queries, and any additional console configuration.

For Glue, an example variables file is available:

```bash
cd ../glue
cp terraform.tfvars.example local.auto.tfvars
```

Customize this file before deployment. Files matching `*.auto.tfvars` are ignored by Git. An existing `terraform.tfvars` file is also loaded automatically: review its contents and any overlapping values.

## Datasets and local files

CSV files and logs are excluded from Git. They are not included in a fresh clone, even when individual lab guides mention sample datasets. Prepare synthetic data matching the schemas described in each guide.

Some labs expect the following local paths:

| Lab | Expected local file |
| --- | --- |
| EMR | `emr/data/hr-salary-data.csv` |
| QuickSight | `quicksight/data/sales.csv`, or the path set through `csv_file_path` |
| Redshift | `redshift/data/sales_sample.csv` |
| Lake Formation | `lakeformation/data/orders.csv`, uploaded manually |

For Athena, Glue, and Lambda, follow the lab guide for schemas, S3 locations, and data uploads.

The Step Functions lab references `stepfunctions/scripts/salary_aggregations.py`, which is missing from the repository. Provide that script or update the reference before deploying. The EMR lab includes an example at `emr/scripts/salary_aggregations.py`.

The `.gitignore` also excludes Terraform state files and the `.terraform/` directory. Ordinary `*.tfvars` files are not all ignored: use `local.auto.tfvars` for local settings and keep AWS credentials out of project files.

## Clean up resources

Deployed services can incur charges, especially EMR and Redshift. After completing a lab, run the following from its directory:

```bash
terraform plan -destroy
terraform destroy
```

Depending on the configuration, destroying resources may delete bucket contents. Back up anything you need to retain. Follow the lab's README to remove resources created manually, since Terraform does not manage them automatically.
