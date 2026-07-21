-- =====================================================================
-- Module 08: Querying, the Results Cache, & Cloning
-- Lab: Getting Started with Snowflake (Zero to Snowflake)
-- =====================================================================
--
-- In the previous modules we loaded data using the COMPUTE_WH virtual
-- warehouse. Now we take on the role of the analytics users querying
-- that data with the second warehouse, ANALYTICS_WH.
--
-- In a real company, analytics users would likely use a different
-- role than SYSADMIN and a BI tool (Tableau, Looker, PowerBI, etc.)
-- rather than the worksheet — but we keep it simple here.

-- ---------------------------------------------------------------------
-- Step 1: Execute Some Queries
-- ---------------------------------------------------------------------
-- Set worksheet context: Role SYSADMIN, Warehouse ANALYTICS_WH (L),
-- Database PUBLIC_DATA, Schema PUBLIC.
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;
USE WAREHOUSE ANALYTICS_WH;
USE DATABASE PUBLIC_DATA;
USE SCHEMA PUBLIC;

-- See a sample of the COMPANY_METADATA data:
SELECT * FROM COMPANY_METADATA;

-- Closing Price Statistics: calculate the daily return of a stock (the
-- percent change in price from the previous day's close to today's
-- close) and a 5-day moving average of closing prices (smooths out
-- daily fluctuations to identify trends).
--
-- NOTE: if you have a database set in your worksheet context and want
-- to query a table from a different database, you must fully qualify
-- the reference with its database and schema name (as below, for
-- SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.STOCK_PRICE_TIMESERIES).
SELECT
    META.PRIMARY_TICKER,
    META.COMPANY_NAME,
    TS.DATE,
    TS.VALUE AS POST_MARKET_CLOSE,
    (TS.VALUE / LAG(TS.VALUE, 1) OVER (PARTITION BY META.PRIMARY_TICKER ORDER BY TS.DATE))::DOUBLE AS DAILY_RETURN,
    AVG(TS.VALUE) OVER (PARTITION BY META.PRIMARY_TICKER ORDER BY TS.DATE ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS FIVE_DAY_MOVING_AVG_PRICE
FROM
    SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.STOCK_PRICE_TIMESERIES AS TS
INNER JOIN
    COMPANY_METADATA AS META
    ON TS.TICKER = META.PRIMARY_TICKER
WHERE TS.VARIABLE_NAME = 'Post-Market Close';

-- Trading Volume Statistics: calculate the trading volume change from
-- one day to the next, to spot increasing/decreasing interest in a
-- stock.
SELECT
    META.PRIMARY_TICKER,
    META.COMPANY_NAME,
    TS.DATE,
    TS.VALUE AS NASDAQ_VOLUME,
    (TS.VALUE / LAG(TS.VALUE, 1) OVER (PARTITION BY META.PRIMARY_TICKER ORDER BY TS.DATE))::DOUBLE AS VOLUME_CHANGE
FROM
    SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.STOCK_PRICE_TIMESERIES AS TS
INNER JOIN
    COMPANY_METADATA AS META
    ON TS.TICKER = META.PRIMARY_TICKER
WHERE TS.VARIABLE_NAME = 'Nasdaq Volume';

-- ---------------------------------------------------------------------
-- Step 2: Use the Result Cache
-- ---------------------------------------------------------------------
-- Snowflake caches the results of every query executed in the past 24
-- hours, available across warehouses and users, provided the
-- underlying data hasn't changed. Repeated queries return extremely
-- fast and consume no compute credits.
--
-- Run the exact same query again to see the result cache in action:
-- ---------------------------------------------------------------------
SELECT
    meta.primary_ticker,
    meta.company_name,
    ts.date,
    ts.value AS post_market_close,
    (
        ts.value / LAG(ts.value, 1) OVER (
            PARTITION BY meta.primary_ticker
            ORDER BY ts.date
        )
    )::DOUBLE AS daily_return,
    AVG(ts.value) OVER (
        PARTITION BY meta.primary_ticker
        ORDER BY ts.date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS five_day_moving_avg_price
FROM 
    SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.STOCK_PRICE_TIMESERIES AS ts
INNER JOIN COMPANY_METADATA AS meta
    ON ts.ticker = meta.primary_ticker
WHERE ts.variable_name = 'Post-Market Close';

-- ---------------------------------------------------------------------
-- Step 3: Clone a Table
-- ---------------------------------------------------------------------
-- Snowflake lets you create "zero-copy clones" of tables, schemas, and
-- databases in seconds. A clone snapshots the source data; the clone
-- is writable and fully independent — changes to either side are not
-- reflected in the other. Only metadata/pointers change, so storage
-- is not doubled. A popular use case: cloning production for Dev/Test
-- without impacting production or duplicating infrastructure.
--
-- Create a dev clone of COMPANY_METADATA:
-- ---------------------------------------------------------------------
CREATE TABLE COMPANY_METADATA_DEV CLONE COMPANY_METADATA;

-- Refresh the object browser (... > Refresh) and verify
-- COMPANY_METADATA_DEV appears under PUBLIC_DATA. The Dev team can now
-- freely update/delete this clone without affecting the original
-- table.

-- ---------------------------------------------------------------------
-- Step 4: Joining Tables
-- ---------------------------------------------------------------------
-- Join the JSON SEC filing datasets to investigate the revenue of one
-- CPG company, Kraft Heinz (KHC), and see how its business segments
-- have performed over time:
-- ---------------------------------------------------------------------
WITH DATA_PREP AS (
    SELECT
        IDX.CIK,
        IDX.COMPANY_NAME,
        IDX.ADSH,
        IDX.FORM_TYPE,
        ATT.MEASURE_DESCRIPTION,
        CAST(ATT.VALUE AS DOUBLE) AS VALUE,
        ATT.PERIOD_START_DATE,
        ATT.PERIOD_END_DATE,
        ATT.COVERED_QTRS,
        TRIM(ATT.METADATA:"ProductOrService"::STRING) AS PRODUCT
    FROM
        SEC_FILINGS_ATTRIBUTES_VIEW AS ATT
    JOIN
        SEC_FILINGS_INDEX_VIEW AS IDX
        ON IDX.CIK = ATT.CIK AND IDX.ADSH = ATT.ADSH
    WHERE IDX.CIK = '0001637459'
        AND IDX.FORM_TYPE IN ('10-K', '10-Q')
        AND LOWER(ATT.MEASURE_DESCRIPTION) = 'net sales'
        AND (ATT.METADATA IS NULL OR OBJECT_KEYS(ATT.METADATA) = ARRAY_CONSTRUCT('ProductOrService'))
        AND ATT.COVERED_QTRS IN (1, 4)
        AND VALUE > 0
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY IDX.CIK, IDX.COMPANY_NAME, ATT.MEASURE_DESCRIPTION, ATT.PERIOD_START_DATE, ATT.PERIOD_END_DATE, ATT.COVERED_QTRS, PRODUCT
        ORDER BY IDX.FILED_DATE DESC
    ) = 1
)
SELECT
    COMPANY_NAME,
    MEASURE_DESCRIPTION,
    PRODUCT,
    PERIOD_END_DATE,
    CASE
        WHEN COVERED_QTRS = 1 THEN VALUE
        WHEN COVERED_QTRS = 4 THEN VALUE - SUM(VALUE) OVER (
            PARTITION BY CIK, MEASURE_DESCRIPTION, PRODUCT, YEAR(PERIOD_END_DATE)
            ORDER BY PERIOD_END_DATE
            ROWS BETWEEN 4 PRECEDING AND 1 PRECEDING
        )
    END AS QUARTERLY_VALUE
FROM DATA_PREP
ORDER BY PRODUCT, PERIOD_END_DATE;

-- Continue to 09-SQL-LAB-USING-TIME-TRAVEL.sql.
