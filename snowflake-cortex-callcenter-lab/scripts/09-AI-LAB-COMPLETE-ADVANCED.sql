--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Configures the session to use the appropriate database, schema, 
-- and warehouse before running any analysis.
--------------------------------------------------------------------------

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Generate Call Review Summary (Arctic Model)
--------------------------------------------------------------------------
-- Uses the SNOWFLAKE.CORTEX.COMPLETE function with the 'snowflake-arctic'
-- model to analyze the transcript of a specific file. The output includes:
-- • A suggested response to the customer
-- • Recommended follow-up actions for the agent
-- • A brief tone analysis
-- This step is helpful for assessing call quality and guiding agent behavior.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        [
            {
                'role': 'user',
                'content': 'You are a call center quality assistant. ' ||
                           'Based on the following transcript, generate: ' ||
                           '\n\n1. A suggested response to the customer ' ||
                           '\n2. Recommended follow-up actions for the agent ' ||
                           '\n3. A brief tone analysis ' ||
                           '\n\nTranscript:\n' || TRANSCRIPT
            }
        ],
        {
            'temperature': 0.5,
            'max_tokens': 300
        }
    ) AS CALL_REVIEW_SUMMARY
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 3: Summarize Transcript (LLaMA 2 Model)
--------------------------------------------------------------------------
-- Uses the SNOWFLAKE.CORTEX.COMPLETE function with the 'llama2-70b-chat'
-- model to generate a concise summary of the transcript.
-- Also returns metadata such as:
-- • Token usage
-- • Model used
-- • Generation timestamp
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE
    (
        'llama2-70b-chat',
        [
            {
                'role': 'system',
                'content': 'You are a professional summarizer. Extract key information clearly and concisely. '
            },
            {
                'role': 'user',
                'content': 'Summarize this transcript in 1-2 sentences: ' || TRANSCRIPT
            }
        ],
        {
            'temperature': 0.3,
            'top_p': 0.9,
            'max_tokens': 200
        }
    ) AS TRANSCRIPT_SUMMARY,
    TRANSCRIPT_SUMMARY:choices[0]:messages::string,
    TRY_TO_TIMESTAMP(TRANSCRIPT_SUMMARY:created::string) AS CREATED,
    TRANSCRIPT_SUMMARY:model::string AS MODEL,
    TRANSCRIPT_SUMMARY:usage:completion_tokens::number AS COMPLETION_TOKENS,
    TRANSCRIPT_SUMMARY:usage:prompt_tokens::number AS PROMPT_TOKENS,
    TRANSCRIPT_SUMMARY:usage:total_tokens::number AS TOTAL_TOKENS
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 4: Generate Professional Email Response
--------------------------------------------------------------------------
-- Uses the SNOWFLAKE.CORTEX.COMPLETE function with the 'llama2-70b-chat'
-- model to draft a polished email reply to the customer based on the transcript.
-- The output includes:
-- • Subject line
-- • Greeting
-- • Message body
-- • Sign-off
-- This can be used by agents for consistent, empathetic follow-up communication.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE
    (
        'llama2-70b-chat',
        [
            {
                'role': 'system',
                'content': 'You are a customer service representative crafting professional email responses. ' ||
                           'Your goal is to write a polite, clear, and helpful reply to the customer. ' ||
                           'Focus on being empathetic, addressing the main issue, and including any necessary follow-up steps. ' ||
                           'Respond in the form of an email, with a subject line, greeting, body, and sign-off. '
            },
            {
                'role': 'user',
                'content': 'Please write a professional email response to the following call transcript: ' || TRANSCRIPT
            }
        ],
        {
            'temperature': 0.4,
            'top_p': 0.9,
            'max_tokens': 1000
        }
    ) AS EMAIL_RESPONSE_JSON,
    EMAIL_RESPONSE_JSON:choices[0]:messages::string AS EMAIL_RESPONSE,
    TRY_TO_TIMESTAMP(EMAIL_RESPONSE_JSON:created::string) AS CREATED,
    EMAIL_RESPONSE_JSON:model::string AS MODEL,
    EMAIL_RESPONSE_JSON:usage:completion_tokens::number AS COMPLETION_TOKENS,
    EMAIL_RESPONSE_JSON:usage:prompt_tokens::number AS PROMPT_TOKENS,
    EMAIL_RESPONSE_JSON:usage:total_tokens::number AS TOTAL_TOKENS
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 5: Create Structured Transcript Table
--------------------------------------------------------------------------
-- Creates a new table to store:
-- • FILE_NAME: the source transcript file
-- • TRANSCRIPT_JSON: the structured dialogue output in JSON format
-- • TRANSCRIPT: the original transcript text
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_DIALOGUE (
    FILE_NAME VARCHAR,
    TRANSCRIPT_JSON VARIANT,
    TRANSCRIPT VARCHAR
);

