# dbt_bigcommerce

A dbt package for BigCommerce. Built by Fueled for BigCommerce's native BigQuery ETL

## About Fueled

Fueled.io is a 1st-party data platform for eCommerce. We help BigCommerce and Shopify brands
pipe 1st-party events from their storefronts to various destinations, most notably data warehouses.

We provide dbt packages that help these brands work with this valuable data.

## About This package

This dbt package is licensed under the Apache 2.0 open source license. It's free to use, please just
be respectful of the license's terms of use.

If you would like support with this package, please reach out to support@fueled.io - though like all
open source projects, this dbt package is "free as in kittens."

## How To Use This Package

This package is designed to work with BigCommerce data that has been ETL'd into BigQuery via
BigCommerce's native BigQuery ETL. This package can be used as a dependency within other dbt projects, or 
it can simply be modified to meet your organizations needs.

## Acknowledgements

This package was originally built at part of a BigCommerce Hackaton, in August 2023. It was initially
launched with the support of Scott Williams and Human Design, Fueled's partners in this Hackaton.

## To Dos 

#### Decisions

* [ ] Should rollups be based on total_order_value or subtotal_value of orders? Should that be a configuration?

#### Documentation

* [ ] Document source tables and columns in /models/base/source.yml
* [ ] Document intermediate views in /models/intermediate/intermediate.yml
* [ ] Document finalized views in /models/bigcommerce.yml

#### Customer Flattening & Rollups

* [x] Add days_between_first_last to int_customers.sql
* [x] Add order_frequency to int_customers.sql
* [ ] Add discount_usage_count to int_customers.sql
* [ ] Add discount_usage_amount to int_customers.sql
* [ ] Add most recent billing & shipping address information to int_customers.sql

#### Order Flattening & Rollups

* [ ] Add order_position as a calculation of the number of a specific order for all orders associated with a specific customer
* [ ] Add total order count for the specific customer to each order
* [ ] Add the customer's CLTV to each order record
* [ ] Add date of the customer's first order to each order record
* [ ] Add days since first order to each order record
* [ ] Add days since most recent previous order to each order record

#### Order Line Item Flattening & Rollups

* For this table, we need to think a bit more, but we could use it as the basis for ML on what products are purchased together frequently.
