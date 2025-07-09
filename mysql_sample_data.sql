-- MySQL Sample Data for Ecommerce ETL Pipeline
-- Run this script in your RDS MySQL instance to create sample data

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    address_city VARCHAR(50),
    address_state VARCHAR(2),
    address_zip VARCHAR(10),
    registration_date DATE,
    loyalty_status ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    unit_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    item_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Insert sample customers
INSERT INTO customers (first_name, last_name, email, address_city, address_state, address_zip, registration_date, loyalty_status) VALUES
('John', 'Doe', 'john.doe@email.com', 'New York', 'NY', '10001', '2023-01-15', 'gold'),
('Jane', 'Smith', 'jane.smith@email.com', 'Los Angeles', 'CA', '90210', '2023-02-20', 'platinum'),
('Mike', 'Johnson', 'mike.johnson@email.com', 'Chicago', 'IL', '60601', '2023-03-10', 'silver'),
('Sarah', 'Williams', 'sarah.williams@email.com', 'Houston', 'TX', '77001', '2023-04-05', 'bronze'),
('David', 'Brown', 'david.brown@email.com', 'Phoenix', 'AZ', '85001', '2023-05-12', 'gold'),
('Lisa', 'Davis', 'lisa.davis@email.com', 'Philadelphia', 'PA', '19101', '2023-06-18', 'silver'),
('Robert', 'Miller', 'robert.miller@email.com', 'San Antonio', 'TX', '78201', '2023-07-22', 'bronze'),
('Jennifer', 'Wilson', 'jennifer.wilson@email.com', 'San Diego', 'CA', '92101', '2023-08-30', 'platinum'),
('Michael', 'Moore', 'michael.moore@email.com', 'Dallas', 'TX', '75201', '2023-09-14', 'gold'),
('Amanda', 'Taylor', 'amanda.taylor@email.com', 'San Jose', 'CA', '95101', '2023-10-25', 'silver');

-- Insert sample products
INSERT INTO products (product_id, product_name, category, subcategory, brand, unit_price) VALUES
(101,'iPhone 15 Pro', 'Electronics', 'Smartphones', 'Apple', 999.99),
(102,'Samsung Galaxy S24', 'Electronics', 'Smartphones', 'Samsung', 899.99),
(103,'MacBook Air M2', 'Electronics', 'Laptops', 'Apple', 1199.99),
(104,'Dell XPS 13', 'Electronics', 'Laptops', 'Dell', 999.99),
(105,'Nike Air Max 270', 'Clothing', 'Shoes', 'Nike', 129.99),
(106,'Adidas Ultraboost', 'Clothing', 'Shoes', 'Adidas', 179.99),
(107,'Levi\'s 501 Jeans', 'Clothing', 'Pants', 'Levi\'s', 59.99),
(108,'H&M T-Shirt', 'Clothing', 'Shirts', 'H&M', 19.99),
(109,'Sony WH-1000XM5', 'Electronics', 'Headphones', 'Sony', 349.99),
(110,'Bose QuietComfort 45', 'Electronics', 'Headphones', 'Bose', 329.99),
(111,'Kindle Paperwhite', 'Electronics', 'E-readers', 'Amazon', 139.99),
(112,'iPad Air', 'Electronics', 'Tablets', 'Apple', 599.99),
(113,'Samsung Galaxy Tab S9', 'Electronics', 'Tablets', 'Samsung', 649.99),
(114,'Canon EOS R6', 'Electronics', 'Cameras', 'Canon', 2499.99),
(115,'Sony A7 III', 'Electronics', 'Cameras', 'Sony', 1999.99);


-- Insert sample orders
INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15 10:30:00', 999.99, 'delivered'),
(2, '2024-01-16 14:20:00', 1199.99, 'delivered'),
(3, '2024-01-17 09:15:00', 129.99, 'shipped'),
(4, '2024-01-18 16:45:00', 59.99, 'delivered'),
(5, '2024-01-19 11:30:00', 349.99, 'processing'),
(6, '2024-01-20 13:20:00', 599.99, 'pending'),
(7, '2024-01-21 15:10:00', 179.99, 'delivered'),
(8, '2024-01-22 08:45:00', 2499.99, 'shipped'),
(9, '2024-01-23 12:30:00', 899.99, 'delivered'),
(10, '2024-01-24 10:15:00', 139.99, 'processing'),
(1, '2024-01-25 14:20:00', 329.99, 'pending'),
(2, '2024-01-26 09:30:00', 649.99, 'delivered'),
(3, '2024-01-27 16:45:00', 19.99, 'delivered'),
(4, '2024-01-28 11:20:00', 1999.99, 'shipped'),
(5, '2024-01-29 13:15:00', 999.99, 'processing');

-- Insert sample order items
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, item_price, created_at) VALUES
(1, 1, 101, 1, 999.99, '2024-01-15 10:30:00'),
(2, 2, 103, 1, 1199.99, '2024-01-16 14:20:00'),
(3, 3, 105, 1, 129.99, '2024-01-17 09:15:00'),
(4, 4, 107, 1, 59.99, '2024-01-18 16:45:00'),
(5, 5, 109, 1, 349.99, '2024-01-19 11:30:00'),
(6, 6, 112, 1, 599.99, '2024-01-20 13:20:00'),
(7, 7, 106, 1, 179.99, '2024-01-21 15:10:00'),
(8, 8, 114, 1, 2499.99, '2024-01-22 08:45:00'),
(9, 9, 102, 1, 899.99, '2024-01-23 12:30:00'),
(10, 10, 111, 1, 139.99, '2024-01-24 10:15:00'),
(11, 11, 110, 1, 329.99, '2024-01-25 14:20:00'),
(12, 12, 113, 1, 649.99, '2024-01-26 09:30:00'),
(13, 13, 108, 1, 19.99, '2024-01-27 16:45:00'),
(14, 14, 115, 1, 1999.99, '2024-01-28 11:20:00'),
(15, 15, 104, 1, 999.99, '2024-01-29 13:15:00');


-- Create indexes for better performance
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_products_category ON products(category);

-- Show sample data
SELECT 'Customers' as table_name, COUNT(*) as record_count FROM customers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items; 