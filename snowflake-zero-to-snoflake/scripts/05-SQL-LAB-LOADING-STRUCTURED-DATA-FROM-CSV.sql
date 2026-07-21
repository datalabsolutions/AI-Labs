-- =====================================================================
-- Module 05: Loading Structured Data into Snowflake: CSVs
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- We are using company metadata developed from the Securities and
-- Exchange Commission (SEC) detailing the consumer packaged goods
-- (CPG) companies we want to evaluate. The data is pre-staged in a
-- public AWS S3 bucket (US-EAST region), comma-delimited, with a
-- single header line, and double quotes enclosing all string values.
--
-- Getting Data into Snowflake: data can be ingested via the COPY
-- command, Snowpipe auto-ingestion, external connectors, or
-- third-party ETL/ELT tools. This lab uses COPY + AWS S3 for a manual
-- load.

-- ---------------------------------------------------------------------
-- Step 1: Create a Database and Table
-- ---------------------------------------------------------------------
-- Ensure you are using the SYSADMIN role by selecting your name at the
-- top left, Switch Role > SYSADMIN.
-- ---------------------------------------------------------------------

USE ROLE SYSADMIN;

-- ---------------------------------------------------------------------
-- Navigate to the Databases tab. Click Create, name the database
-- PUBLIC_DATA, then click CREATE.
-- (Equivalent SQL — the lab performs this step via the UI "Create" dialog)
-- ---------------------------------------------------------------------

CREATE OR REPLACE DATABASE PUBLIC_DATA;

-- ---------------------------------------------------------------------
-- Set worksheet context: Role SYSADMIN, Warehouse COMPUTE_WH,
-- Database PUBLIC_DATA, Schema PUBLIC.
-- ---------------------------------------------------------------------

USE WAREHOUSE COMPUTE_WH;
USE DATABASE PUBLIC_DATA;
USE SCHEMA PUBLIC;

-- ---------------------------------------------------------------------
-- DDL operations are free! Creating databases/tables/stages/file
-- formats does not consume compute credits.

-- Rename your worksheet to ZERO_TO_SNOWFLAKE_WITH_PUBLIC_DATA (UI action,
-- no SQL required).

-- Create a table called COMPANY_METADATA to load the comma-delimited
-- data into:
-- ---------------------------------------------------------------------

CREATE OR REPLACE TABLE COMPANY_METADATA
(
    CYBERSYN_COMPANY_ID STRING,
    COMPANY_NAME STRING,
    PERMID_SECURITY_ID STRING,
    PRIMARY_TICKER STRING,
    SECURITY_NAME STRING,
    ASSET_CLASS STRING,
    PRIMARY_EXCHANGE_CODE STRING,
    PRIMARY_EXCHANGE_NAME STRING,
    SECURITY_STATUS STRING,
    GLOBAL_TICKERS VARIANT,
    EXCHANGE_CODE VARIANT,
    PERMID_QUOTE_ID VARIANT
);

-- Run the query (cursor in the SQL text, click Play/Run, or
-- [Ctrl]/[Cmd]+[Enter]). Verify: "Table COMPANY_METADATA successfully
-- created" in the Results pane.
--
-- Navigate to Data > Databases > Public_Data > PUBLIC > TABLES to see
-- the newly created COMPANY_METADATA table, then click it and the
-- Columns tab to see its structure.

-- ---------------------------------------------------------------------
-- Step 2: Create an External Stage
-- ---------------------------------------------------------------------
-- We are working with structured, comma-delimited data already staged
-- in a public external S3 bucket. Before we can use it, we create a
-- stage pointing to that bucket. For this lab we use an AWS-East
-- bucket — to avoid data egress costs in production, choose a staging
-- location in the same cloud provider/region as your account.
--
-- From Data > Databases, click Public_Data > PUBLIC, click Create,
-- then Stage > Amazon S3. In the Create Stage dialog, use:
--   Stage Name : Public_Data_company_metadata
--   URL        : s3://sfquickstarts/zero_to_snowflake/cybersyn-consumer-company-metadata-csv/
-- NOTE: include the trailing "/" on the URL or later loads will error.
-- Remove (or comment out with "--") the "credentials = (...)" line —
-- this bucket is public and needs no credentials.
-- ---------------------------------------------------------------------

CREATE OR REPLACE STAGE PUBLIC_DATA_COMPANY_METADATA
    URL = 's3://sfquickstarts/zero_to_snowflake/cybersyn-consumer-company-metadata-csv/';
    -- credentials = ( ... )  -- not required: bucket is public

-- Look at the contents of the stage:
LIST @PUBLIC_DATA_COMPANY_METADATA;

-- ---------------------------------------------------------------------
-- Step 3: Create a File Format
-- ---------------------------------------------------------------------
-- Before loading, create a file format matching the data structure:
-- ---------------------------------------------------------------------

