--------------------------------------------------------------------
-- AUDIT & ERROR LOG QUERIES
-- Children Welfare Management System

-- 1. View all audit log entries
SELECT * FROM dml_audit_log ORDER BY audit_timestamp DESC;

-- 2. Failed operations due to business rules (weekdays/holidays)
SELECT audit_id, table_name, operation_type, user_name, 
       business_rule_violated, error_message, audit_timestamp
FROM dml_audit_log
WHERE operation_status = 'FAILURE'
ORDER BY audit_timestamp DESC;

-- 3. View all inserts made on weekends (should be ALLOWED)
SELECT * 
FROM dml_audit_log
WHERE operation_type = 'INSERT'
  AND business_rule_violated IS NULL
ORDER BY audit_timestamp DESC;

-- 4. Check errors from ERROR_LOG table
SELECT * FROM error_log ORDER BY error_date DESC;

-- 5. See which user performed most DML actions
SELECT user_name, COUNT(*) AS total_operations
FROM dml_audit_log
GROUP BY user_name
ORDER BY total_operations DESC;

-- 6. Each table activity summary
SELECT table_name, operation_type, COUNT(*) AS total_count
FROM dml_audit_log
GROUP BY table_name, operation_type
ORDER BY table_name;

