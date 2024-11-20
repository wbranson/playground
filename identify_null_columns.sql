DECLARE @SchemaName NVARCHAR(MAX) = 'YourSchemaName' -- Replace with your schema name
DECLARE @TableName NVARCHAR(MAX)
DECLARE @ColumnName NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)

-- Temporary table to store all columns and their null-check status
CREATE TABLE #NullColumns (
    SchemaName NVARCHAR(MAX),
    TableName NVARCHAR(MAX),
    ColumnName NVARCHAR(MAX),
    IsNull BIT DEFAULT 0 -- Default to 0, updated to 1 if all values are NULL
)

-- Populate the #NullColumns table with all columns from the specified schema
INSERT INTO #NullColumns (SchemaName, TableName, ColumnName)
SELECT 
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    c.COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.COLUMNS c
JOIN 
    INFORMATION_SCHEMA.TABLES t ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_TYPE = 'BASE TABLE'
    AND c.TABLE_SCHEMA = @SchemaName -- Filter by schema name

-- Cursor to iterate through each column in the #NullColumns table
DECLARE column_cursor CURSOR FOR
SELECT SchemaName, TableName, ColumnName FROM #NullColumns

OPEN column_cursor
FETCH NEXT FROM column_cursor INTO @SchemaName, @TableName, @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build dynamic SQL to check if a column is NULL for all records
    SET @SQL = 'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
               ' WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL) ' +
               'UPDATE #NullColumns ' +
               'SET IsNull = 1 ' +
               'WHERE SchemaName = ''' + @SchemaName + ''' AND TableName = ''' + @TableName + ''' AND ColumnName = ''' + @ColumnName + ''''
    
    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL
    
    FETCH NEXT FROM column_cursor INTO @SchemaName, @TableName, @ColumnName
END

CLOSE column_cursor
DEALLOCATE column_cursor

-- Display results
SELECT * FROM #NullColumns ORDER BY SchemaName, TableName, ColumnName

-- Cleanup
DROP TABLE #NullColumns
