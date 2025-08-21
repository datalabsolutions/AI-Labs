--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for analysis.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Create a view over the aggregated AI outputs
--------------------------------------------------------------------------
-- Combine results from our previous analysis steps into a unified view.
--------------------------------------------------------------------------

CREATE OR REPLACE VIEW CALL_CENTER_DB.ANALYTICS.CALL_CENTER_ANALYSIS
AS 
    SELECT
        TO_DATE(REGEXP_SUBSTR('CALL_20250728_10050', '\\d{8}'), 'YYYYMMDD') AS CALL_DATE,
        TRANSCRIBE_AUDIO_FILES.CALL_ID,
        TRANSCRIBE_AUDIO_FILES.AUDIO_FILE_URL,
        TRANSCRIBE_AUDIO_FILES.DURATION,      
        TRANSCRIBE_AUDIO_FILES_AGENT.CALL_CENTER_AGENT,
        TRANSCRIBE_AUDIO_FILES_CLASSIFY.CALL_TYPE,
        TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT.BRAND_SENTIMENT,
        TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT.COST_SENTIMENT,
        TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT.PRODUCT_SENTIMENT,
        TRANSCRIBE_AUDIO_FILES_OVERALL_SENTIMENT.OVERALL_SENTIMENT,
        TRANSCRIBE_AUDIO_FILES_ANALYSIS.PRIMARY_INTENT,
        TRANSCRIBE_AUDIO_FILES_ANALYSIS.URGENCY_LEVEL,
        TRANSCRIBE_AUDIO_FILES_ANALYSIS.ISSUE_RESOLVED,
        TRANSCRIBE_AUDIO_FILES_ANALYSIS.SUMMARY_ITEMS,
        TRANSCRIBE_AUDIO_FILES_ANALYSIS.ACTION_ITEMS,
        TRANSCRIBE_AUDIO_FILES_SUMMARY.TRANSCRIPT_SUMMARY,
        TRANSCRIBE_AUDIO_FILES.TRANSCRIPT
    FROM
        STAGE.TRANSCRIBE_AUDIO_FILES 
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_AGENT
        ON TRANSCRIBE_AUDIO_FILES_AGENT.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_CLASSIFY
        ON TRANSCRIBE_AUDIO_FILES_CLASSIFY.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT
        ON TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_OVERALL_SENTIMENT
        ON TRANSCRIBE_AUDIO_FILES_OVERALL_SENTIMENT.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_ANALYSIS
        ON TRANSCRIBE_AUDIO_FILES_ANALYSIS.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID
    LEFT JOIN STAGE.TRANSCRIBE_AUDIO_FILES_SUMMARY
        ON TRANSCRIBE_AUDIO_FILES_SUMMARY.CALL_ID = TRANSCRIBE_AUDIO_FILES.CALL_ID;

--------------------------------------------------------------------------
-- Step 3: Test the cortex search service
--------------------------------------------------------------------------
-- Test the search service with a sample query
--------------------------------------------------------------------------

SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW
    (
        'CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE',
        '{
            "query": "billing complaint negative sentiment",
            "limit": 5
        }'
    ) AS SEARCH_RESULTS

--------------------------------------------------------------------------
--------------------------------------------------------------------------


    