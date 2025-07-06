--------------------------------------------------------------------------
-- Step 1: Set Context
--------------------------------------------------------------------------
-- Sets the current database, schema, and warehouse to ensure that 
-- subsequent operations are executed in the correct environment.
--------------------------------------------------------------------------

USE DATABASE CORTEX_ANALYST_DB;
USE SCHEMA DATA;
USE WAREHOUSE USER_STD_XSMALL_WH;

--------------------------------------------------------------------------
-- Step 2: Explore the Source Table
--------------------------------------------------------------------------
-- The table FINANCE_ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES stores variable-based measurements for each ticker per day.
--------------------------------------------------------------------------

SELECT *
FROM FINANCE_ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES;

--------------------------------------------------------------------------
-- Step 3: Transform to Wide Format with a Dynamic Table
--------------------------------------------------------------------------
-- This creates a dynamic table to convert long-format time series data into wide format for easier querying.
--------------------------------------------------------------------------

CREATE OR REPLACE DYNAMIC TABLE CORTEX_ANALYST_DB.DATA.STOCK_PRICE
(
    DATE,
    TICKER,
    ASSET_CLASS,
    PRIMARY_EXCHANGE_CODE,
    PRIMARY_EXCHANGE_NAME,
    VOLUME,
    OPEN_PRICE,
    LOW_PRICE,
    HIGH_PRICE,
    CLOSE_PRICE
)
TARGET_LAG = '1 day'
REFRESH_MODE = AUTO
INITIALIZE = ON_CREATE
WAREHOUSE = USER_STD_XSMALL_WH
AS      
    SELECT
        DATE,
        TICKER,
        ASSET_CLASS,
        PRIMARY_EXCHANGE_CODE,
        PRIMARY_EXCHANGE_NAME,
        MAX(CASE WHEN VARIABLE = 'nasdaq_volume' THEN VALUE ELSE NULL END) AS VOLUME,
        MAX(CASE WHEN VARIABLE = 'pre-market_open' THEN VALUE ELSE NULL END) AS OPEN_PRICE,
        MAX(CASE WHEN VARIABLE = 'all-day_low' THEN VALUE ELSE NULL END) AS LOW_PRICE,
        MAX(CASE WHEN VARIABLE = 'all-day_high' THEN VALUE ELSE NULL END) AS HIGH_PRICE,
        MAX(CASE WHEN VARIABLE = 'post-market_close' THEN VALUE ELSE NULL END) AS CLOSE_PRICE
    FROM
        FINANCE_ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
    WHERE
        DATE >= DATE_FROM_PARTS(YEAR(CURRENT_DATE()) - 2, 1, 1)
    GROUP BY
        DATE,
        TICKER,
        ASSET_CLASS,
        PRIMARY_EXCHANGE_CODE,
        PRIMARY_EXCHANGE_NAME;

--------------------------------------------------------------------------
-- Step 4: Preview Transformed Data
--------------------------------------------------------------------------
-- Queries the new dynamic table to display the reshaped data for validation.
--------------------------------------------------------------------------

SELECT *
FROM CORTEX_ANALYST_DB.DATA.STOCK_PRICE;

--------------------------------------------------------------------------
-- End of Data Preparation Script
--------------------------------------------------------------------------
