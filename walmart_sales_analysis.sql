-- ============================================================
--  WALMART SALES ANALYSIS – SQL Project
--  Author  : Kriti Singh
--  Dataset : Walmart Store Sales Forecasting (Kaggle)
--  Tables  : stores, features, train
--            stores  (Store, Type, Size)
--            features(Store, Date, Temperature, Fuel_Price,
--                     MarkDown1-5, CPI, Unemployment, IsHoliday)
--            train   (Store, Dept, Date, Weekly_Sales, IsHoliday)
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS walmart_db;
USE walmart_db;

-- Stores table
CREATE TABLE IF NOT EXISTS stores (
    Store       INT PRIMARY KEY,
    Type        VARCHAR(1),   -- A, B, or C
    Size        INT
);

-- Features table
CREATE TABLE IF NOT EXISTS features (
    Store       INT,
    Date        DATE,
    Temperature DECIMAL(6,2),
    Fuel_Price  DECIMAL(6,3),
    MarkDown1   DECIMAL(10,2),
    MarkDown2   DECIMAL(10,2),
    MarkDown3   DECIMAL(10,2),
    MarkDown4   DECIMAL(10,2),
    MarkDown5   DECIMAL(10,2),
    CPI         DECIMAL(10,4),
    Unemployment DECIMAL(5,3),
    IsHoliday   BOOLEAN,
    PRIMARY KEY (Store, Date)
);

-- Training / sales table
CREATE TABLE IF NOT EXISTS train (
    Store        INT,
    Dept         INT,
    Date         DATE,
    Weekly_Sales DECIMAL(12,2),
    IsHoliday    BOOLEAN,
    PRIMARY KEY (Store, Dept, Date)
);


-- ============================================================
-- SECTION 2: EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- 2.1 Total records and date range
SELECT
    COUNT(*)        AS total_rows,
    MIN(Date)       AS earliest_date,
    MAX(Date)       AS latest_date,
    COUNT(DISTINCT Store) AS num_stores,
    COUNT(DISTINCT Dept)  AS num_departments
FROM train;

-- 2.2 Store type distribution
SELECT
    s.Type,
    COUNT(s.Store)      AS num_stores,
    AVG(s.Size)         AS avg_store_size,
    SUM(t.Weekly_Sales) AS total_sales
FROM stores s
JOIN train t ON s.Store = t.Store
GROUP BY s.Type
ORDER BY total_sales DESC;

-- 2.3 Sales summary statistics
SELECT
    MIN(Weekly_Sales)  AS min_sales,
    MAX(Weekly_Sales)  AS max_sales,
    AVG(Weekly_Sales)  AS avg_sales,
    SUM(Weekly_Sales)  AS total_sales
FROM train
WHERE Weekly_Sales > 0;   -- exclude returns/negatives


-- ============================================================
-- SECTION 3: SALES TREND ANALYSIS
-- ============================================================

-- 3.1 Monthly sales trend (all stores)
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS Month,
    ROUND(SUM(Weekly_Sales), 2) AS Monthly_Sales,
    ROUND(AVG(Weekly_Sales), 2) AS Avg_Weekly_Sales
FROM train
WHERE Weekly_Sales > 0
GROUP BY Month
ORDER BY Month;

-- 3.2 Year-over-year sales comparison
SELECT
    YEAR(Date)                   AS Year,
    ROUND(SUM(Weekly_Sales), 2)  AS Total_Sales,
    ROUND(AVG(Weekly_Sales), 2)  AS Avg_Weekly_Sales,
    COUNT(DISTINCT Store)        AS Active_Stores
FROM train
WHERE Weekly_Sales > 0
GROUP BY Year
ORDER BY Year;

-- 3.3 Weekly sales trend – top 5 stores
SELECT
    Store,
    Date,
    ROUND(SUM(Weekly_Sales), 2) AS Weekly_Total
