
--preparing stock dimension

Create Table meta_StockTypes(
ST_ID int identity(1,1) primary key,
ST_name varchar(50)
)

insert into meta_StockTypes(ST_name)
select distinct type
from [grs.stocks]


Create Table tbl_Dim_Stock(
Stock_ID int primary key,
Name varchar(50),
Stock_type int foreign key references meta_StockTypes(ST_ID)
)

insert into tbl_Dim_Stock

select num, name, 
	(select ST_ID
	from meta_StockTypes
	where type=ST_name)
from [grs.stocks]

--preparing stock_spots dimension

Create Table tbl_Dim_Stock_spots(
Stock_ID int foreign key references tbl_Dim_Stock(Stock_ID),
date date,
value float,
primary key(Stock_ID,date)
)

insert into tbl_Dim_Stock_spots
select *
from [grs.stock_spots]

--preparing investor dimension

Create Table meta_CountryStandards(
Country_ID int identity(1,1) primary key, 
Country_Name varchar(50), --could probably be primary key, but I wanted a num value + there could be countries with the same name
Country_Curr varchar(20),
Country_AreaCode int
)

insert into meta_CountryStandards(Country_Name,Country_Curr,Country_AreaCode)

select distinct state, cur, left(phone,charindex('-',phone)-1)
from [grs.past_investors]

Create Table meta_EmailStandards(
Supplier_ID int identity(1,1) primary key,
SupplierName varchar(20)
)

insert into meta_EmailStandards(SupplierName)

select distinct dbo.extract_email_supplier(email)
from [grs.past_investors]

Create Table tbl_Dim_Investor(
Investor_ID int identity (2001,1) primary key,
Name varchar(50),
Email varchar(100),
Country_ID int foreign key references meta_CountryStandards(Country_ID),
phone varchar(50),
annual_salary float
)

GO
--Create triggers for Investors

CREATE TRIGGER remove_invalid_email on tbl_Dim_Investor --The email supplier is invalid, set null
after insert
as
begin
	update Inv
	set Inv.email=NULL
	from tbl_Dim_Investor Inv inner join inserted i on Inv.Investor_ID=i.Investor_ID
	where dbo.extract_email_supplier(inv.Email) 
	not in
	(select SupplierName
	 from meta_EmailStandards)

	 IF @@ROWCOUNT > 0
	 RAISERROR('Unauthorized mails were set null, please update them ASAP',16,1)
end;

GO

--transform the email into standard lower case
CREATE TRIGGER make_email_standard_lower_case on tbl_Dim_Investor
after insert
as
begin
	update Inv
	set Inv.Email= replace(Inv.Email, dbo.extract_email_supplier(inv.Email),dbo.extract_email_supplier(inv.Email))
	from tbl_Dim_Investor Inv inner join inserted i on Inv.Investor_ID=i.Investor_ID
end;

GO

--add area code for phone number if necessary, alter it if it is wrong

CREATE TRIGGER add_area_code on tbl_Dim_Investor
after insert
as
begin
	update Inv

	set inv.phone = 

	case when inv.phone not like '%-%' then

	cast((select Country_AreaCode
	from meta_CountryStandards
	where Country_ID = inv.Country_ID) as varchar(10)) + '-' + inv.phone

	else
	cast((select Country_AreaCode
	from meta_CountryStandards
	where Country_ID = inv.Country_ID) as varchar(10)) + right(inv.phone, len(inv.phone)-charindex('-',inv.phone)+1)

	END
	
	from tbl_Dim_Investor Inv inner join inserted i on Inv.Investor_ID=i.Investor_ID

	where inv.phone not like '%-%' or left(inv.phone, charindex('-',inv.phone)-1) not in
	(select Country_AreaCode from meta_CountryStandards)
					
end;

GO


--insert old_investor data

insert into tbl_Dim_Investor(Name,Email, phone, annual_salary, Country_ID)
select name, email,phone, annual_salary,
(select country_ID
 from meta_CountryStandards
 where Country_Name = state)
from [grs.past_investors]


--insert new investors into investors table

insert into tbl_Dim_Investor(Name,Email, phone, annual_salary, Country_ID)

select Investor_Name, Email, Phone, income,

(select country_ID
 from meta_CountryStandards
 where grs.state like '%' + Country_Name +'%')

from [grs.newinvestors] grs


--preparing metadata exchangerates

Create Table meta_ExchangeRates(
ER_date date primary key,
s_to_d float,
e_to_d float
)

insert into meta_ExchangeRates
select *
from [grs.exchangerates]

--prepare Manager dimension

Create Table tbl_Dim_Manager(
Manager_ID int primary key,
Name varchar(50),
Bdate date,
)

insert into tbl_Dim_Manager
select num, name, bdate
from [grs.brokers]
where num in 
(select distinct managerid
 from [grs.brokers])


--prepare broker dimension

Create Table tbl_Dim_Broker(
Broker_ID int identity (1001,1) primary key,
Name varchar(50),
bdate date,
manager_ID int foreign key references tbl_Dim_Manager(Manager_ID)
)

insert into tbl_Dim_Broker
select name, bdate, managerid
from [grs.brokers]

-- prepare calls fact table, first metadata table transaction_type

Create Table meta_TransactionType(
TransactionType_ID int identity(0,1) primary key, --ID 0 seems convenient for no transaction
Description varchar(50)
)

insert into meta_TransactionType(Description) values ('No Transaction'),('Investor Purchase Transaction'),('Investor Sale Transaction')
--explanation for this specific modelling in clause 8 in word
Create Table tbl_Fact_Call(
Call_ID int identity(1,1) primary key, --there is no combination from the dimensions that would suffice as a primary key
Broker_ID int foreign key references tbl_Dim_broker(Broker_ID),
Investor_ID int foreign key references tbl_Dim_Investor(Investor_ID),
date date,
TransactionType int foreign key references meta_TransactionType(TransactionType_ID),
Stock_ID int foreign key references tbl_Dim_Stock(Stock_ID),
Transaction_Value_Dollars float
)

insert into tbl_Fact_Call (Broker_ID,Investor_ID,date,TransactionType,Stock_ID,Transaction_Value_Dollars)
select

 (case
  when broker like '1%' then cast(broker as int)
  else 
 (select br.Broker_ID
  from tbl_Dim_Broker br
  where broker = br.Name) end) as Broker_ID, iid, date,

  (case
   when value is NULL then 0
   when value like '-%' then 2
   else 1
   end) as TransactionType,

   (case
    when value is NULL then NULL
	when stock like '3%' then cast(stock as int)
	else (select st.Stock_ID
		  from tbl_Dim_Stock st
		  where st.Name = stock) end) as Stock_ID,
	(case
	 when value like '-%' and value like '%$' then abs(cast(left(value,len(value)-1) as float))
	 when value like '%$' then cast(left(value,len(value)-1) as float)
	 when value like '-%' then abs(cast(value as float)) * 
		 dbo.get_StockValueInDollars(
		 (case
		 when stock like '3%' then cast(stock as int)
		 else (select st.Stock_ID
		 from tbl_Dim_Stock st
		 where st.Name = stock) end),date)
	when value is not NULL then cast(value as float) *
		 dbo.get_StockValueInDollars(
		 (case
		 when stock like '3%' then cast(stock as int)
		 else (select st.Stock_ID
		 from tbl_Dim_Stock st
		 where st.Name = stock) end),date)

	else NULL end) as Transaction_Value_Dollars

from CALLS_TRADES_IID


