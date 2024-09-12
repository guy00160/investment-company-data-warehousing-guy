# Investment Company Data Warehousing

* This project was developed as the final assignment for my "Data Warehousing" course during my B.Sc. degree, using made-up data.
* The implementation was done using SQL Server.
  
## Workflow

* We started with raw data tables containing unorganized information about the company and its activities (refer to the "raw files" folder included in the repository).
* We established the data warehouse schema (including Dimensions, Facts and Metadata tables) based on the company's operational data.
* We transformed the raw data into a tidied and normalized format suitable for loading into the data warehouse (ETL process).
* We implemented Functions, Triggers, Procedures, Views, and Data Marts to develop a functional warehouse capable of handling daily operations efficiently.

## How to Use

To establish the data warehouse in SQL Server, execute the files in the following order:
1. Functions
2. Create_Data_Warehouse_And_Triggers
3. Views
4. Procedures
5. DataMarts

## Data Warehouse Contents

Data Tables:
1. tbl_Dim_Broker
2. tbl_Dim_Investor
3. tbl_Dim_Manager
4. tbl_Dim_Stock
5. tbl_Dim_Stock_Spots
6. tbl_Fact_Call
7. meta_CountryStandards
8. meta_EmailStandards
9. meta_ExchangeRates
10. meta_StockTypes
11. meta_TransactionType
12. Mart_Bookkeeping
13. Mart_CFO
14. Mart_Manager1007
15. Mart_CEO

In addition to the data tables listed above, the Data Warehouse also includes a variety of practical functions, triggers, views, and procedures.
