/*
This Script will  Create the Database and the Schemas.
Warning: It will Remove if you have "DataWarehouse" db already. Please USE with caution.
*/

use master;
go

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN

ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE DataWarehouse;
END;
GO
--Create Database
create database DataWareHouse;
go

use DataWareHouse
go
--Create Schemas
create schema bronze;
go

create schema silver;
go 

create schema gold;
go

--Query to see in which DB your Schemas are present.
SELECT
    DB_NAME() AS CurrentDatabase,
    name AS SchemaName
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold');
