WITH cust_info AS (
    SELECT * FROM {{ ref('stg_cust_info') }}
),
cust_demo AS (
    SELECT * FROM {{ ref('stg_cust_az12') }}
),
cust_loc AS (
    SELECT * FROM {{ ref('stg_loc_a101') }}
)

SELECT
    c.cst_id                        AS customer_id,
    c.cst_key                       AS customer_key,
    c.cst_firstname                 AS first_name,
    c.cst_lastname                  AS last_name,
    c.cst_marital_status,
    COALESCE(c.cst_gender,
             d.gender, 'Unknown')   AS gender,
    d.birth_date,
    l.country,
    c.cst_create_date               AS created_date
FROM cust_info c
LEFT JOIN cust_demo d ON c.cst_key = d.cid
LEFT JOIN cust_loc  l ON c.cst_key = l.cid