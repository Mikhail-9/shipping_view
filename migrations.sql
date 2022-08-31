
DROP TABLE IF EXISTS shipping_country_rates CASCADE;
DROP TABLE IF EXISTS shipping_agreement CASCADE;
DROP TABLE IF EXISTS shipping_transfer CASCADE;
DROP TABLE IF EXISTS shipping_info CASCADE;
DROP TABLE IF EXISTS shipping_status CASCADE;


CREATE TABLE IF NOT EXISTS shipping_country_rates(
shipping_country_id serial NOT NULL,
shipping_country text NULL,
shipping_country_base_rate numeric(14, 3) NULL,
PRIMARY KEY (shipping_country_id)
);

CREATE TABLE IF NOT EXISTS shipping_agreement (
agreementid bigint NOT NULL,
agreement_number varchar(30) NOT NULL,
agreement_rate numeric(14,3) NOT NULL,
agreement_commission numeric(14,3) NOT NULL,
PRIMARY KEY (agreementid)
);

CREATE TABLE IF NOT EXISTS shipping_transfer(
transfer_type_id serial NOT NULL,
transfer_type text NOT NULL,
transfer_model text NOT NULL, 
shipping_transfer_rate numeric(14, 3) NOT NULL,
PRIMARY KEY (transfer_type_id)
);

CREATE TABLE IF NOT EXISTS shipping_info(
shippingid bigint NOT NULL,
vendorid bigint NOT NULL,
payment_amount numeric(14, 2) NOT NULL,
shipping_plan_datetime timestamp NOT NULL,
transfer_type_id bigint NOT NULL,
shipping_country_id bigint NOT NULL,
agreementid bigint NOT NULL,
PRIMARY KEY (shippingid),
FOREIGN KEY (transfer_type_id) REFERENCES shipping_transfer(transfer_type_id) ON UPDATE cascade,
FOREIGN KEY (shipping_country_id) REFERENCES shipping_country_rates(shipping_country_id) ON UPDATE cascade,
FOREIGN KEY (agreementid) REFERENCES shipping_agreement(agreementid) ON UPDATE cascade
);

CREATE TABLE IF NOT EXISTS shipping_status(
shippingid bigint NOT NULL,
status text NOT NULL,
state text NOT NULL,
shipping_start_fact_datetime timestamp,
shipping_end_fact_datetime timestamp,
PRIMARY KEY (shippingid)
);

INSERT INTO shipping_country_rates(shipping_country, shipping_country_base_rate)
SELECT DISTINCT shipping_country,
       shipping_country_base_rate
FROM shipping;

--select * from shipping_country_rates;

INSERT INTO shipping_agreement(agreementid, agreement_number, agreement_rate, agreement_commission)
SELECT DISTINCT descript[1]::BIGINT AS agreementid,
       descript[2]::varchar(30) AS agreement_number,
       descript[3]::numeric(14, 3) AS agreement_rate,
       descript[4]::numeric(14, 3) AS agreement_commission
FROM (SELECT regexp_split_to_array(vendor_agreement_description, E'\\:+') AS descript
	  FROM shipping) AS vendor_description_info;

--select * from shipping_agreement;

INSERT INTO shipping_transfer(transfer_type, transfer_model, shipping_transfer_rate)
SELECT DISTINCT transfer_info[1] AS transfer_type,
       transfer_info[2] AS transfer_model,
        shipping_transfer_rate
FROM (SELECT shipping_transfer_rate, 
             regexp_split_to_array(shipping_transfer_description, E'\\:+') AS transfer_info
	  FROM shipping) AS vendor_transfer_info;

--select * from shipping_transfer;      

INSERT INTO shipping_info(shippingid, vendorid, payment_amount,
shipping_plan_datetime, transfer_type_id, shipping_country_id, agreementid)
SELECT DISTINCT shippingid,
       vendorid,
       payment_amount,
       shipping_plan_datetime,
       st.transfer_type_id, 
       scr.shipping_country_id,
       sa.agreementid
FROM shipping AS s
LEFT JOIN shipping_transfer AS st ON (regexp_split_to_array(s.shipping_transfer_description , E'\\:+'))[1] = st.transfer_type
                                  AND (regexp_split_to_array(s.shipping_transfer_description , E'\\:+'))[2] = st.transfer_model
LEFT JOIN shipping_country_rates scr ON s.shipping_country = scr.shipping_country
LEFT JOIN shipping_agreement AS sa ON (regexp_split_to_array(vendor_agreement_description, E'\\:+'))[1]::bigint = sa.agreementid;

--select * from  shipping_info limit 10;

INSERT INTO shipping_status(shippingid, status, state , shipping_start_fact_datetime, shipping_end_fact_datetime)
WITH shipping_date AS (SELECT DISTINCT shippingid,
                              max(CASE WHEN state = 'booked' THEN state_datetime ELSE NULL END) AS shipping_start_fact_datetime,
                              max(CASE WHEN state = 'recieved' THEN state_datetime ELSE NULL END) AS shipping_end_fact_datetime,
                              max(state_datetime) AS max_state_datetime
                              FROM shipping
                              GROUP BY shippingid)
SELECT sd.shippingid,
       s.status,
       s.state,
       sd.shipping_start_fact_datetime,
       sd.shipping_end_fact_datetime
FROM shipping_date AS sd
LEFT JOIN shipping AS s ON sd.shippingid = s.shippingid
                        AND sd.max_state_datetime = s.state_datetime
ORDER BY shippingid;

--select * from shipping_status ss 

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