--------------------------------------------------------------------------
-- Step 6: Generate Structured Dialogue from Transcript
--------------------------------------------------------------------------
-- Uses the 'llama2-70b-chat' model to convert the free-form transcript
-- into a structured JSON format including:
-- • Caller and agent identification
-- • Ordered dialogue sequence
-- • Role-tagged statements with speaker names
-- • Response must conform to a strict JSON schema under a "dialogue" key
--------------------------------------------------------------------------

INSERT INTO LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_DIALOGUE
SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE
    (
        'llama2-70b-chat',
        [
            {
                'role': 'system',
                'content': 'You will receive a conversation transcript between the tags <transcript></transcript>. ' ||
                           'Your task is to: ' ||
                           '\n1. Identify the caller (the person requesting help) and the agent (the person assisting). ' ||
                           '\n2. Convert the transcript into a structured conversation with each statement tagged as either caller or agent. ' ||
                           '\n3. Respond strictly in JSON format with a top-level "dialogue" key. ' ||
                           '\n4. Generate an "order" field that records the order of the conversation. ' ||
                           '\n5. Each entry must include the fields "order", "role", "name", and "speech". '
            },
            {
                'role': 'user',
                'content': '<transcript>' || TRANSCRIPT || '</transcript>'
            }
        ],
        {
            'temperature': 0.3,
            'top_p': 0.9,
            'response_format': {
                'type': 'json',
                'schema': {
                    'type': 'object',
                    'properties': {
                        'dialogue': {
                            'type': 'array',
                            'items': {
                                'type': 'object',
                                'properties': {
                                    'order': { 'type': 'integer' },
                                    'role': { 'type': 'string' },
                                    'name': { 'type': 'string' },
                                    'speech': { 'type': 'string' }
                                },
                                'required': ['order', 'role', 'name', 'speech']
                            }
                        }
                    },
                    'required': ['dialogue']
                }
            }
        }
    ) AS TRANSCRIPT_JSON,
    TRANSCRIPT
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 7: Preview Structured Transcript Output
--------------------------------------------------------------------------
-- Simple SELECT query to preview the contents of the structured dialogue
-- table for validation or review.
--------------------------------------------------------------------------

SELECT * 
FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_DIALOGUE;

--------------------------------------------------------------------------
-- Step 8: Flatten Structured Dialogue into Tabular Format
--------------------------------------------------------------------------
-- Extracts the role-tagged conversation from the JSON structure into
-- a tabular format with the following fields:
-- • ROLE
-- • NAME
-- • speech
-- • ORDER
-- Enables easier analysis and visualization of the dialogue.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,    
    d.value:"role"::STRING AS "ROLE",
    d.value:"name"::STRING  AS "NAME",
    d.value:"speech"::STRING AS "SPEECH",
    d.value:"order"::NUMBER AS "ORDER"
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_DIALOGUE,
    LATERAL FLATTEN(
        input => TRANSCRIPT_JSON:"structured_output"[0]:"raw_message":"dialogue"
    ) AS d;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
