USE ROLE ACCOUNTADMIN;
USE WAREHOUSE USER_STD_XSMALL_WH;
USE DATABASE CALL_CENTER_ANALYTICS_DW;
USE SCHEMA EXTRACT;

-------------------------------------------------------
-- CHECK FILES IN STAGE
-------------------------------------------------------

LIST @EXTRACT.INT_STAGE_DOC;

-------------------------------------------------------
-- EXTRACT TABLES
-------------------------------------------------------

SELECT * FROM EXTRACT.AUDIO_FILES;

SELECT * FROM EXTRACT.LOOKUP;

-------------------------------------------------------
-- STAGE TABLES
-------------------------------------------------------

SELECT * FROM STAGE.AUDIO_TRANSCRIPT;

SELECT * FROM STAGE.AUDIO_TRANSCRIPT_ANALYSIS;

-------------------------------------------------------
-- STAGE TABLES
-------------------------------------------------------

SELECT * FROM DWH.DIM_AGENT;

SELECT * FROM DWH.DIM_CALL_PRIORITY;

SELECT * FROM DWH.DIM_CALL_SENTIMENT;

SELECT * FROM DWH.DIM_CALL_STATUS;

SELECT * FROM DWH.DIM_CALL_TYPE;

-------------------------------------------------------

SELECT * FROM DWH.FCT_CALL_TRANSCRIPT;

-------------------------------------------------------
/*
TRUNCATE TABLE DWH.DIM_CALL_PRIORITY;
TRUNCATE TABLE DWH.DIM_CALL_SENTIMENT;
TRUNCATE TABLE DWH.DIM_CALL_STATUS;
TRUNCATE TABLE DWH.DIM_CALL_TYPE;
TRUNCATE TABLE DWH.FCT_CALL_TRANSCRIPT;
*/
-------------------------------------------------------


