/*
========================================================================
Quality Checks
========================================================================
Script Purpose:
  This script performs quality checks to validate the integrity, consistency,
  and accuracy of the Gold Layer. These Checks ensure:
  - Uniqueness of surrogate keys in dimension tables.
  - Referential integrity between fact and dimension tables.
  - Validation of relationships in the data model for analytical purposes.

Usage Notes:
  - Run these checks after data loading in the Silver Layer.
  - Investigate and resolve any discrepancies found during the checks.
========================================================================
*/

SELECT
	ci.cst_gndr,
	ca.gen,
	la.cntry
	CASE
		WHEN ci.cst_gndr = 'Female' THEN ca.gen = 'Female'
		WHEN ci.cst_gndr = 'Male' THEN ca.gen = 'Male'
		ELSE ci.cst_gndr
	END AS ci.cst_gndr
FROM
	gold.crm_cust_info AS ci
LEFT JOIN gold.erp_cust_az12 AS ca
ON	ci.cst_key = ca.cid
LEFT JOIN gold.erp_loc_a101 AS la
ON	ci.cst_key = la.cid
WHERE ci.cst_gndr != ca.gen
;

GO

SELECT
	ci.cst_gndr,
	ca.gen,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM
	gold.crm_cust_info AS ci
LEFT JOIN gold.erp_cust_az12 AS ca
ON	ci.cst_key = ca.cid
LEFT JOIN gold.erp_loc_a101 AS la
ON	ci.cst_key = la.cid
WHERE ci.cst_gndr != ca.gen
;

GO

SELECT prd_key, COUNT(*)
FROM(
	SELECT pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM gold.crm_prd_info pn
LEFT JOIN gold.erp_px_cat_g1v2 pc
ON	pn.cat_id = pc.id
WHERE prd_end_dt IS NULL
) t
GROUP BY prd_key
HAVING COUNT(*) > 1
;

GO

SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance AS maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM gold.crm_prd_info pn
LEFT JOIN gold.erp_px_cat_g1v2 pc
ON	pn.cat_id = pc.id
WHERE prd_end_dt IS NULL
;

GO

SELECT
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM gold.crm_sales_details AS sd
LEFT JOIN gold.dim_products pr
ON	sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
ON	sd.sls_cust_id = cu.customer_id
;

GO

SELECT * FROM gold.dim_customers
;
