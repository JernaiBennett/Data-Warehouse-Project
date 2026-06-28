{{
    config(
        materialized='incremental',
        unique_key='sls_ord_num',
        on_schema_change='append_new_columns'
    )
}}

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales_details') }}
    {% if is_incremental() %}
        WHERE order_date > (SELECT MAX(order_date) FROM {{ this }})
    {% endif %}
),
customers AS (
    SELECT * FROM {{ ref('dim_customers') }}
),
products AS (
    SELECT * FROM {{ ref('dim_products') }}
)

SELECT
    s.sls_ord_num       AS order_number,
    s.order_date,
    s.ship_date,
    s.due_date,
    s.sls_quantity      AS quantity,
    s.sls_price         AS unit_price,
    s.sls_sales         AS total_sales,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country,
    c.gender,
    p.product_id,
    p.product_name,
    p.product_line,
    p.category,
    p.subcategory
FROM sales s
LEFT JOIN customers c ON s.sls_cust_id = c.customer_id
LEFT JOIN products  p ON s.sls_prd_key = p.product_key