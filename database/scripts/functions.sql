create or replace FUNCTION calculate_child_age(
    p_child_id IN NUMBER
) RETURN NUMBER IS
    v_dob DATE;
    v_age_years NUMBER;
BEGIN
    -- Get child's date of birth
    SELECT date_of_birth INTO v_dob
    FROM children
    WHERE child_id = p_child_id;

    -- Calculate age in years with 2 decimal precision
    v_age_years := MONTHS_BETWEEN(SYSDATE, v_dob) / 12;

    -- Return rounded to 2 decimal places
    RETURN ROUND(v_age_years, 2);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'Child not found with ID: ' || p_child_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20031, 'Error calculating age: ' || SQLERRM);
END calculate_child_age;








--FUNCTION 2


create or replace FUNCTION count_services_by_type(
    p_service_type IN VARCHAR2,
    p_start_date IN DATE DEFAULT NULL,
    p_end_date IN DATE DEFAULT NULL
) RETURN NUMBER IS
    v_count NUMBER;
    v_where_clause VARCHAR2(500);
BEGIN
    -- Build dynamic WHERE clause
    v_where_clause := 'WHERE service_type = :service_type';

    IF p_start_date IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND service_date >= :start_date';
    END IF;

    IF p_end_date IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND service_date <= :end_date';
    END IF;

    -- Execute dynamic SQL
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        EXECUTE IMMEDIATE 
            'SELECT COUNT(*) FROM support_services ' || v_where_clause
        INTO v_count
        USING p_service_type, p_start_date, p_end_date;
    ELSIF p_start_date IS NOT NULL THEN
        EXECUTE IMMEDIATE 
            'SELECT COUNT(*) FROM support_services ' || v_where_clause
        INTO v_count
        USING p_service_type, p_start_date;
    ELSIF p_end_date IS NOT NULL THEN
        EXECUTE IMMEDIATE 
            'SELECT COUNT(*) FROM support_services ' || v_where_clause
        INTO v_count
        USING p_service_type, p_end_date;
    ELSE
        EXECUTE IMMEDIATE 
            'SELECT COUNT(*) FROM support_services ' || v_where_clause
        INTO v_count
        USING p_service_type;
    END IF;

    RETURN v_count;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20034, 'Error counting services: ' || SQLERRM);
END count_services_by_type;




--FUNCTION 3


create or replace FUNCTION get_child_summary(
    p_child_id IN NUMBER
) RETURN VARCHAR2 IS
    v_child_name children.full_name%TYPE;
    v_dob children.date_of_birth%TYPE;
    v_gender children.gender%TYPE;
    v_disability children.disability_status%TYPE;
    v_section_name sections.section_name%TYPE;
    v_age_years NUMBER;
    v_vulnerability_score NUMBER;
    v_education_count NUMBER;
    v_service_count NUMBER;
    v_last_service_date DATE;
    v_summary VARCHAR2(1000);
BEGIN
    -- Get all child details in one query
    SELECT 
        c.full_name,
        c.date_of_birth,
        c.gender,
        c.disability_status,
        s.section_name,
        calculate_child_age(c.child_id),
        get_vulnerability_score(c.child_id),
        COUNT(DISTINCT e.education_id),
        COUNT(DISTINCT ss.service_id),
        MAX(ss.service_date)
    INTO 
        v_child_name,
        v_dob,
        v_gender,
        v_disability,
        v_section_name,
        v_age_years,
        v_vulnerability_score,
        v_education_count,
        v_service_count,
        v_last_service_date
    FROM children c
    JOIN sections s ON c.section_id = s.section_id
    LEFT JOIN education e ON c.child_id = e.child_id
    LEFT JOIN support_services ss ON c.child_id = ss.child_id
    WHERE c.child_id = p_child_id
    GROUP BY 
        c.full_name, c.date_of_birth, c.gender, 
        c.disability_status, s.section_name, c.child_id;

    -- Build comprehensive summary
    v_summary := 'CHILD SUMMARY REPORT' || CHR(10);
    v_summary := v_summary || '═══════════════════' || CHR(10);
    v_summary := v_summary || 'ID: ' || p_child_id || CHR(10);
    v_summary := v_summary || 'Name: ' || v_child_name || CHR(10);
    v_summary := v_summary || 'Date of Birth: ' || TO_CHAR(v_dob, 'DD-MON-YYYY') || 
                ' (Age: ' || v_age_years || ' years)' || CHR(10);
    v_summary := v_summary || 'Gender: ' || v_gender || CHR(10);
    v_summary := v_summary || 'Disability Status: ' || v_disability || CHR(10);
    v_summary := v_summary || 'Section: ' || v_section_name || CHR(10);
    v_summary := v_summary || 'Vulnerability Score: ' || v_vulnerability_score || '/7' || CHR(10);
    v_summary := v_summary || 'Education Records: ' || v_education_count || CHR(10);
    v_summary := v_summary || 'Services Received: ' || v_service_count || CHR(10);

    IF v_last_service_date IS NOT NULL THEN
        v_summary := v_summary || 'Last Service: ' || 
                    TO_CHAR(v_last_service_date, 'DD-MON-YYYY') || 
                    ' (' || ROUND(MONTHS_BETWEEN(SYSDATE, v_last_service_date), 1) || 
                    ' months ago)' || CHR(10);
    ELSE
        v_summary := v_summary || 'Last Service: Never' || CHR(10);
    END IF;

    -- Add priority indicator
    IF v_vulnerability_score >= 5 THEN
        v_summary := v_summary || 'PRIORITY: HIGH NEEDS ATTENTION' || CHR(10);
    ELSIF v_vulnerability_score >= 3 THEN
        v_summary := v_summary || 'Priority: Medium' || CHR(10);
    ELSE
        v_summary := v_summary || 'Priority: Low' || CHR(10);
    END IF;

    RETURN v_summary;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Child not found with ID ' || p_child_id;
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END get_child_summary;




