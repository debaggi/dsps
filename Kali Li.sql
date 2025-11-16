CREATE TABLE "customer" (
  "customer_id" integer PRIMARY KEY,
  "postcode" integer,
  "deceased_indicator" bool,
  "last_name" varchar(50),
  "first_name" varchar(50),
  "DOB" date,
  "gender" char(1),
  "address" varchar,
  "owns_car" bool,
  "job_title" varchar,
  "job_industry_category" varchar,
  "wealth_segment" varchar
);

CREATE TABLE "place" (
  "postcode" integer PRIMARY KEY,
  "state" varchar,
  "country" varchar,
  "property_valuation" integer
);

CREATE TABLE "transaction" (
  "transaction_id" integer PRIMARY KEY,
  "customer_id" integer,
  "product_id" integer,
  "transaction_date" timestamp,
  "online_order" bool,
  "order_status" varchar,
  "list_price" decimal(10,3),
  "standart_cost" decimal(10,3)
);

CREATE TABLE "product" (
  "product_id" integer PRIMARY KEY,
  "brand" varchar,
  "product_class" varchar,
  "product_line" varchar,
  "product_size" varchar
);

ALTER TABLE "transaction" ADD FOREIGN KEY ("customer_id") REFERENCES "customer" ("customer_id");

ALTER TABLE "customer" ADD FOREIGN KEY ("postcode") REFERENCES "place" ("postcode");

ALTER TABLE "transaction" ADD FOREIGN KEY ("product_id") REFERENCES "product" ("product_id");
