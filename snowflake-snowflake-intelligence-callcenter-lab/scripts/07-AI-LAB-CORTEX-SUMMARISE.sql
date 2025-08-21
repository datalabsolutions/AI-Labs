--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for summarization.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Summarize Transcripts (Example)
--------------------------------------------------------------------------
-- Summarizes each transcript using SNOWFLAKE.CORTEX.SUMMARIZE.
-- Adjust prompt/parameters as needed for your use case.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    TRANSCRIPT,
    SNOWFLAKE.CORTEX.SUMMARIZE
    (
        TRANSCRIPT
    ) AS TRANSCRIPT_SUMMARY
FROM
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;

-- Step 3: Persist Summaries
--------------------------------------------------------------------------
-- Saves summaries into a table for reuse.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_SUMMARY
AS
    SELECT
        CALL_ID,
        SNOWFLAKE.CORTEX.SUMMARIZE
        (
            TRANSCRIPT
        ) AS TRANSCRIPT_SUMMARY
    FROM
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;

--------------------------------------------------------------------------
-- Step 4: Preview Summaries
--------------------------------------------------------------------------
-- Displays a sample of saved summaries for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_SUMMARY LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------