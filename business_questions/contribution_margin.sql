-- ============================================================
-- 3. - CONTRIBUTION MARGIN
--
-- Grain:
--   One row per sale order line.
--
-- Methodology and assumptions:
--   1. Realized net sales deduct the estimated value of
--      returned units from source net sales.
--
--   2. Product COGS is calculated only for units retained by
--      the customer; returned units are therefore excluded
--      from COGS.
--
--   3. Sale lines with an SKU that does not exist in
--      dim_product are excluded because their product cost
--      and category cannot be determined reliably.
--
--   4. Sale lines with a shipment_id that does not exist in
--      fct_shipment are excluded because their shipping cost
--      cannot be determined reliably.
--
--   5. When a return occurs, the original shipping cost is
--      used as a proxy for the return cost, since no separate
--      return-cost field is available in the source data.
--
--   6. Contribution margin is calculated as realized net sales
--      minus product COGS, outbound shipping cost, and the
--      estimated return cost.
-- ============================================================

WITH sales AS (

    SELECT
        s.channel,
        s.sku,
        s.shipment_id,
        s.quantity_sold,
        s.quantity_returned,
        s.gross_sale,
        s.taxes,
        s.net_sales,
        s.created_at,

        p.name,
        p.category,
        p.base_price,
        p.cost AS unit_product_cost,

        sh.shipping_method,
        sh.country AS shipping_country,
        sh.shipping_cost

    FROM `alohas-recruiting-study-case.production.fct_sale_order_line` AS s

    INNER JOIN `alohas-recruiting-study-case.production.dim_product` AS p
        ON s.sku = p.sku

    INNER JOIN `alohas-recruiting-study-case.production.fct_shipment` AS sh
        ON s.shipment_id = sh.shipment_id
),

sales_enriched AS (

    SELECT
        *,

        -- Estimate the net-sales value associated with returned units.
        SAFE_DIVIDE(
            net_sales,
            quantity_sold
        ) * quantity_returned AS returned_sales_value,

        -- Revenue retained after deducting the estimated value
        -- of returned units.
        net_sales
        - (
            SAFE_DIVIDE(
                net_sales,
                quantity_sold
            ) * quantity_returned
        ) AS realized_net_sales,

        -- Product COGS for units retained by the customer.
        -- Returned units are excluded because their COGS is reversed.
        (
            quantity_sold - quantity_returned
        ) * unit_product_cost AS product_cogs,

        -- Estimate the cost of processing a return by using the
        -- original shipping cost as a proxy.
        CASE
            WHEN quantity_returned > 0 THEN shipping_cost
            ELSE 0
        END AS estimated_return_cost

    FROM sales
),

contribution_margin_cte AS (

    SELECT
        *,

        -- Contribution margin after product cost, outbound shipping,
        -- and estimated return cost.
        realized_net_sales
        - product_cogs
        - shipping_cost
        - estimated_return_cost AS contribution_margin

    FROM sales_enriched
)


-- ============================================================
-- 3A. - CONTRIBUTION MARGIN BY CHANNEL
-- ============================================================
SELECT
    channel,

    SUM(net_sales) AS net_sales,
    SUM(realized_net_sales) AS realized_net_sales,
    SUM(product_cogs) AS product_cogs,
    SUM(shipping_cost) AS shipping_cost,
    SUM(estimated_return_cost) AS estimated_return_cost,
    SUM(contribution_margin) AS contribution_margin,

    SAFE_DIVIDE(
        SUM(contribution_margin),
        SUM(realized_net_sales)
    ) AS contribution_margin_pct

FROM contribution_margin_cte

GROUP BY
    channel

ORDER BY
    contribution_margin_pct DESC;


-- ============================================================
-- 3B. - CONTRIBUTION MARGIN BY CATEGORY
-- ============================================================
SELECT
    category,

    SUM(net_sales) AS net_sales,
    SUM(realized_net_sales) AS realized_net_sales,
    SUM(product_cogs) AS product_cogs,
    SUM(shipping_cost) AS shipping_cost,
    SUM(estimated_return_cost) AS estimated_return_cost,
    SUM(contribution_margin) AS contribution_margin,

    SAFE_DIVIDE(
        SUM(contribution_margin),
        SUM(realized_net_sales)
    ) AS contribution_margin_pct

FROM contribution_margin_cte

GROUP BY
    category

ORDER BY
    contribution_margin_pct DESC;


-- ============================================================
-- 3C. - PRODUCTS WITH HIGH REVENUE BUT LOW MARGIN
-- ============================================================

SELECT
    sku,
    name,
    category,

    SUM(net_sales) AS net_sales,
    SUM(realized_net_sales) AS realized_net_sales,
    SUM(product_cogs) AS product_cogs,
    SUM(shipping_cost) AS shipping_cost,
    SUM(estimated_return_cost) AS estimated_return_cost,
    SUM(contribution_margin) AS contribution_margin,

    SAFE_DIVIDE(
        SUM(contribution_margin),
        SUM(realized_net_sales)
    ) AS contribution_margin_pct,

    SUM(quantity_sold) AS units_sold,

    SUM(quantity_returned) AS units_returned,

    SAFE_DIVIDE(
        SUM(quantity_returned),
        SUM(quantity_sold)
    ) AS return_rate

FROM contribution_margin_cte

GROUP BY
    sku,
    name,
    category

ORDER BY
    contribution_margin_pct ASC;