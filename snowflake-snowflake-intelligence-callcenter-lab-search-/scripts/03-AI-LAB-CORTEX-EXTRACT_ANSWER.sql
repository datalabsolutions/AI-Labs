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
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(TRANSCRIPT,'What is the name of the caller center agent?') AS AGENT_JSON,
    AGENT_JSON[0]:answer::TEXT AS CALL_CENTER_AGENT,
    AGENT_JSON[0]:score::TEXT AS CALL_CENTER_AGENT_SCORE
FROM
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;

--------------------------------------------------------------------------
-- Step 3: Persist Overall Sentiment
--------------------------------------------------------------------------
-- Saves overall sentiment per call into a table for reuse.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_AGENT
AS

    WITH CTE_AGENT
    AS
    (
        SELECT
            CALL_ID,
            TRANSCRIPT,
            SNOWFLAKE.CORTEX.EXTRACT_ANSWER(TRANSCRIPT,'What is the name of the caller center agent?') AS AGENT_JSON,
            AGENT_JSON[0]:answer::TEXT AS CALL_CENTER_AGENT
        FROM
            CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    )

    SELECT
        CALL_ID,
        TRANSCRIPT,
        CALL_CENTER_AGENT
    FROM
        CTE_AGENT;
        
--------------------------------------------------------------------------
-- Step 4: View Sentiment Scores
--------------------------------------------------------------------------
-- Displays the saved sentiment scores for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_AGENT LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