CREATE OR REPLACE FILE FORMAT CSV
    TYPE = 'CSV'
    COMPRESSION = 'AUTO'  -- Automatically determines the compression of files
    FIELD_DELIMITER = ','  -- Specifies comma as the field delimiter
    RECORD_DELIMITER = '\n'  -- Specifies newline as the record delimiter
    SKIP_HEADER = 1  -- Skip the first line
    FIELD_OPTIONALLY_ENCLOSED_BY = '\042'  -- Fields are optionally enclosed by double quotes (ASCII code 34)
    TRIM_SPACE = FALSE  -- Spaces are not trimmed from fields
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE  -- Does not raise an error if the number of fields in the data file varies
    ESCAPE = 'NONE'  -- No escape character for special character escaping
    ESCAPE_UNENCLOSED_FIELD = '\134'  -- Backslash is the escape character for unenclosed fields
    DATE_FORMAT = 'AUTO'  -- Automatically detects the date format
    TIMESTAMP_FORMAT = 'AUTO'  -- Automatically detects the timestamp format
    NULL_IF = ('')  -- Treats empty strings as NULL values
    COMMENT = 'File format for ingesting data for zero to snowflake';

-- Verify the file format was created with the correct settings:
SHOW FILE FORMATS IN DATABASE PUBLIC_DATA;

-- ---------------------------------------------------------------------
-- Step 4: Resize and Use a Warehouse for Data Loading
-- ---------------------------------------------------------------------
-- Compute resources are needed for loading data. Snowflake's compute
-- nodes are virtual warehouses; they can be sized up/out per workload.
-- Navigate to Admin > Warehouses. We use the existing COMPUTE_WH
-- warehouse rather than creating a new one.
--
-- WARNING - Watch Your Spend! Do not disable auto-suspend, and don't
-- use a warehouse size larger than the workload needs — both burn
-- through free trial credits faster than necessary.
--
-- Change the warehouse size from X-Small to Small, then Save Warehouse.
-- (Equivalent SQL — the lab performs this step via the Warehouse "Edit" UI)
-- ---------------------------------------------------------------------
ALTER WAREHOUSE COMPUTE_WH SET warehouse_size = 'small';

-- ---------------------------------------------------------------------
-- Step 5: Load the Data
-- ---------------------------------------------------------------------
-- Ensure worksheet context: Role SYSADMIN, Warehouse COMPUTE_WH,
-- Database Public_Data, Schema PUBLIC.
--
-- Load the staged CSV data into COMPANY_METADATA (may take up to
-- ~30 seconds):
-- ---------------------------------------------------------------------

COPY INTO COMPANY_METADATA FROM @PUBLIC_DATA_COMPANY_METADATA FILE_FORMAT = CSV PATTERN = '.*csv.*' ON_ERROR = 'CONTINUE';

-- ---------------------------------------------------------------------

-- Check status in the Query Details pane. Then check Query History
-- (Home > Activity > Query History) and open the Query Profile tab
-- for the COPY INTO statement to see execution steps, details, most
-- expensive nodes, and stats.

-- Now reload with a larger warehouse to compare load time. First
-- clear the table:
-- ---------------------------------------------------------------------

TRUNCATE TABLE COMPANY_METADATA;

-- ---------------------------------------------------------------------
-- Verify that the table is empty by running the following command:
-- ---------------------------------------------------------------------

SELECT * FROM COMPANY_METADATA LIMIT 10;

-- ---------------------------------------------------------------------
-- Result should show "Query produced no results".
-- Change the warehouse size to LARGE:
-- ---------------------------------------------------------------------

ALTER WAREHOUSE COMPUTE_WH SET warehouse_size='large';

-- ---------------------------------------------------------------------
-- Verify the change using the following SHOW WAREHOUSES:
-- ---------------------------------------------------------------------

SHOW WAREHOUSES;

-- ---------------------------------------------------------------------
-- Execute the same COPY INTO statement as before to load the same
-- data again:
-- ---------------------------------------------------------------------

COPY INTO COMPANY_METADATA FROM @PUBLIC_DATA_COMPANY_METADATA FILE_FORMAT = CSV PATTERN = '.*csv.*' ON_ERROR = 'CONTINUE';

-- ---------------------------------------------------------------------
-- Compare the two COPY INTO durations in Query History — the Large
-- warehouse load should be significantly faster.

-- ---------------------------------------------------------------------
-- Step 6: Create a New Warehouse for Data Analytics
-- ---------------------------------------------------------------------
-- To eliminate resource contention between data loading/ETL and
-- end-user analytics, create a dedicated warehouse for analytics.
-- Navigate to Admin > Warehouses, click + Warehouse, name it
-- ANALYTICS_WH, set Size to Large. If Multi-cluster Warehouses is
-- enabled, set Max Clusters to 1 and leave other settings at default.
-- Click Create Warehouse.
-- (Equivalent SQL — the lab performs this step via the "+ Warehouse" UI dialog)
-- ---------------------------------------------------------------------

CREATE OR REPLACE WAREHOUSE ANALYTICS_WH
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- ---------------------------------------------------------------------
-- Continue to 06-SQL-LAB-LOADING-SEMI-STRUCTURED-DATA-JSON.sql.
-- ---------------------------------------------------------------------

