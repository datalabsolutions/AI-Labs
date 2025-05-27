--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the working context to the LLM_CORTEX_DEMO_DB database, STAGE schema,
-- and the compute warehouse USER_STD_XSMALL_WH.
--------------------------------------------------------------------------

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Create Transcript Caller Table
--------------------------------------------------------------------------
-- Creates a new table to store structured metadata extracted from transcripts:
-- - FILE_NAME: source document
-- - CALLER_NAME: extracted name of the caller
-- - CALL_DATE: date of the call (if mentioned)
-- - CALL_DURATION: duration of the call in minutes or seconds
-- - TRANSCRIPT: full transcript text
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CALLER 
(
    FILE_NAME VARCHAR,
    CALLER_NAME VARCHAR,
    CALL_DATE DATE,
    CALL_DURATION FLOAT,
    TRANSCRIPT VARCHAR
);

--------------------------------------------------------------------------
-- Step 3: Extract Caller Name (Simple Test)
--------------------------------------------------------------------------
-- Uses SNOWFLAKE.CORTEX.EXTRACT_ANSWER with a plain-text question 
-- to extract the caller's name from a transcript.
-- This version hardcodes the question into the function.
--------------------------------------------------------------------------

SELECT TOP 1
    FILE_NAME,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
        'What is the name of the customer speaking in this transcript? Only return the name.',
        TRANSCRIPT
    ) AS CALLER_NAME,
    TRANSCRIPT AS TRANSCRIPT
FROM 
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT;

--------------------------------------------------------------------------
-- Step 4: Extract Caller Name (With WHERE clause)
--------------------------------------------------------------------------
-- Another variant of extracting the caller's name using a different
-- argument order and filtering for a specific file.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER
    (
        TRANSCRIPT,
        'What is the name of the caller?'
    ) AS CALLER_NAME,
    TRANSCRIPT AS TRANSCRIPT
FROM 
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 5: Extract and Parse Response Struct
--------------------------------------------------------------------------
-- Uses EXTRACT_ANSWER and accesses the structured response array.
-- Extracts both the `answer` and the confidence `score` from the response object.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER
    (
        TRANSCRIPT,
        'What is the name of the caller?'
    ) AS RESPONSE,
    RESPONSE[0]:answer::string AS CALLER_NAME,
    RESPONSE[0]:score::float AS CALLER_SCORE,
    TRANSCRIPT AS TRANSCRIPT
FROM 
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 6: Insert Extracted Data into TRANSCRIPT_CALLER Table
--------------------------------------------------------------------------
-- Performs full extraction and transformation:
-- - Extracts CALLER_NAME, CALL_DATE, and CALL_DURATION using EXTRACT_ANSWER
-- - Applies string cleaning and conversion functions
-- - Inserts the structured results into the TRANSCRIPT_CALLER table
--------------------------------------------------------------------------

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CALLER  
SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.EXTRACT_ANSWER
    (
        TRANSCRIPT,
        'What is the name of the caller?'
    )[0]:answer::string AS CALLER_NAME,
    
    TRY_TO_DATE(REPLACE(SNOWFLAKE.CORTEX.EXTRACT_ANSWER
    (
        TRANSCRIPT,
        'What is the Date of the call?'
    )[0]:answer::string,' ','')) AS CALL_DATE,
    
    TRY_TO_NUMBER(REPLACE(SNOWFLAKE.CORTEX.EXTRACT_ANSWER
    (
        TRANSCRIPT,
        'What is the call duration?'
    )[0]:answer::string,' ','')) AS CALL_DURATION,

    TRANSCRIPT AS TRANSCRIPT
FROM 
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT;

--------------------------------------------------------------------------
-- Step 7: Preview Transcript Caller Table
--------------------------------------------------------------------------
-- Displays all structured data extracted and inserted into the TRANSCRIPT_CALLER table.
--------------------------------------------------------------------------

SELECT * FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CALLER;

--------------------------------------------------------------------------
