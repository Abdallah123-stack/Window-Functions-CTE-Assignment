USE NORTHWND;


-- 1
SELECT c.CustomerID, c.CompanyName,
       SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalOrderValue,
       RANK() OVER (ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC) AS CustomerRank
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY c.CustomerID, c.CompanyName;

-- 2
SELECT CategoryID, ProductID, ProductName, UnitPrice
FROM (
    SELECT CategoryID, ProductID, ProductName, UnitPrice,
           DENSE_RANK() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS rnk
    FROM Products
) t
WHERE rnk = 2;

-- 3
WITH EmpSales AS (
    SELECT e.EmployeeID, e.FirstName, e.LastName,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
    FROM Employees e
    JOIN Orders o ON o.EmployeeID = e.EmployeeID
    JOIN [Order Details] od ON od.OrderID = o.OrderID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
)
SELECT EmployeeID, FirstName, LastName, TotalSales,
       SUM(TotalSales) OVER (ORDER BY EmployeeID
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM EmpSales
ORDER BY EmployeeID;

-- 4
WITH OrderTotals AS (
    SELECT o.OrderID, o.EmployeeID,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue
    FROM Orders o
    JOIN [Order Details] od ON od.OrderID = o.OrderID
    GROUP BY o.OrderID, o.EmployeeID
)
SELECT e.EmployeeID, e.FirstName, e.LastName, AVG(ot.OrderValue) AS AvgOrderValue
FROM OrderTotals ot
JOIN Employees e ON e.EmployeeID = ot.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
HAVING AVG(ot.OrderValue) > (SELECT AVG(OrderValue) FROM OrderTotals);

-- 5
WITH YearlyCounts AS (
    SELECT YEAR(o.OrderDate) AS OrderYear, o.EmployeeID, COUNT(*) AS OrderCount
    FROM Orders o
    GROUP BY YEAR(o.OrderDate), o.EmployeeID
),
Ranked AS (
    SELECT *, RANK() OVER (PARTITION BY OrderYear ORDER BY OrderCount DESC) AS rnk
    FROM YearlyCounts
)
SELECT r.OrderYear, e.EmployeeID, e.FirstName, e.LastName, r.OrderCount
FROM Ranked r
JOIN Employees e ON e.EmployeeID = r.EmployeeID
WHERE r.rnk = 1
ORDER BY r.OrderYear;

-- 6
SELECT CategoryID, ProductID, ProductName, UnitPrice
FROM (
    SELECT CategoryID, ProductID, ProductName, UnitPrice,
           ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS rn
    FROM Products
) t
WHERE rn <= 3
ORDER BY CategoryID, UnitPrice DESC;

-- 7
SELECT c.CategoryName, p.ProductName,
       SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales,
       RANK() OVER (PARTITION BY c.CategoryID
                    ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC) AS SalesRank
FROM Products p
JOIN Categories c ON c.CategoryID = p.CategoryID
JOIN [Order Details] od ON od.ProductID = p.ProductID
GROUP BY c.CategoryID, c.CategoryName, p.ProductID, p.ProductName;

-- 8
WITH OrderTotals AS (
    SELECT o.OrderID, o.EmployeeID, o.CustomerID, o.OrderDate,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS OrderValue
    FROM Orders o
    JOIN [Order Details] od ON od.OrderID = o.OrderID
    GROUP BY o.OrderID, o.EmployeeID, o.CustomerID, o.OrderDate
),
Ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY OrderValue DESC) AS rn
    FROM OrderTotals
)
SELECT e.EmployeeID, e.FirstName, e.LastName,
       r.OrderID, r.CustomerID, r.OrderDate, r.OrderValue
FROM Ranked r
JOIN Employees e ON e.EmployeeID = r.EmployeeID
WHERE r.rn = 1;

-- 9
SELECT c.CategoryName,
       SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS CategorySales,
       ROUND(100.0 * SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))
             / SUM(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))) OVER (), 2) AS PercentOfTotal
FROM Categories c
JOIN Products p ON p.CategoryID = c.CategoryID
JOIN [Order Details] od ON od.ProductID = p.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY CategorySales DESC;

-- 10
WITH CustTotals AS (
    SELECT c.CustomerID, c.CompanyName,
           SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalValue
    FROM Customers c
    JOIN Orders o ON o.CustomerID = c.CustomerID
    JOIN [Order Details] od ON od.OrderID = o.OrderID
    GROUP BY c.CustomerID, c.CompanyName
)
SELECT CustomerID, CompanyName, TotalValue
FROM CustTotals
WHERE TotalValue > (SELECT AVG(TotalValue) FROM CustTotals)
ORDER BY TotalValue DESC;

-- 11
SELECT p.ProductID, p.ProductName
FROM Products p
WHERE NOT EXISTS (SELECT 1 FROM [Order Details] od WHERE od.ProductID = p.ProductID);

-- 12
SELECT e.EmployeeID, e.FirstName, e.LastName,
       YEAR(o.OrderDate) AS SalesYear,
       SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
FROM Employees e
JOIN Orders o ON o.EmployeeID = e.EmployeeID
JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, YEAR(o.OrderDate)
ORDER BY e.EmployeeID, SalesYear;