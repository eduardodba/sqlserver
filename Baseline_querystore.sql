set transaction isolation level read uncommitted

SELECT 
    p.query_id query_id,
    q.object_id object_id,
    ISNULL(OBJECT_NAME(q.object_id),'''') object_name,
    qt.query_sql_text query_sql_text,
    ROUND(CONVERT(float, SUM(rs.avg_duration*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001,2) avg_duration,
    ROUND(CONVERT(float, SUM(rs.avg_cpu_time*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001,2) avg_cpu_time,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_reads*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*8,2) avg_logical_io_reads,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_writes*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*8,2) avg_logical_io_writes,
    ROUND(CONVERT(float, SUM(rs.avg_physical_io_reads*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*8,2) avg_physical_io_reads,
    SUM(rs.count_executions) count_executions,
    ROUND(CONVERT(float, SUM(rs.avg_clr_time*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001,2) avg_clr_time,
    ROUND(CONVERT(float, SUM(rs.avg_dop*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*1,0) avg_dop,
    ROUND(CONVERT(float, SUM(rs.avg_query_max_used_memory*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*8,2) avg_query_max_used_memory,
    ROUND(CONVERT(float, SUM(rs.avg_rowcount*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*1,0) avg_rowcount,
    COUNT(distinct p.plan_id) num_plans
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id 
JOIN sys.query_store_query q ON q.query_id = p.query_id
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id 
JOIN sys.query_store_runtime_stats_interval i ON rs.runtime_stats_interval_id = i.runtime_stats_interval_id
GROUP BY p.query_id, qt.query_sql_text, q.object_id
HAVING COUNT(distinct p.plan_id) >= 1
order by AVG_CPU_TIME DESC
