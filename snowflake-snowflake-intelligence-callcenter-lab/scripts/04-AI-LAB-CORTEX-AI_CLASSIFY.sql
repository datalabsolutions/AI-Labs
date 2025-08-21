--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse to ensure that 
-- subsequent operations are executed in the correct environment.
--------------------------------------------------------------------------

USE DATABASE CALL_CENTER_DB;
USE SCHEMA STAGE;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Quick Classification (Single Row)
--------------------------------------------------------------------------
-- Classifies a single call into predefined categories with task description.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    TRANSCRIPT,
    SNOWFLAKE.CORTEX.AI_CLASSIFY
    (
        TRANSCRIPT,
        ['Complaint', 'Query', 'Support Request', 'Sales', 'Cancellation','Other'],
        {
            'task_description': 'Classify the type of customer service call'
        }
    ) AS CALL_TYPE_JSON,
    CALL_TYPE_JSON:labels[0]::TEXT AS CALL_TYPE
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES
WHERE   
    CALL_ID = 'CALL_20250728_10050';

--------------------------------------------------------------------------
-- Step 3: Quick Classification (With Descriptions)
--------------------------------------------------------------------------
-- Uses labels with descriptions to improve classification quality.
--------------------------------------------------------------------------

SELECT
    CALL_ID,
    TRANSCRIPT,
    AI_CLASSIFY
    (
        TRANSCRIPT,
        [
            {
                'label': 'Complaint',
                'description': 'Caller reports a problem or dissatisfaction'
            },
            {
                'label': 'Query',
                'description': 'Caller asks for information or clarification'
            },
            {
                'label': 'Support Request',
                'description': 'Caller needs help to resolve something'
            },
            {
                'label': 'Sales',
                'description': 'Caller wants to buy or upgrade'
            },
            {
                'label': 'Cancellation',
                'description': 'Caller wants to cancel a service'
            }
        ]
    ) AS CALL_TYPE_JSON,      
    CALL_TYPE_JSON:labels[0]::TEXT AS CALL_TYPE
FROM 
    CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;
        
--------------------------------------------------------------------------
-- Step 4: Extended Classification (With Examples)
--------------------------------------------------------------------------
-- Adds task description, examples, and output_mode for more reliable results.
--------------------------------------------------------------------------

    SELECT
        CALL_ID,
        TRANSCRIPT,
        AI_CLASSIFY
        (
            TRANSCRIPT,
            [
                {
                    'label': 'Complaint',
                    'description': 'Caller reports a problem or dissatisfaction'
                },
                {
                    'label': 'Query',
                    'description': 'Caller asks for information or clarification'
                },
                {
                    'label': 'Support Request',
                    'description': 'Caller needs help to resolve something'
                },
                {
                    'label': 'Sales',
                    'description': 'Caller wants to buy or upgrade'
                },
                {
                    'label': 'Cancellation',
                    'description': 'Caller wants to cancel a service'
                }
            ],
            {
                'task_description': 'Classify the type of customer service call',
                'output_mode': 'single',
                'examples':  
                [
                    {
                      'input': 'My internet has been down all morning and I am very frustrated',
                      'labels': ['Complaint'],
                      'explanation': 'The caller expresses dissatisfaction and reports a recurring problem'
                    },
                    {
                      'input': 'Can you explain how to change my billing address?',
                      'labels': ['Query'],
                      'explanation': 'The caller is asking for information'
                    },
                    {
                      'input': 'I cannot log into my account, can you help me reset my password?',
                      'labels': ['Support Request'],
                      'explanation': 'The caller is explicitly asking for help to resolve a problem'
                    },
                    {
                      'input': 'I am interested in upgrading to the premium plan, what will it cost?',
                      'labels': ['Sales'],
                      'explanation': 'The caller is showing intent to purchase/upgrade'
                    },
                    {
                      'input': 'I want to cancel my subscription and end my service',
                      'labels': ['Cancellation'],
                      'explanation': 'The caller explicitly wants to cancel their subscription'
                    }
                ]
            }
        ) AS CALL_TYPE_JSON,
        IFNULL(CALL_TYPE_JSON:labels[0]::TEXT,'Other') AS CALL_TYPE
    FROM
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES;

--------------------------------------------------------------------------
-- Step 5: Persist Classification Results
--------------------------------------------------------------------------
-- Saves one row per call with the final assigned class.
--------------------------------------------------------------------------

CREATE OR REPLACE TABLE CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_CLASSIFY
AS
  
    WITH CTE_CLASSIFY
    AS
    (
    SELECT
        CALL_ID,
        AI_CLASSIFY
        (
            TRANSCRIPT,
            [
                {
                    'label': 'Complaint',
                    'description': 'Caller reports a problem or dissatisfaction'
                },
                {
                    'label': 'Query',
                    'description': 'Caller asks for information or clarification'
                },
                {
                    'label': 'Support Request',
                    'description': 'Caller needs help to resolve something'
                },
                {
                    'label': 'Sales',
                    'description': 'Caller wants to buy or upgrade'
                },
                {
                    'label': 'Cancellation',
                    'description': 'Caller wants to cancel a service'
                }
            ],
            {
                'task_description': 'Classify the type of customer service call',
                'output_mode': 'single',
                'examples':  
                [
                    {
                      'input': 'My internet has been down all morning and I am very frustrated',
                      'labels': ['Complaint'],
                      'explanation': 'The caller expresses dissatisfaction and reports a recurring problem'
                    },
                    {
                      'input': 'Can you explain how to change my billing address?',
                      'labels': ['Query'],
                      'explanation': 'The caller is asking for information'
                    },
                    {
                      'input': 'I cannot log into my account, can you help me reset my password?',
                      'labels': ['Support Request'],
                      'explanation': 'The caller is explicitly asking for help to resolve a problem'
                    },
                    {
                      'input': 'I am interested in upgrading to the premium plan, what will it cost?',
                      'labels': ['Sales'],
                      'explanation': 'The caller is showing intent to purchase/upgrade'
                    },
                    {
                      'input': 'I want to cancel my subscription and end my service',
                      'labels': ['Cancellation'],
                      'explanation': 'The caller explicitly wants to cancel their subscription'
                    }
                ]
            }
        ) AS CALL_TYPE_JSON,
        IFNULL(CALL_TYPE_JSON:labels[0]::TEXT,'Other') AS CALL_TYPE
    FROM
        CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES AS SRC
    
    )

    SELECT
        CALL_ID,
        CALL_TYPE
    FROM
        CTE_CLASSIFY;

--------------------------------------------------------------------------
-- Step 6: Preview Saved Results
--------------------------------------------------------------------------
-- Displays a sample of the saved classifications for verification.
--------------------------------------------------------------------------

SELECT * FROM CALL_CENTER_DB.STAGE.TRANSCRIBE_AUDIO_FILES_CLASSIFY LIMIT 10;

--------------------------------------------------------------------------
--------------------------------------------------------------------------