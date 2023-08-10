WITH
products AS (
    SELECT
        *
    FROM
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_product') }}
)
select * from products