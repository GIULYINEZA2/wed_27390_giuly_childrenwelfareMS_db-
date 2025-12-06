--PROCEDURE 1

create or replace PROCEDURE add_education_record(
    p_child_id IN NUMBER,
    p_school_name IN VARCHAR2,
    p_grade_level IN VARCHAR2,
    p_performance_notes IN VARCHAR2
) IS
    v_child_exists NUMBER;
    v_current_grade VARCHAR2(30);
    v_performance_score NUMBER;
    v_child_name VARCHAR2(100);
BEGIN
    -- Validate inputs
    IF p_school_name IS NULL OR LENGTH(TRIM(p_school_name)) < 2 THEN
        RAISE_APPLICATION_ERROR(-20012, 'School name must be provided');
    END IF;

    IF p_grade_level IS NULL THEN
        RAISE_APPLICATION_ERROR(-20013, 'Grade level must be provided');
    END IF;

    -- Validate child exists
    BEGIN
        SELECT full_name INTO v_child_name
        FROM children
        WHERE child_id = p_child_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Child not found: ' || p_child_id);
    END;

    -- Get current grade if exists
    BEGIN
        SELECT grade_level INTO v_current_grade
        FROM education
        WHERE child_id = p_child_id
        AND ROWNUM = 1
        ORDER BY education_id DESC;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_current_grade := NULL;
    END;

    -- Calculate performance score
    v_performance_score := CASE
        WHEN UPPER(p_performance_notes) LIKE '%EXCELLENT%' THEN 5
        WHEN UPPER(p_performance_notes) LIKE '%GOOD%' THEN 4
        WHEN UPPER(p_performance_notes) LIKE '%AVERAGE%' THEN 3
        WHEN UPPER(p_performance_notes) LIKE '%NEEDS IMPROVEMENT%' THEN 2
        WHEN UPPER(p_performance_notes) LIKE '%STRUGGLING%' THEN 1
        ELSE 3 -- Default average
    END;

    -- Insert education record
    INSERT INTO education (
        child_id, school_name, grade_level, performance_notes
    ) VALUES (
        p_child_id, p_school_name, p_grade_level, p_performance_notes
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Education record added for ' || v_child_name);
    DBMS_OUTPUT.PUT_LINE('School: ' || p_school_name || 
                       ', Grade: ' || p_grade_level ||
                       ', Performance Score: ' || v_performance_score);

    -- Log grade progression
    IF v_current_grade IS NOT NULL AND v_current_grade != p_grade_level THEN
        DBMS_OUTPUT.PUT_LINE('Grade progression: ' || v_current_grade || 
                           ' → ' || p_grade_level);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in add_education_record: ' || SQLERRM);
        RAISE;
END add_education_record;





---PROCEDURE 2



create or replace PROCEDURE analyze_service_patterns IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('COMPREHENSIVE SERVICE PATTERN ANALYSIS');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');

    -- Service frequency analysis
    DBMS_OUTPUT.PUT_LINE('1. SERVICE FREQUENCY RANKING');
    DBMS_OUTPUT.PUT_LINE('────────────────────────────');

    FOR rec1 IN (
        SELECT 
            service_type,
            total_services,
            percent_of_total,
            type_rank,
            gap_to_next,
            CASE 
                WHEN percent_of_total >= 20 THEN 'HIGH'
                WHEN percent_of_total >= 10 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS frequency_category
        FROM (
            SELECT 
                service_type,
                COUNT(*) AS total_services,
                ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percent_of_total,
                RANK() OVER (ORDER BY COUNT(*) DESC) AS type_rank,
                COUNT(*) - LEAD(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) AS gap_to_next
            FROM support_services
            GROUP BY service_type
        )
        ORDER BY type_rank
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Rank ' || LPAD(rec1.type_rank, 2) || ': ' ||
            RPAD(rec1.service_type, 25) ||
            ' | Services: ' || LPAD(rec1.total_services, 4) ||
            ' | % of total: ' || LPAD(rec1.percent_of_total, 6) || '%' ||
            ' | Gap: ' || LPAD(NVL(TO_CHAR(rec1.gap_to_next), '-'), 4) ||
            ' | Category: ' || rec1.frequency_category
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. MONTHLY TREND WITH WINDOW FUNCTIONS');
    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────');

    FOR rec2 IN (
        SELECT 
            service_month,
            service_count,
            monthly_rank,
            monthly_change,
            ROUND(service_count * 100.0 / AVG(service_count) OVER (
                ORDER BY service_month 
                ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
            ), 2) AS centered_avg_percent,
            SUM(service_count) OVER (
                ORDER BY service_month 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cumulative_total
        FROM (
            SELECT 
                TO_CHAR(service_date, 'YYYY-MM') AS service_month,
                COUNT(*) AS service_count,
                RANK() OVER (ORDER BY COUNT(*) DESC) AS monthly_rank,
                COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(service_date, 'YYYY-MM')) AS monthly_change
            FROM support_services
            WHERE service_date >= ADD_MONTHS(SYSDATE, -6)
            GROUP BY TO_CHAR(service_date, 'YYYY-MM')
        )
        ORDER BY service_month
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Month: ' || rec2.service_month ||
            ' | Count: ' || LPAD(rec2.service_count, 4) ||
            ' | Rank: ' || LPAD(rec2.monthly_rank, 2) ||
            ' | Change: ' || LPAD(NVL(TO_CHAR(rec2.monthly_change), '-'), 5) ||
            ' | % of 5-month avg: ' || LPAD(rec2.centered_avg_percent, 6) || '%' ||
            ' | Cumulative: ' || LPAD(rec2.cumulative_total, 6)
        );
    END LOOP;

END analyze_service_patterns;





--PROCEDURE 3


create or replace PROCEDURE assign_service(
    p_child_id IN NUMBER,
    p_service_type IN VARCHAR2,
    p_description IN VARCHAR2,
    p_staff_id IN NUMBER DEFAULT NULL,
    p_service_date IN DATE DEFAULT SYSDATE
) IS
    v_child_exists NUMBER;
    v_staff_exists NUMBER;
    v_service_id NUMBER;
    v_child_name VARCHAR2(100);
    v_staff_name VARCHAR2(100);
    v_age_months NUMBER;
    v_disability VARCHAR2(3);
BEGIN
    -- Validate service type
    IF p_service_type IS NULL THEN
        RAISE_APPLICATION_ERROR(-20015, 'Service type must be provided');
    END IF;

    -- Validate description
    IF p_description IS NULL OR LENGTH(TRIM(p_description)) < 5 THEN
        RAISE_APPLICATION_ERROR(-20016, 'Description must be at least 5 characters');
    END IF;

    -- Validate service date
    IF p_service_date > SYSDATE + 30 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Service date cannot be more than 30 days in future');
    END IF;

    -- Check child existence and get details
    IF p_child_id IS NOT NULL THEN
        BEGIN
            SELECT full_name, 
                   MONTHS_BETWEEN(SYSDATE, date_of_birth),
                   disability_status
            INTO v_child_name, v_age_months, v_disability
            FROM children
            WHERE child_id = p_child_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20018, 'Child not found: ' || p_child_id);
        END;

        -- Check service eligibility based on age
        IF p_service_type = 'Vocational Training' AND v_age_months < 168 THEN -- Under 14
            RAISE_APPLICATION_ERROR(-20019, 
                'Child too young for vocational training (minimum 14 years)');
        END IF;

        -- Check service frequency limit
        DECLARE
            v_recent_services NUMBER;
        BEGIN
            SELECT COUNT(*)
            INTO v_recent_services
            FROM support_services
            WHERE child_id = p_child_id
            AND service_type = p_service_type
            AND service_date >= ADD_MONTHS(SYSDATE, -3); -- Last 3 months

            IF v_recent_services >= 5 THEN
                RAISE_APPLICATION_ERROR(-20020, 
                    'Service limit reached: Maximum 5 ' || p_service_type || 
                    ' services per 3 months');
            END IF;
        END;
    END IF;

    -- Check staff existence
    IF p_staff_id IS NOT NULL THEN
        BEGIN
            SELECT full_name INTO v_staff_name
            FROM staff
            WHERE staff_id = p_staff_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20021, 'Staff member not found: ' || p_staff_id);
        END;
    ELSE
        v_staff_name := 'Unassigned';
    END IF;

    -- Insert service record
    INSERT INTO support_services (
        service_type, description, child_id, 
        staff_id, service_date
    ) VALUES (
        p_service_type, p_description, p_child_id,
        p_staff_id, p_service_date
    ) RETURNING service_id INTO v_service_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Service assigned successfully.');
    DBMS_OUTPUT.PUT_LINE('Service ID: ' || v_service_id);
    DBMS_OUTPUT.PUT_LINE('Type: ' || p_service_type);

    IF p_child_id IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Child: ' || v_child_name);
    END IF;

    DBMS_OUTPUT.PUT_LINE('Staff: ' || v_staff_name);
    DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(p_service_date, 'DD-MON-YYYY'));

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in assign_service: ' || SQLERRM);
        RAISE;
