WITH source AS (
    SELECT * FROM {{ source('raw', 'prd_info') }}
),
cleaned AS (
    SELECT
        prd_id,
        REPLACE(SUBSTR(prd_key, 4), '-', '_')   AS prd_key,
        TRIM(prd_nm)                             AS prd_name,
        COALESCE(prd_cost, 0)                    AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'M' THEN 'Mountain'
            WHEN 'T' THEN 'Touring'
            ELSE 'Unknown' END                   AS prd_line,
        prd_start_dt,
        COALESCE(prd_end_dt,
            LEAD(prd_start_dt) OVER
            (PARTITION BY REPLACE(SUBSTR(prd_key,4),'-','_')
             ORDER BY prd_start_dt) - 1)         AS prd_end_dt
    FROM source
    WHERE prd_id IS NOT NULL
)
SELECT * FROM cleaned