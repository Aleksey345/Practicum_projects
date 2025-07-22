--Информация о таблицах
-- 1.Выводим  названия всех таблиц схемы fantasy.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'fantasy';
--Схема fantasy содержит семь таблиц: classes, country, users, events, items, skills, race. 
--В них собрана основная информация об игроках и их активности.

-- 2.Данные в таблице users
select table_schema,
table_name,
column_name,
data_type,
constraint_name
from  information_schema.columns 
LEFT JOIN information_schema.key_column_usage AS k USING(table_schema, table_name, column_name)
where table_schema='fantasy' and table_name='users'
/* Таблица users содержит 11 полей, и большинство из них хранят текстовые данные. При этом поле id с идентификатором игрока — это первичный ключ таблицы, а четыре поля class_id, ch_id, race_id и loc_id — внешние ключи. 
   Можно предположить, что таблица users связана с таблицами classes, skills, race и country.*/

--3.Вывод первых строк таблицы users
Select *,
count(*)over() as row_count 
from fantasy.users
limit 5; -- Всего данные содержат информацию о 22214 игроках.

-- 4.Проверка пропусков в таблице users
SELECT Count(*)
FROM fantasy.users
WHERE class_id IS NULL
   OR ch_id IS NULL
   OR pers_gender IS NULL
   OR server IS NULL
   OR race_id IS NULL
   OR payer IS NULL
   OR loc_id IS NULL; --пропусков в данных нет
   
  --5. Знакомство с категориальными данными таблицы users
   Select distinct server,
count(*) 
from fantasy.users
group by server --Игрокам доступно два сервера. При этом на первом сервере примерно в три раза больше игроков, чем на втором.

-- 6.Знакомство с таблицей events
-- Выводим названия полей, их тип данных и метку о ключевом поле таблицы events
SELECT c.table_schema,
       c.table_name,
       c.column_name,
       c.data_type,
       k.constraint_name
FROM information_schema.columns AS c 
-- Присоединяем данные с ограничениями полей
LEFT JOIN information_schema.key_column_usage AS k 
    USING(table_name, column_name, table_schema)
-- Фильтруем результат по названию схемы и таблицы
WHERE table_schema='fantasy'and table_name='events'
ORDER BY c.table_name;
/* Таблица events содержит семь полей, и большинство из них хранит текстовые данные. 
При этом поле transaction_id с идентификатором транзакции — это первичный ключ таблицы, а два поля id и item_code — внешние ключи, связывающие данные с таблицами users и items. */
--7.Вывод первых строк таблицы users
select *,
count(*) over() as row_count 
from fantasy.events
limit 5;
--Игроки совершили больше миллиона внутриигровых покупок

--8. Проверка пропусков в таблице events
select count(*) as total
from fantasy.events
where date is null 
or  time is null
or  amount is null
or  seller_id is null;--В 508186 строках из 1307678 встречаются пропуски хотя бы в одном из полей.

--9.Изучаем пропуски в таблице events
-- Считаем количество строк с данными в каждом поле
SELECT count(date) as  data_count,
count(time) as data_time,
count(amount)as data_amount,
count(seller_id) as data_seller_id
FROM fantasy.events
WHERE date IS NULL
  OR time IS NULL
  OR amount IS NULL
  OR seller_id IS NULL;
/*Все 508186 пропусков содержатся только в поле seller_id, то есть в данных нет информации о продавце. 
Видимо, в таком случае покупка совершалась в игровом магазине, а не у других продавцов.*/
