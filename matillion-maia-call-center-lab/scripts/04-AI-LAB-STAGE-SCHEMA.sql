--------------------------------------------------------------------------------
-- Script: Create Stage Layer Tables (Combined)
-- Description: Consolidated DDL for STAGE-layer tables: AUDIO_TRANSCRIPT and
--              AUDIO_TRANSCRIPT_ANALYSIS used for call center analytics.
-- Database: CALL_CENTER_ANALYTICS_DW
-- Schema:   STAGE
--------------------------------------------------------------------------------

USE DATABASE CALL_CENTER_ANALYTICS_DW;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------------
-- STAGE.AUDIO_TRANSCRIPT
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STAGE.AUDIO_TRANSCRIPT
(
    CALL_TRANSCRIPT_ID VARCHAR COMMENT 'Unique identifier linking transcription back to source audio file',
    FILE_PATH          VARCHAR COMMENT 'Path where the source audio file is stored',
    AUDIO_FILE_URL     VARCHAR COMMENT 'External URL reference to the source audio file',
    FILE_SIZE          NUMBER(38,0) COMMENT 'Size of the original audio file in bytes',
    LAST_MODIFIED      TIMESTAMP_TZ(3) COMMENT 'Timestamp when the source file was last updated',
    TRANSCRIPT_JSON    VARIANT COMMENT 'Raw transcript output in JSON format',
    DURATION           NUMBER COMMENT 'Length of the audio recording in seconds',
    TRANSCRIPT         TEXT COMMENT 'Plain text transcript generated from audio file',
    TRANSCRIPTION_DATE TIMESTAMP_LTZ COMMENT 'Date and time when the transcription was performed',
    CHARACTER_COUNT    NUMBER COMMENT 'Number of characters in the transcript text',
    WORD_COUNT         NUMBER COMMENT 'Number of words in the transcript text'
)
COMMENT = 'Stage table containing audio transcription results and enriched metadata for analytics';

--------------------------------------------------------------------------------
-- STAGE.AUDIO_TRANSCRIPT_ANALYSIS
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STAGE.AUDIO_TRANSCRIPT_ANALYSIS
(
    CALL_TRANSCRIPT_ID   VARCHAR       COMMENT 'Unique identifier linking transcription back to source audio file',
    CALL_SUMMARY         VARCHAR(1000) COMMENT 'AI-generated summary of the call',
    CALL_TRANSCRIPT      VARCHAR(5000) COMMENT 'Full transcript text of the call',
    CALL_DATE            DATE          COMMENT 'Date when the call occurred',
    AGENT_CODE           VARCHAR(50)   COMMENT 'Initials identifying the call center agent',
    AGENT_NAME           VARCHAR(50)   COMMENT 'Name identifying the call center agent',
    CALL_TYPE_CODE       VARCHAR(50)   COMMENT 'Code indicating the type of call',
    CALL_SENTIMENT_CODE  VARCHAR(50)   COMMENT 'Overall sentiment score for the call',
    CALL_PRIORITY_CODE   VARCHAR(50)   COMMENT 'Code indicating call priority level',
    CALL_STATUS_CODE     VARCHAR(50)   COMMENT 'Code indicating the final status of the call',
    CALL_DURATION        NUMBER        COMMENT 'Length of the audio recording in seconds',
    CALL_CHARACTER_COUNT NUMBER        COMMENT 'Number of characters in the transcript text',
    CALL_WORD_COUNT      NUMBER        COMMENT 'Number of words in the transcript text',
    CALL_SENTIMENT_SCORE FLOAT         COMMENT 'Overall sentiment score for the call'
)
COMMENT = 'Stage table containing audio transcription results and enriched metadata for analytics';

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
