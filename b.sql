WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + '
    SELECT 
        t.[Date],
        COUNT(' + QUOTENAME(@currentCommentColumn) + ') AS Volume,
        COUNT(DISTINCT CASE WHEN ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL THEN t.[Date] END) AS DistinctVolume,
        ''' + @currentTableName + ''' AS TableName,
        (SELECT TOP 1 ' + QUOTENAME(@currentCommentColumn) + '  -- Removed 'r.' and simplified subquery
         FROM ' + @currentTable + ' sub
         WHERE ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL
         AND CAST(sub.[Load_Dt] AS DATE) = t.[Date]
         AND CAST(sub.[Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
         ORDER BY (SELECT NULL)) AS SampleComment
    FROM (
        SELECT 
            CAST([Load_Dt] AS DATE) AS [Date],
            ' + QUOTENAME(@currentCommentColumn) + '
        FROM ' + @currentTable + '
        WHERE ' + QUOTENAME(@currentCommentColumn) + ' IS NOT NULL
        AND CAST([Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
    ) t
    GROUP BY t.[Date]';
​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​