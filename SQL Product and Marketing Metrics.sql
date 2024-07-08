/*Tables:
Users: user_id, sex, birth_date
user_actions: user_id, action, order_id, time
Couriers: courier_id, sex, birth_date
courier_actions: courier_id, action, order_id, time
products: product_id, price, name
orders: order_id, products_ids(array), creation_time
*/

/* Product metrics calculation 
Comparing two ads campaigns the task is to find out why one outperform another using product and marketing metrics for analysis
ARPU, ARPPU, AOV, CAC, ROI, Retention Rate*/

/*
Before getting to advertisement campaign let's calculate couple metrics first
Revenue per user (Cumulitative ARPU) .
Revenue per paying user (Cumulitative ARPPU).
Revenue from an order (Cumulitative AOV) the ratio of revenue for a certain period to the total number of orders for the same period.
*/

SELECT date,
       round(sum(revenue) OVER(ORDER BY date)::decimal/sum(new_users) OVER(ORDER BY date),
             2) as running_arpu,
       round(sum(revenue) OVER(ORDER BY date)::decimal/sum(new_paying_users) OVER(ORDER BY date),
             2) as running_arppu,
       round(sum(revenue) OVER(ORDER BY date)::decimal/sum(count_orders) OVER(ORDER BY date),
             2) as running_aov
FROM   (SELECT date,
               revenue,
               sum(revenue) OVER(ORDER BY date) as total_revenue,
               round((revenue / lag(revenue, 1) OVER(ORDER BY date) * 100) - 100,
                     2) as revenue_change,
               count_orders
        FROM   (SELECT date,
                       sum(price) as revenue,
                       count(distinct order_id) as count_orders
                FROM   (SELECT date(creation_time) as date,
                               order_id,
                               unnest(product_ids) as product_id
                        FROM   orders
                        WHERE  order_id not in (SELECT order_id
                                                FROM   user_actions
                                                WHERE  action = 'cancel_order')) t1
                    LEFT JOIN (SELECT price,
                                      product_id
                               FROM   products) t2 using(product_id)
                GROUP BY date
                ORDER BY date) t3
        ORDER BY date) t4
    LEFT JOIN (SELECT date(time) as date,
                      count(distinct user_id) as paying_users
               FROM   user_actions
               WHERE  order_id not in (SELECT order_id
                                       FROM   user_actions
                                       WHERE  action = 'cancel_order')
               GROUP BY date(time)) t5 using(date)
    LEFT JOIN (SELECT date(time) as date,
                      count(distinct user_id) as total_users
               FROM   user_actions
               GROUP BY date(time)) t6 using(date)
    LEFT JOIN (SELECT date,
                      count(user_id) as new_users
               FROM   (SELECT user_id,
                              min(time::date) as date
                       FROM   user_actions
                       GROUP BY user_id) t7
               GROUP BY date) t8 using (date)
    LEFT JOIN (SELECT date,
                      count(user_id) as new_paying_users
               FROM   (SELECT user_id,
                              min(time::date) as date
                       FROM   user_actions
                       WHERE  order_id not in (SELECT order_id
                                               FROM   user_actions
                                               WHERE  action = 'cancel_order')
                       GROUP BY user_id) t8
               GROUP BY date) t9 using (date)
/*
Result: 
Cumulitative ARPU first day(24/08/22)- 372,57
Cumulitative ARPU last day(08/09/22)- 1012,99

Cumulitative ARPPU first day(24/08/22)- 393,10
Cumulitative ARPPU last day(08/09/22)- 1028,03

Cumulitative AOV first day(24/08/22)- 361,77
Cumulitative AOV last day(08/09/22)- 382,91
*/



/*
ROI metric calculation. Return of investments.
*/

SELECT DISTINCT ads_campaign,
                round((sum(price) OVER(PARTITION BY ads_campaign) - 250000) / 250000 * 100,
                      2) as roi
