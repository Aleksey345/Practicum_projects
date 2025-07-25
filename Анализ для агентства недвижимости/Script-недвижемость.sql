/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор:Сурков Алексей Александрович 
 * Дата:21.11.2024
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
), categories AS (
    SELECT 
        CASE 
            WHEN c.city='Санкт-Петербург' THEN 'Санкт-Петербург' 
            ELSE 'ЛенОбл'
        END AS region,
        CASE
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN 'Месяц'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN 'Квартал'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN 'Полгода'
            WHEN days_exposition IS NULL THEN 'незакрытые объявления'
            ELSE 'Более полугода'
        END AS activity_period,
        a.last_price / f.total_area AS price_per_sqm, 
        f.total_area,
        f.rooms,
        f.balcony,
        f.ceiling_height,
  t.type
    FROM real_estate.city AS c 
    JOIN real_estate.flats AS f USING (city_id)
    JOIN real_estate.advertisement AS a USING (id)
    JOIN real_estate.type AS t USING (type_id)
    WHERE f.id IN (SELECT * FROM filtered_id) AND t.TYPE='город'
)
SELECT 
    region,
    activity_period,
    COUNT(*) AS total,
    ROUND(AVG(price_per_sqm)::NUMERIC,2) AS avg_price_per_sqm,-- средня за кв. метр 
    ROUND(AVG(total_area)::NUMERIC,2) AS avg_area,
    ROUND(AVG(rooms)::NUMERIC,2) AS avg_rooms,
    ROUND(AVG(balcony)::NUMERIC,2) AS avg_balcony,
    ROUND(AVG(ceiling_height)::numeric,2) AS avg_ceiling_height
FROM categories
GROUP BY region, activity_period
ORDER BY region, activity_period desc;


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT f.id
    FROM real_estate.flats AS f  
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits) AND
        f.rooms < (SELECT rooms_limit FROM limits) AND 
        f.balcony < (SELECT balcony_limit FROM limits) AND 
        f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits) AND 
        f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
),
publication AS (
    SELECT 
        EXTRACT(MONTH FROM a.first_day_exposition) AS month,
        COUNT(*) AS publication_count
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    WHERE f.id IN (SELECT * FROM filtered_id)
    GROUP BY month
),
removal AS (
    SELECT 
        EXTRACT(MONTH FROM a.first_day_exposition + INTERVAL '1 day' * a.days_exposition) AS month,
        COUNT(*) AS removal_count,
        ROUND(AVG(a.last_price / f.total_area)::NUMERIC, 2) AS avg_price_per_sqm,
        ROUND(AVG(f.total_area)::NUMERIC, 2) AS avg_area
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    WHERE f.id IN (SELECT * FROM filtered_id)
    GROUP BY month
),
activity AS (
    SELECT 
        p.month,
        COALESCE(p.publication_count, 0) AS publication_count,
        COALESCE(r.removal_count, 0) AS removal_count,
        COALESCE(r.avg_price_per_sqm, 0) AS avg_price_per_sqm,
        COALESCE(r.avg_area, 0) AS avg_area
    FROM publication AS p
    FULL OUTER JOIN removal AS r ON p.month = r.month
)
SELECT 
    month,
    publication_count,
    removal_count,
    avg_price_per_sqm,
    avg_area
FROM activity
WHERE MONTH IS NOT null
ORDER BY month;
-- Напишите ваш запрос здесь
-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.
    
 WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit
    FROM real_estate.flats     
),filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
), statistics AS (
    SELECT 
        c.city,
        a.id ,
        a.days_exposition,
        a.last_price / f.total_area AS price_per_sqm, 
        f.total_area,
        f.rooms,
        CASE 
            WHEN a.days_exposition IS NOT NULL THEN 1 
            ELSE 0 
        END AS is_sold
    FROM real_estate.city AS c 
    JOIN real_estate.flats AS f ON c.city_id = f.city_id
    JOIN real_estate.advertisement AS a ON f.id = a.id
    WHERE f.id IN (SELECT * FROM filtered_id) 
        AND c.city <> 'Санкт-Петербург')
SELECT 
    city,
    COUNT(id) AS total_public,
    COUNT(NULLIF(is_sold, 0)) AS sold_public,
    ROUND(AVG(price_per_sqm)::NUMERIC, 2) AS avg_price_per_sqm, 
    ROUND(AVG(total_area)::NUMERIC, 2) AS avg_area,
    ROUND(AVG(rooms)::NUMERIC, 2) AS avg_rooms,
    ROUND(AVG(days_exposition::numeric),2) AS avg_days_active,
    ROUND((COUNT(NULLIF(is_sold, 0))::NUMERIC/ COUNT(id) * 100),2) AS sold_percentage
FROM statistics
GROUP BY city
HAVING COUNT(id) > 50
ORDER BY total_public DESC
LIMIT 15;



