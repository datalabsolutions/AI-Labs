--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the working environment to use the correct database, schema, 
-- and compute warehouse for all subsequent operations.
--------------------------------------------------------------------------

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Create Transcript Classification Table
--------------------------------------------------------------------------
-- Creates a table named TRANSCRIPT_CLASSIFICATION to store:
-- - FILE_NAME: the name of the source PDF
-- - CALL_CLASSIFICATION: the classified label for the call
-- - TRANSCRIPT: the full transcript text
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CLASSIFICATION 
(
    FILE_NAME VARCHAR,
    CALL_CLASSIFICATION VARCHAR,
    TRANSCRIPT VARCHAR
);

--------------------------------------------------------------------------
-- Step 3: Preview Classification for a Specific Transcript
--------------------------------------------------------------------------
-- Uses SNOWFLAKE.CORTEX.CLASSIFY_TEXT to classify a specific transcript
-- into one of the following categories:
-- - Report Incident
-- - Complaint
-- - Follow up
-- Useful for validating classification behavior before bulk operations.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT
    (
        TRANSCRIPT,
        ARRAY_CONSTRUCT('Report Incident', 'Complaint', 'Follow up')
    ) AS CALL_CLASSIFICATION,
    TRANSCRIPT
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 4: Insert Call Classifications into Table
--------------------------------------------------------------------------
-- Classifies all transcripts in the table using the specified labels.
-- Extracts the label from the Cortex classification result and inserts
-- it into the TRANSCRIPT_CLASSIFICATION table.
--------------------------------------------------------------------------

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CLASSIFICATION 
SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT
    (
        TRANSCRIPT,
        ARRAY_CONSTRUCT('Report Incident', 'Complaint', 'Follow up')
    ):label::string AS CALL_CLASSIFICATION,
    TRANSCRIPT
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT;

--------------------------------------------------------------------------
-- Step 5: View Classification Results
--------------------------------------------------------------------------
-- Queries the TRANSCRIPT_CLASSIFICATION table to confirm that each
-- transcript has been correctly labeled.
--------------------------------------------------------------------------

SELECT
    *
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CLASSIFICATION;

--------------------------------------------------------------------------
