CREATE VIEW shipping_datamart AS
SELECT si.shippingid,
       si.vendorid,
       st.transfer_type,
       EXTRACT (DAY FROM (ss.shipping_end_fact_datetime - ss.shipping_start_fact_datetime)) AS full_day_at_shipping,
       CASE WHEN shipping_end_fact_datetime > shipping_plan_datetime THEN '1' ELSE NULL END AS is_delay,
       CASE WHEN status = 'finished' THEN '1' ELSE '0' END AS is_shipping_finish,
       CASE WHEN shipping_end_fact_datetime > shipping_plan_datetime THEN EXTRACT (DAY FROM (ss.shipping_end_fact_datetime - si.shipping_plan_datetime)) ELSE '0' END AS delay_day_at_shipping,
       si.payment_amount,
       si.payment_amount * (scr.shipping_country_base_rate + sa.agreement_rate + st.shipping_transfer_rate) AS vat,
       si.payment_amount * sa.agreement_commission AS profit
FROM shipping_info AS si 
LEFT JOIN shipping_transfer AS st ON si.transfer_type_id = st.transfer_type_id
LEFT JOIN shipping_country_rates AS scr ON si.shipping_country_id = scr.shipping_country_id
LEFT JOIN shipping_agreement AS sa ON si.agreementid = sa.agreementid
LEFT JOIN shipping_status AS ss ON si.shippingid = ss.shippingid;

--select * from shipping_datamart