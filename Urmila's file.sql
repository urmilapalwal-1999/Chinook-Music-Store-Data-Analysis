-- Objectives Questions -------------------------
-- ---- OBJ01 - Finding Nulls in Database

select *from album;
select* from album group by album_id having count(*)>1;

select *from artist;
select* from artist group by artist_id having count(*)>1;

select *from customer;
select*From customer group by customer_id having count(*)>1;

select *from employee;
select * From employee group by employee_id having count(*)>1;

select*From genre;
select*From genre group by genre_id having count(*)>1;

select*From invoice;
select*From invoice group by invoice_id having count(*)>1;


select*From invoice_line;
select*From invoice_line group by invoice_line_id having count(*)>1;

select*From media_type;
select*From media_type group by media_type_id having count(*)>1;

select*From playlist;
select*From playlist group by playlist_id  having count(*)>1;

select*From playlist_track;
select*From playlist_track group by playlist_id,track_id having count(*)>1;

select*From track;
select*From track group by track_id having count(*)>1;



update customer set company = 'None' where company is null; -- 49 rows affected
update customer set state = 'None' where state is null; -- 29 rows affected
update customer set postal_code = 'None' where postal_code is null; -- 4 rows affected
update customer set phone = '0' where phone is null; -- 1  row affected
update customer set fax = 'None' where fax is null; -- 47 rows affected



update employee set reports_to = '0' where reports_to is null; -- 1 row affected
update track set composer = 'None' where composer is null; -- 978 rows affected--
update track set composer = lower(composer); -- 3503 rows affected
update track set composer = trim(both', ' 
from regexp_replace(regexp_replace(regexp_replace(
replace(replace(replace(composer,'/',' ,'), '&', ','), ';', ','),
                '\\s*,\\s*', ', '),',+', ','),',\\s*,', ','));
                
-- objective Q.no.2--

WITH data AS (
    SELECT 
        a.name, 
        g.name AS genre_name, 
        SUM(il.unit_price * quantity) AS revenue 
    FROM invoice i 
    JOIN invoice_line il ON i.invoice_id = il.invoice_id 
    JOIN track t ON il.track_id = t.track_id 
    JOIN album al ON t.album_id = al.album_id 
    JOIN artist a ON al.artist_id = a.artist_id 
    JOIN genre g ON g.genre_id = t.genre_id
    WHERE billing_country = 'USA' 
    GROUP BY a.name, g.name
)
SELECT * 
FROM data 
ORDER BY revenue DESC 
LIMIT 10; 

               
-- OBJECTIVE Q.NO-3-------

Select
country,
count(*) as customer_count
from customer
group by country 
order by customer_count desc;        

-- objective qno- 4---

select
billing_country,
billing_state,
billing_city,
sum(total) as total_revenue,
count(invoice_id) as total_orders 
from invoice
group by billing_country,billing_state,billing_city
order by total_revenue desc;

-- objective qno- 5---


with t1 as 
(select
c.customer_id,
first_name,
last_name,
billing_country,
sum(total) as total_revenue
From invoice i
join customer c 
on c.customer_id=i.customer_id
group by c.customer_id,
first_name,
last_name,
billing_country),

t2 as 
(select 
customer_id,
concat(first_name,' ',last_name) as customer_name,
billing_country,
total_revenue,
dense_rank()over(partition by billing_country order by total_revenue desc) as rnk
from t1)

select
customer_name,billing_country,total_revenue
from t2
where rnk<=5;  

-- objective qno- 6---
WITH cte1 AS (
    SELECT 
        i.customer_id, 
        il.track_id, 
        SUM(il.quantity * il.unit_price) AS total_spent
    FROM invoice i 
    JOIN invoice_line il 
        ON i.invoice_id = il.invoice_id
    GROUP BY i.customer_id, il.track_id
),
cte2 AS (
    SELECT *,
           row_number() OVER (
               PARTITION BY customer_id 
               ORDER BY total_spent DESC
           ) AS rnk
    FROM cte1
)
SELECT 
    c.customer_id,
    Concat(c.first_name,' ',c.last_name) as customer_name,
    t.track_id,
    t.name AS track_name,
    c2.total_spent,
    rnk
