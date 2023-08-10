WITH
orders AS (
    SELECT
        *
    FROM
        {{ ref('int_orders') }}
)
select * from orders