--------------------------------------------------------------------
-- ANALYTICS & BI QUERIES
-- Children Welfare Management System

-- 1. Count children per section
SELECT s.section_name, COUNT(c.child_id) AS total_children
FROM sections s
LEFT JOIN children c ON s.section_id = c.section_id
GROUP BY s.section_name
ORDER BY total_children DESC;

-- 2. Number of disabled vs non-disabled children
SELECT disability_status, COUNT(*) AS total
FROM children
GROUP BY disability_status;

-- 3. Most common support service types
SELECT service_type, COUNT(*) AS usage_count
FROM support_services
GROUP BY service_type
ORDER BY usage_count DESC;

-- 4. Children receiving the highest number of support services
SELECT c.full_name,
       COUNT(ss.service_id) AS total_services
FROM children c
LEFT JOIN support_services ss ON c.child_id = ss.child_id
GROUP BY c.full_name
ORDER BY total_services DESC;

-- 5. RANK children based on total support received
SELECT c.full_name,
       COUNT(ss.service_id) AS total_services,
       RANK() OVER (ORDER BY COUNT(ss.service_id) DESC) AS service_rank
FROM children c
LEFT JOIN support_services ss ON c.child_id = ss.child_id
GROUP BY c.full_name;

-- 6. Most active staff members (who assisted most)
SELECT s.full_name,
       COUNT(ss.service_id) AS services_provided,
       DENSE_RANK() OVER (ORDER BY COUNT(ss.service_id) DESC) AS rank_position
FROM staff s
LEFT JOIN support_services ss ON s.staff_id = ss.staff_id
GROUP BY s.full_name;

-- 7. Monthly count of services provided (trend analytics)
SELECT 
    TO_CHAR(service_date, 'YYYY-MM') AS month,
    COUNT(*) AS total_services
FROM support_services
GROUP BY TO_CHAR(service_date, 'YYYY-MM')
ORDER BY month;

-- 8. Education performance analytics
SELECT 
    school_name,
    COUNT(*) AS total_students
FROM education
GROUP BY school_name
ORDER BY total_students DESC;