FROM cte2 c2
JOIN customer c ON c.customer_id = c2.customer_id
JOIN track t ON t.track_id = c2.track_id
WHERE rnk = 1;

-- objective qno-7---
-- Purchase Frequency
SELECT 
    customer_id, 
    COUNT(*) AS total_purchases,
    MIN(invoice_date) AS first_purchase,
    MAX(invoice_date) AS recent_purchase 
FROM invoice 
GROUP BY customer_id
ORDER BY total_purchases;

-- Average Order Value
SELECT 
    customer_id, 
    ROUND(AVG(total), 2) AS avg_order_value, 
    SUM(total) AS total_spent 
FROM invoice 
GROUP BY customer_id 
ORDER BY avg_order_value DESC;

-- Monthly Trends
SELECT 
    MONTH(invoice_date) AS month,
    COUNT(*) AS total_orders,
    SUM(total) AS revenue 
FROM invoice 
GROUP BY MONTH(invoice_date) 
ORDER BY month;

-- Purchase Interval
WITH cte1 AS (
    SELECT 
        customer_id, 
        invoice_date, 
        LAG(invoice_date) OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date
        ) AS prev_date 
    FROM invoice
)
SELECT 
    customer_id, 
    AVG(DATEDIFF(invoice_date, prev_date)) AS avg_days_between_purchases 
FROM cte1 
WHERE prev_date IS NOT NULL 
GROUP BY customer_id;

-- objective qno-8--
WITH total AS (
    SELECT COUNT(*) AS total FROM customer
),
last AS (
    SELECT 
        c.customer_id, 
        MAX(invoice_date) AS recent 
    FROM customer c 
    LEFT JOIN invoice i 
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),
churned AS (
    SELECT COUNT(*) AS churned 
    FROM last 
    WHERE TIMESTAMPDIFF(MONTH, recent, (SELECT MAX(invoice_date) FROM invoice)) > 3
)
SELECT 
round((churned * 100.0 / total),2) AS churn_rate 
FROM total, churned;

-- objective qno-9----
WITH usa_sales AS (
    SELECT 
        g.name AS genre,
        ar.name AS artist,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    JOIN album al ON t.album_id = al.album_id
    JOIN artist ar ON al.artist_id = ar.artist_id
    WHERE i.billing_country = 'USA'
    GROUP BY g.name, ar.name
),

genre_sales AS (
    SELECT 
        genre,
        SUM(total_sales) AS genre_total
    FROM usa_sales
    GROUP BY genre
),

total_sales AS (
    SELECT SUM(genre_total) AS overall_total
    FROM genre_sales
)

SELECT 
    gs.genre,
    gs.genre_total,
    ROUND((gs.genre_total * 100.0 / ts.overall_total), 2) AS percentage_contribution
FROM genre_sales gs
CROSS JOIN total_sales ts
ORDER BY percentage_contribution DESC;
-- objective qno-10----

SELECT 
    c.customer_id,
   CONCAT(c.first_name,' ',c.last_name) as customer_name,
    COUNT(DISTINCT g.genre_id) AS unique_genres_purchased
FROM customer c
JOIN invoice i 
    ON c.customer_id = i.customer_id
JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
JOIN track t 
    ON il.track_id = t.track_id
JOIN genre g 
    ON t.genre_id = g.genre_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
HAVING 
    COUNT(DISTINCT g.genre_id) >= 3
ORDER BY 
    unique_genres_purchased DESC;
-- objective qno-11----

SELECT 
    g.name AS genre,
    SUM(il.unit_price * il.quantity) AS total_sales,
    DENSE_RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS genre_rank
FROM invoice i
JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
JOIN track t 
    ON il.track_id = t.track_id
JOIN genre g 
    ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY genre_rank;

-- objective qno-12----

WITH last_purchase AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN invoice i
        ON c.customer_id = i.customer_id
    GROUP BY 
        c.customer_id,
        c.first_name,
        c.last_name
)

