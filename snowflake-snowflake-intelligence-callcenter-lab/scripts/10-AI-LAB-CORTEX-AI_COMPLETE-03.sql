--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for analysis.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;


--------------------------------------------------------------------------
-- Step 2: Preview aggregated results for a single call
--------------------------------------------------------------------------
-- Highlights:
--   - AI_COMPLETE with response_format (JSON Schema) to extract
--     structured fields (type, intent, urgency, bullets, action items).
--   - LATERAL FLATTEN to expand arrays into rows.
--   - AI_AGG to combine many text rows into concise outputs.
-- Differences vs. persistence step: Filters to a single CALL_ID for inspection.
--------------------------------------------------------------------------

WITH CTE_RESULTS
AS
(
    SELECT
        CALL_ID,
        AI_COMPLETE
        (
            model => 'claude-4-sonnet',
            prompt => CONCAT('Extract structured data from this call center transcript. <Transcript>', TRANSCRIPT, '</Transcript>'),
            model_parameters => {'temperature': 0.1, 'max_tokens': 4096, 'guardrails': FALSE},
            response_format => 
            {
                'type': 'json',
                'schema': 
                {
                    'type': 'object',
                    'properties': {
                        'call_type': { 'type': 'string', 'enum': ['inbound','outbound','transfer'], 'description': 'Overall direction of the call.' },
                        'primary_intent': { 'type': 'string', 'enum': ['billing','technical_support','complaint','information','sales','cancellation','other'], 'description': 'Main reason for contact.' },
                        'urgency_level': { 'type': 'string', 'enum': ['low','medium','high','critical'], 'description': 'Urgency inferred from the conversation.' },
                        'issue_resolved': {'type': 'string', 'enum': ['yes', 'no', 'partial']},
                        'summary_bullets': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Three concise bullets.' },
                        'action_items': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Concrete next steps.' }
                    },
                    'required': ['call_type','primary_intent','urgency_level','summary_bullets','action_items']
                }
            }
        )::VARIANT AS SUMMARY_JSON
    FROM 
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    WHERE 
        CALL_ID = 'CALL_20250728_10050'
),

CTE_ACTION_ITEMS
AS
(
    SELECT
        SRC.CALL_ID,
        AI.value::string AS ACTION_ITEM
    FROM 
        CTE_RESULTS SRC,
    LATERAL FLATTEN(input => SRC.SUMMARY_JSON:action_items) AI
),

CTE_SUMMARY_ITEMS
AS 
(
    SELECT
        SRC.CALL_ID,
        SI.value::string AS SUMMARY_ITEM
    FROM 
        CTE_RESULTS SRC,
    LATERAL FLATTEN(input => SRC.SUMMARY_JSON:summary_bullets) SI
),

CTE_ROLLUPS 
AS 
(
    SELECT
        SRC.CALL_ID,
        SRC.SUMMARY_JSON:call_type::string AS CALL_TYPE,
        SRC.SUMMARY_JSON:primary_intent::string AS PRIMARY_INTENT,
        SRC.SUMMARY_JSON:urgency_level::string AS URGENCY_LEVEL,
        SRC.SUMMARY_JSON:issue_resolved::string AS ISSUE_RESOLVED,
        AI_AGG(SI.SUMMARY_ITEM, 'Combine these bullets into one concise sentence (<=40 words), keep key facts.') AS SUMMARY_ITEMS,
        AI_AGG(AI.ACTION_ITEM, 'Combine these into one sentence of action items; retain dates/time windows precisely.') AS ACTION_ITEMS
    FROM 
        CTE_RESULTS SRC
    LEFT JOIN CTE_SUMMARY_ITEMS SI 
        ON SI.CALL_ID = SRC.CALL_ID
    LEFT JOIN CTE_ACTION_ITEMS AI  
        ON AI.CALL_ID = SRC.CALL_ID
    GROUP BY 1,2,3,4,5
)

SELECT * FROM CTE_ROLLUPS;

