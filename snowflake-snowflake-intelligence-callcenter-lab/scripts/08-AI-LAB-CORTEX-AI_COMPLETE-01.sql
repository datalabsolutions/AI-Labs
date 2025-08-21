--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse for syntax examples.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Minimal completion (single-string signature)
--------------------------------------------------------------------------
-- Highlights: Uses the simplest AI_COMPLETE form with a single string
--             prompt and default parameters. Returns free-text.
-- Differences vs later steps: No PROMPT() helper, no parameters,
--             no structured output, no metadata.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        'snowflake-arctic',
        'Summarize the call transcript. ' || TRANSCRIPT
    )::VARCHAR AS CALL_SUMMARY
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE   
    CALL_ID = 'CALL_20250728_10050';

--------------------------------------------------------------------------
-- Step 3: PROMPT() helper for safer formatting
--------------------------------------------------------------------------
-- Highlights: Uses PROMPT() with placeholders for cleaner, safer
--             prompt construction and escaping.
-- Differences: Same output type (free-text) as Step 2, but better
--             maintainability and readability.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        'snowflake-arctic',
        PROMPT('Summarize the call transcript. {0}', TRANSCRIPT)
    )::VARCHAR AS CALL_SUMMARY
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE   
    CALL_ID = 'CALL_20250728_10050';

--------------------------------------------------------------------------
-- Step 4: Named arguments + model_parameters + guardrails
--------------------------------------------------------------------------
-- Highlights: Switch to named args; add model_parameters to control
--             temperature/top_p/max_tokens and enable guardrails.
-- Differences: More deterministic/concise output and safer generations.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    AI_COMPLETE
    (
        model  => 'snowflake-arctic',
        prompt => PROMPT('Summarize the call transcript. {0}', TRANSCRIPT),
        model_parameters => {'temperature': 0.2, 'top_p': 0.9, 'max_tokens': 120, 'guardrails': TRUE}
    ) AS CALL_SUMMARY
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE   
    CALL_ID = 'CALL_20250728_10050';

--------------------------------------------------------------------------
-- Step 5: Structured output with response_format (JSON schema)
--------------------------------------------------------------------------
-- Highlights: Provide a JSON Schema to receive structured JSON output.
-- Differences: Output is parsed and easy to select as columns.
-- Note: response_format works with the single-string prompt form.
--------------------------------------------------------------------------

WITH CTE_RESULT 
AS 
(
    SELECT
        CALL_ID,
        AI_COMPLETE
        (
            model  => 'snowflake-arctic',
            prompt => 'Summarize the call transcript. ' || TRANSCRIPT,
            model_parameters => {'temperature': 0.2, 'top_p': 0.9, 'max_tokens': 120, 'guardrails': TRUE},
            response_format => {
                'type': 'json',
                'schema': {
                    'type': 'object',
                    'properties': {
                        'summary': {'type': 'string'}
                    },
                    'required': ['summary']
                }
            }
        ) AS CALL_SUMMARY_JSON
    FROM 
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    WHERE 
        CALL_ID = 'CALL_20250728_10050'
)

SELECT
    CALL_ID,
    CALL_SUMMARY_JSON:summary::string AS "CALL_SUMMARY"
FROM 
    CTE_RESULT;

--------------------------------------------------------------------------
-- Step 6: Enable show_details for model/usage metadata
--------------------------------------------------------------------------
-- Highlights: Returns completion metadata (model, tokens, created time).
-- Differences: Great for observability and cost tracking.
--------------------------------------------------------------------------

WITH CTE_RESULT 
AS 
(
    SELECT
        CALL_ID,
        AI_COMPLETE
        (
            model  => 'snowflake-arctic',
            prompt => 'Summarize the call transcript. ' || TRANSCRIPT,
            model_parameters => {'temperature': 0.2, 'top_p': 0.9, 'max_tokens': 120, 'guardrails': TRUE},
            show_details => TRUE
        ) AS CALL_SUMMARY_JSON
    FROM 
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    WHERE 
        CALL_ID = 'CALL_20250728_10050'
)

SELECT
    CALL_ID,
    CALL_SUMMARY_JSON:choices[0]:messages::string AS "CALL_SUMMARY",
    CALL_SUMMARY_JSON:model::string AS "MODEL_USED",
    TO_TIMESTAMP_NTZ(CALL_SUMMARY_JSON:created) AS "CREATED_TS",
    CALL_SUMMARY_JSON:usage:completion_tokens::int AS "COMPLETION_TOKENS",
    CALL_SUMMARY_JSON:usage:guardrails_tokens::int AS "GUARDRAILS_TOKENS",
    CALL_SUMMARY_JSON:usage:prompt_tokens::int AS "PROMPT_TOKENS",
    CALL_SUMMARY_JSON:usage:total_tokens::int AS "TOTAL_TOKENS"
FROM 
    CTE_RESULT;

--------------------------------------------------------------------------
-- Step 7: Structured output + show_details together
--------------------------------------------------------------------------
-- Highlights: Combine response_format with show_details to get both
--             structured fields and rich metadata.
-- Differences: Best of both worlds for downstream pipelines and audits.
--------------------------------------------------------------------------

WITH CTE_RESULT 
AS 
(
    SELECT
        CALL_ID,
        AI_COMPLETE
        (
            model  => 'snowflake-arctic',
            prompt => 'Summarize the call transcript. ' || TRANSCRIPT,
            model_parameters => {'temperature': 0.2, 'top_p': 0.9, 'max_tokens': 120, 'guardrails': TRUE},
            response_format => {
                'type': 'json',
                'schema': {
                    'type': 'object',
                    'properties': {
                        'summary': {'type': 'string'}
                    },
                    'required': ['summary']
                }
            },
            show_details => TRUE
        ) AS CALL_SUMMARY_JSON
    FROM 
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
    WHERE 
        CALL_ID = 'CALL_20250728_10050'
)

SELECT
    CALL_ID,
    CALL_SUMMARY_JSON:structured_output[0]:raw_message:summary::string AS "CALL_SUMMARY",
    TO_TIMESTAMP_NTZ(CALL_SUMMARY_JSON:created) AS "CREATED_TS",
    CALL_SUMMARY_JSON:model::string AS "MODEL_USED",
    CALL_SUMMARY_JSON:usage:completion_tokens::int AS "COMPLETION_TOKENS",
    CALL_SUMMARY_JSON:usage:guardrails_tokens::int AS "GUARDRAILS_TOKENS",
    CALL_SUMMARY_JSON:usage:prompt_tokens::int AS "PROMPT_TOKENS",
    CALL_SUMMARY_JSON:usage:total_tokens::int AS "TOTAL_TOKENS"
FROM 
    CTE_RESULT;

--------------------------------------------------------------------------
--------------------------------------------------------------------------


