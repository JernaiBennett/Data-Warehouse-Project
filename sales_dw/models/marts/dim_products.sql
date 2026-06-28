WITH products AS (
    SELECT * FROM {{ ref('stg_prd_info') }}
),
categories AS (
    SELECT * FROM {{ ref('stg_px_cat_g1v2') }}
)

SELECT
    p.prd_id        AS product_id,
    p.prd_key       AS product_key,
    p.prd_name      AS product_name,
    p.prd_cost      AS product_cost,
    p.prd_line      AS product_line,
    c.category,
    c.subcategory,
    c.maintenance,
    p.prd_start_dt  AS start_date,
    p.prd_end_dt    AS end_date
FROM products p
LEFT JOIN categories c ON p.prd_key = c.cat_id