FROM   (SELECT user_id,
               order_id,
               action,
 case when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8631, 8632, 8638, 8643, 8657, 8673, 8706, 8707, 8715, 8723, 8732, 8739, 8741, 8750, 8751, 8752, 8770, 8774, 8788, 8791, 8804, 8810, 8815, 8828, 8830, 8845, 8853, 8859, 8867,
							  8869, 8876, 8879, 8883, 8896, 8909, 8911, 8933, 8940, 8972, 8976, 8988, 8990, 9002, 9004, 9009, 9019, 9020, 9035, 9036, 9061, 9069, 9071, 9075, 9081, 9085, 9089, 9108, 9113, 9144, 9145, 9146, 
							  9162, 9165, 9167, 9175, 9180, 9182, 9197, 9198, 9210, 9223, 9251, 9257, 9278, 9287, 9291, 9313, 9317, 9321, 9334, 9351, 9391, 9398, 9414, 9420, 9422, 9431, 9450, 9451, 9454, 9472, 9476, 9478, 
							  9491, 9494, 9505, 9512, 9518, 9524, 9526, 9528, 9531, 9535, 9550, 9559, 9561, 9562, 9599, 9603, 9605, 9611, 9612, 9615, 9625, 9633, 9652, 9654, 9655, 9660, 9662, 9667, 9677, 9679, 9689, 9695, 
							  9720, 9726, 9739, 9740, 9762, 9778, 9786, 9794, 9804, 9810, 9813, 9818, 9828, 9831, 9836, 9838, 9845, 9871, 9887, 9891, 9896, 9897, 9916, 9945, 9960, 9963, 9965, 9968, 9971, 9993, 9998, 9999, 
							  10001, 10013, 10016, 10023, 10030, 10051, 10057, 10064, 10082, 10103, 10105, 10122, 10134, 10135)) then 'Campaign № 1' 
							  when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8629, 8630, 8644, 8646, 8650, 8655, 8659, 8660, 8663, 8665, 8670, 8675, 8680, 8681, 8682, 8683, 8694, 8697, 8700, 8704, 8712, 8713, 8719, 8729, 8733, 8742, 8748, 8754, 8771,
							  8794, 8795, 8798, 8803, 8805, 8806, 8812, 8814, 8825, 8827, 8838, 8849, 8851, 8854, 8855, 8870, 8878, 8882, 8886, 8890, 8893, 8900, 8902, 8913, 8916, 8923, 8929, 8935, 8942, 8943, 8949, 8953, 
							  8955, 8966, 8968, 8971, 8973, 8980, 8995, 8999, 9000, 9007, 9013, 9041, 9042, 9047, 9064, 9068, 9077, 9082, 9083, 9095, 9103, 9109, 9117, 9123, 9127, 9131, 9137, 9140, 9149, 9161, 9179, 9181, 
							  9183, 9185, 9190, 9196, 9203, 9207, 9226, 9227, 9229, 9230, 9231, 9250, 9255, 9259, 9267, 9273, 9281, 9282, 9289, 9292, 9303, 9310, 9312, 9315, 9327, 9333, 9335, 9337, 9343, 9356, 9368, 9370, 
							  9383, 9392, 9404, 9410, 9421, 9428, 9432, 9437, 9468, 9479, 9483, 9485, 9492, 9495, 9497, 9498, 9500, 9510, 9527, 9529, 9530, 9538, 9539, 9545, 9557, 9558, 9560, 9564, 9567, 9570, 9591, 9596, 
							  9598, 9616, 9631, 9634, 9635, 9636, 9658, 9666, 9672, 9684, 9692, 9700, 9704, 9706, 9711, 9719, 9727, 9735, 9741, 9744, 9749, 9752, 9753, 9755, 9757, 9764, 9783, 9784, 9788, 9790, 9808, 9820, 
							  9839, 9841, 9843, 9853, 9855, 9859, 9863, 9877, 9879, 9880, 9882, 9883, 9885, 9901, 9904, 9908, 9910, 9912, 9920, 9929, 9930, 9935, 9939, 9958, 9959, 9961, 9983, 10027, 10033, 10038, 10045, 10047, 
							  10048, 10058, 10059, 10067, 10069, 10073, 10075, 10078, 10079, 10081, 10092, 10106, 10110, 10113, 10131)) then 'Campaign № 2' 
							  else 'unknown' 
							  end as ads_campaign                                       
        FROM   user_actions
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')) as t1
    LEFT JOIN (SELECT *
               FROM   (SELECT order_id,
                              unnest(product_ids) as product_id
                       FROM   orders) t2
                   LEFT JOIN products using(product_id)) t3 using(order_id)
WHERE  ads_campaign in ('Campaign № 1', 'Campaign № 2')
ORDER BY roi desc
/*
Result: Campaign 1- 14.5, Campaign 2- -1.61
Seems like leads from the first marketing campaign brings us much more value comparison to Campaign № 2.
But Why, let's find out
*/




