WITH source AS (
    SELECT * FROM {{ source('raw', 'px_cat_g1v2') }}
),
cleaned AS (
    SELECT
        id                          AS cat_id,
        INITCAP(TRIM(cat))          AS category,
        INITCAP(TRIM(subcat))       AS subcategory,
        UPPER(TRIM(maintenance))    AS maintenance
    FROM source
)
SELECT * FROM cleaned