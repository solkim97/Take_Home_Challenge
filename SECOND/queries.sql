/*CLOSE-ENDED QUESTIONS

What are the top 5 brands by receipts scanned among users 21 and over?
Assumption 1: We only look at users where BIRTH_DATE is available
Assumption 2: All available BIRTH_DATE data is accurate
Assumption 3: We are not counting duplicate receipts (have the same RECEIPT_ID)
Assumption 4: Users have to be 21 or over as of the date, 2/27/14 (this is the CURRENT_DATE)
ANSWER: 1. DOVE - 3
        2.	NERDS CANDY -3
        3.	SOUR PATCH KIDS - 2
        4.	MEIJER - 2
        5.	GREAT VALUE - 2
Query below
*/

WITH deduped_products AS
  (
  SELECT BARCODE, BRAND, CATEGORY_2
  FROM `takehomechallenge-451718.fetch_take_home.products`
  WHERE BARCODE IS NOT NULL
  AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1
  )
SELECT 
  p.BRAND, 
  COUNT(DISTINCT t.RECEIPT_ID) receipts_count
FROM 
  takehomechallenge-451718.fetch_take_home.transactions t
LEFT JOIN 
  deduped_products p ON t.BARCODE = p.BARCODE
LEFT JOIN 
  takehomechallenge-451718.fetch_take_home.users u ON t.USER_ID = u.ID
WHERE 
  FLOOR(DATE_DIFF(CURRENT_DATE(), DATE(u.BIRTH_DATE), DAY)/ 365.25) >= 21
AND
  p.BRAND IS NOT NULL
GROUP BY 1
ORDER BY receipts_count DESC
LIMIT 5

/* What are the top 5 brands by sales among users that have had their account for at least six months?
Assumption 1: This is based on final sales from transactions in unique RECEIPT_IDs
Assumption 2: To remove duplicate RECEIPT_IDs, we keep the highest FINAL_SALE value
ANSWER: 1. CVS - $72.00
        2.	DOVE - $30.91
        3.	TRIDENT - $23.36
        4.	COORS LIGHT - $17.48
        5.	TRESEMMÉ - $14.58
Query below
*/
WITH deduped_transactions AS
  (SELECT RECEIPT_ID, BARCODE, USER_ID, CAST(FINAL_SALE AS FLOAT64) FINAL_SALE
  FROM `takehomechallenge-451718.fetch_take_home.transactions`
  WHERE TRIM(FINAL_SALE) != ''
  QUALIFY ROW_NUMBER() OVER (PARTITION BY RECEIPT_ID ORDER BY FINAL_SALE DESC) = 1
  ),
deduped_products AS
  (
  SELECT BARCODE, BRAND, CATEGORY_2
  FROM `takehomechallenge-451718.fetch_take_home.products`
  WHERE BARCODE IS NOT NULL
  AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1
  )
SELECT 
  p.BRAND, 
  ROUND(SUM(t.FINAL_SALE),2) total_sales
FROM 
  deduped_transactions t
LEFT JOIN 
  deduped_products p ON t.BARCODE = p.BARCODE
LEFT JOIN 
  takehomechallenge-451718.fetch_take_home.users u ON t.USER_ID = u.ID
WHERE 
  DATE_DIFF(CURRENT_DATE(), DATE(u.CREATED_DATE), MONTH) >= 6
AND
  p.BRAND IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5


/*OPEN-ENDED QUESTIONS

Which is the leading brand in the Dips & Salsa category?
Assumption 1: This is based on final sales from transactions in unique RECEIPT_IDs
Assumption 2: To remove duplicate RECEIPT_IDs, we keep the highest FINAL_SALE value
ANSWER: TOSTITOS (total sales of $181.30)
Query below
*/

WITH deduped_transactions AS
  (SELECT RECEIPT_ID, BARCODE, CAST(FINAL_SALE AS FLOAT64) FINAL_SALE
  FROM `takehomechallenge-451718.fetch_take_home.transactions`
  WHERE TRIM(FINAL_SALE) != ''
  QUALIFY ROW_NUMBER() OVER (PARTITION BY RECEIPT_ID ORDER BY FINAL_SALE DESC) = 1
  ),
deduped_products AS
  (
  SELECT BARCODE, BRAND, CATEGORY_2
  FROM `takehomechallenge-451718.fetch_take_home.products`
  WHERE BARCODE IS NOT NULL
  AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1
  )
SELECT 
  p.BRAND, ROUND(SUM(t.FINAL_SALE),2) TOTAL_SALES
FROM 
  deduped_transactions t
LEFT JOIN 
  deduped_products p ON t.BARCODE = p.BARCODE
WHERE p.CATEGORY_2 = 'Dips & Salsa'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