END assign_service;





---PROCEDURE 4


create or replace PROCEDURE bulk_collect_demo IS
    -- Define collection types
    TYPE child_id_table IS TABLE OF children.child_id%TYPE;
    TYPE child_name_table IS TABLE OF children.full_name%TYPE;
    TYPE child_age_table IS TABLE OF NUMBER;

    -- Declare collections
    v_ids child_id_table;
    v_names child_name_table;
    v_ages child_age_table;

    v_total_children NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE('BULK COLLECT DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Demonstrating BULK COLLECT for performance');
    DBMS_OUTPUT.PUT_LINE('');

    -- Get total children count first
    SELECT COUNT(*) INTO v_total_children FROM children;
    DBMS_OUTPUT.PUT_LINE('Total children in database: ' || v_total_children);
    DBMS_OUTPUT.PUT_LINE('');

    -- Bulk collect first 10 children
    SELECT 
        child_id,
        full_name,
        ROUND(MONTHS_BETWEEN(SYSDATE, date_of_birth)/12, 1)
    BULK COLLECT INTO v_ids, v_names, v_ages
    FROM children
    WHERE ROWNUM <= 10;

    DBMS_OUTPUT.PUT_LINE('Bulk collected ' || v_ids.COUNT || ' children');
    DBMS_OUTPUT.PUT_LINE('');

    -- Process the collection
    FOR i IN 1..v_ids.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Child ' || i || ':');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || v_ids(i));
        DBMS_OUTPUT.PUT_LINE('  Name: ' || v_names(i));
        DBMS_OUTPUT.PUT_LINE('  Age: ' || v_ages(i) || ' years');
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    -- Demonstrate collection methods
    DBMS_OUTPUT.PUT_LINE('COLLECTION METHODS:');
    DBMS_OUTPUT.PUT_LINE('  COUNT: ' || v_ids.COUNT);
    DBMS_OUTPUT.PUT_LINE('  FIRST: ' || v_ids.FIRST);
    DBMS_OUTPUT.PUT_LINE('  LAST: ' || v_ids.LAST);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No children found in database.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END bulk_collect_demo;





--PROCEDURE 5



create or replace PROCEDURE bulk_update_disability_status IS
    v_updated_count NUMBER := 0;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_special_needs_section_id NUMBER;

BEGIN
    v_start_time := SYSTIMESTAMP;

    DBMS_OUTPUT.PUT_LINE('BULK DISABILITY STATUS UPDATE');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Starting at: ' || TO_CHAR(v_start_time, 'DD-MON-YYYY HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Get Special Needs Unit section ID
    BEGIN
        SELECT section_id INTO v_special_needs_section_id
        FROM sections 
        WHERE UPPER(section_name) LIKE '%SPECIAL%NEEDS%';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Special Needs Unit section not found');
            RETURN;
    END;

    -- Update children with 3+ medical/psychological services
    UPDATE children c
    SET disability_status = 'Yes',
        section_id = v_special_needs_section_id
    WHERE c.disability_status = 'No'
    AND c.child_id IN (
        SELECT child_id
        FROM support_services
        WHERE service_type IN ('Medical Checkup', 'Psychological Counseling')
        GROUP BY child_id
        HAVING COUNT(*) >= 3
    );

    v_updated_count := SQL%ROWCOUNT;

    COMMIT;

    v_end_time := SYSTIMESTAMP;

    -- Display summary
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('BULK UPDATE COMPLETE');
    DBMS_OUTPUT.PUT_LINE('════════════════════');
    DBMS_OUTPUT.PUT_LINE('Successfully updated: ' || v_updated_count || ' children');
    DBMS_OUTPUT.PUT_LINE('Processing time: ' || 
                        ROUND(EXTRACT(SECOND FROM (v_end_time - v_start_time)), 3) || ' seconds');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END bulk_update_disability_status;





--PROCEDURE 6


create or replace PROCEDURE comprehensive_cursor_demo IS
    -- Multiple cursor types in one procedure
    v_total_processed NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('COMPREHENSIVE CURSOR DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Demonstrating all cursor features');
    DBMS_OUTPUT.PUT_LINE('');

    -- 1. Simple explicit cursor
    DBMS_OUTPUT.PUT_LINE('1. SIMPLE EXPLICIT CURSOR:');
    DECLARE
        CURSOR cur_sections IS
            SELECT section_id, section_name
            FROM sections
            ORDER BY section_id;

        v_section_id sections.section_id%TYPE;
        v_section_name sections.section_name%TYPE;
    BEGIN
        OPEN cur_sections;
        LOOP
            FETCH cur_sections INTO v_section_id, v_section_name;
            EXIT WHEN cur_sections%NOTFOUND;

            v_total_processed := v_total_processed + 1;
            DBMS_OUTPUT.PUT_LINE('   Section ' || v_section_id || ': ' || v_section_name);
        END LOOP;
        CLOSE cur_sections;
    END;

    DBMS_OUTPUT.PUT_LINE('   Total sections: ' || v_total_processed);
    DBMS_OUTPUT.PUT_LINE('');

    -- 2. Cursor with parameters
    DBMS_OUTPUT.PUT_LINE('2. CURSOR WITH PARAMETERS:');
    DECLARE
        CURSOR cur_children_by_gender(p_gender VARCHAR2) IS
            SELECT child_id, full_name
            FROM children
            WHERE gender = p_gender
            AND ROWNUM <= 3;

        v_child_id children.child_id%TYPE;
        v_child_name children.full_name%TYPE;
        v_count NUMBER := 0;
    BEGIN
        OPEN cur_children_by_gender('Male');
        LOOP
            FETCH cur_children_by_gender INTO v_child_id, v_child_name;
            EXIT WHEN cur_children_by_gender%NOTFOUND;

            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('   Male child ' || v_count || ': ' || v_child_name);
        END LOOP;
        CLOSE cur_children_by_gender;
    END;

    DBMS_OUTPUT.PUT_LINE('');

    -- 3. Cursor FOR loop (implicit)
    DBMS_OUTPUT.PUT_LINE('3. CURSOR FOR LOOP (IMPLICIT):');
    DECLARE
        CURSOR cur_education IS
            SELECT e.education_id, c.full_name, e.grade_level
            FROM education e
            JOIN children c ON e.child_id = c.child_id
            WHERE ROWNUM <= 3
            ORDER BY e.education_id;

        v_edu_count NUMBER := 0;
    BEGIN
        FOR edu_rec IN cur_education LOOP
            v_edu_count := v_edu_count + 1;
            DBMS_OUTPUT.PUT_LINE('   Education ' || v_edu_count || ': ' ||
                               edu_rec.full_name || ' - Grade ' || edu_rec.grade_level);
        END LOOP;
    END;

    DBMS_OUTPUT.PUT_LINE('');

    -- 4. Bulk operations summary
    DBMS_OUTPUT.PUT_LINE('4. BULK OPERATIONS PERFORMANCE:');
    DBMS_OUTPUT.PUT_LINE('   Use BULK COLLECT for fetching multiple rows');
    DBMS_OUTPUT.PUT_LINE('   Use FORALL for inserting/updating multiple rows');
    DBMS_OUTPUT.PUT_LINE('   Benefits: Reduced context switches, better performance');

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('DEMONSTRATION COMPLETE');

END comprehensive_cursor_demo;




--PROCEDURE 7


create or replace PROCEDURE cursor_for_loop_demo IS
    -- Simple cursor for FOR loop
    CURSOR cur_staff IS
        SELECT staff_id, full_name, position
        FROM staff
        WHERE ROWNUM <= 5
        ORDER BY staff_id;

    v_counter NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('CURSOR FOR LOOP DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Demonstrating implicit cursor management');
    DBMS_OUTPUT.PUT_LINE('');

    -- Cursor FOR loop (Oracle automatically opens, fetches, and closes)
    FOR staff_rec IN cur_staff LOOP
        v_counter := v_counter + 1;
        DBMS_OUTPUT.PUT_LINE('Staff ' || v_counter || ':');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || staff_rec.staff_id);
        DBMS_OUTPUT.PUT_LINE('  Name: ' || staff_rec.full_name);
        DBMS_OUTPUT.PUT_LINE('  Position: ' || staff_rec.position);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Total staff processed: ' || v_counter);

END cursor_for_loop_demo;




--PROCEDURE 8


