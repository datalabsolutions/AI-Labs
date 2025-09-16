--------------------------------------------------------------------------
-- Step 1: Create Database
--------------------------------------------------------------------------
-- This step initializes the primary database for the LLM Cortex demo environment.
-- It ensures the database exists before continuing with the rest of the setup.
--------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS  CALL_CENTER_ANALYTICS_DW;

--------------------------------------------------------------------------
-- Step 2: Create Warehouse
--------------------------------------------------------------------------
-- This step sets up a compute warehouse named USER_STD_XSMALL_WH.
-- The warehouse is configured to:
-- - Auto-suspend after 60 seconds of inactivity
-- - Automatically resume when queries are issued
-- - Start in a suspended state to minimize credit usage
--------------------------------------------------------------------------

CREATE OR REPLACE WAREHOUSE USER_STD_XSMALL_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE OR REPLACE WAREHOUSE APP_STD_XSMALL_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

--------------------------------------------------------------------------
-- Step 3: Create Schemas
--------------------------------------------------------------------------
-- This step creates two schemas within the CALL_CENTER_DW database:
-- - RAW: for storing unprocessed or ingested data
-- - STAGE: for temporary or intermediate processed data
--------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS CALL_CENTER_ANALYTICS_DW.EXTRACT;
CREATE SCHEMA IF NOT EXISTS CALL_CENTER_ANALYTICS_DW.STAGE;
CREATE SCHEMA IF NOT EXISTS CALL_CENTER_ANALYTICS_DW.DWH;


--------------------------------------------------------------------------
-- Step 4: Create Internal Stage for PDFs
--------------------------------------------------------------------------
-- This step defines an internal stage in the RAW schema to store uploaded PDF documents.
-- The stage supports directory table creation and uses Snowflake-managed SSE encryption.
--------------------------------------------------------------------------

CREATE OR REPLACE STAGE EXTRACT.INT_STAGE_DOC
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

CREATE OR REPLACE FILE FORMAT EXTRACT.JSON_FORMAT
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;      -- flatten outer [ ] arrays automatically;

--------------------------------------------------------------------------
-- Step 5: Create Roles & Permissions
--------------------------------------------------------------------------
-- This step creates two schemas within the CALL_CENTER_DW database:
-- - RAW: for storing unprocessed or ingested data
-- - STAGE: for temporary or intermediate processed data
--------------------------------------------------------------------------
-- Create role
CREATE ROLE IF NOT EXISTS APP_MATILLION_ROLE;

-- Assign application role to SYSADMIN (best practice)
GRANT ROLE APP_MATILLION_ROLE TO ROLE SYSADMIN;

-- Create user
CREATE USER IF NOT EXISTS APP_MATILLION_SVC
  TYPE = LEGACY_SERVICE                           -- Explicitly mark as service account
  PASSWORD = 'M@tillion!1.'
  DEFAULT_ROLE = APP_MATILLION_ROLE
  DEFAULT_WAREHOUSE = APP_STD_XSMALL_WH
  MUST_CHANGE_PASSWORD = FALSE             -- Not required for service users
  COMMENT = 'Service account for Matillion ETL operations';

-- Assign role to user
GRANT ROLE APP_MATILLION_ROLE TO USER APP_MATILLION_SVC;

-- Database & schema usage
GRANT ALL PRIVILEGES ON SCHEMA CALL_CENTER_ANALYTICS_DW.EXTRACT TO ROLE APP_MATILLION_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA CALL_CENTER_ANALYTICS_DW.STAGE TO ROLE APP_MATILLION_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA CALL_CENTER_ANALYTICS_DW.DWH TO ROLE APP_MATILLION_ROLE;

CREATE ROLE IF NOT EXISTS APP_MATILLION_ROLE;

-- Assign application role to SYSADMIN (best practice)
GRANT ROLE APP_MATILLION_ROLE TO ROLE SYSADMIN;

-- Create user
CREATE USER IF NOT EXISTS APP_MATILLION_SVC
  TYPE = LEGACY_SERVICE                           -- Explicitly mark as service account
  PASSWORD = 'M@tillion!1.'
  DEFAULT_ROLE = APP_MATILLION_ROLE
  DEFAULT_WAREHOUSE = APP_STD_XSMALL_WH
  MUST_CHANGE_PASSWORD = FALSE             -- Not required for service users
  COMMENT = 'Service account for Matillion ETL operations';

-- Assign role to user
GRANT ROLE APP_MATILLION_ROLE TO USER APP_MATILLION_SVC;

-- Database & schema usage
GRANT USAGE ON DATABASE CALL_CENTER_ANALYTICS_DW TO ROLE APP_MATILLION_ROLE;
GRANT USAGE ON ALL SCHEMAS IN DATABASE CALL_CENTER_ANALYTICS_DW TO ROLE APP_MATILLION_ROLE;

-- Warehouse usage
GRANT OPERATE ON WAREHOUSE APP_STD_XSMALL_WH TO ROLE APP_MATILLION_ROLE;

GRANT USAGE ON WAREHOUSE APP_STD_XSMALL_WH TO ROLE APP_MATILLION_ROLE;

-- Stage usage

GRANT USAGE ON STAGE CALL_CENTER_DW.RAW.INT_STAGE_DOC_RAW TO ROLE APP_MATILLION_ROLE;
GRANT READ ON STAGE CALL_CENTER_DW.RAW.INT_STAGE_DOC_RAW TO ROLE APP_MATILLION_ROLE;
GRANT WRITE ON STAGE CALL_CENTER_DW.RAW.INT_STAGE_DOC_RAW TO ROLE APP_MATILLION_ROLE;

-- Table privileges (all current + future tables)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.RAW TO ROLE APP_MATILLION_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.STAGE TO ROLE APP_MATILLION_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.ANALYTICS TO ROLE APP_MATILLION_ROLE;

GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.RAW TO ROLE APP_MATILLION_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.STAGE TO ROLE APP_MATILLION_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA CALL_CENTER_ANALYTICS_DW.ANALYTICS TO ROLE APP_MATILLION_ROLE;
--------------------------------------------------------------------------
--------------------------------------------------------------------------
