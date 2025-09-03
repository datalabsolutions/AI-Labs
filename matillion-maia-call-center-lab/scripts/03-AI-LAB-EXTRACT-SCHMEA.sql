--------------------------------------------------------------------------------
-- Script: Create Extract Layer Tables (Combined)
-- Description: Consolidated DDL for EXTRACT-layer tables used in audio intake
--              and reference lookups for call center analytics.
-- Database: CALL_CENTER_ANALYTICS_DW
-- Schema:   EXTRACT
--------------------------------------------------------------------------------
--SET CONTEXT
--------------------------------------------------------------------------------

USE DATABASE CALL_CENTER_ANALYTICS_DW;
USE SCHEMA EXTRACT;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------------
-- AUDIO_FILES (Extract)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS EXTRACT.AUDIO_FILES
(
    CALL_TRANSCRIPT_ID VARCHAR COMMENT 'Unique identifier for each audio file record',
    FILE_PATH          VARCHAR COMMENT 'Path where the audio file is stored',
    AUDIO_FILE         FILE    COMMENT 'Binary audio file content',
    AUDIO_FILE_URL     VARCHAR COMMENT 'External URL reference to the audio file',
    FILE_SIZE          NUMBER(38,0) COMMENT 'Size of the audio file in bytes',
    LAST_MODIFIED      TIMESTAMP_TZ(3) COMMENT 'Date and time when the file was last modified',
    FILE_EXTENSION     VARCHAR COMMENT 'File extension indicating audio format (e.g., wav, mp3)'
)
COMMENT = 'Extract table containing audio files and metadata for transcription and analytics';

--------------------------------------------------------------------------------
-- LOOKUP (Extract)
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS EXTRACT.LOOKUP 
(
    LOOKUP_FILTER      VARCHAR COMMENT 'Category or type of lookup (e.g., CALL_TYPE)',
    LOOKUP_ID          NUMBER  COMMENT 'Unique identifier for the lookup entry',
    LOOKUP_CODE        VARCHAR COMMENT 'Short code representing the lookup value',
    LOOKUP_LOWER_BOUND FLOAT   COMMENT 'Lower boundary value for numeric ranges if applicable',
    LOOKUP_UPPER_BOUND FLOAT   COMMENT 'Upper boundary value for numeric ranges if applicable',
    LOOKUP_SHORT_NAME  VARCHAR COMMENT 'Brief display name for the lookup value',
    LOOKUP_LONG_NAME   VARCHAR COMMENT 'Full display name for the lookup value',
    LOOKUP_DESC        VARCHAR COMMENT 'Detailed description of the lookup value',
    LOOKUP_SORT_ORDER  NUMBER  COMMENT 'Sorting order for display purposes'
)
COMMENT = 'Reference table containing lookup values and their descriptions for various categories used in the call center analytics system';

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
