
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