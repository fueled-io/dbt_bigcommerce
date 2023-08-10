WITH
order_line_items AS (
    SELECT
        *
    FROM
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_order_line_items') }}
)
select * from order_line_items