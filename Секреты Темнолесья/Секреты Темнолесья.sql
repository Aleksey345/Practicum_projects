/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Сурков Алексей Александрович 
 * Дата: 01.11.2024
*/

--  Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT
    COUNT(*) AS total_players,
    SUM(payer) AS plat_players,
    ROUND((SUM(payer)::numeric* 100) / COUNT(*)::numeric) AS dolay
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT r.race ,
SUM(u.payer) AS plat_players,
COUNT(u.*) AS total_players,
SUM(u.payer)::numeric/COUNT(*)::numeric AS players
FROM fantasy.users AS u 
LEFT JOIN fantasy.race AS r ON u.race_id=r.race_id
GROUP BY r.race; 

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT
    COUNT(*) AS total_purchases,
    SUM(amount) AS total_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    AVG(amount) AS avg_amount,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
    STDDEV(amount) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT
    COUNT(*) AS zero_purchases,
    COUNT(*)::numeric  * 100 / (SELECT COUNT(*)::numeric FROM fantasy.events) AS zero_purchase_percentage,(SELECT
    COUNT(*)AS total FROM fantasy.events)
FROM fantasy.events
WHERE amount = 0;
-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
WITH Playerpurchases AS (
    SELECT
        u.id,
        u.payer,
        COUNT(*)FILTER (WHERE amount > 0) AS purchase_count,
        SUM(e.amount) AS total_purchase_amount
    FROM fantasy.users u
    JOIN fantasy.events e ON u.id = e.id
    GROUP BY u.id, u.payer
)
SELECT
    payer,
     COUNT( id) AS total_players,
    AVG(purchase_count) AS avg_purchases_per_player,
    AVG(total_purchase_amount) AS avg_total_amount_per_player
FROM Playerpurchases
GROUP BY payer;

-- 2.4: Популярные эпические предметы:
WITH epic_items AS (
    SELECT i.game_items,
           COUNT(e.transaction_id) AS total_purchases,
           COUNT(DISTINCT u.id) AS total_players
    FROM fantasy.items AS i
    JOIN fantasy.events AS e ON i.item_code = e.item_code
    JOIN fantasy.users AS u ON u.id = e.id
    WHERE e.amount > 0
    GROUP BY i.game_items), 
total_purchases AS (
    SELECT
    SUM(total_purchases) AS sum_purchases
    FROM epic_items
)SELECT e.game_items,
       ROUND((e.total_purchases::NUMERIC * 100) / (SELECT sum_purchases FROM total_purchases), 2) AS relative_percentage,
       ROUND((e.total_players::numeric * 100) / (SELECT COUNT(DISTINCT id) FROM fantasy.users), 2) AS player_percentage
FROM epic_items AS e
WHERE e.total_purchases > 0
ORDER BY e.total_players DESC;

-- Часть 2. Решение ad hoc-задач
--  Зависимость активности игроков от расы персонажа:
WITH players AS (
SELECT r.race , r.race_id,
COUNT(*) AS total_players,
SUM(u.payer) AS plat_players,
SUM(u.payer)::numeric/COUNT(*)::numeric AS player_dolya
FROM fantasy.users AS u 
LEFT JOIN fantasy.race AS r ON u.race_id=r.race_id
GROUP BY r.race, r.race_id),  
activ_players AS 
(SELECT u.race_id,
sum(amount) AS total_amount,
count(transaction_id)AS total_purchases,
count(DISTINCT e.id) AS total_players
FROM fantasy.events AS e
LEFT JOIN fantasy.users AS u ON e.id = u.id
WHERE amount>0
GROUP BY  u.race_id)
SELECT 
    p.race,
    p.total_players,
    p.plat_players,
    p.player_dolya,
    ap.total_purchases AS total_purchases,
    ap.total_amount AS total_amount,
    round(ap.total_purchases::numeric /ap.total_players,2) AS avg_purchases_per_player,
   round(ap.total_amount::numeric /ap.total_players,2) AS avg_purchase_value_per_player,
     Round(ap.total_players::numeric/p.total_players::numeric,2)AS purchases_dolya,
     round(ap.total_purchases::numeric /ap.total_players,2)*round(ap.total_amount::numeric /ap.total_players,2)AS avg_pok
    FROM players AS p
LEFT JOIN activ_players AS ap USING(race_id); 


