/*Tables:
Users: user_id, sex, birth_date
user_actions: user_id, action, order_id, time
Couriers: courier_id, sex, birth_date
courier_actions: courier_id, action, order_id, time
products: product_id, price, name
orders: order_id, products_ids(array), creation_time
*/

/* Calculating daily revenue, revenue growth comparing to preceding day and revenue growth percentage */
WITH temp_table as (SELECT date(creation_time)as date,
                           sum(order_price) as daily_revenue
                    FROM   (SELECT order_id,
                                   order_price,
                                   creation_time,
                                   sum(order_price) OVER(PARTITION BY date_part('day', creation_time)) as daily_revenue
                            FROM   (SELECT order_id,
                                           sum(price) as order_price
                                    FROM   (SELECT *
                                            FROM   (SELECT creation_time,
                                                           order_id,
                                                           unnest(product_ids) as product_id
                                                    FROM   orders) t1
                                                LEFT JOIN products using(product_id)) t2
                                    WHERE  order_id not in (SELECT order_id
                                                            FROM   user_actions
                                                            WHERE  action = 'cancel_order')
                                    GROUP BY order_id)t3
                                LEFT JOIN (SELECT order_id,
                                                  creation_time
                                           FROM   orders) t4 using(order_id)) t5
                    GROUP BY date(creation_time))
SELECT date,
       round(daily_revenue, 1) as daily_revenue,
       coalesce(round(daily_revenue - lag(daily_revenue, 1) OVER(ORDER BY date), 1),
                0) as revenue_growth_abs,
       coalesce(round(((daily_revenue - lag(daily_revenue, 1) OVER(ORDER BY date)) / lag(daily_revenue, 1) OVER(ORDER BY date)) * 100, 1),
                0) as revenue_growth_percentage
FROM   temp_table
ORDER BY date

/* Couriers with over 10 days employment and number of delivered orders */

SELECT DISTINCT courier_id,
                days_employed,
                count(order_id) OVER(PARTITION BY courier_id) delivered_orders
FROM   (SELECT courier_id,
               order_id,
               action,
               min(date(time)) OVER(PARTITION BY courier_id),
               max(date(time)) OVER(),
               date_part('day',
                         age(max(date(time)) OVER(), min(date(time)) OVER(PARTITION BY courier_id)))::int as days_employed
        FROM   courier_actions) t2
WHERE  action = 'deliver_order'
   and days_employed >= 10
ORDER BY days_employed desc , courier_id


/* top 10% of couriers by the number of orders delivered over the entire period. Couriers ranking*/
SELECT courier_id,
       orders_count,
       row_number() OVER (ORDER BY orders_count desc, courier_id) as courier_rank 
	   FROM(SELECT courier_id,
	   count(order_id) as orders_count
       FROM   courier_actions
       WHERE  action = 'deliver_order'
       GROUP BY courier_id) t1 
	   limit round((SELECT count(distinct courier_id)
       FROM   courier_actions)*0.1)

/* Users created/cancelled orders and cancellation rate*/
SELECT user_id,
       order_id,
       action,
       time,
       created_orders,
       canceled_orders,
       round(canceled_orders::decimal/created_orders, 2) as cancel_rate
FROM   (SELECT user_id,
               order_id,
               action,
               time,
               count(order_id) filter(WHERE action != 'cancel_order') OVER(PARTITION BY user_id
                                                                           ORDER BY time) as created_orders,
               count(order_id) filter(WHERE action = 'cancel_order') OVER(PARTITION BY user_id
                                                                          ORDER BY time) as canceled_orders,
               count(order_id) OVER(PARTITION BY user_id
                                    ORDER BY time) as total_orders
        FROM   user_actions) t1
ORDER BY user_id, order_id, time limit 1000

/* Calculating AVG products' price excl. most expensive*/
SELECT product_id,
       name,
       price,
       round(avg(price) OVER(), 2) as avg_price,
       round(avg(price) filter(WHERE price not in (SELECT max(price)
                                            FROM   products))
OVER(), 2) as avg_price_filtered
FROM   products
ORDER BY price desc, product_id

/* Calculating users' 'First' and 'Repeated' orders. Share of first and repeated orders in total orders by day */

SELECT date,
       order_type,
       orders_count,
       round(orders_count/sum(orders_count) OVER(PARTITION BY date), 2) as orders_share
FROM   (SELECT date,
               order_type,
               count(order_type) orders_count
        FROM   (SELECT order_id,
                       user_id,
                       date(time) as date,
                       min(time) OVER(PARTITION BY user_id
                                      ORDER BY user_id) as min_time,
                       case when time = min(time) OVER(PARTITION BY user_id
                                                        ORDER BY user_id) then 'First'
                            else 'Repeated' end as order_type
                FROM   user_actions
                WHERE  order_id not in (SELECT order_id
                                        FROM   user_actions
                                        WHERE  action = 'cancel_order')) t1
        GROUP BY date, order_type
        ORDER BY date, order_type)t2
