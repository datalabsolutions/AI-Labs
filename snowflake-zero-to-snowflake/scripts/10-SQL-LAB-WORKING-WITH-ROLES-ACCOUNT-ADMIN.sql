-- =====================================================================
-- Module 10: Working with Roles, Account Admin, & Account Usage
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- This module explores Snowflake's access control security model:
-- creating a role and granting it specific permissions, plus the
-- ACCOUNTADMIN (Account Administrator) role.
--
-- Lab story: a junior DBA has joined the internal analytics team, and
-- we want to create a new role for them with fewer privileges than
-- the system-defined, default SYSADMIN role.

-- ---------------------------------------------------------------------
-- Step 1: Create a New Role and Add a User
-- ---------------------------------------------------------------------
-- Switch to ACCOUNTADMIN to create a new role. ACCOUNTADMIN
-- encapsulates the SYSADMIN and SECURITYADMIN system-defined roles —
-- it is the top-level role in the account and should be granted to
-- only a limited number of users.
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Before a role can be used for access control, at least one user must
-- be assigned to it. Create a new role named JUNIOR_DBA and assign it
-- to your Snowflake user. Replace YOUR_USERNAME_GOES_HERE with your
-- own username (the one you used to log in to the UI) before running
-- the GRANT ROLE command.
CREATE ROLE JUNIOR_DBA;

GRANT ROLE JUNIOR_DBA TO USER YOUR_USERNAME_GOES_HERE;

-- NOTE: attempting this while in a role such as SYSADMIN would fail
-- due to insufficient privileges — by design, SYSADMIN cannot create
-- new roles or users.

-- Change your worksheet context to the new JUNIOR_DBA role:
USE ROLE JUNIOR_DBA;

-- The warehouse will not be selected, because JUNIOR_DBA has no usage
-- privileges on any warehouse yet. Switch back to ACCOUNTADMIN and
-- grant usage on COMPUTE_WH:
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE JUNIOR_DBA;

-- Switch back to JUNIOR_DBA — you should now be able to use COMPUTE_WH:
USE ROLE JUNIOR_DBA;

USE WAREHOUSE COMPUTE_WH;

-- Note that the Public_Data and SNOWFLAKE_PUBLIC_DATA_FREE databases
-- no longer appear in the object browser panel — JUNIOR_DBA does not
-- yet have privileges to access them.
--
-- Switch back to ACCOUNTADMIN and grant JUNIOR_DBA the USAGE privilege
-- on both databases. Note the Marketplace-shared
-- SNOWFLAKE_PUBLIC_DATA_FREE database uses GRANT IMPORTED PRIVILEGES
-- instead of GRANT USAGE:
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON DATABASE PUBLIC_DATA TO ROLE JUNIOR_DBA;

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_PUBLIC_DATA_FREE TO ROLE JUNIOR_DBA;

USE ROLE JUNIOR_DBA;

-- Both databases should now appear in the object browser panel (click
-- ... > Refresh if they don't appear immediately).

-- ---------------------------------------------------------------------
-- Step 2: View the Account Administrator UI
-- ---------------------------------------------------------------------
-- Switch your UI session role (not the worksheet role) back to
-- ACCOUNTADMIN via the user preferences menu (click your name, bottom
-- left > Switch Role > ACCOUNTADMIN) to see UI areas only accessible
-- to that role:
--
--   Admin > Cost Management
--     Credit usage filtered by Organization, Compute, Storage, and
--     Data Transfer.
--
--   Admin > Security
--     Network policies for the account.
--
--   Admin > Billing & Terms
--     Payment method (contract details, or credit card for on-demand
--     billing).
--
-- NOTE: The UI session role and each worksheet's role are separate —
-- the UI session role controls what you see/access in the UI, while
-- the worksheet role controls only what you can do within that
-- worksheet. Stay in ACCOUNTADMIN (UI session) for the next module.
--
-- Continue to 11-SQL-LAB-SHARING-DATA-SECURELY.sql.
