select * from credit_card_transcations;

/*1- write a query to print top 5 cities with highest spends and 
their percentage contribution of total credit card spends*/
with cte1 as(
select city, sum(amount) as total_spent 
from credit_card_transcations
group by city)
,total as (select sum(cast (amount as bigint)) as ttl_amt from credit_card_transcations)
select top 5 cte1.*,round(total_spent * 1.0/ttl_amt *100,2) as perntge_contribution
from cte1 inner join  total on 1=1
order by total_spent desc;

/*2- write a query to print highest spend month and amount spent in that month for each card type*/
with cte as(
select card_type,datepart(YEAR,transaction_date) as yt, datepart(MONTH,transaction_date) as mt
,sum(amount) as total_spent 
from credit_card_transcations
group by card_type,datepart(YEAR,transaction_date),datepart(MONTH,transaction_date))
,cte2 as (select *,rank()over(partition by card_type order by total_spent desc) as rnk from cte)
select * from cte2 where rnk =1;

/*3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/
with cte as 
(select *,sum(amount) over (partition by card_type order by transaction_date,transaction_id asc )as running_sum 
from credit_card_transcations)
select * from (select *,rank()over(partition by card_type order by running_sum asc) as rnk
from cte where running_sum >= 1000000) A where rnk =1;

/*4- write a query to find city which had lowest percentage spend for gold card type*/
with cte1 as (
select city,card_type, sum(amount) as spent_by_card
from credit_card_transcations
group by city,card_type)
,cte2 as (select city, sum(spent_by_card) as spent_by_city
from cte1 group by city)
select top 1 cte1.city, spent_by_card*1.0/spent_by_city * 100 as percentage_contribution
from cte1 inner join cte2 
on cte1.city = cte2.city
where cte1.card_type = 'Gold'
order by percentage_contribution asc;

/*5- write a query to print 3 columns: 
city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)*/
with cte as 
(select city,exp_type, sum(amount) as ttl_amt
from credit_card_transcations
group by city,exp_type)
,cte2 as (select *,
rank()over (partition by city order by ttl_amt asc) as rnk_asc,
rank()over (partition by city order by ttl_amt desc) as rnk_desc
from cte)
select city, max(case when rnk_asc=1 then exp_type end) as lowest_expense_type
,max(case when rnk_desc=1 then exp_type end) as highest_expense_type from cte2
group by city;

/*6- write a query to find percentage contribution of spends by females for each expense type*/
with cte as 
(select gender,exp_type,sum(amount) as ttl_amt
from credit_card_transcations
group by gender,exp_type)
select gender,exp_type,round(ttl_amt*1.0/ttl_by_exp_type * 100,2) as pecntge_cntrbtion
from (select *, sum(ttl_amt)over(partition by exp_type) as ttl_by_exp_type from cte) A
where gender='F';

/*7- which card and expense type combination saw highest month over month growth in Jan-2014*/
with cte as (
select card_type,exp_type,datepart(year,transaction_date) as yt,datepart(month,transaction_Date) as mt,
sum(amount) as ttl_amt
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date))
select top 1 *,(ttl_amt-prev_month_amt)*1.0/prev_month_amt * 100 as mom_growth
from(
select *,lag(ttl_amt,1) over (partition by card_type,exp_type order by yt,mt) as prev_month_amt
from cte) A where prev_month_amt is not null and yt=2014 and mt=1
order by mom_growth desc;

/*8- during weekends which city has highest total spend to total no of transcations ratio*/
with cte as (
select *,
datepart(weekday,transaction_date) as day_name
from credit_card_transcations where datepart(weekday,transaction_date) in (1,7))
select top 1 city,sum(amount)/count(1) as ratio
from cte group by city
order by ratio desc;

/*9- which city took least number of days to reach its 500th transaction 
after the first transaction in that city*/
with cte as (
select *, row_number()over(partition by city order by transaction_date,transaction_id asc) as rn
from credit_card_transcations) 
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as diff_in_days
from cte where rn=1 or rn=500
group by city
having count(1)=2
order by diff_in_days asc;