ORDER BY date, order_type



SELECT courier_id,
       delivered_orders,
       round(avg(delivered_orders) OVER(), 2) avg_delivered_orders,
       case when delivered_orders > round(avg(delivered_orders) OVER(), 2) then 1
            else 0 end as is_above_avg
FROM   (SELECT courier_id,
               count(order_id) as delivered_orders
        FROM   courier_actions
        WHERE  action = 'deliver_order'
           and date_part('month', time) = 9
           and date_part('year', time) = 2022
        GROUP BY courier_id) t1
ORDER BY courier_id

/* Users' order frequency, time lag between users orders */

SELECT user_id,
       order_id,
       time,
       row_number() OVER(PARTITION BY user_id
                         ORDER BY time) as order_number,
       lag(time, 1) OVER(PARTITION BY user_id
                         ORDER BY time) as time_lag,
       age(time, lag(time, 1) OVER(PARTITION BY user_id)) time_diff
FROM   user_actions
WHERE  order_id not in (SELECT order_id
                        FROM   user_actions
                        WHERE  action = 'cancel_order')
ORDER BY user_id, order_number limit 1000

/* Orders cummulitative count by day */
SELECT date,
       orders_count,
       sum(orders_count) OVER(ORDER BY date)::int orders_cum_count
FROM   (SELECT date(creation_time) as date,
               count(order_id) as orders_count
        FROM   orders
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')
        GROUP BY date) t1

/* Orders that took the longest to deliver */
SELECT t1.order_id
FROM   (SELECT ca.order_id,
               time as delivery_time,
               creation_time,
               age(time, creation_time) as time
        FROM   courier_actions ca
            LEFT JOIN orders o using(order_id)
        WHERE  action = 'deliver_order'
        ORDER BY time desc) t1 limit 10

/* Cancellation rate by Gender */

SELECT coalesce(sex, 'unknown') sex,
       round(avg(cancel_rate), 3) avg_cancel_rate
FROM   (SELECT user_id,
               count(distinct order_id) as orders_count,
               count(distinct order_id) filter (WHERE action = 'cancel_order')::decimal / count(distinct order_id) as cancel_rate
        FROM   user_actions
        GROUP BY user_id
        ORDER BY cancel_rate desc) t1
    LEFT JOIN users t2 using(user_id)
GROUP BY sex
ORDER BY sex

/* Monthly Revenue */

SELECT date(time) as date,
       sum(price) as revenue
FROM   (SELECT u.order_id,
               time,
               o.product_ids,
               unnest(o.product_ids) as product_id
        FROM   user_actions u
            LEFT JOIN orders o using (order_id)
        WHERE  u.order_id not in (SELECT order_id
                                  FROM   user_actions
                                  WHERE  action = 'cancel_order')) t1
    LEFT JOIN products t2
        ON t1.product_id = t2.product_id
GROUP BY date(time)
ORDER BY date

/* AVG order_size per user */
SELECT user_id,
       round(avg(array_length(product_ids, 1)), 2) as avg_order_size
FROM   (SELECT user_id,
               u.order_id,
               product_ids
        FROM   user_actions u
            LEFT JOIN orders o using(order_id)
        WHERE  u.order_id not in (SELECT order_id
                                  FROM   user_actions
                                  WHERE  action = 'cancel_order')) t1
GROUP BY user_id
ORDER BY user_id limit 1000

/* TOP 10 products */
SELECT *
FROM   (SELECT unnest(product_ids) as product_id ,
               count(*) as times_purchased
        FROM   orders
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')
        GROUP BY product_id
        ORDER BY times_purchased desc limit 10) t1
ORDER BY product_id

/* orders delivery time calculation */
SELECT order_id,
       min(time) as time_accepted,
       max(time) as time_delivered,
       (extract(epoch
FROM   max(time) - min(time))/60)::integer as delivery_time
FROM   courier_actions
WHERE  order_id in (SELECT order_id
                    FROM   orders
                    WHERE  array_length(product_ids, 1) > 5)
   and order_id not in (SELECT order_id
                     FROM   user_actions
                     WHERE  action = 'cancel_order')
GROUP BY order_id
ORDER BY order_id

/* average size of orders canceled by male users */
SELECT round(avg(array_length(product_ids, 1)), 3) avg_order_size
FROM   orders
WHERE  order_id in(SELECT order_id
                   FROM   user_actions
                   WHERE  action = 'cancel_order'
                      and user_id in (SELECT user_id
                                   FROM   users
                                   WHERE  sex = 'male'))