SELECT *
FROM last_purchase
WHERE 
    last_purchase_date IS NULL
    OR last_purchase_date < CURDATE() - INTERVAL 3 MONTH
ORDER BY last_purchase_date;                
                
                
               -- SUBJECTIVES QUESTIONS(SOLUTIONS)---------
               
-- SUBJECTIVE QNO-1 -----------    
WITH genre_sales AS (
    SELECT
        g.genre_id,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS genre_revenue
    FROM customer c
    JOIN invoice i
        ON c.customer_id = i.customer_id
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN genre g
        ON t.genre_id = g.genre_id
    WHERE c.country = 'USA'
    GROUP BY g.genre_id, g.name
),

top_genres AS (
    SELECT *
    FROM genre_sales
    ORDER BY genre_revenue DESC
    LIMIT 3
),

album_sales AS (
    SELECT
        al.album_id,
        al.title AS album_title,
        ar.name AS artist_name,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS album_revenue
    FROM customer c
    JOIN invoice i
        ON c.customer_id = i.customer_id
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN album al
        ON t.album_id = al.album_id
    JOIN artist ar
        ON al.artist_id = ar.artist_id
    JOIN genre g
        ON t.genre_id = g.genre_id
    WHERE c.country = 'USA'
      AND g.name IN (
          SELECT genre_name
          FROM top_genres
      )
    GROUP BY
        al.album_id,
        al.title,
        ar.name,
        g.name
),

ranked_albums AS (
    SELECT *,
           RANK() OVER (ORDER BY album_revenue DESC) AS rnk
    FROM album_sales
)

SELECT
    album_title,
    artist_name,
    genre_name,
    album_revenue
FROM ranked_albums
WHERE rnk <= 3
ORDER BY album_revenue DESC;


-- SUBJECTIVE QNO-2 -----------
WITH country_genre_sales AS (
    SELECT
        c.country,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM customer c
    JOIN invoice i
        ON c.customer_id = i.customer_id
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN genre g
        ON t.genre_id = g.genre_id
    WHERE c.country != 'USA'
    GROUP BY c.country, g.name
),

ranked_genres AS (
    SELECT
        country,
        genre_name,
        total_sales,
        RANK() OVER (
            PARTITION BY country
            ORDER BY total_sales DESC
        ) AS genre_rank
    FROM country_genre_sales
)

SELECT
    country,
    genre_name,
    total_sales
FROM ranked_genres
WHERE genre_rank = 1
ORDER BY country;

-- SUBJECTIVE QNO-3 -----------
with data as (
	select c.customer_id,
    sum(total) as total_spent,
    avg(total) as AOV,
    count(invoice_id) as order_count, 
    min((invoice_date)) as first,
    max((invoice_date)) as recent 
    from customer c join invoice i on c.customer_id=i.customer_id  group by customer_id 
)
,cte1 as (
select customer_id, total_spent, AOV, order_count, timestampdiff(month, first, recent) as tenure from data
)
, cte2 as (
select customer_id, total_spent, AOV, order_count, tenure, 
case 
	when tenure<=30 then 'New'
    when tenure>40 then 'Long-Term'
    else 'Mid-Term' end as category from cte1 order by tenure
)

select category, 
	round(avg(total_spent),2) avg_total_spent, 
    round(avg(aov),2) avg_AOV, 
    round(avg(order_count),2) avg_order_count, 
    round(avg(tenure),2) avg_tenure 
    from cte2 
    group by category 
    order by avg(tenure);

-- SUBJECTIVE QNO-4 -----------
WITH data AS (
    SELECT 
    DISTINCT i.invoice_id,
	g.name AS genre_name
    FROM invoice i
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN genre g
        ON g.genre_id = t.genre_id
)
SELECT
    d1.genre_name AS genre_1,
    d2.genre_name AS genre_2,
    COUNT(*) AS frequency
FROM data d1
JOIN data d2
    ON d1.invoice_id = d2.invoice_id
    AND d1.genre_name < d2.genre_name
GROUP BY d1.genre_name, d2.genre_name
ORDER BY frequency DESC
LIMIT 3;


