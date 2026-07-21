-- =====================================================================
-- Module 09: Using Time Travel
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- Snowflake's Time Travel enables accessing historical data (and the
-- objects storing it) at any point within a period of time. The
-- default window is 24 hours, extendable up to 90 days on Enterprise
-- Edition or higher. Useful for:
--   - Restoring accidentally deleted tables/schemas/databases.
--   - Duplicating/backing up data from key points in the past.
--   - Analyzing data usage and manipulation over time.

-- ---------------------------------------------------------------------
-- Step 1: Drop and Undrop a Table
-- ---------------------------------------------------------------------
-- Remove the SEC_FILINGS_INDEX table:
-- ---------------------------------------------------------------------
DROP TABLE SEC_FILINGS_INDEX;

-- Run a query on the table (this will now error, since it was dropped):
SELECT * FROM SEC_FILINGS_INDEX LIMIT 10;

-- Now, restore the table:
UNDROP TABLE SEC_FILINGS_INDEX;

-- The SEC filing index table should be restored. Verify by running:
SELECT * FROM SEC_FILINGS_INDEX LIMIT 10;

-- ---------------------------------------------------------------------
-- Step 2: Roll Back a Table
-- ---------------------------------------------------------------------
-- Roll back COMPANY_METADATA in Public_Data to a previous state to fix
-- an unintentional DML error that replaces all company names with the
-- word "oops".
--
-- First, switch your worksheet to the proper context:
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;

USE WAREHOUSE COMPUTE_WH;

USE DATABASE PUBLIC_DATA;

USE SCHEMA PUBLIC;

-- Replace all of the company names in the table with the word "oops":
UPDATE COMPANY_METADATA SET COMPANY_NAME = 'oops';

-- Run a query that returns the companies. Notice the company names
-- are all the same:
SELECT *
FROM COMPANY_METADATA;

-- Normally we'd need to scramble and hope we have a backup. In
-- Snowflake, find the query ID of the last UPDATE command and store it
-- in a session variable named $QUERY_ID, then use Time Travel to
-- recreate the table with the correct company names:

-- Set the session variable for the query_id
SET query_id = (
  SELECT query_id
  FROM TABLE(information_schema.query_history_by_session(result_limit=>5))
  WHERE query_text LIKE 'UPDATE%'
  ORDER BY start_time DESC
  LIMIT 1
);

-- Use the session variable with the identifier syntax (e.g., $query_id)
CREATE OR REPLACE TABLE COMPANY_METADATA AS
SELECT *
FROM COMPANY_METADATA
BEFORE (STATEMENT => $query_id);

-- Verify the company names have been restored
SELECT *
FROM COMPANY_METADATA;

-- Continue to 10-SQL-LAB-WORKING-WITH-ROLES-ACCOUNT-ADMIN.sql.
