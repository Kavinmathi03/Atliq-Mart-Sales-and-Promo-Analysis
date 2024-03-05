# fact_events_total_revenue - View

with x as
(
select
   event_id,
   CASE
      WHEN promo_type="50% OFF" then (0.5*base_price)
      WHEN promo_type="25% OFF" then (base_price*(1-0.25))
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
   x.price_after_promo,
   f.`quantity_sold(before_promo)` *f.base_price as total_revenue_before_promo,
   f.`quantity_sold(after_promo)` *x.price_after_promo as total_revenue_after_promo
from fact_events f
right join x
on f.event_id=x.event_id
)
select * from y;