---FUNCTION 4


create or replace FUNCTION get_restriction_message RETURN VARCHAR2 IS
    v_day_of_week VARCHAR2(3);
    v_is_holiday NUMBER;
    v_holiday_name VARCHAR2(100);
    v_next_month_start DATE;
    v_next_month_end DATE;
BEGIN
    v_day_of_week := TO_CHAR(SYSDATE, 'DY');

    -- Check weekday
    IF v_day_of_week IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RETURN 'DML operations are not allowed on weekdays (Monday-Friday). Today is ' || 
               INITCAP(v_day_of_week) || '.';
    END IF;

    -- Check if today is a holiday in the upcoming month
    v_next_month_start := TRUNC(ADD_MONTHS(SYSDATE, 1), 'MM');
    v_next_month_end := LAST_DAY(v_next_month_start);

    BEGIN
        SELECT holiday_name INTO v_holiday_name
        FROM holidays
        WHERE holiday_date = TRUNC(SYSDATE)
        AND holiday_date BETWEEN v_next_month_start AND v_next_month_end
        AND ROWNUM = 1;

        RETURN 'DML operations are not allowed on upcoming month holidays. Today is ' || 
               v_holiday_name || ' (falls in next month: ' || 
               TO_CHAR(v_next_month_start, 'Month YYYY') || ').';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    RETURN 'DML operations are allowed (weekend and not an upcoming month holiday).';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Unable to determine restriction status: ' || SQLERRM;
END get_restriction_message;





--FUNCTION 5


create or replace FUNCTION get_vulnerability_score(
    p_child_id IN NUMBER
) RETURN NUMBER IS
    v_disability_status VARCHAR2(3);
    v_age_months NUMBER;
    v_service_count NUMBER;
    v_last_service_date DATE;
    v_education_count NUMBER;
    v_score NUMBER := 0;
BEGIN
    -- Get child details
    SELECT 
        c.disability_status,
        MONTHS_BETWEEN(SYSDATE, c.date_of_birth),
        COUNT(DISTINCT ss.service_id),
        MAX(ss.service_date),
        COUNT(DISTINCT e.education_id)
    INTO 
        v_disability_status,
        v_age_months,
        v_service_count,
        v_last_service_date,
        v_education_count
    FROM children c
    LEFT JOIN support_services ss ON c.child_id = ss.child_id
    LEFT JOIN education e ON c.child_id = e.child_id
    WHERE c.child_id = p_child_id
    GROUP BY c.disability_status, c.date_of_birth;

    -- 1. Disability weight: 3 points if disabled
    IF v_disability_status = 'Yes' THEN
        v_score := v_score + 3;
    END IF;

    -- 2. Age weight: younger = more vulnerable
    IF v_age_months < 24 THEN -- Under 2 years
        v_score := v_score + 2;
    ELSIF v_age_months < 60 THEN -- 2-5 years
        v_score := v_score + 1;
    END IF;

    -- 3. Service gap weight
    IF v_service_count = 0 THEN
        v_score := v_score + 2;
    ELSIF v_last_service_date IS NULL OR 
          MONTHS_BETWEEN(SYSDATE, v_last_service_date) > 3 THEN
        v_score := v_score + 1;
    END IF;

    -- 4. Education gap weight
    IF v_education_count = 0 AND v_age_months >= 36 THEN
        v_score := v_score + 1;
    END IF;

    -- Return score (0-7 scale)
    RETURN v_score;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'Child not found with ID: ' || p_child_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20033, 'Error calculating vulnerability: ' || SQLERRM);
END get_vulnerability_score;





---FUNCTION 6


create or replace FUNCTION is_child_eligible_for_service(
    p_child_id IN NUMBER,
    p_service_type IN VARCHAR2
) RETURN VARCHAR2 IS
    v_age_years NUMBER;
    v_disability_status VARCHAR2(3);
    v_gender VARCHAR2(10);
    v_recent_services NUMBER;
    v_child_name VARCHAR2(100);
