/*
================================================================================
Quality Checks
================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standardisation across the 'silver' schemas. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardisation and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after data loading silver layer.
  - Investigate and resolve any discrepancies found during the checks.
================================================================================
*/


-- ================================================================================
-- CRM_CUST_INFO

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
-- ================================================================================

SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
;

GO

-- Check Unwanted Spaces
-- Expectations: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
;

GO

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)
;

GO

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)
;

GO

SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status)
;

GO
-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info
;

GO

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
;

GO

SELECT TOP 1 *
FROM silver.crm_cust_info
;

GO

-- CRM_PRD_INFO

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NOT NULL
;

GO
-- Check Unwanted Spaces
-- Expectations: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)
;

GO
-- Check For Nulls or Negative Numbers
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL
;

GO
-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info
;

GO
-- Check For Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt
;

GO

-- CRM_SALES_DETAILS
SELECT *
FROM silver.crm_sales_details;

GO
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT sls_ord_num, COUNT(*)
FROM silver.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1 OR sls_ord_num IS NULL
;

GO
-- Check Unwanted Spaces
-- Expectations: No Results
SELECT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key)
;

GO
----
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
SELECT cst_id FROM silver.crm_cust_info
)
;

GO
-- Check For Invalid Dates
SELECT 
	NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt < 0 OR LEN(sls_order_dt) != 8
;

GO
-- Check for Date Boundries
SELECT
	NULLIF(sls_order_dt, 0)
FROM silver.crm_sales_details
WHERE sls_order_dt > 20269282 OR sls_order_dt < 19000000
;

GO
-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
;

GO
-- Check for Invalid Sales, Price, and Quantity
SELECT * 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
;

GO

SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	 ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
	 ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0 OR
	sls_sales IS NULL OR sls_quantity IS NULL
	OR sls_price IS NULL
ORDER BY sls_sales, sls_quantity, sls_price
;

GO

--  ERP_CUST_AZ12
SELECT
CASE WHEN LEN(cid) = 13
	 THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END AS cid, 
CASE
	WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
END AS bdate,
CASE 
	WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
	WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
	WHEN TRIM(gen) = '' THEN NULL
	ELSE TRIM(gen)
END AS gen
FROM silver.erp_cust_az12
;

GO

SELECT * 
FROM silver.erp_cust_az12
WHERE LEN(cid) < 10;

GO

SELECT * FROM silver.crm_cust_info
;

GO
-- Check Gender
SELECT
	CASE 
		WHEN TRIM(gen) = '' THEN NULL
		ELSE TRIM(gen)
	END AS gen
FROM silver.erp_cust_az12
;

GO
-- Check Birthdate
SELECT 
	CASE
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'OR bdate > GETDATE()
;

GO

-- ERP_LOC_A101
SELECT
cid,
cntry
FROM silver.erp_loc_a101
;

GO

SELECT DISTINCT cntry
FROM silver.erp_loc_a101
;

GO
-- Check Keys
SELECT REPLACE(cid, '-', '')
FROM silver.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN 
	(SELECT cst_key FROM silver.crm_cust_info)
;

GO
-- Check Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry
;

GO

SELECT
CASE
	WHEN UPPER(TRIM(cntry)) = 'AUSTRALIAS' THEN 'Australia'
	WHEN UPPER(TRIM(cntry)) = 'CANADA' THEN 'Canada'
	WHEN UPPER(TRIM(cntry)) = 'FRANCE' THEN 'France'
	WHEN UPPER(TRIM(cntry)) = 'GERMANY' THEN 'Germany'
	WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
	WHEN UPPER(TRIM(cntry)) = 'UNITED KINGDOM' THEN 'United Kingdom'
	WHEN UPPER(TRIM(cntry)) = 'UNITED STATES' THEN 'United States'
	WHEN UPPER(TRIM(cntry)) = 'US' THEN 'United States'
	WHEN UPPER(TRIM(cntry)) = 'USA' THEN 'United States'
	WHEN UPPER(TRIM(cntry)) = '' OR UPPER(TRIM(cntry)) = NULL THEN 'n/a'
	ELSE cntry
END AS cntry
FROM silver.erp_loc_a101
;

GO
-- ERP_PX_CAT_G1V2
SELECT *
FROM silver.erp_px_cat_g1v2
;

GO

SELECT
id,
cat,
subcat,
maintenance
FROM silver.erp_px_cat_g1v2
;

GO
-- Check Unwanted Spaces
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
;

GO

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat)
;

GO

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance)
;

GO

-- Data Standardization & Consistency
SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2
;

GO

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2
;

GO

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2
;
;
