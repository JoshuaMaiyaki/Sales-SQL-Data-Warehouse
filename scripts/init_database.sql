/*
DATABASE AND SCHEMA

Purpose: This line or code create's a new database named "SalesWar:
'bronze', 'silver', 'gold'.

Warning:
Running this script will drop the entire 'SalesWarehouse' database if it exist.
All data in the database would be permanently deleted, please proceed with caution.
Do ensure you back up any important data before running the script. 
*/



USE Master;
GO

-- DROP DATABASE 'SalesWarehouse' IF EXISTS AND CREATE DATABASE
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SalesWarehouse')
BEGIN
	ALTER DATABASE SET SINGLE USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE SalesWarehouse;
END;

GO

-- CREATE THE DATABASE
CREATE DATABASE SalesWarehouse;
GO

USE SalesWarehouse;
GO

-- CREATE SCHEMAS
CREATE SCHEMA bronze;

GO

CREATE SCHEMA silver;

GO

CREATE SCHEMA gold;

GO
