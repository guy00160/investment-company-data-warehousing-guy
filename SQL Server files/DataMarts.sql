--create data mart for bookkeeping

Create Table Mart_Bookkeeping(
Broker_ID int foreign key references tbl_Dim_broker(Broker_ID),
Broker_Name varchar(50),
month int,
year int,
salary varchar(50)
primary key(Broker_ID,month,year)
)


insert into Mart_Bookkeeping (Broker_ID,Broker_Name,month,year,salary)

select bms.broker_ID,
(select b.Name
 from tbl_Dim_Broker b
 where b.Broker_ID=bms.broker_ID) as Name, bms.month, bms.year, cast(bms.salary as varchar(50)) + '$'

from Brokers_Monthly_Salary bms

--create data mart for CFO

Create Table Mart_CFO(
month int,
year int,
commissions varchar(50),
expense_on_salaries varchar(50),
net_income varchar(50)
primary key(month,year)
)

insert into Mart_CFO


 select commi.month, commi.year, cast(commi.company_commission as varchar(50))+'$' as company_commission,
 
 cast(expe.company_expense as varchar(50))+'$' as company_expense, cast(income.company_net_income as 
 varchar(50))+'$'
 as company_net_income


 from Company_monthly_commissions commi inner join 

(select month, year, sum(salary) as company_expense
from Brokers_Monthly_Salary
group by month, year) as expe on commi.month=expe.month and commi.year=expe.year inner join
Company_net_income income on expe.month = income.month and expe.year = income.year


--create data mart for manager 1007 (random example)

Create Table Mart_Manager1007(
Broker_ID int primary key,
Broker_Name varchar(50), --addition for mart
num_monthly_calls int,
num_monthly_sales int,
percentage_of_sales varchar(20), --addition for mart
last_sale date,
overall_customers_investment varchar(20),
max_investment varchar(20),
)

insert into Mart_Manager1007

exec choose_team 1007

-- create data mart for CEO

Create Table Mart_CEO(
Manager_ID int primary key,
Manager_Name varchar(50), --addition for mart
Team_Size int,
num_monthly_calls int,
num_monthly_sales int,
percentage_of_sales varchar(20), --addition for mart
overall_customers_investment varchar(20),
most_selling_broker_ID int,
most_selling_broker_Name varchar(20) --addition for mart
)

insert into Mart_CEO

select lm.manager_ID, (select m.name from tbl_Dim_Manager m where m.Manager_ID=lm.manager_ID),
lm.team_size, lm.num_monthly_calls, lm.num_monthly_sales, 

cast(cast(lm.num_monthly_sales as float)/cast(lm.num_monthly_calls as float)*100 as
					  varchar(20))+'%',

cast(lm.overall_customers_investment as varchar(20))+'$', lm.most_selling_broker, (select br.Name
														 from tbl_Dim_Broker br 
														 where br.Broker_ID = lm.most_selling_broker) 

from Teams_stats_lastMonth lm
 

