-- ============================================================
-- ALOHAS Analytics Engineer Study Case
-- Data Quality Audit
--
-- Source dataset:
--   alohas-recruiting-study-case.production
--
-- Tables:
--   dim_product
--   fct_shipment
--   fct_sale_order_line
-- ============================================================


-- ============================================================
-- 1. DUPLICATE PRODUCTS OR SHIPMENTS
-- ============================================================

-- 1A. Duplicate SKUs in dim_product
-- Expected: 0 rows
-- Output: 0 rows ✅
SELECT
    sku,
    COUNT(*) AS record_count
FROM `alohas-recruiting-study-case.production.dim_product`
GROUP BY sku
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- 1B. Duplicate shipment IDs in fct_shipment
-- Expected: 0 rows
-- Output: 0 rows ✅
SELECT
    shipment_id,
    COUNT(*) AS record_count
FROM `alohas-recruiting-study-case.production.fct_shipment`
GROUP BY shipment_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- ============================================================
-- 2. SKUs IN SALES THAT DON'T EXIST IN DIM_PRODUCT
-- ============================================================

-- Total number of distinct sku in Sales
select distinct sku
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`

-- Detailed list of orphan SKUs
select distinct s.sku
FROM `alohas-recruiting-study-case.production.fct_sale_order_line` as s
LEFT JOIN `alohas-recruiting-study-case.production.dim_product` AS p
    ON s.sku = p.sku
WHERE p.sku IS NULL


-- ============================================================
-- 3. SHIPMENT_ID IN SALES THAT DON'T EXIST IN FCT_SHIPMENT
-- ============================================================

-- Total number of distinct shipment_id in Sales
select distinct shipment_id
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`

-- Detailed list of sale lines whose shipment_id does not exist in fct_shipment.
SELECT distinct s.shipment_id
FROM `alohas-recruiting-study-case.production.fct_sale_order_line` AS s
LEFT JOIN `alohas-recruiting-study-case.production.fct_shipment` AS sh
    ON s.shipment_id = sh.shipment_id
WHERE sh.shipment_id IS NULL


-- ============================================================
-- 4. RECORD COUNT AND SALES VOLUME BY YEAR-MONTH
-- ============================================================

-- This is useful for checking whether the dataset has
-- complete monthly coverage or unexpected gaps.
SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS year_month,
    COUNT(*) AS sale_line_count,
    SUM(quantity_sold) AS units_sold,
    SUM(quantity_returned) AS units_returned,
    SUM(net_sales) AS net_sales
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`
GROUP BY year_month
ORDER BY year_month;


-- ============================================================
-- 5. RETURNS > SOLD
-- ============================================================

-- Detailed records where returned quantity exceeds sold quantity.
-- Expected: 0 rows.
SELECT
    created_at,
    channel,
    sku,
    shipment_id,
    quantity_sold,
    quantity_returned,
    gross_sale,
    net_sales
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`
WHERE quantity_returned > quantity_sold
ORDER BY quantity_returned - quantity_sold DESC;


-- ============================================================
-- 6. NEGATIVE QUANTITIES
-- ============================================================

-- Check negative quantity_sold.
-- Expected: 0 rows.
-- Output: 0 rows ✅
SELECT
    created_at,
    channel,
    sku,
    shipment_id,
    quantity_sold,
    quantity_returned,
    gross_sale,
    net_sales
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`
WHERE quantity_sold < 0
ORDER BY quantity_sold;


-- Check negative quantity_returned.
-- Expected: 0 rows.
-- Output: 0 rows ✅
SELECT
    created_at,
    channel,
    sku,
    shipment_id,
    quantity_sold,
    quantity_returned,
    gross_sale,
    net_sales
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`
WHERE quantity_returned < 0
ORDER BY quantity_returned;


-- ============================================================
-- 7. CHECK IF GROSS_SALE FROM SOURCE IS CONSISTENT WITH THE CALCUATED GROSS_SALE
-- ============================================================

SELECT
    s.sku,
    SUM(s.gross_sale) AS source_gross_sale,
    SUM(p.base_price * s.quantity_sold) AS calculated_gross_sale,
    SUM(s.gross_sale) - SUM(p.base_price * s.quantity_sold) AS difference
FROM `alohas-recruiting-study-case.production.fct_sale_order_line` AS s
LEFT JOIN `alohas-recruiting-study-case.production.dim_product` AS p
    ON s.sku = p.sku
GROUP BY s.sku
HAVING SUM(s.gross_sale) != SUM(p.base_price * s.quantity_sold)
ORDER BY s.sku;


-- ============================================================
-- 8. CHECK IF NET_SALES FROM SOURCE IS CONSISTENT WITH THE CALCUATED NET_SALES
-- ============================================================

SELECT
    sku,
    SUM(net_sales) AS net_sale,
    SUM(gross_sale - taxes) AS net_sales_calculated,
    SUM(net_sales) - SUM(gross_sale - taxes) AS difference
FROM `alohas-recruiting-study-case.production.fct_sale_order_line`
GROUP BY sku
HAVING SUM(net_sales) != SUM(gross_sale - taxes) 
ORDER BY sku;