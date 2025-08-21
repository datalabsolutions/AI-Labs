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
-- Step 2: Category Sentiment Score
--------------------------------------------------------------------------
-- Uses SNOWFLAKE.CORTEX.AI_SENTIMENT to score specified categories
-- for each call transcript.
-- Categories analyzed: 'Brand', 'Cost', 'Product'.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    TRANSCRIPT,
    SNOWFLAKE.CORTEX.AI_SENTIMENT
    (
        TRANSCRIPT,
        ARRAY_CONSTRUCT('Brand', 'Cost', 'Product')
    ) AS ENTITY_SENTIMENT
FROM
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;
        
--------------------------------------------------------------------------
-- Step 3: Transpose Category Sentiment
--------------------------------------------------------------------------
-- Flattens the category sentiment results into rows with category name
-- and associated sentiment score for easier inspection.
--------------------------------------------------------------------------

WITH CTE_ENTITY_SENTIMENT
AS
(
    SELECT
        CALL_ID,
        TRANSCRIPT,
        SNOWFLAKE.CORTEX.AI_SENTIMENT
        (
            TRANSCRIPT,
            ARRAY_CONSTRUCT('Brand', 'Cost', 'Product')
        ) AS ENTITY_SENTIMENT
    FROM
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES AS SRC

)

SELECT
    CALL_ID,
    TRANSCRIPT,
    CAT.value:name::TEXT AS "CATEGORY",
    CAT.value:sentiment::TEXT AS "SENTIMENT"
FROM
    CTE_ENTITY_SENTIMENT AS SRC,
LATERAL FLATTEN(INPUT => SRC.ENTITY_SENTIMENT:"categories") AS CAT;

--------------------------------------------------------------------------
-- Step 4: Persist Category Sentiment (Pivoted)
--------------------------------------------------------------------------
-- Creates a table with one row per call, pivoting category sentiment
-- into separate columns for 'Brand', 'Cost', and 'Product'.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT
AS

    WITH CTE_ENTITY_SENTIMENT
    AS
    (
        SELECT
            CALL_ID,
            TRANSCRIPT,
            SNOWFLAKE.CORTEX.AI_SENTIMENT
            (
                TRANSCRIPT,
                ARRAY_CONSTRUCT('Brand', 'Cost', 'Product')
            ) AS ENTITY_SENTIMENT
        FROM
            CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES AS SRC
    )

    SELECT 
        CALL_ID,
        MAX(CASE WHEN CAT.value:name::TEXT = 'Brand' THEN CAT.value:sentiment::TEXT END) AS BRAND_SENTIMENT,
        MAX(CASE WHEN CAT.value:name::STRING = 'Cost' THEN CAT.value:sentiment::STRING END) AS COST_SENTIMENT,
        MAX(CASE WHEN CAT.value:name::STRING = 'Product' THEN CAT.value:sentiment::STRING END) AS PRODUCT_SENTIMENT
    FROM 
        CTE_ENTITY_SENTIMENT AS SRC,
    LATERAL FLATTEN(INPUT => SRC.ENTITY_SENTIMENT:"categories") AS CAT
    GROUP BY
        CALL_ID,
        TRANSCRIPT;

--------------------------------------------------------------------------
-- Step 5: Preview Persisted Results
--------------------------------------------------------------------------
-- Displays the saved category sentiment scores for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_ENTITY_SENTIMENT LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------