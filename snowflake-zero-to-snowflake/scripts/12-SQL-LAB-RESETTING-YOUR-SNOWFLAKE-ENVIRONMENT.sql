-- =====================================================================
-- Module 12: Resetting Your Snowflake Environment
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- ---------------------------------------------------------------------
-- Step 1: Reset Your Snowflake Environment
-- ---------------------------------------------------------------------
-- If you would like to reset your environment by deleting all the
-- objects created as part of this lab, ensure you are using the
-- ACCOUNTADMIN role in the worksheet and run the following commands to
-- drop the objects created in the lab:
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

DROP DATABASE IF EXISTS PUBLIC_DATA;

DROP WAREHOUSE IF EXISTS ANALYTICS_WH;

DROP ROLE IF EXISTS JUNIOR_DBA;

-- Continue to 13-SQL-LAB-CONCLUSION-AND-NEXT-STEPS.sql.
