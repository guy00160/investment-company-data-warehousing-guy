use tar2_grs

GO 

Create function extract_email_supplier(@mail_address varchar(100))
returns varchar(20)
as
begin
declare @supplier varchar(20)

set @supplier = lower(substring(@mail_address,charindex('@',@mail_address)+1,
len(@mail_address)-charindex('@',@mail_address)-4))
return @supplier
end;

GO

Create function get_ExchangeRate(@currency varchar(10),@date date)
returns float
as
begin
declare @ExchangeRate float

set @ExchangeRate = (select (case
					when @currency='Euro' then er.e_to_d
					when @currency='Shekel' then er.s_to_d
					else 1 end)
from  [grs.exchangerates] er
where @date=er.date)

return @ExchangeRate

end;

GO

Create function get_StockValueInDollars(@StockID int,@date date)
returns float
as
begin
declare @StockValueInDollars float

set @StockValueInDollars = (select ss.value
from  [grs.stock_spots] ss
where @date=ss.time and @StockID = ss.num)

return @StockValueInDollars

end;

GO

Create function get_company_commission_from_transaction(@transaction_value float, @currency varchar(20),
@stock_type int)

returns float
as
begin
declare @commission float

set @commission = 

(case
when @stock_type=1 then 0.0025*@transaction_value
else 0.005*@transaction_value end)

+

(case
when @currency= 'Shekel' then 0.02*@transaction_value
when @currency= 'Euro' then 0.01*@transaction_value
else 0 end)

return @commission

end;

