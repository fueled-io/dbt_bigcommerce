WITH
orders AS (
    SELECT
        *
    FROM
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
)
select * from orders