/*
CAC metric- Customer acquisition costs calculation assuming total costs for marketing campaign are 250 000e.
*/

SELECT ads_campaign,
       round((250000::decimal / count(distinct user_id)), 2) as cac
FROM   (SELECT user_id,
               case when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8631, 8632, 8638, 8643, 8657, 8673, 8706, 8707, 8715, 8723, 8732, 8739, 8741, 8750, 8751, 8752, 8770, 8774, 8788, 8791, 8804, 8810, 8815, 8828, 8830, 8845, 8853, 8859, 8867,
							  8869, 8876, 8879, 8883, 8896, 8909, 8911, 8933, 8940, 8972, 8976, 8988, 8990, 9002, 9004, 9009, 9019, 9020, 9035, 9036, 9061, 9069, 9071, 9075, 9081, 9085, 9089, 9108, 9113, 9144, 9145, 9146, 
							  9162, 9165, 9167, 9175, 9180, 9182, 9197, 9198, 9210, 9223, 9251, 9257, 9278, 9287, 9291, 9313, 9317, 9321, 9334, 9351, 9391, 9398, 9414, 9420, 9422, 9431, 9450, 9451, 9454, 9472, 9476, 9478, 
							  9491, 9494, 9505, 9512, 9518, 9524, 9526, 9528, 9531, 9535, 9550, 9559, 9561, 9562, 9599, 9603, 9605, 9611, 9612, 9615, 9625, 9633, 9652, 9654, 9655, 9660, 9662, 9667, 9677, 9679, 9689, 9695, 
							  9720, 9726, 9739, 9740, 9762, 9778, 9786, 9794, 9804, 9810, 9813, 9818, 9828, 9831, 9836, 9838, 9845, 9871, 9887, 9891, 9896, 9897, 9916, 9945, 9960, 9963, 9965, 9968, 9971, 9993, 9998, 9999, 
							  10001, 10013, 10016, 10023, 10030, 10051, 10057, 10064, 10082, 10103, 10105, 10122, 10134, 10135)) then 'Campaign № 1' 
							  when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8629, 8630, 8644, 8646, 8650, 8655, 8659, 8660, 8663, 8665, 8670, 8675, 8680, 8681, 8682, 8683, 8694, 8697, 8700, 8704, 8712, 8713, 8719, 8729, 8733, 8742, 8748, 8754, 8771,
							  8794, 8795, 8798, 8803, 8805, 8806, 8812, 8814, 8825, 8827, 8838, 8849, 8851, 8854, 8855, 8870, 8878, 8882, 8886, 8890, 8893, 8900, 8902, 8913, 8916, 8923, 8929, 8935, 8942, 8943, 8949, 8953, 
							  8955, 8966, 8968, 8971, 8973, 8980, 8995, 8999, 9000, 9007, 9013, 9041, 9042, 9047, 9064, 9068, 9077, 9082, 9083, 9095, 9103, 9109, 9117, 9123, 9127, 9131, 9137, 9140, 9149, 9161, 9179, 9181, 
							  9183, 9185, 9190, 9196, 9203, 9207, 9226, 9227, 9229, 9230, 9231, 9250, 9255, 9259, 9267, 9273, 9281, 9282, 9289, 9292, 9303, 9310, 9312, 9315, 9327, 9333, 9335, 9337, 9343, 9356, 9368, 9370, 
							  9383, 9392, 9404, 9410, 9421, 9428, 9432, 9437, 9468, 9479, 9483, 9485, 9492, 9495, 9497, 9498, 9500, 9510, 9527, 9529, 9530, 9538, 9539, 9545, 9557, 9558, 9560, 9564, 9567, 9570, 9591, 9596, 
							  9598, 9616, 9631, 9634, 9635, 9636, 9658, 9666, 9672, 9684, 9692, 9700, 9704, 9706, 9711, 9719, 9727, 9735, 9741, 9744, 9749, 9752, 9753, 9755, 9757, 9764, 9783, 9784, 9788, 9790, 9808, 9820, 
							  9839, 9841, 9843, 9853, 9855, 9859, 9863, 9877, 9879, 9880, 9882, 9883, 9885, 9901, 9904, 9908, 9910, 9912, 9920, 9929, 9930, 9935, 9939, 9958, 9959, 9961, 9983, 10027, 10033, 10038, 10045, 10047, 
							  10048, 10058, 10059, 10067, 10069, 10073, 10075, 10078, 10079, 10081, 10092, 10106, 10110, 10113, 10131)) then 'Campaign № 2' 
							  else 'unknown' 
							  end as ads_campaign
        FROM   user_actions
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')) as t1
WHERE  ads_campaign in ('Campaign № 1', 'Campaign № 2')
GROUP BY ads_campaign
ORDER BY cac desc
/*
Result: CAC: Campaign 1- 1,461.99, Campaign 2- 1,068.38
So, we found out that the first advertising campaign allows you to attract higher quality leads. 
But the reason for these differences is not yet entirely clear. 
*/


