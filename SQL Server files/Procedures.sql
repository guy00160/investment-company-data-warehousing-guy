create procedure choose_team @managerID int
as
begin

select lm.Broker_ID, (select br.Name
					  from tbl_Dim_Broker br
					  where br.Broker_ID=lm.broker_ID) as Name, lm.num_monthly_calls, lm.num_monthly_sales,
					  
					  cast(cast(lm.num_monthly_sales as float)/cast(lm.num_monthly_calls as float)*100 as
					  varchar(20))+'%' as percent_of_sales,

					  lm.last_sale, cast(lm.overall_customers_investment as varchar(20)) + '$' as
					  overall_customers_investment, cast(lm.max_investment as varchar(20)) + '$' as
					  max_investment

from Brokers_stats_lastMonth lm
where @managerID= (select br.manager_ID
					from tbl_Dim_Broker br
					where lm.broker_ID = br.Broker_ID)

order by lm.overall_customers_investment DESC
end

GO

create procedure insert_stock_spots @stock_ID int, @date date, @value float
as
begin
      insert into tbl_Dim_Stock_spots (Stock_ID,date,value)
	  values (@stock_ID,@date,@value)
end

