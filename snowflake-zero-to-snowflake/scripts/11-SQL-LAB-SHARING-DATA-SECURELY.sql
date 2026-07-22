-- =====================================================================
-- Module 11: Sharing Data Securely via Snowflake Marketplace
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- Snowflake enables data access between accounts through secure data
-- sharing. Shares are created by data providers and imported by data
-- consumers (their own Snowflake account, or a Snowflake Reader
-- account). With secure data sharing:
--   - Only one copy of the data lives in the provider's account.
--   - Shared data is always live, real-time, and immediately available.
--   - Providers can grant revocable, fine-grained access to shares.
--   - No manual/insecure transfer (e.g. large .csv files) is needed.
--
-- (Cross-region/cross-cloud sharing requires replication — out of
-- scope for this lab.)
--
-- Secure data sharing also powers the Snowflake Data Marketplace
-- (Module 07) — the data never leaves the provider's account and can
-- be used without transformation.

-- ---------------------------------------------------------------------
-- Step 1: View Existing Shares
-- ---------------------------------------------------------------------
-- Navigate to Data > Databases. In the SOURCE column, one database
-- shows "Local" (created earlier in this lab), and SNOWFLAKE shows
-- "Share" — indicating it's shared from a provider.
-- (Optional exploratory query — not part of the original lab text)
SHOW SHARES;

-- ---------------------------------------------------------------------
-- Step 2: Create an Outbound Share
-- ---------------------------------------------------------------------
-- Assume you are the Account Administrator. A trusted partner (with
-- their own Snowflake account in the same region) wants to analyze
-- your data on a near real-time basis via secure data sharing.
--
-- Navigate to Data Products > Private Sharing > Shared By Your
-- Account. Click Share (top right) > Create a Direct Share.
-- Click + Select Data, choose the database/schema/tables to share,
-- click Done. Rename the default share to something descriptive, e.g.
-- ZERO_TO_SNOWFLAKE_SHARED_DATA, optionally add a comment.
-- (In a real scenario you would next add one or more consumer
-- accounts — skipped here for lab purposes.) Click Create Share.
--
-- (Equivalent SQL — the lab performs this step via the "Create a
-- Direct Share" UI wizard)
-- ---------------------------------------------------------------------
CREATE OR REPLACE SHARE ZERO_TO_SNOWFLAKE_SHARED_DATA
    COMMENT = 'Share created during the Zero to Snowflake lab';

GRANT USAGE ON DATABASE PUBLIC_DATA TO SHARE ZERO_TO_SNOWFLAKE_SHARED_DATA;
GRANT USAGE ON SCHEMA PUBLIC_DATA.PUBLIC TO SHARE ZERO_TO_SNOWFLAKE_SHARED_DATA;
GRANT SELECT ON TABLE PUBLIC_DATA.PUBLIC.COMPANY_METADATA TO SHARE ZERO_TO_SNOWFLAKE_SHARED_DATA;

-- You can add consumer accounts, change the description, and edit the
-- shared objects at any time. In addition to tables, you can share
-- secure views, secure UDFs, and other secure objects to prevent
-- access to sensitive underlying data.
--
-- Continue to 12-SQL-LAB-RESETTING-YOUR-SNOWFLAKE-ENVIRONMENT.sql.
