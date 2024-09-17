-- Traffic Source Analysis

SELECT 
	utm_source,
    utm_campaign,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
where  utm_source != 'null'
GROUP BY 1,2
ORDER BY 3 DESC;

-- Conversion Rate Analysis

SELECT
    website_sessions.utm_source,
    website_sessions.utm_campaign,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) session_order_CVR
FROM website_sessions LEFT JOIN orders on website_sessions.website_session_id = orders.website_session_id
where utm_source  != 'null' and utm_campaign != 'null'
GROUP BY 1,2
ORDER BY 5 DESC;

-- User Behavior Analysis

SELECT
    utm_source,
    utm_campaign,
    SUM(orders.price_usd) AS total_revenue,
    SUM(orders.price_usd - orders.cogs_usd) AS total_margin,
    AVG(orders.price_usd) AS avg_order_value,
    AVG(orders.price_usd - orders.cogs_usd) AS avg_order_margin
FROM 
    website_sessions
LEFT JOIN orders ON website_sessions.website_session_id = orders.website_session_id
where utm_source != 'null'
GROUP BY utm_source, utm_campaign
ORDER BY total_revenue DESC;

-- Comparative Analysis
WITH metrics AS (
    SELECT
        utm_source,
        utm_campaign,
        COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions,
        COUNT(DISTINCT CASE WHEN orders.order_id IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS total_conversions,
        SUM(orders.price_usd) AS total_revenue,
        SUM(orders.price_usd - orders.cogs_usd) AS total_margin
    FROM 
        website_sessions
    LEFT JOIN orders ON website_sessions.website_session_id = orders.website_session_id
    GROUP BY
        utm_source,
        utm_campaign
)
SELECT
    utm_source,
    utm_campaign,
    total_sessions,
    total_conversions,
    (total_conversions * 1.0 / total_sessions) AS conversion_rate,
    total_revenue,
    total_margin
FROM
    metrics where utm_source != 'null'
ORDER BY
    conversion_rate DESC;
    
-- 2 Identify the most and least viewed website pages:
SELECT pageview_url, 
       COUNT(website_pageview_id) AS pageviews
FROM WEBSITE_PAGEVIEWS
GROUP BY pageview_url
ORDER BY pageviews DESC;

select pageview_url, count(distinct website_session_id) as sessions 
from website_pageviews
where pageview_url in ('/home', '/products','/cart','/shipping','/billing')
group by pageview_url
order by sessions desc;

WITH funnel AS (
    SELECT website_session_id, 
           MIN(wp.created_at) AS landing_time, 
           MAX(wp.created_at) AS purchase_time
    FROM WEBSITE_PAGEVIEWS wp
    JOIN order_items oi ON wp.website_session_id = oi.order_item_id
    GROUP BY website_session_id
)
SELECT pageview_url, 
	
       AVG(TIMESTAMPDIFF(SECOND, landing_time, purchase_time)) AS avg_time_to_purchase
FROM funnel
JOIN WEBSITE_PAGEVIEWS ON funnel.website_session_id = WEBSITE_PAGEVIEWS.website_session_id
GROUP BY pageview_url;



CREATE TEMPORARY TABLE analysis_o AS
SELECT
    website_sessions.website_session_id, 
    MAX(CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END) AS saw_homepage,
    MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS saw_custom_lander,
    MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END) AS saw_products,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS saw_cart,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS saw_shipping,
    MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END) AS saw_billing,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS saw_thankyou
FROM
    website_sessions
LEFT JOIN website_pageviews ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
    website_sessions.created_at < '2012-07-28'
    AND website_sessions.created_at > '2012-06-19'
GROUP BY
    website_sessions.website_session_id;
    
SELECT
    CASE
        WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'opps..logic?'
    END AS segment,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN saw_products = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN saw_cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN saw_shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN saw_billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN saw_thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou,
    COUNT(DISTINCT CASE WHEN saw_thankyou = 1 THEN website_session_id ELSE NULL END) / NULLIF(COUNT(DISTINCT CASE WHEN saw_products = 1 THEN website_session_id ELSE NULL END), 0) AS product_to_thankyou_CVR
FROM analysis_o
GROUP BY segment
ORDER BY product_to_thankyou_CVR DESC;

SELECT pageview_url, 
       COUNT(DISTINCT ORDER_ITEMS.order_id) AS total_orders, 
       SUM(price_usd) AS total_revenue
FROM WEBSITE_PAGEVIEWS
JOIN ORDER_ITEMS ON WEBSITE_PAGEVIEWS.website_session_id = ORDER_ITEMS.order_item_id
GROUP BY pageview_url
ORDER BY total_orders DESC;

select utm_source, utm_campaign, http_referer from website_sessions 
where utm_source != 'null'
group by 1,2,3;

