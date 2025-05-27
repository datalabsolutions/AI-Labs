--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse to ensure that 
-- subsequent operations are executed in the correct environment.
--------------------------------------------------------------------------

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Create Transcript Table
--------------------------------------------------------------------------
-- Creates a table named TRANSCRIPT in the STAGE schema to store the
-- file name and the extracted transcript content as VARCHAR.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT (
    FILE_NAME STRING,
    TRANSCRIPT VARCHAR
);

--------------------------------------------------------------------------
-- Step 3: Insert Extracted PDF Data into Table
--------------------------------------------------------------------------
-- Extracts text from PDF documents using SNOWFLAKE.CORTEX.PARSE_DOCUMENT.
-- The file path and name are parsed from the metadata of staged files.
-- The text content is extracted in 'LAYOUT' mode to preserve formatting.
-- Extracted results are inserted into the TRANSCRIPT table.
--------------------------------------------------------------------------

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
SELECT 
    FILE_NAME,
    TO_VARCHAR
    (
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @LLM_CORTEX_DEMO_DB.RAW.INT_STAGE_DOC_RAW,
            FILE_PATH,
            { 'mode': 'LAYOUT' }  
        ):content::string
    ) AS TRANSCRIPT
FROM
(
    SELECT DISTINCT
        METADATA$FILENAME AS FILE_PATH,
        SPLIT_PART(METADATA$FILENAME, '/', -1) AS FILE_NAME
    FROM
        @LLM_CORTEX_DEMO_DB.RAW.INT_STAGE_DOC_RAW/
) AS A;

--------------------------------------------------------------------------
-- Step 4: Preview Extracted Data
--------------------------------------------------------------------------
-- Queries the TRANSCRIPT table to display the list of files along with
-- their extracted transcript content for validation.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    TRANSCRIPT
FROM 
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT;

--------------------------------------------------------------------------
