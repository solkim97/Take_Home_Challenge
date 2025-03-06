/* Note: Datasets uploaded to Google BigQuery and queried from there

CLOSE-ENDED QUESTIONS

What are the top 5 brands by receipts scanned among users 21 and over?
Assumption 1: We only look at users where BIRTH_DATE is available
Assumption 2: All available BIRTH_DATE data is accurate
Assumption 3: We are not counting duplicate receipts (have the same RECEIPT_ID)
Assumption 4: Users have to be 21 or over as of the date, 3/4/24 (this is the CURRENT_DATE)
Assumption 5: There are 2 brands with 3 receipts and 6 brands with 2 receipts. To get top 5, we are using the RANK function, 
              not DENSE_RANK
ANSWER: 1. DOVE - 3
        1. NERDS CANDY -3
        3. SOUR PATCH KIDS - 2
        3. MEIJER - 2
        3. GREAT VALUE - 2
        3. HERSHEY'S - 2
        3. TRIDENT - 2
        3. COCA-COLA -2
Query below
*/

WITH deduped_products AS --creating a products CTE without duplicates
  (SELECT 
    BARCODE, 
    BRAND, 
    CATEGORY_2
  FROM 
    `takehomechallenge-451718.fetch_take_home.products`
  WHERE 
    BARCODE IS NOT NULL
    AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1), --only keeping the first instance of a barcode
ranked_brands AS --creating CTE with ranked brands
  (SELECT 
    p.BRAND, 
    COUNT(DISTINCT t.RECEIPT_ID) receipts_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT t.RECEIPT_ID) DESC) AS rank
  FROM 
    takehomechallenge-451718.fetch_take_home.transactions t
  LEFT JOIN 
    deduped_products p ON t.BARCODE = p.BARCODE
  LEFT JOIN 
    takehomechallenge-451718.fetch_take_home.users u ON t.USER_ID = u.ID
  WHERE 
    FLOOR(DATE_DIFF(CURRENT_DATE(), DATE(u.BIRTH_DATE), DAY)/ 365.25) >= 21 --filter for users who are at least 21
    AND p.BRAND IS NOT NULL
  GROUP BY 
    p.BRAND
  ORDER BY 
    receipts_count DESC)
SELECT 
  *
FROM 
  ranked_brands
WHERE 
  rank <= 5

/* What are the top 5 brands by sales among users that have had their account for at least six months?
Assumption 1: This is based on final sales from transactions in unique RECEIPT_IDs
Assumption 2: To remove duplicate RECEIPT_IDs, we keep the highest FINAL_SALE value
Assumption 3: Because we have a clear Top 5 based on final_sale amounts, using LIMIT 5 instead of a RANK function
ANSWER: 1. CVS - $72.00
        2.	DOVE - $30.91
        3.	TRIDENT - $23.36
        4.	COORS LIGHT - $17.48
        5.	TRESEMMÉ - $14.58
Query below
*/
WITH deduped_transactions AS  --creating a transactions CTE without duplicates
  (SELECT 
    RECEIPT_ID, 
    BARCODE, 
    USER_ID, 
    CAST(FINAL_SALE AS FLOAT64) FINAL_SALE
  FROM 
    `takehomechallenge-451718.fetch_take_home.transactions`
  WHERE 
    TRIM(FINAL_SALE) != ''
  QUALIFY ROW_NUMBER() OVER (PARTITION BY RECEIPT_ID ORDER BY FINAL_SALE DESC) = 1), --keeping the first instance of a RECEIPT_ID with highest FINAL_SALE value
deduped_products AS    --creating a products CTE without duplicates
  (SELECT 
    BARCODE, 
    BRAND, 
    CATEGORY_2
  FROM 
    `takehomechallenge-451718.fetch_take_home.products`
  WHERE 
    BARCODE IS NOT NULL
    AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1   --only keeping the first instance of a BARCODE
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
  AND p.BRAND IS NOT NULL
GROUP BY 
  p.BRAND
ORDER BY 
  total_sales DESC
LIMIT 5


/*OPEN-ENDED QUESTIONS

Which is the leading brand in the Dips & Salsa category?
Assumption 1: This is based on final sales from transactions in unique RECEIPT_IDs
Assumption 2: To remove duplicate RECEIPT_IDs, we keep the highest FINAL_SALE value
ANSWER: TOSTITOS (total sales of $181.30)
Query below
*/

WITH deduped_transactions AS       --creating a transactions CTE without duplicates
  (SELECT 
    RECEIPT_ID, 
    BARCODE, 
    CAST(FINAL_SALE AS FLOAT64) FINAL_SALE
  FROM 
    `takehomechallenge-451718.fetch_take_home.transactions`
  WHERE 
    TRIM(FINAL_SALE) != ''      -- remove records where FINAL_SALE is blank
  QUALIFY ROW_NUMBER() OVER (PARTITION BY RECEIPT_ID ORDER BY FINAL_SALE DESC) = 1),  --keeping the first instance of a RECEIPT_ID with highest FINAL_SALE value
deduped_products AS            --creating a products CTE without duplicates
  (SELECT 
    BARCODE, 
    BRAND, 
    CATEGORY_2
  FROM 
    `takehomechallenge-451718.fetch_take_home.products`
  WHERE 
    BARCODE IS NOT NULL
    AND BRAND IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY BARCODE) = 1)   --only keeping the first instance of a BARCODE
SELECT 
  p.BRAND, 
  ROUND(SUM(t.FINAL_SALE),2) total_sales
FROM 
  deduped_transactions t
LEFT JOIN 
  deduped_products p ON t.BARCODE = p.BARCODE
WHERE 
  p.CATEGORY_2 = 'Dips & Salsa'
GROUP BY 
  p.BRAND
ORDER BY 
  total_sales DESC
LIMIT 1
