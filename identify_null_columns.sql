DECLARE @TableName NVARCHAR(MAX)
DECLARE @ColumnName NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)

-- Temporary table to store the results
CREATE TABLE #NullColumns (
    TableName NVARCHAR(MAX),
    ColumnName NVARCHAR(MAX)
)

-- Cursor to iterate through all tables and columns in the database
DECLARE column_cursor CURSOR FOR
SELECT 
    t.TABLE_NAME,
    c.COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.COLUMNS c
JOIN 
    INFORMATION_SCHEMA.TABLES t ON c.TABLE_NAME = t.TABLE_NAME
WHERE 
    t.TABLE_TYPE = 'BASE TABLE'

OPEN column_cursor
FETCH NEXT FROM column_cursor INTO @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build dynamic SQL to check if a column is NULL for all records
    SET @SQL = 'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TableName) +
               ' WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL) ' +
               'INSERT INTO #NullColumns (TableName, ColumnName) VALUES (''' +
               @TableName + ''', ''' + @ColumnName + ''')'
               
    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL
    
    FETCH NEXT FROM column_cursor INTO @TableName, @ColumnName
END

CLOSE column_cursor
DEALLOCATE column_cursor

-- Display results
SELECT * FROM #NullColumns

-- Cleanup
DROP TABLE #NullColumns
