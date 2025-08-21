--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for advanced completions.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Structured Completion — Classification (JSON)
--------------------------------------------------------------------------
-- Highlights: Uses response_format with a JSON Schema to classify the call.
-- Differences: Output is machine-parseable JSON with required fields.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        model => 'snowflake-arctic',
        prompt => CONCAT('Extract structured data from this call center transcript. <Transcript>', TRANSCRIPT, '</Transcript>'),
        response_format => {
            'type':'json',
            'schema':{
                'type':'object',
                'properties':{
                    'call_type':{'type':'string','enum':['inbound','outbound','transfer']},
                    'primary_intent':{'type':'string','enum':['billing','technical_support','complaint','information','sales','cancellation','other']},
                    'urgency_level':{'type':'string','enum':['low','medium','high','critical']}
                },
                'required':['call_type','primary_intent','urgency_level']
            }
        }
    ) AS CLASSIFICATION_JSON
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE 
    CALL_ID = 'CALL_20250728_10050';



--------------------------------------------------------------------------
-- Step 3: Free-text Summary — Bullet Points
--------------------------------------------------------------------------
-- Highlights: Simple single-string prompt for a concise bullet summary.
-- Differences: Returns unstructured text suitable for quick human readouts.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        model => 'mistral-large',
        prompt => CONCAT('Summarize this call in 3 concise bullet points. <Transcript>', TRANSCRIPT, '</Transcript>')
    ) AS CALL_SUMMARY
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE 
    CALL_ID = 'CALL_20250728_10050';



--------------------------------------------------------------------------
-- Step 4: Structured Completion — Action Items (JSON)
--------------------------------------------------------------------------
-- Highlights: Extracts actionable follow-ups using a JSON Schema array.
-- Differences: Easier to persist and filter downstream than free text.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        model => 'claude-4-sonnet',
        prompt => CONCAT(
          'Extract concrete action items for the agent and customer. ',
          'Return JSON with key "action_items" as an array of strings. ',
          '<Transcript>', TRANSCRIPT, '</Transcript>'
        ),
        response_format => {
            'type':'json',
            'schema':{
                'type':'object',
                'properties':{
                'action_items':{'type':'array','items':{'type':'string'}}
                },
                'required':['action_items']
            }
        }
    ) AS ACTION_ITEMS_JSON
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE 
    CALL_ID = 'CALL_20250728_10050';



--------------------------------------------------------------------------
-- Step 5: Combined Outputs — Three Prompts in One SELECT
--------------------------------------------------------------------------
-- Highlights: Runs three prompts together to return side-by-side outputs:
--   1) CLASSIFICATION_JSON (structured classification)
--   2) CALL_SUMMARY (free-text bullets)
--   3) ACTION_ITEMS_JSON (structured action items)
-- Differences: Single query, easy to persist/compare and monitor.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    
    -- 1) Classification (JSON)
    AI_COMPLETE
    (
        model => 'snowflake-arctic',
        prompt => CONCAT('Extract structured data from this call center transcript. <Transcript>', TRANSCRIPT, '</Transcript>'),
        response_format => {
            'type':'json',
            'schema':{
                'type':'object',
                'properties':{
                    'call_type':{'type':'string','enum':['inbound','outbound','transfer']},
                    'primary_intent':{'type':'string','enum':['billing','technical_support','complaint','information','sales','cancellation','other']},
                    'urgency_level':{'type':'string','enum':['low','medium','high','critical']}
                },
                'required':['call_type','primary_intent','urgency_level']
            }
        }
    ) AS CLASSIFICATION_JSON,
    
    -- 2) Summary (text)
    AI_COMPLETE
    (
        model => 'mistral-large',
        prompt => CONCAT('Summarize this call in 3 concise bullet points. <Transcript>', TRANSCRIPT, '</Transcript>')
    ) AS CALL_SUMMARY,
    
    -- 3) Action items (JSON)
    AI_COMPLETE
    (
        model => 'claude-4-sonnet',
        prompt => CONCAT(
          'Extract concrete action items for the agent and customer. ',
          'Return JSON with key "action_items" as an array of strings. ',
          '<Transcript>', TRANSCRIPT, '</Transcript>'
        ),
        response_format => {
            'type':'json',
            'schema':{
                'type':'object',
                'properties':{
                'action_items':{'type':'array','items':{'type':'string'}}
                },
                'required':['action_items']
            }
        }
    ) AS ACTION_ITEMS_JSON
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE 
    CALL_ID = 'CALL_20250728_10050';



--------------------------------------------------------------------------
-- Step 6: Unified JSON Payload — One call for multiple fields
--------------------------------------------------------------------------
-- Highlights: Request a single structured JSON payload containing
--             classification, bullets, and action items together.
-- Differences: Simplifies storage/retrieval at the cost of one larger call.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        model => 'snowflake-arctic',
        prompt => CONCAT('Extract structured data from this call center transcript. <Transcript>', TRANSCRIPT, '</Transcript>'),
        response_format => {
          'type': 'json',
          'schema': {
            'type': 'object',
            'properties': {
              'call_type': { 'type': 'string', 'enum': ['inbound','outbound','transfer'], 'description': 'Overall direction of the call.' },
              'primary_intent': { 'type': 'string', 'enum': ['billing','technical_support','complaint','information','sales','cancellation','other'], 'description': 'Main reason for contact.' },
              'urgency_level': { 'type': 'string', 'enum': ['low','medium','high','critical'], 'description': 'Urgency inferred from the conversation.' },
              'summary_bullets': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Three concise bullets.' },
              'action_items': { 'type': 'array', 'items': { 'type': 'string' }, 'description': 'Concrete next steps.' }
            },
            'required': ['call_type','primary_intent','urgency_level','summary_bullets','action_items']
          }
        }
    )::VARIANT AS PAYLOAD
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE 
    CALL_ID = 'CALL_20250728_10050';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
