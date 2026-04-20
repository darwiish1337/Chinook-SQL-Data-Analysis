-- Retrieve top 5 countries generating the highest revenue with invoice count
SELECT
    BillingCountry,
    ROUND(SUM(Total), 2) AS TotalRevenue,
    COUNT(*) AS InvoiceCount
FROM Invoice
GROUP BY BillingCountry
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Retrieve top 5 countries generating the highest revenue with invoice count
SELECT
    BillingCountry,
    ROUND(SUM(Total), 2) AS TotalRevenue,
    COUNT(*) AS InvoiceCount
FROM Invoice
GROUP BY BillingCountry
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Analyze monthly sales distribution (invoices and revenue) over time
SELECT
    strftime('%Y', InvoiceDate) AS Year,
    strftime('%m', InvoiceDate) AS Month,
    COUNT(*) AS Invoices,
    ROUND(SUM(Total), 2) AS MonthlyRevenue
FROM Invoice
GROUP BY Year, Month
ORDER BY Year, Month;

-- Calculate the average invoice value across all transactions
SELECT
    ROUND(AVG(Total), 2) AS AvgInvoice
FROM Invoice;

-- Calculate percentage of invoices that exceed the average invoice value
SELECT
    ROUND(
        100.0 * COUNT(
            CASE
                WHEN Total > (SELECT AVG(Total) FROM Invoice) THEN 1
            END
        ) / COUNT(*), 1
    ) AS PctAboveAvg
FROM Invoice;


-- Retrieve top 8 customers based on total spending
SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS CustomerName,
    c.Country,
    ROUND(SUM(i.Total), 2) AS TotalSpent
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY TotalSpent DESC
LIMIT 10;

-- Count number of customers per country (top 8)
SELECT
    Country,
    COUNT(*) AS CustomerCount
FROM Customer
GROUP BY Country
ORDER BY CustomerCount DESC
LIMIT 10;

-- Calculate average number of invoices per customer
SELECT
    ROUND(AVG(inv_count), 1) AS AvgInvoicesPerCustomer
FROM (
    SELECT CustomerId, COUNT(*) AS inv_count
    FROM Invoice
    GROUP BY CustomerId
);

-- Identify customers inactive for more than 365 days
SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS Customer,
    c.Country,
    MAX(i.InvoiceDate) AS LastPurchase,
    ROUND(
        julianday('2013-12-31') - julianday(MAX(i.InvoiceDate))
    ) AS DaysSinceLastPurchase
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
HAVING DaysSinceLastPurchase > 365
ORDER BY DaysSinceLastPurchase DESCl
LIMIT 10;

-- Calculate number and percentage of customers without assigned support representative
SELECT
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN SupportRepId IS NULL THEN 1 ELSE 0 END) AS NoRepAssigned,
    ROUND(
        100.0 * SUM(CASE WHEN SupportRepId IS NULL THEN 1 ELSE 0 END)
        / COUNT(*), 1
    ) AS PctNoRep
FROM Customer;

-- Identify top music genres by total tracks sold and revenue
SELECT
    g.Name AS Genre,
    COUNT(il.InvoiceLineId) AS TracksSold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Revenue
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Genre g ON t.GenreId  = g.GenreId
GROUP BY g.GenreId
ORDER BY TracksSold DESC
LIMIT 10;

-- Find artists with the largest number of albums and tracks
SELECT
    ar.Name AS Artist,
    COUNT(DISTINCT al.AlbumId) AS Albums,
    COUNT(t.TrackId) AS Tracks
FROM Artist ar
JOIN Album al ON ar.ArtistId = al.ArtistId
JOIN Track t  ON al.AlbumId  = t.AlbumId
GROUP BY ar.ArtistId
ORDER BY Tracks DESC
LIMIT 10;

-- Count number of tracks that have never been sold
SELECT
    COUNT(*) AS NeverSold
FROM Track t
WHERE NOT EXISTS (
    SELECT 1
    FROM InvoiceLine il
    WHERE il.TrackId = t.TrackId
);

-- Calculate percentage of tracks that have never been sold
SELECT
    ROUND(
        100.0 *
        SUM(CASE WHEN il.TrackId IS NULL THEN 1 ELSE 0 END)
        / COUNT(t.TrackId), 1
    ) AS PctNeverSold
FROM Track t
LEFT JOIN InvoiceLine il ON t.TrackId = il.TrackId;

-- Analyze relationship between track duration and sales performance
SELECT
    CASE
        WHEN t.Milliseconds < 180000 THEN 'Short (<3 min)'
        WHEN t.Milliseconds < 300000 THEN 'Medium (3–5 min)'
        WHEN t.Milliseconds < 480000 THEN 'Long (5–8 min)'
        ELSE 'Very Long (>8 min)'
    END AS DurationBucket,
    COUNT(DISTINCT t.TrackId) AS TotalTracks,
    COUNT(il.InvoiceLineId) AS TimesSold,
    ROUND(
        CAST(COUNT(il.InvoiceLineId) AS FLOAT)
        / COUNT(DISTINCT t.TrackId), 2
    ) AS SalesRate
FROM Track t
LEFT JOIN InvoiceLine il ON t.TrackId = il.TrackId
GROUP BY DurationBucket
ORDER BY SalesRate DESC;

-- Analyze distribution of media types in the music catalog
SELECT
    mt.Name AS MediaType,
    COUNT(t.TrackId) AS TrackCount,
    ROUND(
        100.0 * COUNT(t.TrackId)
        / (SELECT COUNT(*) FROM Track), 1
    ) AS Percentage
FROM MediaType mt
JOIN Track t ON mt.MediaTypeId = t.MediaTypeId
GROUP BY mt.MediaTypeId
ORDER BY TrackCount DESC;

-- Identify sales support agents with the highest number of assigned customers
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName AS Employee,
    e.Title,
    COUNT(c.CustomerId) AS CustomerCount
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
GROUP BY e.EmployeeId
ORDER BY CustomerCount DESC;

-- Calculate total revenue, invoices, and average invoice value per support employee
SELECT
    e.FirstName || ' ' || e.LastName AS Employee,
    COUNT(DISTINCT i.InvoiceId) AS TotalInvoices,
    ROUND(SUM(i.Total), 2) AS TotalRevenue,
    ROUND(AVG(i.Total), 2) AS AvgInvoiceValue
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
JOIN Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId
ORDER BY TotalRevenue DESC;

-- Display employee hierarchy including reporting manager
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName AS Employee,
    e.Title,
    m.FirstName || ' ' || m.LastName AS ReportsTo
FROM Employee e
LEFT JOIN Employee m ON e.ReportsId = m.EmployeeId
ORDER BY e.ReportsId NULLS FIRST, e.EmployeeId;

-- Count customers without assigned support representative
SELECT
    COUNT(*) AS UnassignedCustomers
FROM Customer
WHERE SupportRepId IS NULL;

-- Calculate average number of customers handled by each support agent
SELECT
    ROUND(AVG(ccount), 1) AS AvgPortfolioSize
FROM (
    SELECT SupportRepId, COUNT(*) AS ccount
    FROM Customer
    WHERE SupportRepId IS NOT NULL
    GROUP BY SupportRepId
);

