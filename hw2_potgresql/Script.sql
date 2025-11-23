-- customer
CREATE TABLE IF NOT EXISTS customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    gender CHAR(1),
    DOB DATE,
    job_title VARCHAR(255),
    job_industry_category VARCHAR(255),
    wealth_segment VARCHAR(255),
    deceased_indicator CHAR(1),
    owns_car BOOLEAN,
    address VARCHAR(255),
    postcode VARCHAR(20),
    state VARCHAR(100),
    country VARCHAR(100),
    property_valuation NUMERIC
);

-- product
CREATE TABLE IF NOT EXISTS product (
    product_id INT PRIMARY KEY,
    brand VARCHAR(255),
    product_line VARCHAR(255),
    product_class VARCHAR(255),
    product_size VARCHAR(255),
    list_price NUMERIC,
    standard_cost NUMERIC
);

-- orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    online_order BOOLEAN,
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- order_items
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    item_list_price_at_sale NUMERIC,
    item_standard_cost_at_sale NUMERIC,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);