SHOW DATABASES;
USE DATABASE TASTY_BYTES_SAMPLE_DATA;
USE SCHEMA RAW_POS;
SHOW TABLES;
SELECT COUNT(*) FROM MENU;

SELECT *
FROM MENU
LIMIT 10;

DESC TABLE tasty_bytes_sample_data.raw_pos.menu;

SELECT COUNT(*) AS total_items
FROM tasty_bytes_sample_data.raw_pos.menu
WHERE item_category = 'Snack'
  AND item_subcategory = 'Warm Option';

--Question 2
--What are the max sales prices for each of the three item subcategories (hot option, warm option, cold option)? --List from highest price to lowest
SELECT item_subcategory,
       MAX(sale_price_usd) AS max_price
FROM tasty_bytes_sample_data.raw_pos.menu
WHERE item_subcategory IN ('Hot Option', 'Warm Option', 'Cold Option')
GROUP BY item_subcategory
ORDER BY max_price DESC;

--same as above result
SELECT ITEM_SUBCATEGORY,
MAX(SALE_PRICE_USD)
FROM tasty_bytes_sample_data.raw_pos.menu
GROUP BY 1
ORDER BY 2 DESC;

SHOW WAREHOUSES;

CREATE WAREHOUSE warehouse_two;


DROP WAREHOUSE warehouse_two;

ALTER WAREHOUSE warehouse_two set WAREHOUSE_SIZE = 'SMALL';
