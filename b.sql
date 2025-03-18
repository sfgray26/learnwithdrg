WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + '
    SELECT 
        t.[Date],
        COUNT(' + QUOTENAME(@currentCommentColumn) + ') AS Volume,
        COUNT(DISTINCT CASE WHEN ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL THEN t.[Date] END) AS DistinctVolume,
        ''' + @currentTableName + ''' AS TableName,
        (SELECT TOP 1 r.' + QUOTENAME(@currentCommentColumn) + '  -- Added 'r.' to reference the alias and corrected correlation
         FROM ' + @currentTable + ' r
         WHERE r.' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL
         AND CAST(r.[Load_Dt] AS DATE) = t.[Date]
         AND CAST(r.[Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''  -- Added date range
         ORDER BY (SELECT NULL)) AS SampleComment
    FROM (
        SELECT 
            CAST([Load_Dt] AS DATE) AS [Date],
            ' + QUOTENAME(@currentCommentColumn) + ' AS ' + QUOTENAME(@currentCommentColumn) + '  -- Added AS clause for clarity
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
​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​