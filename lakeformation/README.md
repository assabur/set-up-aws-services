# Column-Level Security with AWS Lake Formation

A step-by-step tutorial on implementing **column-level and row-level security** on an AWS Glue Data Catalog table using **AWS Lake Formation**. All steps are performed in the **AWS Console** — no CLI required.

You will restrict user **alice** so that she:
- Sees only rows where **region = 'us-west'**
- Sees only columns **order_id**, **region**, **product**, **amount** — and **not** the sensitive **customer_email** column (filtered at column level)

---

## 1. Overview

### What this tutorial covers

- Storing a CSV file in Amazon S3 and exposing it as a table in the AWS Glue Data Catalog via **Amazon Athena**
- Registering the S3 location with **AWS Lake Formation** and disabling IAM-only mode
- Creating an IAM user **alice** and granting her Lake Formation access to the database and table
- Creating a **data filter** in the console: **column-level** (exclude **customer_email**) and **row-level** (only **us-west** rows)
- Validating in Athena as alice: only us-west rows, and no `customer_email` column

### Why this matters

Sensitive columns (e.g. PII like email) and sensitive rows (e.g. by region or department) often need to be hidden from certain users. Lake Formation enforces this at **query time**: Athena applies the filter so restricted data never appears, without duplicating or transforming the underlying data.

---

## 2. Prerequisites

| Requirement | Details |
|-------------|---------|
| **AWS account** | With permissions to create S3 buckets, IAM users, Glue databases/tables, and Lake Formation resources |
| **AWS region** | Choose one (e.g. `us-east-1`) and use it for all steps |
| **S3 bucket** | Use **`data-mentoring-sales-bucket-<suffix>`**; replace **&lt;suffix&gt;** (e.g. **aag**) with your own so the name is globally unique |
| **CSV file** | Schema: `order_id`, `region`, `product`, `amount`, `customer_email`. A sample is in **`data/orders.csv`** (includes rows with `region = 'us-west'` for the row filter) |
| **Lake Formation** | Available in your account; you will disable IAM-only mode in Step 6 |

> **Tip:** Use a test AWS account or OU. Avoid production until you are comfortable with the flow.

---

## 3. Step 1: Upload Your CSV to S3

1. Go to **S3** → **Buckets** → **Create bucket**
   - **Bucket name:** `data-mentoring-sales-bucket-aag` (replace **aag** with your own suffix so the name is globally unique)
   - **Region:** e.g. `us-east-1`
   - Click **Create bucket**

2. Open the bucket → click **Create folder**
   - **Name:** `orders` → click **Create folder**

