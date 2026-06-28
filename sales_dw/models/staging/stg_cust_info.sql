WITH source AS (
    SELECT * FROM {{ source('raw', 'cust_info') }}
),
cleaned AS (
    SELECT
        cst_id,
        TRIM(cst_key)                               AS cst_key,
        INITCAP(TRIM(cst_firstname))                AS cst_firstname,
        INITCAP(TRIM(cst_lastname))                 AS cst_lastname,
        CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
             WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
             ELSE 'Unknown' END                     AS cst_marital_status,
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
             WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
             ELSE 'Unknown' END                     AS cst_gender,
        cst_create_date
    FROM source
    WHERE cst_id IS NOT NULL
)
SELECT * FROM cleaned