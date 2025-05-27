-- ==============================================================================
-- Step 1: Set Context
-- ==============================================================================
-- Sets the active database, schema, and warehouse to ensure that all
-- subsequent operations are executed within the correct environment.
-- ==============================================================================

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;


-- ==============================================================================
-- Step 2: Create Entity Sentiment Table
-- ==============================================================================
-- Creates a table named TRANSCRIPT_ENTITY_SENTIMENT to store:
--   - FILE_NAME: name of the input document
--   - PRODUCT_ENTITY_SENTIMENT: JSON object with sentiment analysis 
--     tied to specific entities or aspects of the transcript
--   - TRANSCRIPT: original transcript stored as a VARCHAR
-- ==============================================================================

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT (
    FILE_NAME VARCHAR,
    PRODUCT_ENTITY_SENTIMENT VARIANT,
    TRANSCRIPT VARCHAR
);


-- ==============================================================================
-- Step 3: Analyze Entity-Level Sentiment for a Specific File
-- ==============================================================================
-- Uses SNOWFLAKE.CORTEX.ENTITY_SENTIMENT to evaluate sentiment related to:
--   - Tone of voice
--   - Issue Resolved
--   - Follow up action
-- The result is a JSON (VARIANT) object.
-- ==============================================================================

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.ENTITY_SENTIMENT(
        TRANSCRIPT,
        ARRAY_CONSTRUCT('Tone of voice', 'Issue Resolved', 'Follow up action')
    ) AS PRODUCT_ENTITY_SENTIMENT,
    TRANSCRIPT
FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE FILE_NAME = 'audiofile11.pdf';


-- ==============================================================================
-- Step 4: Insert All Entity Sentiment Results into Table
-- ==============================================================================

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT
SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.ENTITY_SENTIMENT(
        TRANSCRIPT,
        ARRAY_CONSTRUCT('Tone of voice', 'Issue Resolved', 'Follow up action')
    ) AS PRODUCT_ENTITY_SENTIMENT,
    TRANSCRIPT
FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT;


-- ==============================================================================
-- Step 5: Create Final Sentiment Score Table
-- ==============================================================================
-- Transposes the sentiment JSON into columns:
--   - FOLLOW_UP_SCORE
--   - ISSUE_RESOLVED_SCORE
--   - TONE_OF_VOICE_SCORE
-- ==============================================================================

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT_FINAL 
(
    FILE_NAME VARCHAR,
    FOLLOW_UP_SCORE VARCHAR,
    ISSUE_RESOLVED_SCORE VARCHAR,
    TONE_OF_VOICE_SCORE VARCHAR
);


-- ==============================================================================
-- Step 6: Insert Transformed Sentiment Scores into Final Table
-- ==============================================================================

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT_FINAL
SELECT 
    FILE_NAME,

    MAX(CASE 
        WHEN category.value:name::STRING = 'Follow up action' 
        THEN category.value:sentiment::STRING 
    END) AS FOLLOW_UP_SCORE,

    MAX(CASE 
        WHEN category.value:name::STRING = 'Issue Resolved' 
        THEN category.value:sentiment::STRING 
    END) AS ISSUE_RESOLVED_SCORE,

    MAX(CASE 
        WHEN category.value:name::STRING = 'Tone of voice' 
        THEN category.value:sentiment::STRING 
    END) AS TONE_OF_VOICE_SCORE

FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT,
     LATERAL FLATTEN(INPUT => PRODUCT_ENTITY_SENTIMENT:categories) AS category

GROUP BY FILE_NAME;
