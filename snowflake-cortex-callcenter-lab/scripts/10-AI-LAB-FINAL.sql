-- ==============================================================================
-- Step 1: Set Context
-- ==============================================================================
-- Configures the session to use the appropriate database, schema, 
-- and warehouse before running any analysis.
-- ==============================================================================

USE DATABASE LLM_CORTEX_DEMO_DB;
USE SCHEMA   STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;


-- ==============================================================================
-- Step 2: Consolidated Transcript Analysis Query
-- ==============================================================================
-- Gathers final output from all transformed tables:
--   - Caller extraction
--   - Call classification
--   - Overall sentiment
--   - Entity-level sentiment (transposed)
--   - Summarization
-- ==============================================================================

SELECT 
    T.FILE_NAME,

    -- Classification Result
    TCL.CALL_CLASSIFICATION,

    -- Caller Details
    TC.CALLER_NAME,
    TC.CALL_DATE,
    TC.CALL_DURATION,

    -- Overall Sentiment Score
    TSENT.OVERALL_SENTIMENT,

    -- Entity-Level Sentiment Scores
    TF.FOLLOW_UP_SCORE,
    TF.ISSUE_RESOLVED_SCORE,
    TF.TONE_OF_VOICE_SCORE,
    
    -- Transcript Summary
    TSUM.TRANSCRIPT_SUMMARY

FROM LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT T

-- Join with extracted caller metadata
LEFT JOIN LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CALLER TC
    ON T.FILE_NAME = TC.FILE_NAME

-- Join with summarization results
LEFT JOIN LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_SUMMARY TSUM
    ON T.FILE_NAME = TSUM.FILE_NAME

-- Join with overall sentiment scores
LEFT JOIN LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_SENTIMENT TSENT
    ON T.FILE_NAME = TSENT.FILE_NAME

-- Join with transposed entity-level sentiment scores
LEFT JOIN LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_ENTITY_SENTIMENT_FINAL TF
    ON T.FILE_NAME = TF.FILE_NAME

-- Join with call classification results
LEFT JOIN LLM_CORTEX_DEMO_DB.STAGE.TRANSCRIPT_CLASSIFICATION TCL
    ON T.FILE_NAME = TCL.FILE_NAME

ORDER BY 
    T.FILE_NAME;
