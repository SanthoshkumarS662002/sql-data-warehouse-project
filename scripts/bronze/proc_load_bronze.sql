/*

Stored Procedure: Load Bronze Layer (Source -> Bronze)

Script Purpose:
This stored procedure loads data into the 'bronze' schema from external CSV files.
It performs the following actions:
- Truncates the bronze tables before loading data.
- Uses the 'BULK INSERT' command to load data from csv Files to bronze tables.

Parameters:
None.
This stored procedure does not accept any parameters or return any values.

Usage Example:
EXEC bronze.load_bronze;

*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @load_start_time DATETIME, @load_end_time DATETIME
	BEGIN TRY
		SET @load_start_time = GETDATE()
		print '========================================================';
		print '----------------- LOADING BRONZE LAYER -----------------';
		print '========================================================';


		print '--------------------------------------------------------';
		print '----------------- Loading CRM Tables -------------------';
		print '--------------------------------------------------------';

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		print '>> INSERTING TABLE: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_crm\cust_info.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		print '>> INSERTING TABLE: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_crm\prd_info.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		print '>> INSERTING TABLE: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_crm\sales_details.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'
		-------------
		print '--------------------------------------------------------';
		print '----------------- Loading ERP Tables -------------------';
		print '--------------------------------------------------------';

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		print '>> INSERTING TABLE: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		print '>> INSERTING TABLE: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'

		SET @start_time = GETDATE();
		print '>> TRUNCATING TABLE: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		print '>> INSERTING TABLE: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\PROJECTS\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv' 
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE();
		print 'Load Duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar) + 'seconds';
		print '------------------------'

		SET @load_end_time = GETDATE();
		print 'Batch loading duration: ' + cast(datediff(second,@load_start_time,@load_end_time) as nvarchar) + 'seconds';

	END TRY
	BEGIN CATCH
		PRINT'=============================================';
		PRINT'==== ERROR OCCURED WHILE LOADING BRONZE =====';
		PRINT'Error Message' + ERROR_MESSAGE();
		PRINT'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT'=============================================';
	END CATCH
END
