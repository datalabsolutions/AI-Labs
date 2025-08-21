--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse to ensure that 
-- subsequent operations are executed in the correct environment.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Overall Sentiment Score
--------------------------------------------------------------------------
-- Computes overall sentiment for each transcript and orders by score.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    TRANSCRIPT,
    SNOWFLAKE.CORTEX.SENTIMENT(TRANSCRIPT) AS OVERALL_SENTIMENT
FROM
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
ORDER BY 
    OVERALL_SENTIMENT DESC;

--------------------------------------------------------------------------
-- Step 3: Persist Overall Sentiment
--------------------------------------------------------------------------
-- Saves overall sentiment per call into a table for reuse.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_OVERALL_SENTIMENT 
AS
    SELECT
        CALL_ID,
        TRANSCRIPT,
        SNOWFLAKE.CORTEX.SENTIMENT(TRANSCRIPT) AS OVERALL_SENTIMENT
    FROM
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    ORDER BY 
        OVERALL_SENTIMENT DESC;

--------------------------------------------------------------------------
-- Step 4: View Sentiment Scores
--------------------------------------------------------------------------
-- Displays the saved sentiment scores for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_OVERALL_SENTIMENT LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------