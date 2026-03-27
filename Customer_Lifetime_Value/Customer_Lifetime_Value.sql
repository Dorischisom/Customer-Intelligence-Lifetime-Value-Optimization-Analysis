Create database Customer_Analysis;



Use Customer_Analysis;


-- Fix data types for employees
ALTER TABLE employees
MODIFY employeeNumber VARCHAR(10);

-- Fix data types for customers
ALTER TABLE customers
MODIFY customerNumber VARCHAR(10),
MODIFY salesRepEmployeeNumber VARCHAR(10);

-- Fix data types for orders
ALTER TABLE orders
MODIFY orderNumber VARCHAR(10),
MODIFY customerNumber VARCHAR(10);

-- Fix data types for order_details
ALTER TABLE order_details
MODIFY orderNumber VARCHAR(10);

-- Fix data types for payments
ALTER TABLE payments
MODIFY customerNumber VARCHAR(10),
MODIFY checkNumber VARCHAR(20);

ALTER TABLE employees ADD PRIMARY KEY (employeeNumber);
ALTER TABLE customers ADD PRIMARY KEY (customerNumber);
ALTER TABLE orders ADD PRIMARY KEY (orderNumber);
ALTER TABLE order_details ADD PRIMARY KEY (orderNumber, orderLineNumber);
ALTER TABLE payments ADD PRIMARY KEY (customerNumber, checkNumber);

ALTER TABLE customers
ADD FOREIGN KEY (salesRepEmployeeNumber) REFERENCES employees(employeeNumber);

ALTER TABLE orders
ADD FOREIGN KEY (customerNumber) REFERENCES customers(customerNumber);

ALTER TABLE order_details
ADD FOREIGN KEY (orderNumber) REFERENCES orders(orderNumber);

ALTER TABLE payments
ADD FOREIGN KEY (customerNumber) REFERENCES customers(customerNumber);

-- Task 1: Retrieve order details with customer information
Select 
o.orderNumber, 
o.orderDate, 
c.customerName, 
c.contactfirstname, 
c.contactlastname, 
c.phone
From orders o
Inner Join customers c
ON o.customernumber = c.customernumber
Order by o.orderDate;


-- Task 2: Find employee sales performance
SELECT
    e.employeeNumber,
    e.firstName,
    e.lastName,
    COUNT(DISTINCT c.customerNumber) AS totalCustomers,
    COALESCE(SUM(c.creditLimit), 0) AS totalCreditLimit
FROM employees e
LEFT JOIN customers c
    ON c.salesRepEmployeeNumber = e.employeeNumber
GROUP BY e.employeeNumber, e.firstName, e.lastName
ORDER BY totalCustomers DESC, totalCreditLimit DESC;


-- Task 3: Identify high-value customers
WITH CustomerTotals AS (
    SELECT c.customerName,
           SUM(p.amount) AS Total_Payment_Amount
    FROM customers c
    JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY c.customerNumber, c.customerName
)
SELECT customerName, Total_Payment_Amount
FROM CustomerTotals
WHERE Total_Payment_Amount > (SELECT AVG(Total_Payment_Amount) FROM CustomerTotals)
ORDER BY Total_Payment_Amount ASC;

SELECT 
    c.customerName,
    SUM(p.amount) AS total_payment_amount
FROM customers c
INNER JOIN payments p ON c.customerNumber = p.customerNumber
GROUP BY c.customerNumber, c.customerName
HAVING SUM(p.amount) > (
    SELECT AVG(total_payment)
    FROM (
        SELECT SUM(amount) AS total_payment
        FROM payments
        GROUP BY customerNumber
    ) AS customer_totals
)
ORDER BY total_payment_amount ASC;


-- Task 4: Calculate customer lifetime value
-- Write a query to find the total amount spent by each customer, sorted in descending order.
-- Key columns: customer name, total amount spent


Select 
c.customername,
c.contactfirstname, 
c.contactlastname,
Sum(p.amount) AS Total_Payment_Amount
From customers c
Left Join payments p
ON c.customernumber = p.customernumber
Group by c.customername,
c.contactfirstname, 
c.contactlastname
Order by Sum(p.amount) DESC;

-- Task 5: average order value per customer
SELECT
    c.customerName, COALESCE(tp.totalPayments, 0) AS totalPayments, COALESCE(to1.totalOrders, 0) AS totalOrders,
    CASE
        WHEN COALESCE(to1.totalOrders, 0) = 0 THEN 0
        ELSE tp.totalPayments / to1.totalOrders
    END AS AOV
FROM customers c
LEFT JOIN (
    SELECT customerNumber, SUM(amount) AS totalPayments
    FROM payments
    GROUP BY customerNumber
) tp
    ON tp.customerNumber = c.customerNumber
LEFT JOIN (
    SELECT customerNumber, COUNT(*) AS totalOrders
    FROM orders
    GROUP BY customerNumber
) to1
    ON to1.customerNumber = c.customerNumber
ORDER BY AOV DESC;

-- Task 6: Number of orders per customer with order count categories
-- Retrieve the number of order placed by each customer and classify them as:
-- High frequency if greater than 10 orders
-- Regular if 5 - 10 orders
-- Occasional if less than 5 orders
-- Key columns: customer name, order count, customer category


Select c.customername, c.contactfirstname, c.contactlastname, 
COUNT(o.ordernumber) AS Total_Orders,
Case 
   When COUNT(ordernumber) > 10 Then 'High Frequency'
   When COUNT(ordernumber) Between 5 and 10 then 'Regular'
   When COUNT(ordernumber) < 5 then 'Occasional'
End AS Customer_Category
From orders o
Left Join customers c 
ON o.customernumber = c.customernumber
Group by c.customername, c.contactfirstname, c.contactlastname
Order by COUNT(o.ordernumber) DESC;