/*
Why do users from the first advertising channel bring us more money (ROI)? Maybe they have a higher average bill?
Let's find out
*/
SELECT ads_campaign,
       round(avg(avg_order_price), 2) as avg_check
FROM   (SELECT ads_campaign,
               user_id,
               avg(order_price) as avg_order_price
        FROM   (SELECT user_id,
                       order_id,
                       action,
                       date(time) as date,
                       case when user_id in (SELECT user_id
                                      FROM   user_actions
                                      WHERE  user_id in (8631, 8632, 8638, 8643, 8657, 8673, 8706, 8707, 8715, 8723, 8732, 8739, 8741, 8750, 8751, 8752, 8770, 8774, 8788, 8791, 8804, 8810, 8815, 8828, 8830, 8845, 8853, 8859, 8867, 8869, 8876, 8879, 8883, 8896, 8909, 8911, 8933, 8940, 8972, 8976, 8988, 8990, 9002, 9004, 9009, 9019, 9020, 9035, 9036, 9061, 9069, 9071, 9075, 9081, 9085, 9089, 9108, 9113, 9144, 9145, 9146, 9162, 9165, 9167, 9175, 9180, 9182, 9197, 9198, 9210, 9223, 9251, 9257, 9278, 9287, 9291, 9313, 9317, 9321, 9334, 9351, 9391, 9398, 9414, 9420, 9422, 9431, 9450, 9451, 9454, 9472, 9476, 9478, 9491, 9494, 9505, 9512, 9518, 9524, 9526, 9528, 9531, 9535, 9550, 9559, 9561, 9562, 9599, 9603, 9605, 9611, 9612, 9615, 9625, 9633, 9652, 9654, 9655, 9660, 9662, 9667, 9677, 9679, 9689, 9695, 9720, 9726, 9739, 9740, 9762, 9778, 9786, 9794, 9804, 9810, 9813, 9818, 9828, 9831, 9836, 9838, 9845, 9871, 9887, 9891, 9896, 9897, 9916, 9945, 9960, 9963, 9965, 9968, 9971, 9993, 9998, 9999, 10001, 10013, 10016, 10023, 10030, 10051, 10057, 10064, 10082, 10103, 10105, 10122, 10134, 10135)) then 'Кампания № 1' when user_id in (SELECT user_id
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         FROM   user_actions
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         WHERE  user_id in (8629, 8630, 8644, 8646, 8650, 8655, 8659, 8660, 8663, 8665, 8670, 8675, 8680, 8681, 8682, 8683, 8694, 8697, 8700, 8704, 8712, 8713, 8719, 8729, 8733, 8742, 8748, 8754, 8771, 8794, 8795, 8798, 8803, 8805, 8806, 8812, 8814, 8825, 8827, 8838, 8849, 8851, 8854, 8855, 8870, 8878, 8882, 8886, 8890, 8893, 8900, 8902, 8913, 8916, 8923, 8929, 8935, 8942, 8943, 8949, 8953, 8955, 8966, 8968, 8971, 8973, 8980, 8995, 8999, 9000, 9007, 9013, 9041, 9042, 9047, 9064, 9068, 9077, 9082, 9083, 9095, 9103, 9109, 9117, 9123, 9127, 9131, 9137, 9140, 9149, 9161, 9179, 9181, 9183, 9185, 9190, 9196, 9203, 9207, 9226, 9227, 9229, 9230, 9231, 9250, 9255, 9259, 9267, 9273, 9281, 9282, 9289, 9292, 9303, 9310, 9312, 9315, 9327, 9333, 9335, 9337, 9343, 9356, 9368, 9370, 9383, 9392, 9404, 9410, 9421, 9428, 9432, 9437, 9468, 9479, 9483, 9485, 9492, 9495, 9497, 9498, 9500, 9510, 9527, 9529, 9530, 9538, 9539, 9545, 9557, 9558, 9560, 9564, 9567, 9570, 9591, 9596, 9598, 9616, 9631, 9634, 9635, 9636, 9658, 9666, 9672, 9684, 9692, 9700, 9704, 9706, 9711, 9719, 9727, 9735, 9741, 9744, 9749, 9752, 9753, 9755, 9757, 9764, 9783, 9784, 9788, 9790, 9808, 9820, 9839, 9841, 9843, 9853, 9855, 9859, 9863, 9877, 9879, 9880, 9882, 9883, 9885, 9901, 9904, 9908, 9910, 9912, 9920, 9929, 9930, 9935, 9939, 9958, 9959, 9961, 9983, 10027, 10033, 10038, 10045, 10047, 10048, 10058, 10059, 10067, 10069, 10073, 10075, 10078, 10079, 10081, 10092, 10106, 10110, 10113, 10131)) then 'Кампания № 2' else 'unknown' end as ads_campaign
                FROM   user_actions) as t1
            LEFT JOIN (SELECT order_id,
                              sum(price) as order_price
                       FROM   (SELECT order_id,
                                      unnest(product_ids) as product_id
                               FROM   orders) t2
                           LEFT JOIN products using(product_id)
                       GROUP BY order_id) t3 using(order_id)
        WHERE  ads_campaign in ('Кампания № 1', 'Кампания № 2')
           and date between '2022-09-01'
           and '2022-09-07 23:59:59'
           and order_id not in (SELECT order_id
                             FROM   user_actions
                             WHERE  action = 'cancel_order')
        GROUP BY user_id, ads_campaign) t4
