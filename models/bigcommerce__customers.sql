WITH
customers AS (
    SELECT
        *
    FROM
        {{ ref('int_customers') }}
)
select * from customers