FROM train
WHERE Store IN (
    SELECT Store FROM train
    GROUP BY Store
    ORDER BY SUM(Weekly_Sales) DESC
    LIMIT 5
)
GROUP BY Store, Date
ORDER BY Store, Date;


-- ============================================================
-- SECTION 4: SEASONALITY ANALYSIS
-- ============================================================

-- 4.1 Sales by month (to identify seasonal patterns)
SELECT
    MONTH(Date)                  AS Month_Num,
    MONTHNAME(Date)              AS Month_Name,
    ROUND(SUM(Weekly_Sales), 2)  AS Total_Sales,
    ROUND(AVG(Weekly_Sales), 2)  AS Avg_Sales
FROM train
WHERE Weekly_Sales > 0
GROUP BY Month_Num, Month_Name
ORDER BY Month_Num;

-- 4.2 Holiday vs Non-Holiday sales comparison
SELECT
    IsHoliday,
    COUNT(*)                     AS num_weeks,
    ROUND(SUM(Weekly_Sales), 2)  AS Total_Sales,
    ROUND(AVG(Weekly_Sales), 2)  AS Avg_Weekly_Sales
FROM train
WHERE Weekly_Sales > 0
GROUP BY IsHoliday;

-- 4.3 Sales uplift during key holiday weeks
--     Super Bowl: Feb 10, 2012 | Labour Day: Sep 9, 2011
--     Thanksgiving: Nov 25, 2011 | Christmas: Dec 30, 2011
SELECT
    Date,
    ROUND(SUM(Weekly_Sales), 2)  AS Holiday_Sales,
    ROUND(AVG(Weekly_Sales), 2)  AS Avg_Store_Sales
FROM train
WHERE IsHoliday = TRUE
GROUP BY Date
ORDER BY Holiday_Sales DESC;

-- 4.4 Quarter-wise sales breakdown
SELECT
    YEAR(Date)                    AS Year,
    QUARTER(Date)                 AS Quarter,
    ROUND(SUM(Weekly_Sales), 2)   AS Quarterly_Sales,
    ROUND(AVG(Weekly_Sales), 2)   AS Avg_Sales
FROM train
WHERE Weekly_Sales > 0
GROUP BY Year, Quarter
ORDER BY Year, Quarter;


-- ============================================================
-- SECTION 5: STORE PERFORMANCE ANALYSIS
-- ============================================================

-- 5.1 Top 10 stores by total sales
SELECT
    t.Store,
    s.Type                        AS Store_Type,
    s.Size                        AS Store_Size,
    ROUND(SUM(t.Weekly_Sales), 2) AS Total_Sales,
    ROUND(AVG(t.Weekly_Sales), 2) AS Avg_Weekly_Sales
FROM train t
JOIN stores s ON t.Store = s.Store
WHERE t.Weekly_Sales > 0
GROUP BY t.Store, s.Type, s.Size
ORDER BY Total_Sales DESC
LIMIT 10;

-- 5.2 Bottom 5 underperforming stores
SELECT
    t.Store,
    s.Type,
    ROUND(SUM(t.Weekly_Sales), 2) AS Total_Sales
FROM train t
JOIN stores s ON t.Store = s.Store
WHERE t.Weekly_Sales > 0
GROUP BY t.Store, s.Type
ORDER BY Total_Sales ASC
LIMIT 5;

-- 5.3 Store performance vs chain average (using subquery)
SELECT
    t.Store,
    s.Type,
    ROUND(SUM(t.Weekly_Sales), 2)  AS Store_Total,
    ROUND(AVG(t.Weekly_Sales), 2)  AS Store_Avg,
    ROUND((SELECT AVG(Weekly_Sales) FROM train WHERE Weekly_Sales > 0), 2) AS Chain_Avg,
    ROUND(AVG(t.Weekly_Sales) -
          (SELECT AVG(Weekly_Sales) FROM train WHERE Weekly_Sales > 0), 2) AS Variance_From_Avg
FROM train t
JOIN stores s ON t.Store = s.Store
WHERE t.Weekly_Sales > 0
GROUP BY t.Store, s.Type
ORDER BY Store_Total DESC;


