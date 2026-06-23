/*

Stored Procedure: Load Silver Layer (Bronze -> Silver)

Script Purpose:
This stored procedure performs the ETL (Extract, Transform, Load) process to
populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
- Truncates Silver tables.
- Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
None.
This stored procedure does not accept any parameters or return any values.

Usage Example:
EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
	BEGIN
		DECLARE @start_time DATETIME, @end_time DATETIME, @load_start_time DATETIME, @load_end_time DATETIME
		BEGIN TRY
			SET @load_start_time = getdate()
			print '========================================================';
			print '----------------- LOADING SILVER LAYER -----------------';
			print '========================================================';


			print '--------------------------------------------------------';
			print '----------------- Loading CRM Tables -------------------';
			print '--------------------------------------------------------';
			
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.crm_cust_info'
			truncate table silver.crm_cust_info;
			PRINT '>> Inserting Data into silver.crm_cust_info'
			insert into silver.crm_cust_info (
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gndr,
				cst_create_date)

			select 
				cst_id,
				cst_key,
				trim(cst_firstname) AS cst_firstname,
				trim(cst_lastname) AS cst_lastname,
				CASE upper(trim(cst_marital_status))
					when 'S' then 'Single'
					when 'M' then 'Married'
					else 'n/a'
				END cst_marital_status,
				CASE upper(trim(cst_gndr))
					when 'M' then 'Male'
					when 'F' then 'Female'
					else 'n/a'
				END cst_gndr,
				cst_create_date
			from
				(select 
					*,
					ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) 'flag_last'
				from bronze.crm_cust_info
				where cst_id is not null
				)t
			where flag_last = 1
			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'


			---------------------------------------------------------------------------
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.crm_prd_info'
			truncate table silver.crm_prd_info;
			PRINT '>> Inserting Data into silver.crm_prd_info'

			insert into silver.crm_prd_info (
				prd_id,
				cat_id,
				prd_key,
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
			)
			select 
				prd_id,
				replace(substring(trim(prd_key),1,5),'-','_') AS cat_id,
				substring(trim(prd_key),7,len(trim(prd_key))) AS prd_key,
				prd_nm,
				coalesce(prd_cost,0) prd_cost,
				CASE trim(upper(prd_line))
					when 'M' then 'Mountain'
					when 'R' then 'Road'
					when 'S' then 'Other Sales'
					when 'T' then 'Touring'
					else 'n/a'
				END AS prd_line,
				CASE WHEN prd_start_dt IS NOT NULL THEN prd_start_dt END AS prd_start_dt,
				DATEADD(DAY,-1,LEAD(prd_start_dt,1) over(PARTITION BY prd_key ORDER BY prd_start_dt ASC)) AS prd_end_dt
			from bronze.crm_prd_info
			where prd_start_dt is not null
			order by prd_id
			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'

			---------------------------------------------------------------------------
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.crm_sales_details'
			truncate table silver.crm_sales_details;
			PRINT '>> Inserting Data into silver.crm_sales_details'

			INSERT INTO silver.crm_sales_details 
			(
				sls_ord_num ,
				sls_prd_key ,
				sls_cust_id ,
				sls_order_dt ,
				sls_ship_dt ,
				sls_due_dt,
				sls_sales ,
				sls_quantity ,
				sls_price
			)
			select
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				CASE 
					WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
					ELSE cast(cast(sls_order_dt as varchar) as date)
				END AS sls_order_dt,
				CASE 
					WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
					ELSE cast(cast(sls_ship_dt as varchar) as date)
				END AS sls_ship_dt,
				CASE 
					WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
					ELSE cast(cast(sls_due_dt as varchar) as date)
				END AS sls_due_dt,
				CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != abs(sls_quantity) * abs(sls_price) 
					 THEN sls_price * abs(sls_quantity) 
					 ELSE sls_sales 
				END AS sls_sales,
				sls_quantity,
				CASE WHEN sls_price is null or sls_price <= 0
					 THEN sls_sales / nullif(sls_quantity,0)
					 ELSE sls_price
				END AS sls_price
			from bronze.crm_sales_details

			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'

			--===================================================================================
			print '--------------------------------------------------------';
			print '----------------- Loading ERP Tables -------------------';
			print '--------------------------------------------------------';
			
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.erp_cust_az12'
			truncate table silver.erp_cust_az12;
			PRINT '>> Inserting Data into silver.erp_cust_az12'

			INSERT INTO silver.erp_cust_az12 (
				cid,
				bdate,
				gen
			)

			select 
				CASE WHEN cid like 'NAS%' THEN SUBSTRING(cid,4,len(cid)) 
					 ELSE cid 
				END AS cid,
				CASE WHEN bdate > GETDATE() THEN null
					 ELSE bdate
				END AS bdate,
				CASE  
					WHEN upper(trim(gen)) in ('F','FEMALE') THEN 'Female'
					WHEN upper(trim(gen)) in ('M','MALE') THEN 'Male'
					ELSE 'n/a'
				END gen
			from bronze.erp_cust_az12

			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'

			---------------------------------------------------------------
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.erp_loc_a101'
			truncate table silver.erp_loc_a101;
			PRINT '>> Inserting Data into silver.erp_loc_a101'

			INSERT INTO silver.erp_loc_a101 (cid,cntry) select distinct
				replace(cid,'-','') cid,
				CASE 
					WHEN trim(upper(cntry)) IN ('DE','GERMANY') THEN 'Germany'
					WHEN TRIM(UPPER(cntry)) IN ('USA','UNITED STATES','US') THEN 'United States'
					WHEN cntry is null or cntry = '' THEN 'n/a'
					ELSE cntry 
				END AS cntry
			from bronze.erp_loc_a101
			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'

			SET @load_end_time = GETDATE();
			print 'Batch loading duration: ' + cast(datediff(second,@load_start_time,@load_end_time) as nvarchar) + 'seconds';

			-----------------------------------------------------------------
			SET @start_time = GETDATE();
			PRINT '>> Truncating Table silver.erp_px_cat_g1v2'
			truncate table silver.erp_px_cat_g1v2;
			PRINT '>> Inserting Data into silver.erp_px_cat_g1v2'

			insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
			select * from bronze.erp_px_cat_g1v2
			SET @end_time = GETDATE();
			print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
			print '------------------------'

		END TRY
		BEGIN CATCH
			PRINT'=============================================';
			PRINT'==== ERROR OCCURED WHILE SILVER BRONZE =====';
			PRINT'Error Message' + ERROR_MESSAGE();
			PRINT'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
			PRINT'=============================================';
		END CATCH
	END
