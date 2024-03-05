select * from dim_campaigns;
select * from dim_products;

select * from dim_stores;
select * from fact_events;

update fact_events
set `quantity_sold(after_promo)`=`quantity_sold(after_promo)`*2
where promo_type='BOGOF';

SELECT * from fact_events;
/*
Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free). 
This information will help us identify high-value products that are currently being heavily discounted, 
which can be useful for evaluating our pricing and promotion strategies.
*/

select 
   distinct(p.product_code),p.product_name,e.promo_type,e.base_price
from fact_events e
join
dim_products p
on e.product_code=p.product_code
where base_price>500 and promo_type="BOGOF";

/*
2.	Generate a report that provides an overview of the number of stores in each city. 
The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence.
 The report includes two essential fields: city and store count, which will assist in optimizing our retail operations
*/

select 
    city,count(city) as no_of_stores
from dim_stores
group by city
order by no_of_stores desc;

/*
3.Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
The report includes three key fields: campaign _name, total revenue(before_promotion), total revenue(after_promotion). 
This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)
*/

with x as
(
select
   *,
   CASE
      WHEN promo_type="50% OFF" then (0.5*base_price)
      WHEN promo_type="25% OFF" then base_price*(1-0.25)
      WHEN promo_type="33% OFF" then base_price*(1-0.33)
      WHEN promo_type="500 Cashback" then (base_price-500)
      WHEN promo_type="BOGOF" then (0.5*base_price)
      END  as price_after_promo
from fact_events
),

y as
(
select
   f.*,
   f.`quantity_sold(before_promo)` *f.base_price as total_revenue_before_promo,
   f.`quantity_sold(after_promo)` *x.price_after_promo as total_revenue_after_promo
from fact_events f
right join x
on f.event_id=x.event_id
)

select 
     c.campaign_name,
     concat(format(sum(y.total_revenue_before_promo)/1000000,2),'M') as total_revenue_before_promo,
     concat(format(sum(y.total_revenue_after_promo)/1000000,2),'M') as total_revenue_after_promo
from y
left join dim_campaigns c
on y.campaign_id=c.campaign_id
group by c.campaign_name;


/*
4.	Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
 Additionally, provide rankings for the categories based on their ISU%. 
 The report will include three key fields: category, isu%, and rank order. 
 This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.
Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage increase/decrease in quantity sold (after promo)
compared to quantity sold (before promo)

*/
with cte1 as
(
select 
	p.category,
	round((sum(f.`quantity_sold(after_promo)`)-sum(f.`quantity_sold(before_promo)`))/sum(f.`quantity_sold(before_promo)`)*100,2) as isu_pct
from fact_events f
join dim_products p
on f.product_code=p.product_code
where f.campaign_id="CAMP_DIW_01"
group by p.category
)

select
     *,
     dense_rank() over(order by isu_pct desc) as isu_rank
from cte1;


/*
5.	Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
The report will provide essential information including product name, category, and ir%. 
This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, 
assisting in product optimization.
*/

select
  p.product_name,
  p.category,
  round((sum(r.total_revenue_after_promo)-sum(r.total_revenue_before_promo))/sum(r.total_revenue_before_promo) *100,2) as ir_pct
from 
dim_products p
join fact_events_total_revenue r
on p.product_code=r.product_code
group by r.product_code
order by ir_pct desc
limit 5;
    