SELECT pageview_url, count(pageview_url) from website_pageviews group by 1;

select min(website_pageview_id) as first_test from website_pageviews where pageview_url ='/lander-1';

--  Business Patterns and Analyzing Seasonality
SELECT MONTH(created_at) AS month, 
       COUNT(order_id) AS total_orders, 
       SUM(price_usd) AS total_revenue
FROM ORDERS
GROUP BY month
ORDER BY month;

SELECT HOUR(created_at) AS hour, 
       COUNT(order_id) AS total_orders, 
       SUM(price_usd) AS total_revenue
FROM ORDERS
GROUP BY hour
ORDER BY total_orders DESC;

SELECT product_id, 
       MONTH(created_at) AS month, 
       COUNT(order_id) AS total_orders, 
       SUM(price_usd) AS total_revenue
FROM ORDER_ITEMS
GROUP BY product_id, month
ORDER BY product_id, month;

SELECT MONTH(created_at) AS month, 
       COUNT(order_item_refund_id) AS total_refunds, 
       SUM(refund_amount_usd) AS total_refund_amount
FROM order_item_refunds
GROUP BY month
ORDER BY month;

WITH total_revenue AS (
    SELECT MONTH(created_at) AS month, 
           SUM(price_usd) AS revenue
    FROM ORDER_ITEMS
    GROUP BY month
),
total_refunds AS (
    SELECT MONTH(created_at) AS month, 
           SUM(refund_amount_usd) AS refund_amount
    FROM order_item_refunds
    GROUP BY month
)
SELECT total_revenue.month, 
       total_revenue.revenue, 
       total_refunds.refund_amount, 
       (total_refunds.refund_amount / total_revenue.revenue) * 100 AS refund_rate
FROM total_revenue
LEFT JOIN total_refunds ON total_revenue.month = total_refunds.month
ORDER BY total_revenue.month;

SELECT user_id, 
       COUNT(DISTINCT order_id) AS total_orders, 
       SUM(price_usd) AS total_revenue
FROM ORDER_ITEMS
JOIN WEBSITE_SESSIONS ON ORDER_ITEMS.order_item_id = WEBSITE_SESSIONS.website_session_id
WHERE is_repeat_session = 1
GROUP BY user_id
ORDER BY total_revenue DESC;

SELECT is_repeat_session, 
       AVG(price_usd) AS avg_order_value
FROM ORDER_ITEMS
JOIN WEBSITE_SESSIONS ON ORDER_ITEMS.order_id = WEBSITE_SESSIONS.website_session_id
GROUP BY is_repeat_session;

SELECT
YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_CVR,
    ROUND(SUM(price_usd)/COUNT(DISTINCT orders.order_id),2) AS revenue_per_order,
    ROUND(SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id),2) AS revenue_per_session
FROM
    website_sessions LEFT JOIN orders ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

SELECT
    YEAR(created_at) AS yer,
    monthname(created_at) AS mon,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS The_Original_MrFuzzy,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS The_Forever_Love_Bear,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS The_Birthday_Sugar_Panda,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS The_Hudson_River_Mini_bear,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM order_items
GROUP BY 1,2
ORDER BY 1,2;

WITH monthly_revenue AS (
    SELECT
        YEAR(created_at) AS yr,
        MONTH(created_at) AS mo,
        SUM(CASE WHEN product_id = 1 THEN price_usd ELSE 0 END) AS the_original_mrfuzzy,
        SUM(CASE WHEN product_id = 2 THEN price_usd ELSE 0 END) AS the_forever_love_bear,
        SUM(CASE WHEN product_id = 3 THEN price_usd ELSE 0 END) AS the_birthday_sugar_panda,
        SUM(CASE WHEN product_id = 4 THEN price_usd ELSE 0 END) AS the_hudson_river_mini_bear,
        SUM(price_usd) AS total_revenue,
        SUM(price_usd - cogs_usd) AS total_margin
    FROM order_items
    GROUP BY YEAR(created_at), MONTH(created_at)
),
yearly_revenue AS (
    SELECT
        yr,
        SUM(the_original_mrfuzzy) AS the_original_mrfuzzy,
        SUM(the_forever_love_bear) AS the_forever_love_bear,
        SUM(the_birthday_sugar_panda) AS the_birthday_bear,
        SUM(the_hudson_river_mini_bear) AS the_hudson_river_mini_bear,
        SUM(total_revenue) AS total_revenue,
        SUM(total_margin) AS total_margin
    FROM monthly_revenue
    GROUP BY yr
)
SELECT yr,
    the_original_mrfuzzy,
	the_forever_love_bear,
	the_birthday_bear,
	the_hudson_river_mini_bear,
    total_revenue,
    total_margin
FROM yearly_revenue
ORDER BY yr;