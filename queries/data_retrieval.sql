--------------------------------------------------------------------
-- DATA RETRIEVAL QUERIES
-- Children Welfare Management System

-- 1. View all sections
SELECT * FROM sections;

-- 2. View all children with section names
SELECT c.child_id, c.full_name, c.gender, c.disability_status, s.section_name
FROM children c
LEFT JOIN sections s ON c.section_id = s.section_id;

-- 3. View education details with child names
SELECT e.education_id, c.full_name, e.school_name, e.grade_level, e.performance_notes
FROM education e
JOIN children c ON e.child_id = c.child_id;

-- 4. List all support services with child & staff names
SELECT ss.service_id, ss.service_type, ss.service_date,
       c.full_name AS child_name,
       s.full_name AS staff_name
FROM support_services ss
LEFT JOIN children c ON ss.child_id = c.child_id
LEFT JOIN staff s ON ss.staff_id = s.staff_id;

-- 5. View all holidays
SELECT * FROM holidays ORDER BY holiday_date;

-- 6. View staff details
SELECT * FROM staff ORDER BY full_name;

-- 7. View children with disabilities only
SELECT child_id, full_name, gender, section_id
FROM children
WHERE disability_status = 'Yes';

