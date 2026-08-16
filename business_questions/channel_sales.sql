-- ============================================================
-- 1A. CHANNEL SALES PERFORMANCE
-- Grain: one row per month and channel
-- ============================================================

WITH sales AS (

    SELECT
        DATE_TRUNC(DATE(created_at), MONTH) AS year_month,
        channel,
        sku,
        quantity_sold,
        quantity_returned,
        gross_sale,
        taxes,
        net_sales,

        -- Estimate the value of returned units using
        -- the line's net selling price.
        SAFE_DIVIDE(
            net_sales,
            quantity_sold
        ) * quantity_returned AS returned_sales_value

    FROM `alohas-recruiting-study-case.production.fct_sale_order_line`

),

channel_monthly AS (

    SELECT
        year_month,
        channel,

        SUM(quantity_sold) AS units_sold,
        SUM(quantity_returned) AS units_returned,

        SUM(gross_sale) AS gross_sales,
        SUM(taxes) AS taxes,
        SUM(net_sales) AS net_sales,

        SUM(returned_sales_value) AS returned_sales_value

    FROM sales
    GROUP BY
        year_month,
        channel

)

SELECT
    year_month,
    channel,

    units_sold,
    units_returned,

    gross_sales,
    taxes,
    net_sales,

    returned_sales_value,

    -- Revenue after estimated returns
    net_sales - returned_sales_value AS realized_net_sales,

    -- Unit return rate
    SAFE_DIVIDE(
        units_returned,
        units_sold
    ) AS return_rate,

    -- Revenue per unit before returns
    SAFE_DIVIDE(
        net_sales,
        units_sold
    ) AS net_sales_per_unit,

    -- Revenue per unit after returns
    SAFE_DIVIDE(
        net_sales - returned_sales_value,
        units_sold
    ) AS realized_net_sales_per_unit

FROM channel_monthly
ORDER BY
    year_month,
    channel;


-- ============================================================
-- 1B. OVERALL CHANNEL PERFORMANCE
-- ============================================================

WITH sales AS (

    SELECT
        channel,
        quantity_sold,
        quantity_returned,
        gross_sale,
        taxes,
        net_sales,

        SAFE_DIVIDE(
            net_sales,
            quantity_sold
        ) * quantity_returned AS returned_sales_value

    FROM `alohas-recruiting-study-case.production.fct_sale_order_line`

),

channel_summary AS (

    SELECT
        channel,

        SUM(quantity_sold) AS units_sold,
        SUM(quantity_returned) AS units_returned,

        SUM(gross_sale) AS gross_sales,
        SUM(taxes) AS taxes,
        SUM(net_sales) AS net_sales,

        SUM(returned_sales_value) AS returned_sales_value

    FROM sales
    GROUP BY channel

)

SELECT
    channel,

    units_sold,
    units_returned,

    gross_sales,
    taxes,
    net_sales,

    returned_sales_value,

    net_sales - returned_sales_value AS realized_net_sales,

    SAFE_DIVIDE(
        units_returned,
        units_sold
    ) AS return_rate,

    SAFE_DIVIDE(
        net_sales,
        SUM(net_sales) OVER ()
    ) AS net_sales_mix,

    SAFE_DIVIDE(
        net_sales - returned_sales_value,
        SUM(net_sales - returned_sales_value) OVER ()
    ) AS realized_sales_mix,

    SAFE_DIVIDE(
        net_sales,
        units_sold
    ) AS net_sales_per_unit,

    SAFE_DIVIDE(
        net_sales - returned_sales_value,
        units_sold
    ) AS realized_net_sales_per_unit

FROM channel_summary
ORDER BY realized_net_sales DESC;

