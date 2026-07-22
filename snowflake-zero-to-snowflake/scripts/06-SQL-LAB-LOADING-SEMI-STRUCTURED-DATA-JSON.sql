-- =====================================================================
-- Module 06: Loading Semi-Structured Data into Snowflake: JSONs
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- Our analytics team wants to evaluate CPG company performance through
-- the lens of SEC filings. In this module we:
--   - Load SEC filing data in semi-structured JSON format from a
--     public S3 bucket.
--   - Create a view and query the JSON data using SQL dot notation.
--
-- The JSON data consists of SEC filings from Snowflake Public Data,
-- covering 2019-2023, staged on AWS S3 as gzipped JSON.
--
-- Snowflake can load and query semi-structured data (JSON, Parquet,
-- Avro) without transformation — a key differentiator from many
-- traditional data warehouses.

-- ---------------------------------------------------------------------
-- Step 1: Create a New Database and Table for the Data
-- ---------------------------------------------------------------------
-- You can execute multiple commands in sequence by selecting all of
-- them and clicking Play/Run (or the keyboard shortcut).
--
-- Create two tables, SEC_FILINGS_INDEX and SEC_FILINGS_ATTRIBUTES, to
-- load the JSON data into. The VARIANT data type lets Snowflake ingest
-- semi-structured data without predefining the schema.
-- ---------------------------------------------------------------------
CREATE TABLE SEC_FILINGS_INDEX (V VARIANT);

CREATE TABLE SEC_FILINGS_ATTRIBUTES (V VARIANT);

-- Verify in the results pane that both tables were created.

-- ---------------------------------------------------------------------
-- Step 2: Create Another External Stage
-- ---------------------------------------------------------------------
-- Create a stage pointing to the bucket where the semi-structured JSON
-- data is stored on AWS S3:
-- ---------------------------------------------------------------------
CREATE STAGE PUBLIC_DATA_SEC_FILINGS
URL = 's3://sfquickstarts/zero_to_snowflake/cybersyn_cpg_sec_filings/';

-- Look at the contents of the stage:
LIST @PUBLIC_DATA_SEC_FILINGS;

-- ---------------------------------------------------------------------
-- Step 3: Load and Verify the Semi-structured Data
-- ---------------------------------------------------------------------
-- Note: a FILE FORMAT object can be specified inline in the COPY
-- command. Because this JSON data is well-formed, we can just specify
-- the JSON type with default settings (no separate file format object
-- needed, unlike the CSV load in Module 05):
-- ---------------------------------------------------------------------
COPY INTO SEC_FILINGS_INDEX
FROM @PUBLIC_DATA_SEC_FILINGS/cybersyn_sec_report_index.json.gz
    FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE);

COPY INTO SEC_FILINGS_ATTRIBUTES
FROM @PUBLIC_DATA_SEC_FILINGS/cybersyn_sec_report_attributes.json.gz
    FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE);

-- Take a look at the data that was loaded (click any row to see the
-- formatted JSON in the right panel):
SELECT * FROM SEC_FILINGS_INDEX LIMIT 10;
SELECT * FROM SEC_FILINGS_ATTRIBUTES LIMIT 10;

-- ---------------------------------------------------------------------
-- Step 4: Create a View and Query Semi-Structured Data
-- ---------------------------------------------------------------------
-- A view lets the result of a query be accessed as if it were a
-- table — useful for presenting data more cleanly and writing modular
-- SQL. (Snowflake also supports materialized views on Enterprise
-- Edition or higher.)
--
-- CIK = Central Index Key (SEC's unique identifier per filing entity).
-- ADSH = the document number for a filing submitted to the SEC.
--
-- Create a columnar view of the semi-structured JSON SEC filing index
-- data so it's easier for analysts to query:
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW SEC_FILINGS_INDEX_VIEW AS
SELECT
    V:CIK::STRING                   AS CIK,
    V:COMPANY_NAME::STRING          AS COMPANY_NAME,
    V:EIN::INT                      AS EIN,
    V:ADSH::STRING                  AS ADSH,
    V:TIMESTAMP_ACCEPTED::TIMESTAMP AS TIMESTAMP_ACCEPTED,
    V:FILED_DATE::DATE              AS FILED_DATE,
    V:FORM_TYPE::STRING             AS FORM_TYPE,
    V:FISCAL_PERIOD::STRING         AS FISCAL_PERIOD,
    V:FISCAL_YEAR::STRING           AS FISCAL_YEAR
FROM SEC_FILINGS_INDEX;

CREATE OR REPLACE VIEW SEC_FILINGS_ATTRIBUTES_VIEW AS
SELECT
    V:VARIABLE::STRING            AS VARIABLE,
    V:CIK::STRING                 AS CIK,
    V:ADSH::STRING                 AS ADSH,
    V:MEASURE_DESCRIPTION::STRING AS MEASURE_DESCRIPTION,
    V:TAG::STRING                 AS TAG,
    V:TAG_VERSION::STRING         AS TAG_VERSION,
    V:UNIT_OF_MEASURE::STRING     AS UNIT_OF_MEASURE,
    V:VALUE::STRING               AS VALUE,
    V:REPORT::INT                 AS REPORT,
    V:STATEMENT::STRING           AS STATEMENT,
    V:PERIOD_START_DATE::DATE     AS PERIOD_START_DATE,
    V:PERIOD_END_DATE::DATE       AS PERIOD_END_DATE,
    V:COVERED_QTRS::INT           AS COVERED_QTRS,
    TRY_PARSE_JSON(V:METADATA)    AS METADATA
FROM SEC_FILINGS_ATTRIBUTES;

-- SQL dot notation (v:VARIABLE) pulls out values at lower levels
-- within the JSON object hierarchy, letting us treat each field as if
-- it were a relational column.
--
-- The new view appears as SEC_FILINGS_INDEX_VIEW under
-- Public_Data > PUBLIC > Views in the object browser (refresh/expand
-- the browser if it doesn't appear immediately).
--
-- Notice the results look just like a regular structured data source:
SELECT *
FROM SEC_FILINGS_INDEX_VIEW
LIMIT 20;

-- Continue to 07-SQL-LAB-GETTING-DATA-FROM-SNOWFLAKE-MARKETPLACE.sql.
