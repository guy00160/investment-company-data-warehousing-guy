
GO

Create view Calls_full_info as(

select call_ID,Broker_ID,(select manager_ID from tbl_Dim_Broker br where br.Broker_ID=ca.Broker_ID) as manager_ID,
Investor_ID,  (select country_curr
			   from meta_CountryStandards
			   where country_ID=
								(select Country_ID
								from tbl_Dim_Investor inv
								where inv.Investor_ID = ca.Investor_ID)) as Currency,

date,
TransactionType,stock_ID,(select st.Stock_type from tbl_Dim_Stock st where st.Stock_ID= ca.stock_ID) as Stock_Type,
Transaction_Value_Dollars

from tbl_fact_call ca
)

GO

Create view Brokers_Work_Days as(

select Broker_ID, month(date) as month,year(date) as year, count(distinct date) as work_days
from Calls_full_info
where TransactionType=0 or TransactionType=1
group by Broker_ID, month(date), year(date)

)

GO

Create view Brokers_Monthly_Commission as(
select
broker_ID,month(date) as month,year(date) as year,
sum(case
when Stock_Type=1 then 0.01*Transaction_Value_Dollars
else 0.5*Transaction_Value_Dollars end) as Monthly_Commission

from Calls_full_info
where TransactionType=1 
group by broker_ID,month(date),year(date)
)

GO
Create view Brokers_Monthly_Salary as (

select c.broker_ID,c.month,c.year,

(w.work_days * 100)+c.Monthly_Commission as salary

from Brokers_Monthly_Commission c inner join Brokers_Work_Days w on c.broker_ID=w.broker_ID and
	 c.month=w.month and c.year=w.year

)


GO
create view Transactions_full_info as(

select *
from Calls_full_info
where TransactionType=1 or TransactionType=2
)

GO

create view Company_monthly_commissions as(

select month(date) as month ,year(date) as year, sum(dbo.get_company_commission_from_transaction(transaction_value_dollars,currency,stock_type)) as
Company_Commission

from transactions_full_info
group by month(date),year(date)
)

GO

create view Company_net_income as(

select commi.month, commi.year, commi.company_commission - expense.company_expense as company_net_income

from Company_monthly_commissions commi
inner join
(select month, year, sum(salary) as company_expense
from Brokers_Monthly_Salary
group by month, year) as expense

on commi.month=expense.month and commi.year=expense.year)



GO

create view Brokers_stats_lastMonth as(
select Broker_ID, 
count(*) as num_monthly_calls, 
sum(case when TransactionType=1 then 1 else 0 end) as num_monthly_sales, 
max(case when transactiontype=1 then date else '1751-1-1' end) as last_sale,
sum(case when TransactionType=1 then transaction_value_dollars else 0 end) as overall_customers_investment,
max(case when TransactionType=1 then transaction_value_dollars else 0 end) as max_investment

from Calls_full_info

where year(date)= (select max(year(date)) --get data from last month
					from Calls_full_info)

and month(date)=   (select max(month(date))
					from Calls_full_info)

group by Broker_ID
)


GO

create view Teams_stats_lastMonth as(

select ca.manager_ID,(select count(*) from tbl_Dim_Broker br where br.manager_ID=ca.manager_ID) as Team_Size,
	   count(*) as num_monthly_calls, 
	   sum(case when TransactionType=1 then 1 else 0 end) as num_monthly_sales, 
	   sum(case when TransactionType=1 then transaction_value_dollars else 0 end) as overall_customers_investment,
	   (select lm.broker_ID
	    from Brokers_stats_lastMonth lm
		where ca.manager_ID= (select br1.manager_ID
							 from tbl_Dim_Broker br1
							 where lm.broker_ID = br1.Broker_ID)

		and lm.overall_customers_investment = (select max(lm1.overall_customers_investment) 
											   from Brokers_stats_lastMonth lm1
											   where ca.manager_ID = (select br2.manager_ID
																	  from tbl_Dim_Broker br2
																	  where lm1.broker_ID = br2.Broker_ID)))
as most_selling_broker

from Calls_full_info ca

where year(date)= (select max(year(date)) --get data from last month
					from Calls_full_info)

and month(date)=   (select max(month(date))
					from Calls_full_info)
group by manager_ID
)