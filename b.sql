DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @tableList TABLE (
    TableName NVARCHAR(255), 
    SchemaName NVARCHAR(50), 
    FullTableName NVARCHAR(255),
    CommentColumn NVARCHAR(255)
);

DECLARE @startDate DATE = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
DECLARE @endDate DATE = CAST(GETDATE() AS DATE);

-- Step 1: Find tables with Load_Dt or LOAD_DT and a recognized comment column in the EDR schema
INSERT INTO @tableList (TableName, SchemaName, FullTableName, CommentColumn)
SELECT 
    t.TABLE_NAME,
    t.TABLE_SCHEMA,
    QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) AS FullTableName,
    c2.COLUMN_NAME AS CommentColumn
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c1 
    ON t.TABLE_SCHEMA = c1.TABLE_SCHEMA 
    AND t.TABLE_NAME = c1.TABLE_NAME
INNER JOIN INFORMATION_SCHEMA.COLUMNS c2 
    ON t.TABLE_SCHEMA = c2.TABLE_SCHEMA 
    AND t.TABLE_NAME = c2.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'EDR'
    AND LOWER(c1.COLUMN_NAME) = 'load_dt'
    AND LOWER(c2.COLUMN_NAME) IN (
        'additionalcomments', 'lienpositioncomments', 'transactioncomments', 
        'intappservicecomments', 'intappadditionalcomments', 
        'isbusinessoutsideresidencecomments', 'agadditionalpropcomments', 
        'intappadditionalpropcomments', 'structurefloodzonecomments', 'prop_comments'
    );

-- Debug: Print the tables found
PRINT 'Tables found with required columns:';
SELECT SchemaName + '.' + TableName + ' (Comment Column: ' + CommentColumn + ')' 
FROM @tableList;

-- Step 2: Build and execute the dynamic SQL
IF EXISTS (SELECT 1 FROM @tableList)
BEGIN
    DECLARE @currentTable NVARCHAR(255);
    DECLARE @currentTableName NVARCHAR(255);
    DECLARE @currentCommentColumn NVARCHAR(255);
    
    DECLARE table_cursor CURSOR FOR
    SELECT FullTableName, TableName, CommentColumn FROM @tableList;

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @currentTable, @currentTableName, @currentCommentColumn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = @sql + '
        SELECT 
            t.[Date],
            COUNT(' + QUOTENAME(@currentCommentColumn) + ') AS Volume,
            COUNT(DISTINCT CASE WHEN ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL THEN t.[Date] END) AS DistinctVolume,
            ''' + @currentTableName + ''' AS TableName,
            (SELECT TOP 1 ' + QUOTENAME(@currentCommentColumn) + '
             FROM ' + @currentTable + ' t
             WHERE ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL
             AND CAST([Load_Dt] AS DATE) = t.[Date]
             ) AS SampleComment
        FROM (
            SELECT 
                CAST([Load_Dt] AS DATE) AS [Date],
                ' + QUOTENAME(@currentCommentColumn) + '
            FROM ' + @currentTable + '
            WHERE ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL
            AND CAST([Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
        ) t
        GROUP BY t.[Date]';

        FETCH NEXT FROM table_cursor INTO @currentTable, @currentTableName, @currentCommentColumn;

        IF @@FETCH_STATUS = 0
            SET @sql = @sql + '
        UNION ALL';
    END;

    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    PRINT 'Generated SQL:';
    PRINT @sql;

    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
END
ELSE
BEGIN
    PRINT 'No tables found with both Load_Dt and a recognized comment column.';
END;
