WITH
customers AS (
    SELECT
        customer_id,
        full_name,
        first_name,
        last_name,
        company,
        email,
        phone,
        notes,
        accepts_product_review_abandoned_cart_emails AS accepts_transactional,
        tax_exempt_category,
        registration_ip_address,
        date_created,
        date_modified,
        --store_credit_amount,
        --store_credit_currency,
        store_credit_in_usd
    FROM
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_customer') }}
),

order_aggregates AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_including_tax) AS cltv
    FROM
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
    WHERE
        order_status_id IN ({{ var('bc_order_success_codes') | join(", ") }}) -- Replace with your array of order status codes
    GROUP BY
        customer_id
),

first_order AS (
    WITH ranked_orders AS (
        SELECT
            customer_id,
            order_created_date_time,
            total_including_tax,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_created_date_time) AS rn
        FROM
            {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
    )
    SELECT
        customer_id,
        order_created_date_time AS first_order_date,
        total_including_tax as first_order_total
    FROM
        ranked_orders
    WHERE
        rn = 1
),

most_recent_order AS (
    WITH ranked_orders AS (
        SELECT
            customer_id,
            order_created_date_time,
            total_including_tax,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_created_date_time DESC) AS rn
        FROM
            {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
    )
    SELECT
        customer_id,
        order_created_date_time AS most_recent_order_date,
        total_including_tax as most_recent_order_total
    FROM
        ranked_orders
    WHERE
        rn = 1
)

SELECT 
    c.*,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(o.cltv, 0) AS cltv,
    fo.first_order_date,
    fo.first_order_total,
    mro.most_recent_order_date,
    mro.most_recent_order_total
FROM 
    customers c
LEFT JOIN 
    order_aggregates o ON c.customer_id = o.customer_id
LEFT JOIN
    first_order fo ON c.customer_id = fo.customer_id
LEFT JOIN
    most_recent_order mro ON mro.customer_id = o.customer_id