-- ============================================================
-- SECTION 6: DEPARTMENT PERFORMANCE
-- ============================================================

-- 6.1 Top 10 departments by total sales
SELECT
    Dept,
    ROUND(SUM(Weekly_Sales), 2)  AS Total_Sales,
    ROUND(AVG(Weekly_Sales), 2)  AS Avg_Sales,
    COUNT(DISTINCT Store)        AS Num_Stores_Carrying
FROM train
WHERE Weekly_Sales > 0
GROUP BY Dept
ORDER BY Total_Sales DESC
LIMIT 10;

-- 6.2 Department sales by store type
SELECT
    s.Type     AS Store_Type,
    t.Dept,
    ROUND(SUM(t.Weekly_Sales), 2)  AS Total_Sales
FROM train t
JOIN stores s ON t.Store = s.Store
WHERE t.Weekly_Sales > 0
GROUP BY s.Type, t.Dept
ORDER BY s.Type, Total_Sales DESC;

-- 6.3 Departments with highest holiday sales uplift
SELECT
    t.Dept,
    ROUND(AVG(CASE WHEN t.IsHoliday = TRUE  THEN t.Weekly_Sales END), 2) AS Holiday_Avg,
    ROUND(AVG(CASE WHEN t.IsHoliday = FALSE THEN t.Weekly_Sales END), 2) AS NonHoliday_Avg,
    ROUND(
        AVG(CASE WHEN t.IsHoliday = TRUE THEN t.Weekly_Sales END) -
        AVG(CASE WHEN t.IsHoliday = FALSE THEN t.Weekly_Sales END)
    , 2) AS Uplift
FROM train t
WHERE t.Weekly_Sales > 0
GROUP BY t.Dept
ORDER BY Uplift DESC
LIMIT 10;


-- ============================================================
-- SECTION 7: EXTERNAL FACTORS IMPACT
-- ============================================================

-- 7.1 Impact of fuel price on sales (binned)
SELECT
    CASE
        WHEN f.Fuel_Price < 3.0  THEN 'Low (<$3)'
        WHEN f.Fuel_Price < 3.5  THEN 'Medium ($3–3.5)'
        WHEN f.Fuel_Price < 4.0  THEN 'High ($3.5–4)'
        ELSE 'Very High (>$4)'
    END                               AS Fuel_Range,
    COUNT(*)                          AS Weeks,
    ROUND(AVG(t.Weekly_Sales), 2)     AS Avg_Sales
FROM train t
JOIN features f ON t.Store = f.Store AND t.Date = f.Date
WHERE t.Weekly_Sales > 0
GROUP BY Fuel_Range
ORDER BY Avg_Sales DESC;

-- 7.2 Impact of unemployment rate on sales
SELECT
    CASE
        WHEN f.Unemployment < 6   THEN 'Low (<6%)'
        WHEN f.Unemployment < 8   THEN 'Medium (6–8%)'
        WHEN f.Unemployment < 10  THEN 'High (8–10%)'
        ELSE 'Very High (>10%)'
    END                               AS Unemployment_Band,
    ROUND(AVG(t.Weekly_Sales), 2)     AS Avg_Sales,
    COUNT(*)                          AS Records
FROM train t
JOIN features f ON t.Store = f.Store AND t.Date = f.Date
WHERE t.Weekly_Sales > 0
GROUP BY Unemployment_Band
ORDER BY Avg_Sales DESC;

-- 7.3 Temperature effect on sales
SELECT
    CASE
        WHEN f.Temperature < 32  THEN 'Freezing (<32F)'
        WHEN f.Temperature < 60  THEN 'Cold (32–60F)'
        WHEN f.Temperature < 80  THEN 'Warm (60–80F)'
        ELSE 'Hot (>80F)'
    END                               AS Temp_Band,
    ROUND(AVG(t.Weekly_Sales), 2)     AS Avg_Sales,
    COUNT(*)                          AS Weeks
