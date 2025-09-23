/*Задача 1. Расчёт DAU
Первая задача — расчёт DAU. 
Рассчитайте ежедневное количество активных зарегистрированных клиентов (user_id) за май и июнь 2021 года в городе Саранске.
 Критерием активности клиента считайте размещение заказа. 
Это позволит оценить эффективность вовлечения клиентов в ключевую бизнес-цель — совершение покупки.
Необходимо вывести следующие поля:
log_date — дата события.
DAU — количество активных зарегистрированных клиентов.
Отсортируйте результат по дате события в возрастающем порядке.
Для проверки решения ограничьте выгрузку первыми десятью строками.*/

select log_date as "Дата",
count( distinct user_id) as DAU 
from rest_analytics.analytics_events as a 
join rest_analytics.cities as c on a.city_id=c.city_id
where log_date >= '2021-05-01' and log_date<= '2021-06-30' and city_name='Саранск' and event='order'
group by log_date 
 order by log_date 
 limit 10
 /*Дата	dau
2021-05-01	56
2021-05-02	36
2021-05-03	72
2021-05-04	85
2021-05-05	60
2021-05-06	52
2021-05-07	52
2021-05-08	52
2021-05-09	33
2021-05-10	35*/
 
 
/*Задача 2.Расчёт Conversion Rate
Теперь вам нужно определить активность аудитории: 
как часто зарегистрированные пользователи переходят к размещению заказа, будет ли одинаковым этот показатель по дням или видны сезонные колебания в поведении пользователей.
Для решения этой задачи рассчитайте конверсию зарегистрированных пользователей, которые посещают приложение, в активных клиентов. 
Напомним, что критерий активности — размещение заказа.
Конверсия должна быть рассчитана за каждый день в мае и июне 2021 года для клиентов из Саранска.
Необходимо вывести следующие поля:
log_date — дата события.
CR — значение конверсии.
Отсортируйте результат по дню активности в возрастающем порядке.
 Округлите значение конверсии до двух знаков после точки.
  Для проверки решения ограничьте выгрузку первыми десятью строками.*/
 select log_date as "Дата",
round((count( distinct user_id) filter(where event='order'))/count( distinct user_id)::numeric,2) as cr 
from rest_analytics.analytics_events as a 
join rest_analytics.cities as c on a.city_id=c.city_id
where log_date >= '2021-05-01' and log_date<= '2021-06-30' and city_name='Саранск' 
group by log_date 
order by log_date 
limit 10
/*Дата	cr
2021-05-01	0.43
2021-05-02	0.28
2021-05-03	0.41
2021-05-04	0.41
2021-05-05	0.32
2021-05-06	0.25
2021-05-07	0.28
2021-05-08	0.33
2021-05-09	0.28
2021-05-10	0.3*/


