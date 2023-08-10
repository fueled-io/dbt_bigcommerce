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
        -- tax_exempt_category, -- Just rarely used. Noise for most merchants.
        registration_ip_address,
        date_created,
        date_modified,
        --store_credit_amount, -- Can be added back if helpful for a specific merchant.
        --store_credit_currency, -- Can be added back if helpful for a specific merchant.
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
            order_id,
            order_created_date_time,
            total_including_tax,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_created_date_time) AS rn
        FROM
            {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
        WHERE
            order_status_id IN ({{ var('bc_order_success_codes') | join(", ") }})
    )
    SELECT
        customer_id,
        order_id as first_order_id,
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
            order_id,
            order_created_date_time,
            total_including_tax,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_created_date_time DESC) AS rn
        FROM
            {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }}
        WHERE
            order_status_id IN ({{ var('bc_order_success_codes') | join(", ") }})

    )
    SELECT
        customer_id,
        order_id as most_recent_order_id,
        order_created_date_time AS most_recent_order_date,
        total_including_tax as most_recent_order_total
    FROM
        ranked_orders
    WHERE
        rn = 1
),

discount_usage as (
    SELECT 
        c.customer_id,
        COUNT(DISTINCT d.order_id) AS number_of_discounted_orders,
        SUM(d.discount_amount) AS total_discounts_value
    FROM 
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_customer') }} c
    LEFT JOIN 
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_order') }} o ON c.customer_id = o.customer_id AND order_status_id IN ({{ var('bc_order_success_codes') | join(", ") }})
    LEFT JOIN 
        {{ source(var('bc_schema', 'bigcommerce'), 'bc_order_line_items_discounts') }} d ON o.order_id = d.order_id
    GROUP BY 
        c.customer_id
    )

SELECT 
    c.*,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(o.cltv, 0) AS cltv,
    fo.first_order_id,
    fo.first_order_date,
    fo.first_order_total,
    mro.most_recent_order_id,
    mro.most_recent_order_date,
    mro.most_recent_order_total,
    date_diff(mro.most_recent_order_date, fo.first_order_date, DAY) as days_between_first_last_order,
    CASE
        WHEN o.order_count <= 1 THEN NULL
        ELSE
            round(date_diff(mro.most_recent_order_date, fo.first_order_date, DAY)
            / (order_count - 1))
    END AS order_frequency_days,
    du.number_of_discounted_orders,
    du.total_discounts_value
FROM 
    customers c
LEFT JOIN 
    order_aggregates o ON c.customer_id = o.customer_id
LEFT JOIN
    first_order fo ON c.customer_id = fo.customer_id
LEFT JOIN
    most_recent_order mro ON mro.customer_id = o.customer_id
LEFT JOIN
    discount_usage du ON du.customer_id = o.customer_id
ORDER BY du.number_of_discounted_orders
