--------------------------------------------------------------------------
-- Step 1: Create Database
--------------------------------------------------------------------------
-- This step initializes the primary database for the LLM Cortex demo environment.
-- It ensures the database exists before continuing with the rest of the setup.
--------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS LLM_CORTEX_DEMO_DB;

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

--------------------------------------------------------------------------
-- Step 3: Create Schemas
--------------------------------------------------------------------------
-- This step creates two schemas within the LLM_CORTEX_DEMO_DB database:
-- - RAW: for storing unprocessed or ingested data
-- - STAGE: for temporary or intermediate processed data
--------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS LLM_CORTEX_DEMO_DB.RAW;
CREATE SCHEMA IF NOT EXISTS LLM_CORTEX_DEMO_DB.STAGE;

--------------------------------------------------------------------------
-- Step 4: Create Internal Stage for PDFs
--------------------------------------------------------------------------
-- This step defines an internal stage in the RAW schema to store uploaded PDF documents.
-- The stage supports directory table creation and uses Snowflake-managed SSE encryption.
--------------------------------------------------------------------------

CREATE OR REPLACE STAGE LLM_CORTEX_DEMO_DB.RAW.INT_STAGE_DOC_RAW
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

--------------------------------------------------------------------------