/*Задача 3. Расчёт среднего чека
Следующая метрика, за которой следят аналитики сервиса «Всё.из.кафе», — средний чек.
 В рамках этой задачи вам предстоит рассчитать средний чек активных клиентов в Саранске в мае и в июне.
Напомним: средний чек — это средний доход за одну транзакцию, то есть заказ. 
Учитывайте, что вы анализируете средний чек сервиса доставки, а не ресторанов. 
Значит, вам необходимо вычислить его как среднее значение комиссии со всех заказов за месяц. 
Таким образом, для корректного расчёта метрики вычислите общий размер комиссии и количество заказов. 
Разделив сумму комиссии на количество заказов, вы рассчитаете величину среднего чека за месяц.
Необходимо вывести следующие поля:
"Месяц" — месяц события.
"Количество заказов" — количество заказов за месяц.
"Сумма комиссии" — сумма комиссии за месяц.
"Средний чек" — средняя комиссия на одну транзакцию.
Сумму комиссии и среднего чека округлите до копеек. Результат отсортируйте по полю с месяцем в возрастающем порядке.*/
WITH orders AS
    (SELECT *,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')
SELECT CAST(DATE_TRUNC('month', log_date) AS date) AS "Месяц",
       COUNT(DISTINCT order_id) AS "Количество заказов",
       ROUND(SUM(commission_revenue)::numeric, 2) AS "Сумма комиссии",
       ROUND((SUM(commission_revenue) / COUNT(DISTINCT order_id))::numeric, 2) AS "Средний чек"
FROM orders
GROUP BY "Месяц"
ORDER BY "Месяц";

/*Месяц	Количество заказов	Сумма комиссии	Средний чек
2021-05-01	2111	286852	135.88
2021-06-01	2225	328539	147.66*/

/*Задача 4. Расчёт LTV ресторанов
Определите три ресторана из Саранска с наибольшим LTV с начала мая до конца июня. 
Как правило, LTV рассчитывается для пользователя приложения. Однако клиентами для сервиса доставки будут и рестораны, как и пользователи, которые делают заказы.
В рамках этой задачи считайте LTV как суммарную комиссию, которая была получена от заказов в ресторане за эти два месяца.
Необходимо вывести следующие поля:
rest_id — уникальный идентификатор сети, к которой принадлежит ресторан.
"Название сети" — название сети, к которой принадлежит ресторан.
"Тип кухни" — тип кухни ресторана.
LTV — суммарная комиссия, которая была получена от заказов в ресторане за эти два месяца, округлённая до копеек.
Результат отсортируйте по полю LTV в убывающем порядке.*/

WITH orders AS
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            revenue * commission AS commission_revenue
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')
SELECT orders.rest_id,
       chain AS "Название сети",
       type AS "Тип кухни",
       ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
FROM orders
JOIN rest_analytics.partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id
GROUP BY 1, 2, 3
ORDER BY LTV DESC
LIMIT 3;
/* rest_id	                         Название сети           Тип кухни    ltv
2e2b2b9c458b42ce9da395ba9c247fdc	Гурманское Наслаждение	Ресторан	170479
b94505e7efff41d2b2bf6bbb78fe71f2	Гастрономический Шторм	Ресторан	164508
42d14fe9fd254ba9b18ab4acd64d4f33	Шоколадный Рай	Кондитерская	61199.8
 */

/*Задача 5. Расчёт LTV ресторанов — самые популярные блюда
Как вы видите, наибольший LTV с большим отрывом у двух ресторанов Саранска: «Гурманское Наслаждение» и «Гастрономический Шторм». 
Теперь вам нужно узнать, сколько LTV принесли пять самых популярных блюд этих ресторанов. 
При этом популярных блюд должно быть всего пять, а не по пять из каждого ресторана.
Вам необходимо проанализировать данные о ресторанах и их блюдах, чтобы определить вклад самых популярных блюд из двух ресторанов Саранска — «Гурманское Наслаждение» и «Гастрономический Шторм» — в общий показатель LTV. Для этого нужно выбрать пять блюд с максимальным LTV за весь рассматриваемый период, то есть за май — июнь, из этих двух ресторанов.
Для каждого блюда требуется вывести название ресторана, название блюда, признаки того, является ли блюдо острым, рыбным или мясным, а также значение LTV, округлённое до копеек.
Необходимо вывести следующие поля:
"Название сети" — название сети, к которой принадлежит ресторан.
"Название блюда" — название блюда, которое оказалось популярным.
spicy — логический признак острых блюд. 1 — блюдо острое.
fish — логический признак рыбных блюд. 1 — блюдо содержит морепродукты.
meat — логический признак мясных блюд. 1 — блюдо содержит мясо.
LTV — суммарная комиссия, которая была получена от заказов блюда в ресторане за эти два месяца, округлённая до копеек.
Результаты следует отсортировать по значению LTV в порядке убывания. В решении используйте эталонный код предыдущей задачи.*/
WITH orders AS
  (SELECT events.rest_id,
          events.city_id,
          events.object_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'), 
-- Рассчитываем два ресторана с наибольшим LTV
top_ltv_restaurants AS
  (SELECT orders.rest_id,
          chain,
          type,
          ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
   FROM orders
   JOIN rest_analytics.partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id 
   GROUP BY 1, 2, 3
   ORDER BY LTV DESC
   LIMIT 2)
SELECT chain AS "Название сети",
       dishes.name AS "Название блюда",
       spicy,
       fish,
       meat,
       ROUND(SUM(orders.commission_revenue)::numeric, 2) AS LTV
FROM orders
JOIN top_ltv_restaurants ON orders.rest_id = top_ltv_restaurants.rest_id
JOIN rest_analytics.dishes ON orders.object_id = dishes.object_id
AND top_ltv_restaurants.rest_id = dishes.rest_id
GROUP BY 1, 2, 3, 4, 5
ORDER BY LTV DESC
LIMIT 5;
Название сети	Название блюда	spicy	fish	meat	ltv
Гастрономический Шторм	brokkoli zapechennaja v duhovke s jajcami i travami	0	1	1	41140.4
Гурманское Наслаждение	govjazhi shashliki v pesto iz kinzi	0	1	1	36676.8
Гурманское Наслаждение	medaloni iz lososja	0	1	1	14946.9
Гурманское Наслаждение	myasnye ezhiki	0	0	1	14337.9
Гастрономический Шторм	teljatina s sousom iz belogo vina petrushki	0	1	1	13981


/*Название сети	Название блюда	spicy	fish	meat	ltv
Гастрономический Шторм	brokkoli zapechennaja v duhovke s jajcami i travami	0	1	1	41140.4
Гурманское Наслаждение	govjazhi shashliki v pesto iz kinzi	0	1	1	36676.8
Гурманское Наслаждение	medaloni iz lososja	0	1	1	14946.9
Гурманское Наслаждение	myasnye ezhiki	0	0	1	14337.9
Гастрономический Шторм	teljatina s sousom iz belogo vina petrushki	0	1	1	13981*/

/*Задача 6. Расчёт Retention Rate
В рамках этой задачи вам предстоит определить показатель возвращаемости: какой процент пользователей возвращается в приложение в течение первой недели после регистрации и в какие дни. Рассчитайте показатель Retention Rate в первую неделю для всех новых пользователей в Саранске.
Напомним, что в проекте вы анализируете данные за май и июнь, и для корректного расчёта недельного Retention Rate нужно, чтобы с момента первого посещения прошла хотя бы неделя. Поэтому для этой задачи ограничьте дату первого посещения продукта, выбрав промежуток с начала мая по 24 июня. Retention Rate считайте по любой активности пользователей, а не только по факту размещения заказа.
В данных могут встречаться дубликаты по полю user_id, поэтому для корректного расчёта используйте условие log_date >= first_date.
Вам необходимо вывести следующие поля:
day_since_install — срок жизни пользователя в днях.
retained_users — количество пользователей, которые вернулись в приложение в конкретный день.
retention_rate — коэффициент удержания для вернувшихся пользователей по отношению к общему числу пользователей, которые установили приложение.
Результаты отсортируйте по полю day_since_install в порядке возрастания. Округлите метрику Retention Rate до двух знаков после точки.*/
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

daily_retention AS
    (SELECT new_users.user_id,
            first_date,
            log_date::date - first_date::date AS day_since_install
     FROM new_users
     JOIN active_users ON new_users.user_id = active_users.user_id
     AND log_date >= first_date)

SELECT day_since_install,
       COUNT(DISTINCT user_id) AS retained_users,
       ROUND((1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (ORDER BY day_since_install))::numeric, 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY day_since_install
ORDER BY day_since_install;

/*day_since_install	retained_users	retention_rate
0	5572	1
1	768	0.14
2	419	0.08
3	283	0.05
4	251	0.05
5	207	0.04
6	205	0.04
7	205	0.044*/


/*Задача 7. Сравнение Retention Rate по месяцам
Используя эталонный код из предыдущей задачи, разделите пользователей на две когорты по месяцу первого посещения продукта. Так вы сможете сравнить Retention Rate этих когорт между собой.
Необходимо вывести следующие поля:
"Месяц" — месяц первого посещения продукта.
day_since_install — срок жизни пользователя в днях.
retained_users — количество пользователей, которые вернулись в приложение в конкретный день.
retention_rate — коэффициент удержания для вернувшихся пользователей по отношению к общему числу пользователей, которые установили приложение в день установки.
Результаты отсортируйте по полям "Месяц" и day_since_install в порядке возрастания. Метрику Retention Rate округлите до двух знаков после точки.*/
-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM rest_analytics.analytics_events
     JOIN rest_analytics.cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

-- Соединяем таблицы с новыми и активными пользователями
daily_retention AS
    (SELECT new_users.user_id,
            first_date,
            log_date::date - first_date::date AS day_since_install
     FROM new_users
     JOIN active_users ON new_users.user_id = active_users.user_id
     AND log_date >= first_date)
     
SELECT DISTINCT CAST(DATE_TRUNC('month', first_date) AS date) AS "Месяц",
                day_since_install,
                COUNT(DISTINCT user_id) AS retained_users,
                ROUND((1.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (PARTITION BY CAST(DATE_TRUNC('month', first_date) AS date) ORDER BY day_since_install))::numeric, 2) AS retention_rate
FROM daily_retention
WHERE day_since_install < 8
GROUP BY "Месяц", day_since_install
ORDER BY "Месяц", day_since_install;
/*Месяц	day_since_install	retained_users	retention_rate
2021-05-01	0	3069	1
2021-05-01	1	443	0.14
2021-05-01	2	223	0.07
2021-05-01	3	144	0.05
2021-05-01	4	142	0.05
2021-05-01	5	122	0.04
2021-05-01	6	120	0.04
2021-05-01	7	140	0.05
2021-06-01	0	2576	1
2021-06-01	1	328	0.13
2021-06-01	2	196	0.08
2021-06-01	3	140	0.05
2021-06-01	4	109	0.04
2021-06-01	5	86	0.03
2021-06-01	6	85	0.03
2021-06-01	7	65	0.03*/