--------------------------------------------------------------------------
-- Step 3: Persist aggregated results across the dataset
--------------------------------------------------------------------------
-- Highlights:
--   - Processes all calls and persists AI_AGG rollups into a table.
--   - Prompts for AI_AGG can be tuned (sentence vs. bullets, length, etc.).
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_ANALYSIS
AS

    WITH CTE_RESULTS
    AS
    (
        SELECT
            CALL_ID,
            AI_COMPLETE
            (
                model => 'claude-4-sonnet',
                prompt => CONCAT('Extract structured data from this call center transcript. <Transcript>', TRANSCRIPT, '</Transcript>'),
                model_parameters => {'temperature': 0.1, 'max_tokens': 4096, 'guardrails': FALSE},
                response_format => 
                {
                    'type': 'json',
                    'schema': 
                    {
                        'type': 'object',
                        'properties': {
                            'call_type': { 'type': 'string', 'enum': ['inbound','outbound','transfer'], 'description': 'Overall direction of the call.' },
                            'primary_intent': { 'type': 'string', 'enum': ['billing','technical_support','complaint','information','sales','cancellation','other'], 'description': 'Main reason for contact.' },
                            'urgency_level': { 'type': 'string', 'enum': ['low','medium','high','critical'], 'description': 'Urgency inferred from the conversation.' },
                            'issue_resolved': {'type': 'string', 'enum': ['yes', 'no', 'partial']},
                            'summary_bullets': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Three concise bullets.' },
                            'action_items': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Concrete next steps.' }
                        },
                        'required': ['call_type','primary_intent','urgency_level','summary_bullets','action_items']
                    }
                }
            )::VARIANT AS SUMMARY_JSON
        FROM 
            CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
        WHERE 
            ARRAY_CONTAINS('guardrails'::VARIANT,OBJECT_KEYS(SUMMARY_JSON)) = FALSE
    ),
    
    CTE_ACTION_ITEMS
    AS
    (
        SELECT
            SRC.CALL_ID,
            AI.value::string AS ACTION_ITEM
        FROM 
            CTE_RESULTS SRC,
        LATERAL FLATTEN(input => SRC.SUMMARY_JSON:action_items) AI
    ),
    
    CTE_SUMMARY_ITEMS
    AS 
    (
        SELECT
            SRC.CALL_ID,
            SI.value::string AS SUMMARY_ITEM
        FROM 
            CTE_RESULTS SRC,
        LATERAL FLATTEN(input => SRC.SUMMARY_JSON:summary_bullets) SI
    ),
    
    CTE_ROLLUPS 
    AS 
    (
        SELECT
            SRC.CALL_ID,
            SRC.SUMMARY_JSON:call_type::string AS CALL_TYPE,
            SRC.SUMMARY_JSON:primary_intent::string AS PRIMARY_INTENT,
            SRC.SUMMARY_JSON:urgency_level::string AS URGENCY_LEVEL,
            SRC.SUMMARY_JSON:issue_resolved::string AS ISSUE_RESOLVED,
            AI_AGG(SI.SUMMARY_ITEM, 'Combine these items into single bullet list') AS SUMMARY_ITEMS,
            AI_AGG(AI.ACTION_ITEM, 'Combine these items into single bullet list') AS ACTION_ITEMS
        FROM 
            CTE_RESULTS SRC
        LEFT JOIN CTE_SUMMARY_ITEMS SI 
            ON SI.CALL_ID = SRC.CALL_ID
        LEFT JOIN CTE_ACTION_ITEMS AI  
            ON AI.CALL_ID = SRC.CALL_ID
        GROUP BY 1,2,3,4,5
    )
    
    SELECT 
        CALL_ID,
        CALL_TYPE,
        PRIMARY_INTENT,
        URGENCY_LEVEL,
        ISSUE_RESOLVED,
        SUMMARY_ITEMS,
        ACTION_ITEMS
    FROM 
        CTE_ROLLUPS;

--------------------------------------------------------------------------
-- Step 4: Preview persisted analysis
--------------------------------------------------------------------------
-- Displays a sample of saved rollups for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_ANALYSIS LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
