--------------------------------------------------------------------------
-- Step 1: Create Database
--------------------------------------------------------------------------
-- This step initializes the primary database for the Cortex Analyst lab environment.
-- It ensures the database exists before continuing with the rest of the setup.
--------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS CORTEX_ANALYST_DB;

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
  WAREHOUSE_SIZE = XSMALL
  WAREHOUSE_TYPE = STANDARD
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

--------------------------------------------------------------------------
-- Step 3: Create Schema
--------------------------------------------------------------------------
-- This step creates the DATA schema for your semantic model and transformed data.
--------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS CORTEX_ANALYST_DB.DATA;

--------------------------------------------------------------------------
-- Step 4: Create Internal Stage for Semantic Model YAML
--------------------------------------------------------------------------
-- This step defines an internal stage in the DATA schema to store uploaded semantic model YAML files.
-- The stage supports directory table creation and uses Snowflake-managed SSE encryption.
--------------------------------------------------------------------------

CREATE OR REPLACE STAGE CORTEX_ANALYST_DB.DATA.SEMANTIC_MODEL
  DIRECTORY = ( ENABLE = TRUE )
  ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

--------------------------------------------------------------------------
-- Step 5: (Manual) Subscribe to Finance & Economics Dataset
--------------------------------------------------------------------------
-- To access financial data:
-- 1. Navigate to Data Products > Marketplace in Snowsight
-- 2. Search and select Finance & Economics
-- 3. Click Get, name the database FINANCE_ECONOMICS, and assign to role PUBLIC
--------------------------------------------------------------------------
