--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse to ensure that 
-- subsequent operations are executed in the correct environment.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA RAW;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: List Staged Audio Files
--------------------------------------------------------------------------
-- Lists audio files available in the internal stage for processing.
--------------------------------------------------------------------------

LIST @CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW/;

--------------------------------------------------------------------------
-- Step 3: Create Audio Files Table
--------------------------------------------------------------------------
-- Creates a table with FILE objects and metadata from the staged audio
-- files to drive batch transcription.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.RAW.AUDIO_FILES 
AS
    SELECT 
        RELATIVE_PATH AS "FILE_PATH",
        TO_FILE('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW', RELATIVE_PATH) AS "AUDIO_FILE",
        BUILD_STAGE_FILE_URL('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW',RELATIVE_PATH) AS "AUDIO_FILE_URL",
        SIZE AS "FILE_SIZE",
        LAST_MODIFIED,
        SPLIT_PART(RELATIVE_PATH, '.', -1) AS "FILE_EXTENSION",
        REPLACE(RELATIVE_PATH, '.mp3', '') AS "CALL_ID"
    FROM 
        DIRECTORY('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW')
    WHERE 
        RELATIVE_PATH ILIKE '%.mp3' 
    OR  RELATIVE_PATH ILIKE '%.wav';

--------------------------------------------------------------------------
-- Step 4: Preview Audio Files
--------------------------------------------------------------------------
-- Verifies that AUDIO_FILES has been populated as expected.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.RAW.AUDIO_FILES LIMIT 1;

--------------------------------------------------------------------------
-- Step 5: Transcribe Audio Files
--------------------------------------------------------------------------
-- Performs AI transcription and persists results, including transcript,
-- basic quality checks, and simple metrics.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES 
AS
    SELECT 
        CALL_ID,
        FILE_PATH,
        AUDIO_FILE_URL,
        FILE_SIZE,
        LAST_MODIFIED,
        AI_TRANSCRIBE(AUDIO_FILE) AS "TRANSCRIPT_JSON",
        TRANSCRIPT_JSON:audio_duration::FLOAT AS "DURATION",
        TRANSCRIPT_JSON:text::STRING AS "TRANSCRIPT",
        CURRENT_TIMESTAMP() AS "TRANSCRIPTION_DATE",
        LENGTH(TRANSCRIPT) AS "CHARACTER_COUNT",
        ARRAY_SIZE(SPLIT(TRANSCRIPT, ' ')) AS "WORD_COUNT",
        CASE 
            WHEN TRANSCRIPT IS NULL THEN 'FAILED'
            WHEN CHARACTER_COUNT < 10 THEN 'SHORT'
            ELSE 'SUCCESS'
        END AS "TRANSCRIPT_STATUS"
    FROM 
        CALL_CENTER_DB.RAW.AUDIO_FILES
    ORDER BY
        FILE_SIZE ASC;  

--------------------------------------------------------------------------
-- Step 6: Preview Transcriptions
--------------------------------------------------------------------------
-- Displays a sample of transcribed rows for validation.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------