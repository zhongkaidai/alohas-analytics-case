-- ============================================================
-- 2A. - Metrics: 
--          - NET SALES AS-OF DATE OF SALE (net_sales_at_sale)
--          - NET SALES AS-OF REPORT DATE (realized_net_sales)
-- ============================================================

SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS year_month,
    channel,

    SUM(quantity_sold) AS units_sold,
    SUM(quantity_returned) AS units_returned,

    SUM(net_sales) AS net_sales_at_sale,

    -- Estimate the value of returned units using
    -- the net selling price of each sale line.
    SUM(
        SAFE_DIVIDE(net_sales, quantity_sold)
        * quantity_returned
    ) AS returned_sales_value,

    SUM(net_sales)
        - SUM(
            SAFE_DIVIDE(net_sales, quantity_sold)
            * quantity_returned
        ) AS realized_net_sales,

    SAFE_DIVIDE(
        SUM(quantity_returned),
        SUM(quantity_sold)
    ) AS return_rate

FROM `alohas-recruiting-study-case.production.fct_sale_order_line`

GROUP BY
    year_month,
    channel

ORDER BY
    year_month,
    channel;


-- ============================================================
-- 2B. PROPOSED MODEL: SALES EVENTS AND RETURN EVENTS
-- ============================================================

WITH sales AS (

    SELECT
        sale_line_id,
        DATE(created_at) AS sale_date,
        channel,
        quantity_sold,
        net_sales

    FROM `project.dataset.fct_sale_order_line`

),

returns AS (

    SELECT
        sale_line_id,
        SUM(quantity_returned) AS quantity_returned

    FROM `project.dataset.fct_return`

    WHERE return_date <= @report_date

    GROUP BY
        sale_line_id

)

SELECT
    DATE_TRUNC(s.sale_date, MONTH) AS year_month,
    s.channel,

    SUM(s.net_sales) AS net_sales,

    SUM(
        SAFE_DIVIDE(s.net_sales, s.quantity_sold)
        * COALESCE(r.quantity_returned, 0)
    ) AS returned_sales_value,

    SUM(s.net_sales)
        -
        SUM(
            SAFE_DIVIDE(s.net_sales, s.quantity_sold)
            * COALESCE(r.quantity_returned, 0)
        ) AS realized_net_sales

FROM sales AS s

LEFT JOIN returns AS r
    ON s.sale_line_id = r.sale_line_id

GROUP BY
    year_month,
    s.channel

ORDER BY
    year_month,
    s.channel;