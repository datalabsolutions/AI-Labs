--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for analysis.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Create a search service
--------------------------------------------------------------------------
-- Include additional fields that could be used for filtering
--------------------------------------------------------------------------

CREATE OR REPLACE CORTEX SEARCH SERVICE CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE
ON TRANSCRIPT
ATTRIBUTES CALL_ID,PRIMARY_INTENT,URGENCY_LEVEL,CALL_CENTER_AGENT
WAREHOUSE = USER_STD_XSMALL_WH
TARGET_LAG = '1 Day'
AS 
(
    SELECT 
        ----------------------------------------------------
    -- Transcript (primary searchable text)
        ----------------------------------------------------
        TRANSCRIPT,
        ----------------------------------------------------
        -- Indexed Fields
        ----------------------------------------------------
        AUDIO_FILE_URL,
        ----------------------------------------------------
    -- Filters (available as filterable fields in queries)
        ----------------------------------------------------
        CALL_ID,
        CALL_CENTER_AGENT,
        PRIMARY_INTENT,
        URGENCY_LEVEL,
        ISSUE_RESOLVED
    FROM 
        CALL_CENTER_DB.ANALYTICS.CALL_CENTER_ANALYSIS
    WHERE 
        TRANSCRIPT IS NOT NULL
    AND LENGTH(TRANSCRIPT) > 50
);

--------------------------------------------------------------------------
-- Step 3: SEARCH_PREVIEW
--------------------------------------------------------------------------
-- Highlights:
--   - SEARCH_PREVIEW runs the service without persisting results.
--   - "query" searches the TRANSCRIPT text; 
--   - "limit" caps returned rows.
--   - "columns" requests additional indexed/selected fields returned alongside each hit.
--   - "filter" (shown below) constrains by filterable fields, e.g. urgency_level if present in the service definition.
--------------------------------------------------------------------------

SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW
    (
        'CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE',
        '{
            "query": "billing complaint",
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;

--------------------------------------------------------------------------
-- Step 4: SEARCH_PREVIEW
--------------------------------------------------------------------------

SELECT
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW
    (
        'CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE',
        '{
            "query": "billing complaint",
            "columns": ["CALL_ID", "CALL_CENTER_AGENT","AUDIO_FILE_URL"],
            "limit": 5
        }'
    ) AS SEARCH_RESULTS;
    
--------------------------------------------------------------------------
-- Step 5: SEARCH_PREVIEW
--------------------------------------------------------------------------

WITH CTE_SEARCH_PREVIEW
AS
(
    SELECT
        PARSE_JSON
        (
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW
            (
                'CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE',
                '{
                    "query": "billing complaint",
                    "columns": ["CALL_ID", "CALL_CENTER_AGENT","URGENCY_LEVEL"],
                    "limit": 5
                }'
            ) 
        ) AS SEARCH_RESULTS
)

SELECT
    SEARCH_RESULTS:"request_id"::string AS REQUEST_ID,
    REC.value:"CALL_ID"::string AS CALL_ID,
    REC.value:"CALL_CENTER_AGENT"::string AS CALL_CENTER_AGENT,
    REC.value:"URGENCY_LEVEL"::string AS URGENCY_LEVEL
FROM 
    CTE_SEARCH_PREVIEW,
LATERAL FLATTEN(input => SEARCH_RESULTS:"results") REC;

--------------------------------------------------------------------------
-- Step 6: SEARCH_PREVIEW
--------------------------------------------------------------------------

WITH CTE_SEARCH_PREVIEW
AS
(
    SELECT
        PARSE_JSON
        (
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW
            (
                'CALL_CENTER_DB.ANALYTICS.CALL_CENTER_SEARCH_SERVICE',
                '{
                    "query": "billing complaint",
                    "filter": { "@eq": { "URGENCY_LEVEL": "high" } },
                    "columns": ["CALL_ID", "CALL_CENTER_AGENT","URGENCY_LEVEL"],
                    "limit": 5
                }'
            ) 
        ) AS SEARCH_RESULTS
)

SELECT
    SEARCH_RESULTS:"request_id"::string AS REQUEST_ID,
    REC.value:"CALL_ID"::string AS CALL_ID,
    REC.value:"CALL_CENTER_AGENT"::string AS CALL_CENTER_AGENT,
    REC.value:"URGENCY_LEVEL"::string AS URGENCY_LEVEL
FROM 
    CTE_SEARCH_PREVIEW,
LATERAL FLATTEN(input => SEARCH_RESULTS:"results") REC;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