FROM train t
JOIN features f ON t.Store = f.Store AND t.Date = f.Date
WHERE t.Weekly_Sales > 0
GROUP BY Temp_Band
ORDER BY Avg_Sales DESC;

-- 7.4 MarkDown promotions vs sales (stores with markdown data)
SELECT
    t.Store,
    ROUND(AVG(f.MarkDown1), 2)        AS Avg_Markdown1,
    ROUND(AVG(f.MarkDown2), 2)        AS Avg_Markdown2,
    ROUND(AVG(t.Weekly_Sales), 2)     AS Avg_Sales
FROM train t
JOIN features f ON t.Store = f.Store AND t.Date = f.Date
WHERE f.MarkDown1 IS NOT NULL
  AND t.Weekly_Sales > 0
GROUP BY t.Store
ORDER BY Avg_Sales DESC
LIMIT 10;


-- ============================================================
-- SECTION 8: ADVANCED QUERIES
-- ============================================================

-- 8.1 Rolling 4-week average sales per store (window function)
SELECT
    Store,
    Date,
    ROUND(Weekly_Sales, 2) AS Weekly_Sales,
    ROUND(AVG(Weekly_Sales) OVER (
        PARTITION BY Store
        ORDER BY Date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_4wk_Avg
FROM train
WHERE Weekly_Sales > 0
ORDER BY Store, Date;

-- 8.2 Rank stores by sales within each store type
SELECT
    t.Store,
    s.Type,
    ROUND(SUM(t.Weekly_Sales), 2) AS Total_Sales,
    RANK() OVER (
        PARTITION BY s.Type
        ORDER BY SUM(t.Weekly_Sales) DESC
    ) AS Rank_Within_Type
FROM train t
JOIN stores s ON t.Store = s.Store
WHERE t.Weekly_Sales > 0
GROUP BY t.Store, s.Type
ORDER BY s.Type, Rank_Within_Type;

-- 8.3 Month-over-month sales growth rate
WITH monthly AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m')   AS Month,
        ROUND(SUM(Weekly_Sales), 2)  AS Monthly_Sales
    FROM train
    WHERE Weekly_Sales > 0
    GROUP BY Month
)
SELECT
    Month,
    Monthly_Sales,
    LAG(Monthly_Sales) OVER (ORDER BY Month) AS Prev_Month_Sales,
    ROUND(
        (Monthly_Sales - LAG(Monthly_Sales) OVER (ORDER BY Month))
        / LAG(Monthly_Sales) OVER (ORDER BY Month) * 100
    , 2) AS MoM_Growth_Pct
FROM monthly
ORDER BY Month;

-- 8.4 Stores with consistent above-average performance (all years)
SELECT Store
FROM (
    SELECT
        Store,
        YEAR(Date)                    AS Year,
        AVG(Weekly_Sales)             AS Yearly_Avg
    FROM train
    WHERE Weekly_Sales > 0
    GROUP BY Store, Year
) yearly_perf
GROUP BY Store
HAVING MIN(Yearly_Avg) > (SELECT AVG(Weekly_Sales) FROM train WHERE Weekly_Sales > 0)
ORDER BY Store;

-- 8.5 Correlation proxy – high markdown vs high sales stores
SELECT
    t.Store,
    ROUND(SUM(t.Weekly_Sales), 2)                 AS Total_Sales,
    ROUND(SUM(COALESCE(f.MarkDown1,0)
            + COALESCE(f.MarkDown2,0)
            + COALESCE(f.MarkDown3,0)
            + COALESCE(f.MarkDown4,0)
            + COALESCE(f.MarkDown5,0)), 2)        AS Total_Markdown_Spend
FROM train t
JOIN features f ON t.Store = f.Store AND t.Date = f.Date
WHERE t.Weekly_Sales > 0
GROUP BY t.Store
ORDER BY Total_Sales DESC;


-- ============================================================
-- END OF SCRIPT
-- ============================================================