GROUP BY ads_campaign
ORDER BY avg_check desc
/*
Result: AVG check Campaign 1- 380.88, Campaign 2- 371.73

We calculated the average bill, but did not receive an answer to our question. 
What then could be the matter with so much difference in ROI between two campaigns? 
Let's pay attention to another important indicator - Retention rate.
*/



/*
Retention for all users, dividing them into batches based on the date of their first interaction with the app.
*/

SELECT date_trunc('month', start_date)::date as start_month,
       start_date,
       (date-start_date)::int as day_number,
       round(user_cnt::decimal / max(user_cnt) OVER(PARTITION BY start_date),
             2) as retention
FROM   (SELECT count(distinct user_id) as user_cnt,
               start_date,
               date
        FROM   (SELECT user_id,
                       min(time::date) OVER(PARTITION BY user_id) as start_date,
                       time::date as date
                FROM   user_actions) t1
        GROUP BY start_date, date) t2
ORDER BY start_date, day_number
/*
Result: AVG overall retention is 0.24
Let's break down retention by advertisement campaigns
*/

/*
Retention rate by our ads campaigns  broken down by the very first and 7th day right after ads campaign have been finished. 
Thus we will see how many of newly acquired customers keep using our app within next 7 days.
*/

SELECT ads_campaign,
       start_date,
       (date-start_date)::int as day_number,
       round(user_cnt::decimal / max(user_cnt) OVER(PARTITION BY start_date,
                                                                 ads_campaign), 2) as retention
