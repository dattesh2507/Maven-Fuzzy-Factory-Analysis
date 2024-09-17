use evershop;
/* Gsearch seems to be the biggest driver of our business. Could you pull monthly trends 
for Gsearch sessions and orders so that we can showcase the growth there? */

SELECT
	YEAR(website_sessions.created_at) as year,
	MONTH(website_sessions.created_at) as month,
	count(website_sessions.website_session_id) as sessions,
	count(order_id) as gsearch_orders,
	count(order_id) / count(website_sessions.website_session_id) as gsearch_conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at<'2012-11-27'
and website_sessions.utm_source='gsearch'
GROUP BY 1, 2;

 /*02. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and 
brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. */
SELECT
	YEAR(website_sessions.created_at) AS year,
	MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch' and website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

/* 03. While we’re on Gsearch, could you dive into nonbrand, and pull monthly 
sessions and orders split by device 3 type? I want to flex our analytical muscles a little and show the board we really know our traffic sources. */
SELECT
	YEAR(website_sessions.created_at) AS YEAR,
    MONTH(website_sessions.created_at) AS MONTH,
	COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = 'gsearch' 
		AND utm_campaign = 'nonbrand' 
		AND website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;


/* 04. I’m worried that one of our more pessimistic board members may be concerned about the 
large % of traffic from 4 Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels */

SELECT
	distinct utm_source,
	utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-11-27';

SELECT YEAR(website_sessions.created_at) as year,
	MONTH(website_sessions.created_at) as month,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1, 2;

/* 05.  I’d like to tell the story of our website performance improvements over the course of the 
first 8 months. Could you pull session to order conversion rates, by month? */
use evershop;
SELECT
	YEAR(website_sessions.created_at) AS year,
    MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS ordrs,
    COUNT(DISTINCT orders.order_id) / 
	COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
	Left JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

/* 06. For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR 
from the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value) */
SELECT MIN(website_pageview_id) AS test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

CREATE TEMPORARY TABLE first_test_pageview
SELECT
	website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.website_pageview_id >= '23504'
	AND website_sessions.created_at < '2012-07-28'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_sessions.website_session_id;

-- next, we'll bring in the landing page to each session, like last time, but restricting to home or lander-1 this time
SELECT
	website_pageviews.website_session_id,
    pageview_url AS landing_page
FROM first_test_pageview
	LEFT JOIN website_pageviews
		ON first_test_pageview.min_pageview_id = website_pageviews.website_pageview_id
WHERE pageview_url IN ('/home', '/lander-1');

SELECT
	WP.pageview_url AS landing_page,
    COUNT(DISTINCT wp.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT wp.website_session_id) AS conv_rate
FROM website_pageviews WP
LEFT JOIN  orders o on wp.website_session_id = o.order_id
where pageview_url in ('/home', '/lander-1')  
GROUP BY 1;

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
SELECT 
	MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_session
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND website_sessions.created_at < '2012-11-27';
    
SELECT
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
    
    
/* 07. For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each 
of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28). */

CREATE TEMPORARY TABLE view_analysis
SELECT
    website_session_id, 
    MAX(homepage) AS saw_homepage,
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS saw_products,
    MAX(cart_page) AS saw_cart,
    MAX(shipping_page) AS saw_shipping,
    MAX(billing_page) AS saw_billing,
    MAX(thankyou_page) AS saw_thankyou
FROM(
SELECT
    website_sessions.website_session_id,
    website_pageviews.pageview_url,
    CASE WHEN pageview_url ='/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url ='/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url ='/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url ='/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url ='/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url ='/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url ='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM
    website_sessions LEFT JOIN website_pageviews ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
    AND website_sessions.created_at > '2012-06-19'
ORDER BY 
    website_sessions.website_session_id
) AS preview_level
GROUP BY website_sessions.website_session_id;

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
    COUNT(DISTINCT CASE WHEN saw_thankyou = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN saw_products = 1 THEN website_session_id ELSE NULL END) AS product_to_thankyou_CVR
FROM view_analysis
GROUP BY 1
ORDER BY product_to_thankyou_CVR DESC;



/* 08.  I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test 
(Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions 
for the past month to understand monthly impact*/

select  website_pageviews.website_session_id, 
       website_pageviews.pageview_url,
       orders.order_id,
       orders.price_usd
from website_pageviews
join orders on website_pageviews.website_session_id = orders.website_session_id
where orders.created_at >'2012-09-10' and orders.created_at <'2019-11-10' 
and website_pageviews.pageview_url in ('/billing','/billing-2');

SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd) / COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM (
	SELECT
		website_pageviews.website_session_id, 
		website_pageviews.pageview_url AS billing_version_seen, 
		orders.order_id, 
		orders.price_usd
	FROM website_pageviews
		LEFT JOIN orders
			ON website_pageviews.website_session_id = orders.website_session_id
	WHERE website_pageviews.created_at > '2012-09-10'
		AND website_pageviews.created_at < '2012-11-10'
		AND website_pageviews.pageview_url IN ('/billing', '/billing-2')
) AS billing_version_revenue
GROUP BY 1;


SELECT COUNT(website_session_id) AS billing_sessions_last_month
FROM website_pageviews
WHERE pageview_url IN ('/billing', '/billing-2')
	AND created_at > '2012-10-27'
	AND created_at < '2012-11-27';

-- here in results for billing page RPBP = 0.4566 but for billing-2 page RPBP = 0.6269
-- as we got increase of 31.339-22.826 = 8.512 dollars has increased per session seen by changing billing page to billing-2 page

-- now we calculate how revenue generated for last whole month from this change.
-- find last month total session from billing-2 and multiply with this 8.512 to get total revenue

-- result is 1311 sessions are there in last month.
-- 1311*8.512= 11159.232 dollars are the last month revenue from billing-2 page change test
-- $11,159 revenue last month