BEGIN
    -- Get child details
    SELECT 
        full_name,
        calculate_child_age(p_child_id),
        disability_status,
        gender
    INTO 
        v_child_name,
        v_age_years,
        v_disability_status,
        v_gender
    FROM children
    WHERE child_id = p_child_id;

    -- Check recent services of same type
    SELECT COUNT(*)
    INTO v_recent_services
    FROM support_services
    WHERE child_id = p_child_id
    AND service_type = p_service_type
    AND service_date >= ADD_MONTHS(SYSDATE, -3);

    -- Service-specific eligibility rules
    CASE p_service_type
        WHEN 'Vocational Training' THEN
            IF v_age_years < 14 THEN
                RETURN 'No - Minimum age is 14 years';
            END IF;

        WHEN 'Family Reunification' THEN
            IF v_age_years > 16 THEN
                RETURN 'No - Maximum age is 16 years';
            END IF;

        WHEN 'Medical Checkup' THEN
            IF v_recent_services >= 2 THEN
                RETURN 'Limited - Maximum 2 checkups per 3 months';
            END IF;

        WHEN 'Psychological Counseling' THEN
            IF v_disability_status = 'Yes' THEN
                RETURN 'Priority - Disability support';
            END IF;
            IF v_recent_services >= 4 THEN
                RETURN 'Limited - Maximum 4 sessions per 3 months';
            END IF;

        WHEN 'Educational Support' THEN
            IF v_age_years < 4 THEN
                RETURN 'No - Minimum age for education support is 4 years';
            END IF;

        ELSE
            -- No special restrictions for other services
            NULL;
    END CASE;

    -- Check service frequency limit
    IF v_recent_services >= 5 THEN
        RETURN 'No - Service frequency limit reached (5 per 3 months)';
    END IF;

    RETURN 'Yes - Eligible';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'No - Child not found';
    WHEN OTHERS THEN
        RETURN 'No - Error: ' || SQLERRM;
END is_child_eligible_for_service;





--FUNCTION 7


create or replace FUNCTION is_dml_allowed RETURN BOOLEAN IS
    v_day_of_week VARCHAR2(3);
    v_is_holiday NUMBER;
    v_next_month_start DATE;
    v_next_month_end DATE;
    v_dummy NUMBER; -- To capture function return value
BEGIN
    -- Check if it's a weekday (Monday-Friday)
    v_day_of_week := TO_CHAR(SYSDATE, 'DY');

    IF v_day_of_week IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        -- Log denied attempt
        v_dummy := log_dml_audit(
            p_table_name => 'SYSTEM_CHECK',
            p_operation_type => 'CHECK',
            p_old_values => NULL,
            p_new_values => NULL,
            p_affected_rows => NULL,
            p_child_id => NULL
        );
        RETURN FALSE;
    END IF;

    -- Check if today is a holiday in the upcoming month ONLY (CRITICAL REQUIREMENT)
    -- Calculate next month's first and last day
    v_next_month_start := TRUNC(ADD_MONTHS(SYSDATE, 1), 'MM'); -- First day of next month
    v_next_month_end := LAST_DAY(v_next_month_start); -- Last day of next month

    -- ONLY check holidays in the upcoming month (not all holidays)
    SELECT COUNT(*)
    INTO v_is_holiday
    FROM holidays
    WHERE holiday_date = TRUNC(SYSDATE) -- Today's date
    AND holiday_date BETWEEN v_next_month_start AND v_next_month_end; -- ONLY if in next month

    IF v_is_holiday > 0 THEN
        -- Log denied attempt
        v_dummy := log_dml_audit(
            p_table_name => 'SYSTEM_CHECK',
            p_operation_type => 'CHECK',
            p_old_values => NULL,
            p_new_values => NULL,
            p_affected_rows => NULL,
            p_child_id => NULL
        );
        RETURN FALSE;
    END IF;

    RETURN TRUE; -- DML is allowed (it's a weekend and not a holiday in upcoming month)

EXCEPTION
    WHEN OTHERS THEN
        -- If check fails (e.g., holidays table doesn't exist), default to allowing (fail-safe)
        RETURN TRUE;
END is_dml_allowed;




--FUNCTION 8


create or replace FUNCTION log_dml_audit(
    p_table_name IN VARCHAR2,
    p_operation_type IN VARCHAR2,
    p_old_values IN CLOB DEFAULT NULL,
    p_new_values IN CLOB DEFAULT NULL,
    p_affected_rows IN NUMBER DEFAULT NULL,
    p_operation_status IN VARCHAR2 DEFAULT 'SUCCESS',
    p_error_message IN VARCHAR2 DEFAULT NULL,
    p_business_rule IN VARCHAR2 DEFAULT NULL,
    p_child_id IN NUMBER DEFAULT NULL,
    p_staff_id IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_audit_id NUMBER;
BEGIN
    INSERT INTO dml_audit_log (
        table_name, 
        operation_type, 
        user_name,
        old_values, 
        new_values, 
        affected_rows,
        operation_status,
        error_message,
        business_rule_violated,
        child_id,
        staff_id
    ) VALUES (
        p_table_name, 
        p_operation_type, 
        USER,
        p_old_values, 
        p_new_values, 
        p_affected_rows,
        p_operation_status,
        p_error_message,
        p_business_rule,
        p_child_id,
        p_staff_id
    ) RETURNING audit_id INTO v_audit_id;

    COMMIT;
    RETURN v_audit_id;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END log_dml_audit;