-- SUBJECTIVE QNO-5 -----------
select 
    billing_country,
    sum(total) as revenue,
    count(invoice_id) as orders,
    count(distinct customer_id) as customers,
    
    round(sum(total)/count(invoice_id),2) as AOV,
    round(sum(total)/count(distinct customer_id),2) as revenue_per_customer,
    round(count(invoice_id)/count(distinct customer_id),2) as orders_per_customer,
    
    date(min(invoice_date)) as first_purchase,
    date(max(invoice_date)) as last_purchase,
    timestampdiff(day, max(invoice_date), current_date) as days_since_last_purchase,
    
    rank() over (order by sum(total) desc) as revenue_rank,
    round(sum(total) * 100 / sum(sum(total)) over (),2) as revenue_pct

from invoice
group by billing_country
order by revenue_rank;

-- SUBJECTIVE QNO-6 -----------

with customer_metrics as (
    select 
        c.customer_id,
        c.country,
        count(i.invoice_id) as order_count,
        sum(i.total) as total_spent,
        avg(i.total) as aov,
        max(i.invoice_date) as last_purchase,
        min(i.invoice_date) as first_purchase
    from customer c
    left join invoice i 
        on c.customer_id = i.customer_id
    group by c.customer_id, c.country
),

rfm as (
    select *,
        timestampdiff(month, last_purchase, (select max(invoice_date) from invoice)) as months_inactive
    from customer_metrics
),

segmented as (
    select *,
        case 
            when months_inactive >= 6 then 'high_risk'
            when months_inactive between 3 and 5 then 'medium_risk'
            else 'low_risk'
        end as risk_segment
    from rfm
)

select 
    country,
    risk_segment,
    count(*) as customers,
    round(avg(total_spent),2) as avg_spend,
    round(avg(order_count),2) as avg_orders,
    round(
        sum(case when risk_segment = 'high_risk' then 1 else 0 end) * 100.0
        / sum(count(*)) over (partition by country),
    2) as churn_rate
from segmented
group by country, risk_segment;


-- SUBJECTIVE QNO-7 -----------
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        MIN(i.invoice_date) AS first_purchase,
        MAX(i.invoice_date) AS last_purchase,
        COUNT(DISTINCT i.invoice_id) AS order_count,
        SUM(i.total) AS total_spent,
        AVG(i.total) AS avg_order_value
    FROM customer c
    JOIN invoice i 
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),

final AS (
    SELECT 
        customer_id,
        TIMESTAMPDIFF(MONTH, first_purchase, last_purchase) AS tenure,
        TIMESTAMPDIFF(MONTH, last_purchase, (SELECT MAX(invoice_date) FROM invoice)) AS recency,
        order_count,
        total_spent,
        avg_order_value,
        order_count / NULLIF(TIMESTAMPDIFF(MONTH, first_purchase, last_purchase),0) AS purchase_frequency,
        avg_order_value * order_count AS estimated_clv
    FROM customer_metrics
)

SELECT *,
    CASE 
        WHEN recency <= 3 AND order_count >= 10 THEN 'High Value'
        WHEN recency > 6 THEN 'Churned'
        WHEN order_count <= 3 THEN 'Low Engagement'
        ELSE 'Mid Value'
    END AS segment
FROM final;


-- SUBJECTIVE QNO-10 -----------

ALTER TABLE album
ADD COLUMN ReleaseYear INTEGER;
SELECT * 
FROM album;

-- SUBJECTIVE QNO-11 -----------
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        c.country,
        SUM(i.total) AS total_spent,
        SUM(il.quantity) AS total_tracks
    FROM customer c
    LEFT JOIN invoice i 
        ON c.customer_id = i.customer_id
    LEFT JOIN invoice_line il 
        ON i.invoice_id = il.invoice_id
    GROUP BY
        c.customer_id,
        c.country
)
SELECT 
    country,
    COUNT(customer_id) AS num_customers,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(total_tracks), 2) AS avg_tracks_per_customer
FROM customer_stats
GROUP BY country
ORDER BY country;
               
                
                
                
                
                
                
                
                
