WITH
order_line_items AS (
    SELECT
        *
    FROM
        {{ ref('int_order_line_items') }}
)
select * from order_line_items