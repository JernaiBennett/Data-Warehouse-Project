WITH source AS (
    SELECT * FROM {{ source('raw', 'loc_a101') }}
),
cleaned AS (
    SELECT
        cid,
        INITCAP(TRIM(cntry)) AS country
    FROM source
    WHERE cid IS NOT NULL
)
SELECT * FROM cleaned