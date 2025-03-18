WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + '
    SELECT 
        t.[Date],
        COUNT(CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))) AS Volume,
        COUNT(DISTINCT CASE WHEN CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX)) IS NOT NULL 
                            AND DATALENGTH(CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))) > 0 THEN t.[Date] END) AS DistinctVolume,  -- Changed to DATALENGTH
        COUNT(*) AS TotalRows,
        ''' + @currentTableName + ''' AS TableName,
        (SELECT TOP 1 CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))
         FROM ' + @currentTable + ' sub
         WHERE CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX)) IS NOT NULL
         AND DATALENGTH(CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))) > 0  -- Changed to DATALENGTH
         AND CAST(sub.[Load_Dt] AS DATE) = t.[Date]
         AND CAST(sub.[Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
         ORDER BY (SELECT NULL)) AS SampleComment
    FROM (
        SELECT 
            CAST([Load_Dt] AS DATE) AS [Date],
            CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))
        FROM ' + @currentTable + '
        WHERE CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX)) IS NOT NULL
        AND DATALENGTH(CAST(' + QUOTENAME(@currentCommentColumn) + ' AS NVARCHAR(MAX))) > 0  -- Changed to DATALENGTH
        AND CAST([Load_Dt] AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
    ) t
    GROUP BY t.[Date]';
​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​