FROM   (SELECT count(distinct user_id) as user_cnt,
               start_date,
               date,
               ads_campaign
        FROM   (SELECT user_id,
                       min(time::date) OVER(PARTITION BY user_id) as start_date,
                       date(time) as date,
					   case when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8631, 8632, 8638, 8643, 8657, 8673, 8706, 8707, 8715, 8723, 8732, 8739, 8741, 8750, 8751, 8752, 8770, 8774, 8788, 8791, 8804, 8810, 8815, 8828, 8830, 8845, 8853, 8859, 8867,
							  8869, 8876, 8879, 8883, 8896, 8909, 8911, 8933, 8940, 8972, 8976, 8988, 8990, 9002, 9004, 9009, 9019, 9020, 9035, 9036, 9061, 9069, 9071, 9075, 9081, 9085, 9089, 9108, 9113, 9144, 9145, 9146, 
							  9162, 9165, 9167, 9175, 9180, 9182, 9197, 9198, 9210, 9223, 9251, 9257, 9278, 9287, 9291, 9313, 9317, 9321, 9334, 9351, 9391, 9398, 9414, 9420, 9422, 9431, 9450, 9451, 9454, 9472, 9476, 9478, 
							  9491, 9494, 9505, 9512, 9518, 9524, 9526, 9528, 9531, 9535, 9550, 9559, 9561, 9562, 9599, 9603, 9605, 9611, 9612, 9615, 9625, 9633, 9652, 9654, 9655, 9660, 9662, 9667, 9677, 9679, 9689, 9695, 
							  9720, 9726, 9739, 9740, 9762, 9778, 9786, 9794, 9804, 9810, 9813, 9818, 9828, 9831, 9836, 9838, 9845, 9871, 9887, 9891, 9896, 9897, 9916, 9945, 9960, 9963, 9965, 9968, 9971, 9993, 9998, 9999, 
							  10001, 10013, 10016, 10023, 10030, 10051, 10057, 10064, 10082, 10103, 10105, 10122, 10134, 10135)) then 'Campaign № 1' 
							  when user_id in (SELECT user_id
                              FROM   user_actions
                              WHERE  user_id in (8629, 8630, 8644, 8646, 8650, 8655, 8659, 8660, 8663, 8665, 8670, 8675, 8680, 8681, 8682, 8683, 8694, 8697, 8700, 8704, 8712, 8713, 8719, 8729, 8733, 8742, 8748, 8754, 8771,
							  8794, 8795, 8798, 8803, 8805, 8806, 8812, 8814, 8825, 8827, 8838, 8849, 8851, 8854, 8855, 8870, 8878, 8882, 8886, 8890, 8893, 8900, 8902, 8913, 8916, 8923, 8929, 8935, 8942, 8943, 8949, 8953, 
							  8955, 8966, 8968, 8971, 8973, 8980, 8995, 8999, 9000, 9007, 9013, 9041, 9042, 9047, 9064, 9068, 9077, 9082, 9083, 9095, 9103, 9109, 9117, 9123, 9127, 9131, 9137, 9140, 9149, 9161, 9179, 9181, 
							  9183, 9185, 9190, 9196, 9203, 9207, 9226, 9227, 9229, 9230, 9231, 9250, 9255, 9259, 9267, 9273, 9281, 9282, 9289, 9292, 9303, 9310, 9312, 9315, 9327, 9333, 9335, 9337, 9343, 9356, 9368, 9370, 
							  9383, 9392, 9404, 9410, 9421, 9428, 9432, 9437, 9468, 9479, 9483, 9485, 9492, 9495, 9497, 9498, 9500, 9510, 9527, 9529, 9530, 9538, 9539, 9545, 9557, 9558, 9560, 9564, 9567, 9570, 9591, 9596, 
							  9598, 9616, 9631, 9634, 9635, 9636, 9658, 9666, 9672, 9684, 9692, 9700, 9704, 9706, 9711, 9719, 9727, 9735, 9741, 9744, 9749, 9752, 9753, 9755, 9757, 9764, 9783, 9784, 9788, 9790, 9808, 9820, 
							  9839, 9841, 9843, 9853, 9855, 9859, 9863, 9877, 9879, 9880, 9882, 9883, 9885, 9901, 9904, 9908, 9910, 9912, 9920, 9929, 9930, 9935, 9939, 9958, 9959, 9961, 9983, 10027, 10033, 10038, 10045, 10047, 
							  10048, 10058, 10059, 10067, 10069, 10073, 10075, 10078, 10079, 10081, 10092, 10106, 10110, 10113, 10131)) then 'Campaign № 2' 
							  else 'unknown' 
							  end as ads_campaign                 
                FROM   user_actions) as t1
        WHERE  ads_campaign in ('Campaign № 1', 'Campaign № 2')
        GROUP BY start_date, date, ads_campaign)t2
WHERE  (date-start_date)::int in (0, 1, 7)
ORDER BY ads_campaign, day_number
/*
Result: 
Campaign 1, day 0- Retention- 1; Campaign 2, day 0- Retention- 1
Campaign 1, day 1- Retention- 0.42; Campaign 2, day 1- Retention- 0.17
Campaign 1, day 7- Retention- 0.22; Campaign 2, day 7- Retention- 0.09
*/



/*
Conclusion
Users from both advertising campaigns do not differ in terms of all metrics applied, 
so WHY ROI is so much higher for Campaign №1.
The answer is- the Retention rate is almost twice as high for the first advertising campaign 0.22 vs 0.09. 
This leads to the fact that users from the first campaign bring us more value.
/*