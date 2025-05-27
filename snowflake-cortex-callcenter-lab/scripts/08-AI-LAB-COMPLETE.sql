--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Configures the session to use the correct database, schema, and warehouse.
--------------------------------------------------------------------------

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Simple Summary using Cortex COMPLETE
--------------------------------------------------------------------------
-- Uses SNOWFLAKE.CORTEX.COMPLETE with a plain prompt to generate a brief 
-- one-sentence summary of the transcript.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'Summarize the following call transcript in one sentence: ' || TRANSCRIPT
    ) AS CALL_SUMMARY
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 3: Bullet Summary for Team Leader Review
--------------------------------------------------------------------------
-- Instruction: Summarize the call into exactly 3 concise bullet points.
-- Persona: Senior support team lead.
-- Purpose: Internal quality review of call transcripts.
-- Constraints:
-- • Each bullet must be under 15 words
-- • Use hyphen as bullet character
-- • Maintain a professional and neutral tone
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'You are a senior support team lead. ' ||
        'Read the following transcript and summarize it into exactly three bullet points. ' ||
        'Keep each bullet point under 15 words and use a professional tone. ' ||
        'Use hyphens for each bullet. ' ||
        'Transcript: ' || TRANSCRIPT
    ) AS BULLET_SUMMARY
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 4: Identify Escalation Indicators
--------------------------------------------------------------------------
-- Instruction: Determine whether the call should be escalated.
-- Persona: Triage bot for customer service.
-- Output format:
-- • YES/NO
-- • If YES, add one-sentence justification
-- Tone: Decisive and concise.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'You are a triage assistant. ' ||
        'Does this call require escalation? Answer YES or NO. ' ||
        'If YES, explain briefly in one sentence why. ' ||
        'Transcript: ' || TRANSCRIPT
    ) AS ESCALATION_FLAG
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME IN ('audiofile11.pdf', 'audiofile79.pdf');

--------------------------------------------------------------------------
-- Step 5: Sentiment-Based Quality Assessment
--------------------------------------------------------------------------
-- Instruction: Score call quality from 1–5 stars.
-- Persona: AI quality assessor using tone, clarity, empathy signals.
-- Output format: "Score: X/5 - Justification"
-- Tone: Constructive and fair.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'You are a quality control AI. ' ||
        'Rate the call on a scale of 1–5 stars based on clarity, empathy, and professionalism. ' ||
        'Format as "Score: X/5 - Reason". ' ||
        'Transcript: ' || TRANSCRIPT
    ) AS QUALITY_SCORE
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 6: Follow-Up Email Draft
--------------------------------------------------------------------------
-- Instruction: Generate a follow-up email under 100 words.
-- Persona: Customer service agent.
-- Format:
-- • Greeting
-- • Main message
-- • Sign-off
-- Tone: Friendly, helpful, and professional.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'You are a customer service agent. ' ||
        'Based on this transcript, write a short follow-up email under 100 words. ' ||
        'Keep it friendly and professional. ' ||
        'Transcript: ' || TRANSCRIPT
    ) AS FOLLOW_UP_EMAIL
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';

--------------------------------------------------------------------------
-- Step 7: Red Flag Detection
--------------------------------------------------------------------------
-- Instruction: Identify red flags (e.g., threats, abusive language, compliance risks).
-- Persona: Risk compliance assistant.
-- Format:
-- • Bullet points for each red flag
-- • Return "None" if no red flags are found
-- Tone: Neutral and informative.
--------------------------------------------------------------------------

SELECT
    FILE_NAME,
    SNOWFLAKE.CORTEX.COMPLETE(
        'snowflake-arctic',
        'You are a risk compliance assistant. ' ||
        'Read the following transcript and identify any red flags ' ||
        '(e.g., threats to cancel, abusive language, compliance issues). ' ||
        'If no red flags are found, return "None". ' ||
        'Use bullet points for each red flag. ' ||
        'Transcript: ' || TRANSCRIPT
    ) AS RED_FLAGS
FROM
    LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT
WHERE
    FILE_NAME = 'audiofile11.pdf';