create or replace PROCEDURE cursor_with_parameters(
    p_gender IN VARCHAR2 DEFAULT 'Male'
) IS
    CURSOR cur_gender(cp_gender VARCHAR2) IS
        SELECT child_id, full_name, 
               MONTHS_BETWEEN(SYSDATE, date_of_birth)/12 as age
        FROM children
        WHERE gender = cp_gender
        AND ROWNUM <= 5;

    v_child_id children.child_id%TYPE;
    v_name children.full_name%TYPE;
    v_age NUMBER;
    v_counter NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('CURSOR WITH PARAMETERS: Gender = ' || p_gender);
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════');

    OPEN cur_gender(p_gender);

    LOOP
        FETCH cur_gender INTO v_child_id, v_name, v_age;
        EXIT WHEN cur_gender%NOTFOUND;

        v_counter := v_counter + 1;
        DBMS_OUTPUT.PUT_LINE(
            v_name || ' - Age: ' || ROUND(v_age, 1) || ' years'
        );
    END LOOP;

    CLOSE cur_gender;

    DBMS_OUTPUT.PUT_LINE('Total: ' || v_counter || ' ' || p_gender || ' children');

END cursor_with_parameters;



--PROCEDURE 9

create or replace PROCEDURE demonstrate_aggregate_functions IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('WINDOW FUNCTIONS: AGGREGATES WITH OVER CLAUSE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('1. Running totals and averages');
    DBMS_OUTPUT.PUT_LINE('─────────────────────────────');

    FOR rec IN (
        SELECT 
            service_date,
            service_type,
            COUNT(*) AS daily_count,
            SUM(COUNT(*)) OVER (
                ORDER BY service_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_total,
            AVG(COUNT(*)) OVER (
                ORDER BY service_date
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ) AS moving_avg_3days,
            MAX(COUNT(*)) OVER (
                ORDER BY service_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS max_so_far
        FROM support_services
        WHERE service_date >= TRUNC(SYSDATE) - 10
        AND service_type = 'Medical Checkup'
        GROUP BY service_date, service_type
        ORDER BY service_date
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Date: ' || TO_CHAR(rec.service_date, 'DD-MON') ||
            ' | Daily: ' || LPAD(rec.daily_count, 3) ||
            ' | Running Total: ' || LPAD(rec.running_total, 5) ||
            ' | 3-day Avg: ' || LPAD(ROUND(rec.moving_avg_3days, 1), 5) ||
            ' | Max so far: ' || LPAD(rec.max_so_far, 3)
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. Section-wise aggregates');
    DBMS_OUTPUT.PUT_LINE('─────────────────────────');

    FOR rec2 IN (
        SELECT 
            s.section_name,
            c.full_name,
            calculate_child_age(c.child_id) AS age,
            COUNT(*) OVER (PARTITION BY c.section_id) AS section_total,
            AVG(calculate_child_age(c.child_id)) OVER (PARTITION BY c.section_id) AS section_avg_age,
            MIN(calculate_child_age(c.child_id)) OVER (PARTITION BY c.section_id) AS section_min_age,
            MAX(calculate_child_age(c.child_id)) OVER (PARTITION BY c.section_id) AS section_max_age
        FROM children c
        JOIN sections s ON c.section_id = s.section_id
        WHERE calculate_child_age(c.child_id) IS NOT NULL
        AND ROWNUM <= 10
        ORDER BY s.section_name, calculate_child_age(c.child_id) DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Section: ' || RPAD(rec2.section_name, 25) ||
            ' | Child: ' || RPAD(rec2.full_name, 20) ||
            ' | Age: ' || LPAD(ROUND(rec2.age, 1), 5) ||
            ' | Section Total: ' || LPAD(rec2.section_total, 3) ||
            ' | Avg Age: ' || LPAD(ROUND(rec2.section_avg_age, 1), 5) ||
            ' | Min-Max: ' || LPAD(ROUND(rec2.section_min_age, 1), 4) || 
            '-' || LPAD(ROUND(rec2.section_max_age, 1), 4)
        );
    END LOOP;

END demonstrate_aggregate_functions;




--PROCEDURE 10


create or replace PROCEDURE demonstrate_lag_lead_functions IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('WINDOW FUNCTIONS: LAG() AND LEAD() DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('═════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('1. LAG() - Access previous row');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────');

    FOR rec IN (
        SELECT 
            service_date,
            service_type,
            COUNT(*) AS daily_count,
            LAG(COUNT(*), 1, 0) OVER (
                ORDER BY service_date
            ) AS previous_day_count,
            COUNT(*) - LAG(COUNT(*), 1, 0) OVER (
                ORDER BY service_date
            ) AS day_to_day_change
        FROM support_services
        WHERE service_date >= TRUNC(SYSDATE) - 7
        GROUP BY service_date, service_type
        HAVING service_type = 'Medical Checkup'
        ORDER BY service_date
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Date: ' || TO_CHAR(rec.service_date, 'DD-MON') ||
            ' | Type: ' || RPAD(rec.service_type, 20) ||
            ' | Today: ' || LPAD(rec.daily_count, 3) ||
            ' | Yesterday: ' || LPAD(rec.previous_day_count, 3) ||
            ' | Change: ' || LPAD(rec.day_to_day_change, 3)
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. LEAD() - Access next row');
    DBMS_OUTPUT.PUT_LINE('───────────────────────────');

    FOR rec2 IN (
        SELECT 
            child_id,
            full_name,
            date_of_birth,
            LEAD(full_name, 1, 'No next child') OVER (
                ORDER BY date_of_birth
            ) AS next_child,
            LEAD(date_of_birth, 1) OVER (
                ORDER BY date_of_birth
            ) AS next_birthdate,
            LEAD(date_of_birth, 1) OVER (
                ORDER BY date_of_birth
            ) - date_of_birth AS days_to_next_birth
        FROM children
        WHERE ROWNUM <= 8
        ORDER BY date_of_birth
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Child: ' || RPAD(rec2.full_name, 20) ||
            ' | Born: ' || TO_CHAR(rec2.date_of_birth, 'DD-MON-YY') ||
            ' | Next Child: ' || RPAD(rec2.next_child, 20) ||
            ' | Days to next: ' || NVL(TO_CHAR(rec2.days_to_next_birth), 'N/A')
        );
    END LOOP;

END demonstrate_lag_lead_functions;




--PROCEDURE 11


create or replace PROCEDURE demonstrate_ranking_functions IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('WINDOW FUNCTIONS: RANKING DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('1. ROW_NUMBER(), RANK(), DENSE_RANK()');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────');

    FOR rec IN (
        SELECT 
            child_id,
            full_name,
            calculate_child_age(child_id) AS age,
            disability_status,
            -- ROW_NUMBER: Sequential numbering
            ROW_NUMBER() OVER (ORDER BY calculate_child_age(child_id) DESC) AS row_num,
            -- RANK: Leaves gaps for ties
            RANK() OVER (ORDER BY calculate_child_age(child_id) DESC) AS age_rank,
            -- DENSE_RANK: No gaps for ties
            DENSE_RANK() OVER (ORDER BY calculate_child_age(child_id) DESC) AS dense_age_rank
        FROM children
        WHERE calculate_child_age(child_id) IS NOT NULL
        AND ROWNUM <= 10
        ORDER BY calculate_child_age(child_id) DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Child: ' || RPAD(rec.full_name, 20) ||
            ' | Age: ' || LPAD(ROUND(rec.age, 1), 5) ||
            ' | Row#: ' || LPAD(rec.row_num, 3) ||
            ' | Rank: ' || LPAD(rec.age_rank, 3) ||
            ' | Dense Rank: ' || LPAD(rec.dense_age_rank, 3)
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. PARTITION BY (Group-wise ranking)');
    DBMS_OUTPUT.PUT_LINE('────────────────────────────────────');

    FOR rec2 IN (
        SELECT 
            s.section_name,
            c.full_name,
            calculate_child_age(c.child_id) AS age,
            -- Rank within each section
            ROW_NUMBER() OVER (
                PARTITION BY c.section_id 
                ORDER BY calculate_child_age(c.child_id) DESC
            ) AS section_row_num,
            RANK() OVER (
                PARTITION BY c.section_id 
                ORDER BY calculate_child_age(c.child_id) DESC
            ) AS section_rank
        FROM children c
        JOIN sections s ON c.section_id = s.section_id
        WHERE calculate_child_age(c.child_id) IS NOT NULL
        AND ROWNUM <= 15
        ORDER BY s.section_name, age DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Section: ' || RPAD(rec2.section_name, 25) ||
            ' | Child: ' || RPAD(rec2.full_name, 20) ||
            ' | Age: ' || LPAD(ROUND(rec2.age, 1), 5) ||
            ' | Section Row#: ' || LPAD(rec2.section_row_num, 2) ||
            ' | Section Rank: ' || LPAD(rec2.section_rank, 2)
        );
    END LOOP;

END demonstrate_ranking_functions;




--PROCEDURE 12


create or replace PROCEDURE forall_bulk_update IS
    -- Collections for bulk operations
    TYPE child_id_table IS TABLE OF children.child_id%TYPE;
    TYPE service_desc_table IS TABLE OF support_services.description%TYPE;

    v_ids child_id_table;
    v_descriptions service_desc_table;

    v_update_count NUMBER;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;

BEGIN
    v_start_time := SYSTIMESTAMP;

    DBMS_OUTPUT.PUT_LINE('FORALL BULK UPDATE DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Demonstrating FORALL for bulk DML operations');
    DBMS_OUTPUT.PUT_LINE('Start time: ' || TO_CHAR(v_start_time, 'HH24:MI:SS.FF3'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Get first 5 children
    SELECT child_id
    BULK COLLECT INTO v_ids
    FROM children
    WHERE ROWNUM <= 5;

    DBMS_OUTPUT.PUT_LINE('Selected ' || v_ids.COUNT || ' children for update');

    IF v_ids.COUNT > 0 THEN
        -- Initialize descriptions collection
        v_descriptions := service_desc_table();
        v_descriptions.EXTEND(v_ids.COUNT);

        -- Prepare descriptions
        FOR i IN 1..v_ids.COUNT LOOP
            v_descriptions(i) := 'Health checkup for child ID ' || v_ids(i) || 
                                ' on ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY');
        END LOOP;

        -- Use FORALL for bulk insert
        FORALL i IN 1..v_ids.COUNT
            INSERT INTO support_services (
                service_type, description, child_id, service_date
            ) VALUES (
                'Medical Checkup', v_descriptions(i), v_ids(i), SYSDATE
            );

        v_update_count := SQL%ROWCOUNT;

        COMMIT;

        v_end_time := SYSTIMESTAMP;

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('BULK INSERT COMPLETE');
        DBMS_OUTPUT.PUT_LINE('  Records inserted: ' || v_update_count);
        DBMS_OUTPUT.PUT_LINE('  Processing time: ' || 
                            ROUND(EXTRACT(SECOND FROM (v_end_time - v_start_time)) * 1000, 3) || ' ms');
        DBMS_OUTPUT.PUT_LINE('  End time: ' || TO_CHAR(v_end_time, 'HH24:MI:SS.FF3'));

        -- Show what was inserted
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('INSERTED RECORDS:');
        FOR i IN 1..v_ids.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  Child ID ' || v_ids(i) || ': ' || 
                               SUBSTR(v_descriptions(i), 1, 40) || '...');
        END LOOP;
    ELSE
        DBMS_OUTPUT.PUT_LINE('No children found to process');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END forall_bulk_update;



--PROCEDURE 13


create or replace PROCEDURE generate_monthly_report(
    p_month IN VARCHAR2 DEFAULT TO_CHAR(SYSDATE, 'YYYY-MM'),
    p_report OUT CLOB
) IS
    v_start_date DATE;
    v_end_date DATE;
    v_report_text CLOB;

    -- Variables for statistics
    v_total_children NUMBER;
    v_disabled_count NUMBER;
    v_services_provided NUMBER;
    v_staff_involved NUMBER;
    v_education_updates NUMBER;
    v_avg_age NUMBER;
    v_percentage NUMBER;
    v_avg_services_per_day NUMBER;
BEGIN
    -- Validate month format
    BEGIN
        v_start_date := TO_DATE(p_month || '-01', 'YYYY-MM-DD');
        v_end_date := LAST_DAY(v_start_date);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20022, 
                'Invalid month format. Use YYYY-MM (e.g., 2025-12)');
    END;

    -- Initialize report
    v_report_text := 'CHILDREN WELFARE MANAGEMENT SYSTEM' || CHR(10);
    v_report_text := v_report_text || '======================================' || CHR(10);
    v_report_text := v_report_text || 'MONTHLY REPORT: ' || p_month || CHR(10);
    v_report_text := v_report_text || 'Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI') || CHR(10);
    v_report_text := v_report_text || CHR(10);

    -- Get statistics using separate queries
    -- Total children
    SELECT COUNT(DISTINCT child_id)
    INTO v_total_children
    FROM children;

    -- Children with disabilities
    SELECT COUNT(*)
    INTO v_disabled_count
    FROM children
    WHERE disability_status = 'Yes';

    -- Services provided in the month
    SELECT COUNT(DISTINCT service_id)
    INTO v_services_provided
    FROM support_services
    WHERE service_date BETWEEN v_start_date AND v_end_date;

    -- Staff involved in the month
    SELECT COUNT(DISTINCT staff_id)
    INTO v_staff_involved
    FROM support_services
    WHERE service_date BETWEEN v_start_date AND v_end_date;

    -- Education updates in the month
    SELECT COUNT(DISTINCT education_id)
    INTO v_education_updates
    FROM education;

    -- Average age
    SELECT ROUND(AVG(MONTHS_BETWEEN(SYSDATE, date_of_birth)/12), 1)
    INTO v_avg_age
    FROM children;

    -- Calculate percentage for disabled children
    IF v_total_children > 0 THEN
        v_percentage := ROUND(v_disabled_count * 100.0 / v_total_children, 2);
    ELSE
        v_percentage := 0;
    END IF;

    -- Calculate average services per day
    IF (v_end_date - v_start_date + 1) > 0 THEN
        v_avg_services_per_day := ROUND(v_services_provided / (v_end_date - v_start_date + 1), 2);
    ELSE
        v_avg_services_per_day := 0;
    END IF;

    -- Add statistics section
    v_report_text := v_report_text || 'OVERALL STATISTICS:' || CHR(10);
    v_report_text := v_report_text || '──────────────────' || CHR(10);
    v_report_text := v_report_text || 'Total Children: ' || v_total_children || CHR(10);
    v_report_text := v_report_text || 'Children with Disabilities: ' || v_disabled_count || 
                     ' (' || v_percentage || '%)' || CHR(10);
    v_report_text := v_report_text || 'Services Provided: ' || v_services_provided || CHR(10);
    v_report_text := v_report_text || 'Staff Involved: ' || v_staff_involved || CHR(10);
    v_report_text := v_report_text || 'Education Updates: ' || v_education_updates || CHR(10);
    v_report_text := v_report_text || 'Average Age: ' || v_avg_age || ' years' || CHR(10);
    v_report_text := v_report_text || CHR(10);

    -- Add section distribution
    v_report_text := v_report_text || 'SECTION DISTRIBUTION:' || CHR(10);
    v_report_text := v_report_text || '────────────────────' || CHR(10);

    FOR rec IN (
        SELECT 
            s.section_name,
            COUNT(c.child_id) AS child_count
        FROM sections s
        LEFT JOIN children c ON s.section_id = c.section_id
        GROUP BY s.section_name, s.section_id
        ORDER BY s.section_id
    ) LOOP
        v_report_text := v_report_text || 
            RPAD(rec.section_name, 30) || ': ' || 
            LPAD(rec.child_count, 4) || ' children' || CHR(10);
    END LOOP;

    v_report_text := v_report_text || CHR(10);

    -- Add service breakdown
    v_report_text := v_report_text || 'SERVICE BREAKDOWN FOR ' || p_month || ':' || CHR(10);
    v_report_text := v_report_text || '──────────────────────────────────────' || CHR(10);

    FOR rec IN (
        SELECT 
            service_type,
            COUNT(*) AS service_count,
            COUNT(DISTINCT child_id) AS children_served,
            COUNT(DISTINCT staff_id) AS staff_assigned
        FROM support_services
        WHERE service_date BETWEEN v_start_date AND v_end_date
        GROUP BY service_type
        ORDER BY service_count DESC
    ) LOOP
        v_report_text := v_report_text || 
            RPAD(rec.service_type, 25) || ': ' || 
            LPAD(rec.service_count, 4) || ' services | ' ||
            LPAD(rec.children_served, 3) || ' children | ' ||
            LPAD(rec.staff_assigned, 2) || ' staff' || CHR(10);
    END LOOP;

    v_report_text := v_report_text || CHR(10);

    -- Add top performing staff
    v_report_text := v_report_text || 'TOP 5 ACTIVE STAFF:' || CHR(10);
    v_report_text := v_report_text || '───────────────────' || CHR(10);

    FOR rec IN (
        SELECT 
            s.full_name,
            s.position,
            COUNT(ss.service_id) AS service_count
        FROM staff s
        LEFT JOIN support_services ss ON s.staff_id = ss.staff_id
            AND ss.service_date BETWEEN v_start_date AND v_end_date
        GROUP BY s.staff_id, s.full_name, s.position
        ORDER BY service_count DESC
        FETCH FIRST 5 ROWS ONLY
    ) LOOP
        v_report_text := v_report_text || 
            RPAD(rec.full_name, 25) || ' (' || 
            rec.position || '): ' || 
            rec.service_count || ' services' || CHR(10);
    END LOOP;

    -- Add summary line
    v_report_text := v_report_text || CHR(10);
    v_report_text := v_report_text || 'REPORT SUMMARY:' || CHR(10);
    v_report_text := v_report_text || '──────────────' || CHR(10);
    v_report_text := v_report_text || 'Report Period: ' || 
                     TO_CHAR(v_start_date, 'DD-MON-YYYY') || ' to ' || 
                     TO_CHAR(v_end_date, 'DD-MON-YYYY') || CHR(10);
    v_report_text := v_report_text || 'Days in Period: ' || 
                     (v_end_date - v_start_date + 1) || ' days' || CHR(10);
    v_report_text := v_report_text || 'Average Services per Day: ' || 
                     v_avg_services_per_day || CHR(10);

    -- Set output parameter
    p_report := v_report_text;

    DBMS_OUTPUT.PUT_LINE('Monthly report generated for ' || p_month);
    DBMS_OUTPUT.PUT_LINE('Report size: ' || LENGTH(v_report_text) || ' characters');

EXCEPTION
    WHEN OTHERS THEN
        p_report := 'Error generating report: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE('Error in generate_monthly_report: ' || SQLERRM);
        RAISE;
END generate_monthly_report;




--PROCEDURE 14


create or replace PROCEDURE generate_test_documentation IS
    v_doc CLOB;
    v_total_errors NUMBER;
    v_unique_errors NUMBER;
    v_recent_errors NUMBER;
BEGIN
    v_doc := 'CHILD WELFARE MANAGEMENT SYSTEM - TEST DOCUMENTATION' || CHR(10);
    v_doc := v_doc || '══════════════════════════════════════════════════════════' || CHR(10) || CHR(10);

    v_doc := v_doc || '1. TEST COVERAGE SUMMARY' || CHR(10);
    v_doc := v_doc || '──────────────────────' || CHR(10);
    v_doc := v_doc || '• Window Functions: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD()' || CHR(10);
    v_doc := v_doc || '• Packages: Complete package with specification and body' || CHR(10);
    v_doc := v_doc || '• Exception Handling: Custom exceptions, error logging, recovery' || CHR(10);
    v_doc := v_doc || '• Testing: Comprehensive test suite with edge cases' || CHR(10);
    v_doc := v_doc || '• Performance: Timing tests and optimization recommendations' || CHR(10) || CHR(10);

    v_doc := v_doc || '2. TEST CASES EXECUTED' || CHR(10);
    v_doc := v_doc || '─────────────────────' || CHR(10);

    -- Check if error_log table exists and has data
    BEGIN
        FOR rec IN (
            SELECT 
                procedure_name,
                COUNT(*) AS execution_count,
                MIN(error_date) AS first_run,
                MAX(error_date) AS last_run
            FROM error_log
            WHERE procedure_name LIKE '%TEST%'
            OR error_message LIKE '%Test%'
            OR UPPER(procedure_name) IN ('RUN_COMPREHENSIVE_TESTS', 'TEST_PERFORMANCE')
            GROUP BY procedure_name
            ORDER BY procedure_name
        ) LOOP
            v_doc := v_doc || '• ' || rec.procedure_name || ': ' || 
                    rec.execution_count || ' executions' || CHR(10);
        END LOOP;

        IF v_doc NOT LIKE '%executions%' THEN
            v_doc := v_doc || '• No test executions recorded yet' || CHR(10);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            v_doc := v_doc || '• Error log not available: ' || SQLERRM || CHR(10);
    END;

    v_doc := v_doc || CHR(10);

    v_doc := v_doc || '3. ERROR STATISTICS' || CHR(10);
    v_doc := v_doc || '──────────────────' || CHR(10);

    BEGIN
        SELECT COUNT(*) INTO v_total_errors FROM error_log;
        SELECT COUNT(DISTINCT error_message) INTO v_unique_errors FROM error_log;
        SELECT COUNT(*) INTO v_recent_errors 
        FROM error_log 
        WHERE error_date >= SYSDATE - 7;

        v_doc := v_doc || '• Total Errors: ' || v_total_errors || CHR(10);
        v_doc := v_doc || '• Unique Error Messages: ' || v_unique_errors || CHR(10);
        v_doc := v_doc || '• Errors in Last 7 Days: ' || v_recent_errors || CHR(10);
    EXCEPTION
        WHEN OTHERS THEN
            v_doc := v_doc || '• Error statistics not available' || CHR(10);
    END;

    v_doc := v_doc || CHR(10);

    v_doc := v_doc || '4. RECOMMENDATIONS' || CHR(10);
    v_doc := v_doc || '─────────────────' || CHR(10);
    v_doc := v_doc || '• Run comprehensive tests weekly' || CHR(10);
    v_doc := v_doc || '• Monitor error log daily' || CHR(10);
    v_doc := v_doc || '• Perform performance testing monthly' || CHR(10);
    v_doc := v_doc || '• Review and update test cases with each release' || CHR(10);

    -- Output documentation
    DBMS_OUTPUT.PUT_LINE('TEST DOCUMENTATION GENERATED');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');

    -- Display in chunks to avoid buffer overflow
    DECLARE
        v_chunk_size CONSTANT NUMBER := 2000;
        v_position NUMBER := 1;
        v_length NUMBER;
    BEGIN
        v_length := LENGTH(v_doc);

        WHILE v_position <= v_length LOOP
            DBMS_OUTPUT.PUT_LINE(SUBSTR(v_doc, v_position, v_chunk_size));
            v_position := v_position + v_chunk_size;
        END LOOP;
    END;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Documentation generation error: ' || SQLERRM);
END generate_test_documentation;




---PROCEDURE 15


create or replace PROCEDURE process_birthday_children(
    p_month IN NUMBER DEFAULT EXTRACT(MONTH FROM SYSDATE)
) IS
    -- Explicit cursor declaration
    CURSOR cur_birthday_children IS
        SELECT 
            c.child_id,
            c.full_name,
            c.date_of_birth,
            EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM c.date_of_birth) AS turning_age,
            s.section_name,
            c.disability_status,
            c.gender
        FROM children c
        JOIN sections s ON c.section_id = s.section_id
        WHERE EXTRACT(MONTH FROM c.date_of_birth) = p_month
        ORDER BY EXTRACT(DAY FROM c.date_of_birth);

    -- Record type for cursor
    TYPE birthday_rec IS RECORD (
        child_id children.child_id%TYPE,
        full_name children.full_name%TYPE,
        date_of_birth children.date_of_birth%TYPE,
        turning_age NUMBER,
        section_name sections.section_name%TYPE,
        disability_status children.disability_status%TYPE,
        gender children.gender%TYPE
    );

    v_child birthday_rec;
    v_birthday_count NUMBER := 0;
    v_services_created NUMBER := 0;
    v_sections_updated NUMBER := 0;
    v_errors NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('PROCESSING BIRTHDAYS FOR MONTH: ' || p_month);
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Starting at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Open the cursor
    OPEN cur_birthday_children;

    -- Process each record with explicit FETCH
    LOOP
        FETCH cur_birthday_children INTO v_child;
        EXIT WHEN cur_birthday_children%NOTFOUND;

        v_birthday_count := v_birthday_count + 1;

        BEGIN
            -- Display birthday information
            DBMS_OUTPUT.PUT_LINE(
                '🎂 Birthday: ' || v_child.full_name || 
                ' (ID: ' || v_child.child_id || 
                ') turns ' || v_child.turning_age || 
                ' on ' || TO_CHAR(v_child.date_of_birth, 'DD-MON')
            );

            -- Create birthday service for children under 12
            IF v_child.turning_age < 12 THEN
                INSERT INTO support_services (
                    service_type, description, child_id, 
                    staff_id, service_date
                ) VALUES (
                    'Recreational Activities',
                    'Birthday celebration for ' || v_child.full_name || 
                    ' turning ' || v_child.turning_age,
                    v_child.child_id,
                    NULL, -- To be assigned by coordinator
                    SYSDATE
                );
                v_services_created := v_services_created + 1;
                DBMS_OUTPUT.PUT_LINE('   ✓ Birthday service created');
            END IF;

            -- Update section if age triggers change
            IF v_child.turning_age = 2 OR v_child.turning_age = 5 OR 
               v_child.turning_age = 12 OR v_child.turning_age = 13 THEN

                DECLARE
                    v_new_section_name VARCHAR2(50);
                BEGIN
                    -- Determine new section based on age and gender
                    IF v_child.turning_age = 2 THEN
                        v_new_section_name := 'Toddlers (2-4 years)';
                    ELSIF v_child.turning_age = 5 THEN
                        v_new_section_name := 'Kindergarten (4-6 years)';
                    ELSIF v_child.turning_age = 12 THEN
                        IF v_child.gender = 'Female' THEN
                            v_new_section_name := 'Adolescent Girls (13-18 years)';
                        ELSE
                            v_new_section_name := 'Adolescent Boys (13-18 years)';
                        END IF;
                    END IF;

                    -- Update section if different from current
                    IF v_new_section_name != v_child.section_name THEN
                        UPDATE children
                        SET section_id = (
                            SELECT section_id 
                            FROM sections 
                            WHERE section_name = v_new_section_name
                        )
                        WHERE child_id = v_child.child_id;

                        v_sections_updated := v_sections_updated + 1;
                        DBMS_OUTPUT.PUT_LINE('   ✓ Section updated: ' || 
                                           v_child.section_name || ' → ' || v_new_section_name);
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('   ✗ Error updating section: ' || SQLERRM);
                        v_errors := v_errors + 1;
                END;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('   ✗ Error processing child ' || v_child.child_id || 
                                   ': ' || SQLERRM);
                v_errors := v_errors + 1;
        END;

    END LOOP;

    -- Close the cursor
    CLOSE cur_birthday_children;

    COMMIT;

    -- Display summary
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PROCESSING COMPLETE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════');
    DBMS_OUTPUT.PUT_LINE('Children processed: ' || v_birthday_count);
    DBMS_OUTPUT.PUT_LINE('Services created: ' || v_services_created);
    DBMS_OUTPUT.PUT_LINE('Sections updated: ' || v_sections_updated);
    DBMS_OUTPUT.PUT_LINE('Errors encountered: ' || v_errors);
    DBMS_OUTPUT.PUT_LINE('Completed at: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));

EXCEPTION
    WHEN OTHERS THEN
        -- Ensure cursor is closed if error occurs
        IF cur_birthday_children%ISOPEN THEN
            CLOSE cur_birthday_children;
        END IF;
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Fatal error in process_birthday_children: ' || SQLERRM);
        RAISE;
END process_birthday_children;




--PROCUDURE 16


create or replace PROCEDURE register_child(
    p_full_name IN VARCHAR2,
    p_dob IN DATE,
    p_gender IN VARCHAR2,
    p_disability IN VARCHAR2,
    p_section_name IN VARCHAR2 DEFAULT NULL,
    p_child_id OUT NUMBER
) IS
    v_section_id NUMBER;
    v_age_months NUMBER;
    v_calculated_section_name VARCHAR2(50);
BEGIN
    -- Validate input data
    IF p_full_name IS NULL OR LENGTH(TRIM(p_full_name)) < 2 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Full name must be at least 2 characters');
    END IF;

    IF p_dob IS NULL OR p_dob > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20002, 'Date of birth cannot be in the future');
    END IF;

    IF p_gender NOT IN ('Male', 'Female') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Gender must be Male or Female');
    END IF;

    IF p_disability NOT IN ('Yes', 'No') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Disability status must be Yes or No');
    END IF;

    -- Calculate age in months
    v_age_months := MONTHS_BETWEEN(SYSDATE, p_dob);

    IF v_age_months < 0 OR v_age_months > 216 THEN -- 0-18 years
        RAISE_APPLICATION_ERROR(-20005, 'Age must be between 0-18 years');
    END IF;

    -- Determine section if not provided
    IF p_section_name IS NULL THEN
        v_calculated_section_name := CASE
            WHEN v_age_months <= 24 THEN 'Infants (0-2 years)'
            WHEN v_age_months <= 48 THEN 'Toddlers (2-4 years)'
            WHEN v_age_months <= 72 THEN 'Kindergarten (4-6 years)'
            WHEN v_age_months <= 108 THEN 'Primary 1-3 (6-9 years)'
            WHEN v_age_months <= 144 THEN 'Primary 4-6 (9-12 years)'
            WHEN p_gender = 'Female' THEN 'Adolescent Girls (13-18 years)'
            ELSE 'Adolescent Boys (13-18 years)'
        END;

        -- Override for disabled children
        IF p_disability = 'Yes' THEN
            v_calculated_section_name := 'Special Needs Unit';
        END IF;
    ELSE
        v_calculated_section_name := p_section_name;
    END IF;

    -- Get section_id
    BEGIN
        SELECT section_id INTO v_section_id
        FROM sections
        WHERE UPPER(section_name) = UPPER(v_calculated_section_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Invalid section name: ' || v_calculated_section_name);
    END;

    -- Insert child record
    INSERT INTO children (
        full_name, date_of_birth, gender, 
        disability_status, section_id
    ) VALUES (
        p_full_name, p_dob, p_gender, 
        p_disability, v_section_id
    ) RETURNING child_id INTO p_child_id;

    -- Add default education record for children 3+ years
    IF v_age_months >= 36 THEN
        INSERT INTO education (
            child_id, school_name, grade_level, performance_notes
        ) VALUES (
            p_child_id, 'Not Enrolled', 
            CASE 
                WHEN v_age_months <= 48 THEN 'Nursery'
                WHEN v_age_months <= 72 THEN 'KG1'
                ELSE 'Not Assigned'
            END,
            'New registration - education status pending'
        );
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Child registered successfully. ID: ' || p_child_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in register_child: ' || SQLERRM);
        RAISE;
END register_child;




--PROCEDURE 17


create or replace PROCEDURE run_comprehensive_tests IS
    v_test_count NUMBER := 0;
    v_pass_count NUMBER := 0;
    v_fail_count NUMBER := 0;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;

    PROCEDURE record_test_result(
        p_test_name VARCHAR2,
        p_result VARCHAR2,
        p_message VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        v_test_count := v_test_count + 1;

        IF p_result = 'PASS' THEN
            v_pass_count := v_pass_count + 1;
            DBMS_OUTPUT.PUT_LINE('✓ PASS: ' || p_test_name);
        ELSE
            v_fail_count := v_fail_count + 1;
            DBMS_OUTPUT.PUT_LINE('✗ FAIL: ' || p_test_name || 
                               CASE WHEN p_message IS NOT NULL THEN ' - ' || p_message ELSE '' END);
        END IF;
    END record_test_result;

BEGIN
    v_start_time := SYSTIMESTAMP;

    DBMS_OUTPUT.PUT_LINE('COMPREHENSIVE TEST SUITE');
    DBMS_OUTPUT.PUT_LINE('════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Start time: ' || TO_CHAR(v_start_time, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('');

    -- Test 1: Window Functions
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST GROUP 1: WINDOW FUNCTIONS');
        DBMS_OUTPUT.PUT_LINE('──────────────────────────────');

        child_welfare_management_pkg.generate_ranking_report;
        record_test_result('Window Functions - Ranking', 'PASS');

        child_welfare_management_pkg.analyze_trends_with_lag_lead;
        record_test_result('Window Functions - Trends', 'PASS');

        child_welfare_management_pkg.calculate_running_aggregates;
        record_test_result('Window Functions - Aggregates', 'PASS');

        DBMS_OUTPUT.PUT_LINE('');
    EXCEPTION
        WHEN OTHERS THEN
            record_test_result('Window Functions', 'FAIL', SQLERRM);
    END;

    -- Test 2: Child Registration
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST GROUP 2: CHILD MANAGEMENT');
        DBMS_OUTPUT.PUT_LINE('──────────────────────────────');

        DECLARE
            v_child_id NUMBER;
            v_section_name VARCHAR2(50);
        BEGIN
            -- Test valid registration
            child_welfare_management_pkg.register_new_child(
                p_full_name => 'Test Child ' || TO_CHAR(SYSDATE, 'HH24MISS'),
                p_dob => TO_DATE('2020-01-15', 'YYYY-MM-DD'),
                p_gender => 'Male',
                p_disability => 'No',
                p_section_name => NULL,
                p_child_id => v_child_id
            );
            record_test_result('Child Registration - Valid', 'PASS');

            -- Test child summary function
            DECLARE
                v_summary VARCHAR2(4000);
            BEGIN
                v_summary := child_welfare_management_pkg.generate_child_summary(v_child_id);
                IF v_summary LIKE '%CHILD SUMMARY%' OR v_summary LIKE '%CHILD ID%' THEN
                    record_test_result('Child Summary Function', 'PASS');
                ELSE
                    record_test_result('Child Summary Function', 'FAIL', 'Invalid summary format: ' || SUBSTR(v_summary, 1, 50));
                END IF;
            END;

            -- Test service recording
            DECLARE
                v_service_id NUMBER;
            BEGIN
                child_welfare_management_pkg.record_service(
                    p_child_id => v_child_id,
                    p_service_type => 'Medical Checkup',
                    p_description => 'Test service recording',
                    p_staff_id => NULL,
                    p_service_date => SYSDATE,
                    p_service_id => v_service_id
                );
                record_test_result('Service Recording', 'PASS');
            END;

        EXCEPTION
            WHEN OTHERS THEN
                record_test_result('Child Management Tests', 'FAIL', SQLERRM);
        END;

        -- Test invalid data handling
        BEGIN
            DECLARE
                v_invalid_id NUMBER;
            BEGIN
                child_welfare_management_pkg.register_new_child(
                    p_full_name => 'A', -- Too short
                    p_dob => SYSDATE + 1, -- Future date
                    p_gender => 'Invalid',
                    p_disability => 'No',
                    p_section_name => NULL,
                    p_child_id => v_invalid_id
                );
                record_test_result('Invalid Data Validation', 'FAIL', 'Should have raised exception');
            EXCEPTION
                WHEN child_welfare_management_pkg.e_invalid_data THEN
                    record_test_result('Invalid Data Validation', 'PASS');
                WHEN OTHERS THEN
                    record_test_result('Invalid Data Validation', 'FAIL', 'Wrong exception: ' || SQLERRM);
            END;
        END;

        DBMS_OUTPUT.PUT_LINE('');
    EXCEPTION
        WHEN OTHERS THEN
            record_test_result('Child Management Tests', 'FAIL', SQLERRM);
    END;

    -- Test 3: Analytical Functions
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST GROUP 3: ANALYTICAL FUNCTIONS');
        DBMS_OUTPUT.PUT_LINE('─────────────────────────────────');

        DECLARE
            v_test_child_id NUMBER;
            v_rank NUMBER;
        BEGIN
            -- Get a real child ID for testing
            BEGIN
                SELECT child_id INTO v_test_child_id
                FROM children
                WHERE ROWNUM = 1;

                -- Test ranking function
                v_rank := child_welfare_management_pkg.get_child_rank(v_test_child_id);
                IF v_rank >= 0 THEN -- Returns 0 if no data
                    record_test_result('Get Child Rank', 'PASS');
                ELSE
                    record_test_result('Get Child Rank', 'FAIL', 'Invalid rank: ' || v_rank);
                END IF;

                -- Test service gap calculation (FIXED: Declare v_gap here)
                DECLARE
                    v_gap NUMBER;
                BEGIN
                    v_gap := child_welfare_management_pkg.calculate_service_gap(v_test_child_id);
                    record_test_result('Calculate Service Gap', 'PASS');
                END;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- If no children, create a test child
                    DECLARE
                        v_new_child_id NUMBER;
                        v_gap NUMBER; -- FIXED: Added declaration here
                    BEGIN
                        child_welfare_management_pkg.register_new_child(
                            p_full_name => 'Test Child for Analysis',
                            p_dob => TO_DATE('2018-05-10', 'YYYY-MM-DD'),
                            p_gender => 'Female',
                            p_disability => 'No',
                            p_section_name => NULL,
                            p_child_id => v_new_child_id
                        );

                        v_rank := child_welfare_management_pkg.get_child_rank(v_new_child_id);
                        record_test_result('Get Child Rank', 'PASS');

                        -- FIXED: Now v_gap is declared
                        v_gap := child_welfare_management_pkg.calculate_service_gap(v_new_child_id);
                        record_test_result('Calculate Service Gap', 'PASS');
                    END;
            END;

        EXCEPTION
            WHEN OTHERS THEN
                record_test_result('Analytical Functions', 'FAIL', SQLERRM);
        END;

        DBMS_OUTPUT.PUT_LINE('');
    END;

    -- Test 4: Error Handling
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST GROUP 4: ERROR HANDLING');
        DBMS_OUTPUT.PUT_LINE('────────────────────────────');

        -- Test non-existent child
        BEGIN
            DECLARE
                v_dummy NUMBER;
            BEGIN
                child_welfare_management_pkg.update_child_status(
                    p_child_id => -999,
                    p_new_disability_status => 'Yes'
                );
                record_test_result('Non-existent Child', 'FAIL', 'Should have raised exception');
            EXCEPTION
                WHEN child_welfare_management_pkg.e_child_not_found THEN
                    record_test_result('Non-existent Child', 'PASS');
                WHEN OTHERS THEN
                    record_test_result('Non-existent Child', 'FAIL', 'Wrong exception: ' || SQLERRM);
            END;
        END;

        -- Test error logging
        BEGIN
            child_welfare_management_pkg.log_error(
                p_procedure_name => 'test_procedure',
                p_error_code => -99999,
                p_error_message => 'Test error message',
                p_child_id => NULL
            );
            record_test_result('Error Logging', 'PASS');
        EXCEPTION
            WHEN OTHERS THEN
                record_test_result('Error Logging', 'FAIL', SQLERRM);
        END;

        -- Test cleanup function
        BEGIN
            child_welfare_management_pkg.cleanup_error_log(999); -- Keep all records
            record_test_result('Error Log Cleanup', 'PASS');
        EXCEPTION
            WHEN OTHERS THEN
                record_test_result('Error Log Cleanup', 'FAIL', SQLERRM);
        END;

        DBMS_OUTPUT.PUT_LINE('');
    END;

    -- Test 5: Edge Cases
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST GROUP 5: EDGE CASES');
        DBMS_OUTPUT.PUT_LINE('───────────────────────');

        -- Test very young child (newborn)
        BEGIN
            DECLARE
                v_newborn_id NUMBER;
            BEGIN
                child_welfare_management_pkg.register_new_child(
                    p_full_name => 'Newborn Test',
                    p_dob => SYSDATE - 7, -- 7 days old
                    p_gender => 'Female',
                    p_disability => 'No',
                    p_section_name => NULL,
                    p_child_id => v_newborn_id
                );
                record_test_result('Newborn Registration', 'PASS');
            EXCEPTION
                WHEN OTHERS THEN
                    record_test_result('Newborn Registration', 'FAIL', SQLERRM);
            END;
        END;

        -- Test disabled child auto-assignment
        BEGIN
            DECLARE
                v_disabled_child_id NUMBER;
            BEGIN
                child_welfare_management_pkg.register_new_child(
                    p_full_name => 'Disabled Test Child',
                    p_dob => TO_DATE('2018-06-10', 'YYYY-MM-DD'),
                    p_gender => 'Male',
                    p_disability => 'Yes',
                    p_section_name => NULL,
                    p_child_id => v_disabled_child_id
                );

                -- Verify auto-assignment
                DECLARE
                    v_section_name VARCHAR2(50);
                BEGIN
                    SELECT s.section_name INTO v_section_name
                    FROM children c
                    JOIN sections s ON c.section_id = s.section_id
                    WHERE c.child_id = v_disabled_child_id;

                    IF UPPER(v_section_name) LIKE '%SPECIAL%NEEDS%' THEN
                        record_test_result('Disabled Child Auto-assignment', 'PASS');
                    ELSE
                        record_test_result('Disabled Child Auto-assignment', 'FAIL', 
                                         'Assigned to: ' || v_section_name);
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        record_test_result('Disabled Child Auto-assignment', 'FAIL', 'Child not found');
                END;
            EXCEPTION
                WHEN OTHERS THEN
                    record_test_result('Disabled Child Auto-assignment', 'FAIL', SQLERRM);
            END;
        END;

        DBMS_OUTPUT.PUT_LINE('');
    END;

    v_end_time := SYSTIMESTAMP;

    -- Final Summary
    DBMS_OUTPUT.PUT_LINE('TEST SUMMARY');
    DBMS_OUTPUT.PUT_LINE('════════════');
    DBMS_OUTPUT.PUT_LINE('Total Tests: ' || v_test_count);
    DBMS_OUTPUT.PUT_LINE('Passed: ' || v_pass_count);
    DBMS_OUTPUT.PUT_LINE('Failed: ' || v_fail_count);

    IF v_test_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Success Rate: ' || 
                            ROUND(v_pass_count * 100.0 / v_test_count, 2) || '%');
    END IF;

    DBMS_OUTPUT.PUT_LINE('Total Time: ' || 
                        ROUND(EXTRACT(SECOND FROM (v_end_time - v_start_time)), 3) || ' seconds');
    DBMS_OUTPUT.PUT_LINE('');

    IF v_fail_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ ALL TESTS PASSED!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  ' || v_fail_count || ' TESTS FAILED. Review errors above.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test suite error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Tests completed before error: ' || v_test_count);
END run_comprehensive_tests;




--PROCEDURE 18



create or replace PROCEDURE simple_explicit_cursor IS
    -- Explicit cursor declaration
    CURSOR cur_children IS
        SELECT child_id, full_name, date_of_birth
        FROM children
        WHERE ROWNUM <= 5
        ORDER BY child_id;

    -- Variables to hold cursor data
    v_child_id children.child_id%TYPE;
    v_full_name children.full_name%TYPE;
    v_dob children.date_of_birth%TYPE;

    v_counter NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('SIMPLE EXPLICIT CURSOR DEMONSTRATION');
    DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Demonstrating: OPEN → FETCH → CLOSE');
    DBMS_OUTPUT.PUT_LINE('');

    -- Step 1: OPEN the cursor
    OPEN cur_children;
    DBMS_OUTPUT.PUT_LINE('Cursor opened successfully');

    -- Step 2: FETCH records in a loop
    LOOP
        FETCH cur_children INTO v_child_id, v_full_name, v_dob;
        EXIT WHEN cur_children%NOTFOUND;  -- Exit when no more rows

        v_counter := v_counter + 1;
        DBMS_OUTPUT.PUT_LINE('Record ' || v_counter || ':');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || v_child_id);
        DBMS_OUTPUT.PUT_LINE('  Name: ' || v_full_name);
        DBMS_OUTPUT.PUT_LINE('  Date of Birth: ' || TO_CHAR(v_dob, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    -- Step 3: CLOSE the cursor
    CLOSE cur_children;
    DBMS_OUTPUT.PUT_LINE('Cursor closed successfully');

    -- Display cursor attributes
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('CURSOR ATTRIBUTES:');
    DBMS_OUTPUT.PUT_LINE('  %ROWCOUNT: ' || cur_children%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('  %ISOPEN: ' || 
        CASE WHEN cur_children%ISOPEN THEN 'TRUE' ELSE 'FALSE' END);
    DBMS_OUTPUT.PUT_LINE('  Total records fetched: ' || v_counter);

EXCEPTION
    WHEN OTHERS THEN
        -- Ensure cursor is closed if error occurs
        IF cur_children%ISOPEN THEN
            CLOSE cur_children;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END simple_explicit_cursor;




--PROCEDURE 19

create or replace PROCEDURE test_performance IS
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_iterations NUMBER := 100;
    v_total_time NUMBER := 0;

    TYPE timing_rec IS RECORD (
        test_name VARCHAR2(100),
        iterations NUMBER,
        total_time NUMBER,
        avg_time NUMBER
    );

    TYPE timing_tab IS TABLE OF timing_rec;
    v_results timing_tab := timing_tab();

    v_child_id NUMBER;
    v_service_id NUMBER;
    v_summary_rec child_welfare_management_pkg.child_summary_rec;

BEGIN
    DBMS_OUTPUT.PUT_LINE('PERFORMANCE TESTING');
    DBMS_OUTPUT.PUT_LINE('═══════════════════');
    DBMS_OUTPUT.PUT_LINE('');

    -- Test 1: Individual service recording
    v_start_time := SYSTIMESTAMP;

    FOR i IN 1..v_iterations LOOP
        BEGIN
            -- Get a child ID
            SELECT child_id INTO v_child_id
            FROM children
            WHERE ROWNUM = 1;

            -- Record service (using existing function)
            child_welfare_management_pkg.record_service(
                p_child_id => v_child_id,
                p_service_type => 'Performance Test',
                p_description => 'Iteration ' || i,
                p_staff_id => NULL,
                p_service_date => SYSDATE,
                p_service_id => v_service_id
            );
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Continue testing
        END;
    END LOOP;

    v_end_time := SYSTIMESTAMP;
    v_total_time := EXTRACT(SECOND FROM (v_end_time - v_start_time));

    v_results.EXTEND;
    v_results(v_results.LAST) := timing_rec(
        'Individual Service Recording',
        v_iterations,
        v_total_time,
        v_total_time / v_iterations
    );

    -- Test 2: Child summary generation (simpler bulk test)
    v_start_time := SYSTIMESTAMP;

    FOR i IN 1..v_iterations LOOP
        BEGIN
            -- Get a child ID
            SELECT child_id INTO v_child_id
            FROM children
            WHERE ROWNUM = 1;

            -- Call child summary function
            DECLARE
                v_summary VARCHAR2(4000);
            BEGIN
                v_summary := child_welfare_management_pkg.generate_child_summary(v_child_id);
            END;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END LOOP;

    v_end_time := SYSTIMESTAMP;
    v_total_time := EXTRACT(SECOND FROM (v_end_time - v_start_time));

    v_results.EXTEND;
    v_results(v_results.LAST) := timing_rec(
        'Child Summary Generation',
        v_iterations,
        v_total_time,
        v_total_time / v_iterations
    );

    -- Test 3: Ranking function performance
    v_start_time := SYSTIMESTAMP;

    FOR i IN 1..v_iterations LOOP
        BEGIN
            SELECT child_id INTO v_child_id
            FROM children
            WHERE MOD(ROWNUM, 10) = 0 AND ROWNUM = 1;

            v_child_id := child_welfare_management_pkg.get_child_rank(v_child_id);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END LOOP;

    v_end_time := SYSTIMESTAMP;
    v_total_time := EXTRACT(SECOND FROM (v_end_time - v_start_time));

    v_results.EXTEND;
    v_results(v_results.LAST) := timing_rec(
        'Child Ranking Function',
        v_iterations,
        v_total_time,
        v_total_time / v_iterations
    );

    -- Display results
    DBMS_OUTPUT.PUT_LINE('PERFORMANCE RESULTS');
    DBMS_OUTPUT.PUT_LINE('═══════════════════');
    DBMS_OUTPUT.PUT_LINE('');

    FOR i IN 1..v_results.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_results(i).test_name || ':');
        DBMS_OUTPUT.PUT_LINE('  Iterations: ' || v_results(i).iterations);
        DBMS_OUTPUT.PUT_LINE('  Total Time: ' || ROUND(v_results(i).total_time, 3) || ' seconds');
        DBMS_OUTPUT.PUT_LINE('  Average Time: ' || ROUND(v_results(i).avg_time * 1000, 3) || ' ms');
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    -- Performance recommendations
    DBMS_OUTPUT.PUT_LINE('PERFORMANCE RECOMMENDATIONS');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════');
    DBMS_OUTPUT.PUT_LINE('1. Use BULK COLLECT for reading multiple rows');
    DBMS_OUTPUT.PUT_LINE('2. Use FORALL for writing multiple rows');
    DBMS_OUTPUT.PUT_LINE('3. Create indexes on frequently queried columns');
    DBMS_OUTPUT.PUT_LINE('4. Use window functions instead of correlated subqueries');
    DBMS_OUTPUT.PUT_LINE('5. Implement proper error handling to avoid rollbacks');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Performance test error: ' || SQLERRM);
END test_performance;



--PROCEDURE 20

create or replace PROCEDURE update_child_section(
    p_child_id IN NUMBER,
    p_new_section_name IN VARCHAR2
) IS
    v_section_id NUMBER;
    v_current_section VARCHAR2(50);
    v_age_months NUMBER;
    v_gender VARCHAR2(10);
    v_disability VARCHAR2(3);
BEGIN
    -- Check if child exists
    BEGIN
        SELECT c.section_id, s.section_name, 
               MONTHS_BETWEEN(SYSDATE, c.date_of_birth),
               c.gender, c.disability_status
        INTO v_section_id, v_current_section, v_age_months,
             v_gender, v_disability
        FROM children c
        JOIN sections s ON c.section_id = s.section_id
        WHERE c.child_id = p_child_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007, 'Child not found: ' || p_child_id);
    END;

    -- Get new section_id
    BEGIN
        SELECT section_id INTO v_section_id
        FROM sections
        WHERE UPPER(section_name) = UPPER(p_new_section_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20008, 'Invalid section name: ' || p_new_section_name);
    END;

    -- Validate section assignment for disabled children
    IF v_disability = 'Yes' AND UPPER(p_new_section_name) != 'SPECIAL NEEDS UNIT' THEN
        RAISE_APPLICATION_ERROR(-20009, 
            'Children with disabilities must be in Special Needs Unit');
    END IF;

    -- Validate age-appropriate section
    IF UPPER(p_new_section_name) LIKE '%INFANTS%' AND v_age_months > 24 THEN
        RAISE_APPLICATION_ERROR(-20010, 
            'Child too old for Infants section');
    ELSIF UPPER(p_new_section_name) LIKE '%ADOLESCENT%' AND v_age_months < 156 THEN -- 13 years
        RAISE_APPLICATION_ERROR(-20011, 
            'Child too young for Adolescent section');
    END IF;

    -- Update child section
    UPDATE children
    SET section_id = v_section_id
    WHERE child_id = p_child_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Child ' || p_child_id || 
                       ' moved from ' || v_current_section || 
                       ' to ' || p_new_section_name);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in update_child_section: ' || SQLERRM);
        RAISE;
END update_child_section;






