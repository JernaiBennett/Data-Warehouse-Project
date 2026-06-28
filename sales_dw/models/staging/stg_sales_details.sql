WITH source AS (
    SELECT * FROM {{ source('raw', 'sales_details') }}
),
cleaned AS (
    SELECT
        sls_ord_num,
        REPLACE(sls_prd_key, '-', '_')  AS sls_prd_key,
        sls_cust_id,
        TRY_TO_DATE(sls_order_dt::VARCHAR, 'YYYYMMDD') AS order_date,
        TRY_TO_DATE(sls_ship_dt::VARCHAR,  'YYYYMMDD') AS ship_date,
        TRY_TO_DATE(sls_due_dt::VARCHAR,   'YYYYMMDD') AS due_date,
        CASE WHEN sls_sales <= 0 OR sls_sales IS NULL
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales END         AS sls_sales,
        sls_quantity,
        CASE WHEN sls_price <= 0 OR sls_price IS NULL
             THEN sls_sales / NULLIF(sls_quantity, 0)
             ELSE sls_price END         AS sls_price
    FROM source
    WHERE sls_ord_num IS NOT NULL
)
SELECT * FROM cleaned