3. Open the **orders/** folder → click **Upload** → **Add files**
   - Select your CSV (**`data/orders.csv`** from this repo)
   - Click **Upload**

> Your file should now be at **`s3://data-mentoring-sales-bucket-aag/orders/orders.csv`** (use your bucket name if you changed the suffix).

---

## 4. Step 2: Create the Database in Athena

> ⚠️ **Disclaimer:** Athena requires a **query results location** (an S3 bucket) to be set before you can run queries. If you have not used Athena in this account or region before, you will be prompted to add one. Go to **Settings** → **Manage** in the Athena console and specify an S3 path (e.g. a folder in your data bucket). Without this, queries will not run.

1. Go to **Athena** → **Query Editor**
2. If prompted, set the **query result location**: click **Settings** → **Manage** and choose an S3 path, e.g. **`s3://data-mentoring-sales-bucket-aag/athena-results/`** (replace **aag** with your suffix).
3. Run:

```sql
CREATE DATABASE sales_db;
```

4. Confirm **sales_db** appears in the database list in the left panel.

---

## 5. Step 3: Create IAM User Alice

1. Go to **IAM** → **Users** → **Create user**
   - **User name:** `alice`
   - Check **Provide user access to the AWS Management Console** if she needs to log in to the console.
   - Click **Next**

2. **Attach policies directly** — search and attach:
   - **AmazonAthenaFullAccess**
   - **AWSGlueConsoleReadOnlyAccess**

3. Click **Next** → **Create user**.

4. (Optional) To allow console login: open user **alice** → **Security credentials** → **Assign console password** → set a password (and optionally require reset on first login).

---

## 6. Step 4: Create the Table in Athena

1. In the **Query Editor**, select **sales_db** in the left panel.
2. Run:

```sql
CREATE EXTERNAL TABLE sales_db.orders (
  order_id       INT,
  region         STRING,
  product        STRING,
  amount         INT,
  customer_email STRING
)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://data-mentoring-sales-bucket-aag/orders/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

3. Verify with:

```sql
SELECT * FROM sales_db.orders;
```

> You should see all your rows (30 rows if using **`data/orders.csv`**). ✅

---

## 7. Step 5: Register the S3 Location in Lake Formation

1. Go to **Lake Formation** (search for it in the AWS Console).
2. In the left menu → **Data lake locations**.
3. Click **Register location**.
   - **Amazon S3 path:** `s3://data-mentoring-sales-bucket-aag/orders/`
   - **IAM role:** leave default (**AWSServiceRoleForLakeFormationDataAccess**).
4. Click **Register location**.

---

## 8. Step 6: Disable IAM-Only Mode in Lake Formation

1. In **Lake Formation** → left menu → **Settings**.
2. **Uncheck** both boxes:
   - *Use only IAM access control for new databases*
   - *Use only IAM access control for new tables in new databases*
3. Click **Save**.

> **Important:** After this, Lake Formation permissions (and your data filter) will govern access to the Data Catalog and S3 data. Ensure your admin user is a **Data lake administrator** or has the needed Lake Formation grants.

---

## 9. Step 7: Grant Alice Access to the Database in Lake Formation

1. Go to **Lake Formation** → **Data permissions** → **Grant**.
2. Fill in:
   - **Principal:** IAM users and roles → select **alice**
   - **LF-Tags or catalog resources:** **Named data catalog resources**
   - **Database:** **sales_db**
   - **Database permissions:** check **Describe**
3. Click **Grant**.

---

## 10. Step 8: Grant Alice Table-Level SELECT in Lake Formation

1. Go to **Lake Formation** → **Data permissions** → **Grant** again.
2. Fill in:
   - **Principal:** **alice**
   - **Named data catalog resources**
   - **Database:** **sales_db**
   - **Table:** **orders**
   - **Table permissions:** check **Select**
3. Click **Grant**.

(You will attach the data filter to alice in Step 10 so her SELECT is restricted by row and column.)

---

## 11. Step 9: Create a Data Filter (Column + Row) in the Console

1. Go to **Lake Formation** → **Data filters** → **Create data filter** (or **Create new filter**).
2. Fill in:
   - **Data filter name:** `alice_region_filter`
   - **Database:** **sales_db**
   - **Table:** **orders**
   - **Column access:** choose **Exclude columns** → select **customer_email** (so alice cannot see this PII column).
   - **Row filter expression:** `region = 'us-west'` (so alice sees only us-west rows).
3. Click **Create filter**.

---

## 12. Step 10: Attach the Filter to Alice

1. Go to **Lake Formation** → **Data permissions** → **Grant**.
2. Fill in:
   - **Principal:** **alice**
   - **Named data catalog resources**
   - **Database:** **sales_db**
   - **Table:** **orders**
   - **Data filter:** select **alice_region_filter**
   - **Permissions:** check **Select**
3. Click **Grant**.

Alice now has **Select** on **sales_db.orders** only **through** the filter: she will see only **us-west** rows and the **customer_email** column will be hidden (excluded by the filter).

---

## 13. Step 11: Test as Alice in Athena

1. Sign in to the **AWS Console** as **alice** (e.g. use a private/incognito window).
2. Go to **Athena** → **Query Editor** (same region as your database).
3. Run:

```sql
SELECT * FROM sales_db.orders;
```

**Alice will only see:**

| order_id | region  | product    | amount |
|----------|---------|------------|--------|
| 2        | us-west | Phone      | 800    |
| 5        | us-west | Keyboard   | 100    |
| 8        | us-west | Headphones | 150    |
| ...      | ...     | ...        | ...    |

- Only **us-west** rows are visible (row filter).
- The **customer_email** column is not visible (column filter: excluded).

With **`data/orders.csv`**, alice sees 7 us-west rows. The important check is **4 columns, no customer_email**.

---

## 14. Summary — What You Did (ASCII)

```
S3 (orders.csv in orders/)
    │
    ▼
Athena → CREATE DATABASE sales_db + CREATE EXTERNAL TABLE orders
    │
    ▼
Lake Formation → Register S3 location (orders/)
    │
    ▼
Lake Formation → Disable IAM-only mode
    │
    ▼
IAM → Create user alice + attach Athena + Glue read-only
    │
    ▼
Lake Formation → Grant alice: Describe on sales_db
    │
    ▼
Lake Formation → Grant alice: Select on orders (table-level)
    │
    ▼
Lake Formation → Create data filter (exclude customer_email, rows us-west) → Grant to alice
    │
    ▼
Alice queries Athena → sees us-west rows only, 4 columns (no customer_email)
```

## 15. Cleanup

When you are done with the tutorial, delete the following resources to avoid ongoing charges:

1. **S3 bucket** — `data-mentoring-sales-bucket-aag` (and all its contents)
2. **Athena table** — `sales_db.orders`
3. **Athena database** — `sales_db`
4. **Lake Formation data filter** — `alice_region_filter`
5. **Lake Formation S3 location registration** — `s3://data-mentoring-sales-bucket-aag/orders/`
6. **IAM user** — `alice`
