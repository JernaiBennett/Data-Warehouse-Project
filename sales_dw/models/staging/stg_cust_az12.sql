WITH source AS (
    SELECT * FROM {{ source('raw', 'cust_az12') }}
),
cleaned AS (
    SELECT
        REPLACE(cid, 'NASAW', 'AW-')   AS cid,
        bdate                           AS birth_date,
        INITCAP(TRIM(gen))              AS gender
    FROM source
)
SELECT * FROM cleaned