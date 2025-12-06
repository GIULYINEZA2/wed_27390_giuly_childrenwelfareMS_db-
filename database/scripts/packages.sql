create or replace PACKAGE child_welfare_management_pkg AS
    
    -- ========== EXCEPTIONS ==========
    e_child_not_found EXCEPTION;
    e_invalid_data EXCEPTION;
    e_service_limit_reached EXCEPTION;
    e_duplicate_record EXCEPTION;
    e_operation_not_allowed EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_child_not_found, -20001);
    PRAGMA EXCEPTION_INIT(e_invalid_data, -20002);
    PRAGMA EXCEPTION_INIT(e_service_limit_reached, -20003);
    PRAGMA EXCEPTION_INIT(e_duplicate_record, -20004);
    PRAGMA EXCEPTION_INIT(e_operation_not_allowed, -20005);

    -- ========== TYPES ==========
    TYPE child_summary_rec IS RECORD (
        child_id NUMBER,
        full_name VARCHAR2(100),
        age NUMBER,
        section_name VARCHAR2(50),
        disability_status VARCHAR2(3),
        vulnerability_score NUMBER,
        service_count NUMBER
    );

    TYPE child_summary_tab IS TABLE OF child_summary_rec;

    TYPE service_stats_rec IS RECORD (
        service_type VARCHAR2(50),
        total_count NUMBER,
        unique_children NUMBER,
        percent_of_total NUMBER,
        monthly_trend VARCHAR2(10)
    );

    TYPE service_stats_tab IS TABLE OF service_stats_rec;

    -- ========== WINDOW FUNCTION PROCEDURES ==========
    PROCEDURE generate_ranking_report;
    PROCEDURE analyze_trends_with_lag_lead;
    PROCEDURE calculate_running_aggregates;

    -- ========== CHILD MANAGEMENT PROCEDURES ==========
    PROCEDURE register_new_child(
        p_full_name IN VARCHAR2,
        p_dob IN DATE,
        p_gender IN VARCHAR2,
        p_disability IN VARCHAR2 DEFAULT 'No',
        p_section_name IN VARCHAR2 DEFAULT NULL,
        p_child_id OUT NUMBER
    );

    PROCEDURE update_child_status(
        p_child_id IN NUMBER,
        p_new_disability_status IN VARCHAR2,
        p_new_section_name IN VARCHAR2 DEFAULT NULL
    );

    -- ========== SERVICE MANAGEMENT PROCEDURES ==========
    PROCEDURE record_service(
        p_child_id IN NUMBER,
        p_service_type IN VARCHAR2,
        p_description IN VARCHAR2,
        p_staff_id IN NUMBER DEFAULT NULL,
        p_service_date IN DATE DEFAULT SYSDATE,
        p_service_id OUT NUMBER
    );

    -- ========== ANALYTICAL FUNCTIONS ==========
    FUNCTION get_child_rank(p_child_id IN NUMBER) RETURN NUMBER;
    FUNCTION calculate_service_gap(p_child_id IN NUMBER) RETURN NUMBER;

    -- ========== REPORTING FUNCTIONS ==========
    FUNCTION generate_child_summary(p_child_id IN NUMBER) RETURN VARCHAR2;
    FUNCTION generate_section_report(p_section_id IN NUMBER) RETURN CLOB;

    -- ========== UTILITY FUNCTIONS ==========
    FUNCTION validate_child_data(
        p_full_name IN VARCHAR2,
        p_dob IN DATE,
        p_gender IN VARCHAR2
    ) RETURN BOOLEAN;

    -- ========== ERROR HANDLING ==========
    PROCEDURE log_error(
        p_procedure_name IN VARCHAR2,
        p_error_code IN NUMBER DEFAULT NULL,
        p_error_message IN VARCHAR2,
        p_child_id IN NUMBER DEFAULT NULL
    );

    PROCEDURE cleanup_error_log(p_days_to_keep IN NUMBER DEFAULT 30);

END child_welfare_management_pkg;





--PACKAGE BODY


create or replace PACKAGE BODY child_welfare_management_pkg AS
    
    -- Global variables
    g_error_count NUMBER := 0;
    g_success_count NUMBER := 0;
    g_last_error_date DATE := SYSDATE;

    -- ========== WINDOW FUNCTION PROCEDURES ==========

    PROCEDURE generate_ranking_report IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('CHILD RANKING REPORT');
        DBMS_OUTPUT.PUT_LINE('════════════════════');
        DBMS_OUTPUT.PUT_LINE('');

        -- Rank children by service count using window functions
        FOR rec IN (
            SELECT 
                c.child_id,
                c.full_name,
                COUNT(ss.service_id) AS service_count,
                ROW_NUMBER() OVER (ORDER BY COUNT(ss.service_id) DESC) AS row_num,
                RANK() OVER (ORDER BY COUNT(ss.service_id) DESC) AS service_rank,
                DENSE_RANK() OVER (ORDER BY COUNT(ss.service_id) DESC) AS dense_rank
            FROM children c
            LEFT JOIN support_services ss ON c.child_id = ss.child_id
            GROUP BY c.child_id, c.full_name
            HAVING COUNT(ss.service_id) > 0
            ORDER BY service_count DESC
            FETCH FIRST 10 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Rank ' || rec.service_rank || 
                ' (Row ' || rec.row_num || '): ' ||
                rec.full_name || ' - ' || rec.service_count || ' services'
            );
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('generate_ranking_report', SQLCODE, SQLERRM, NULL);
            RAISE;
    END generate_ranking_report;

    PROCEDURE analyze_trends_with_lag_lead IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('SERVICE TREND ANALYSIS');
        DBMS_OUTPUT.PUT_LINE('══════════════════════');
        DBMS_OUTPUT.PUT_LINE('');

        -- Use LAG and LEAD for trend analysis
        FOR rec IN (
            SELECT 
                service_date,
                service_type,
                daily_count,
                previous_day,
                next_day,
                daily_change,
                running_total
            FROM (
                SELECT 
                    TRUNC(service_date) AS service_date,
                    service_type,
                    COUNT(*) AS daily_count,
                    LAG(COUNT(*), 1, 0) OVER (
                        ORDER BY TRUNC(service_date)
                    ) AS previous_day,
                    LEAD(COUNT(*), 1, 0) OVER (
                        ORDER BY TRUNC(service_date)
                    ) AS next_day,
                    COUNT(*) - LAG(COUNT(*), 1, 0) OVER (
                        ORDER BY TRUNC(service_date)
                    ) AS daily_change,
                    SUM(COUNT(*)) OVER (
                        ORDER BY TRUNC(service_date)
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ) AS running_total
                FROM support_services
                WHERE service_date >= SYSDATE - 30
                GROUP BY TRUNC(service_date), service_type
            )
            WHERE service_type = 'Medical Checkup'
            AND ROWNUM <= 10
            ORDER BY service_date DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Date: ' || TO_CHAR(rec.service_date, 'DD-MON') ||
                ' | Type: ' || RPAD(rec.service_type, 20) ||
                ' | Today: ' || LPAD(rec.daily_count, 3) ||
                ' | Prev: ' || LPAD(rec.previous_day, 3) ||
                ' | Next: ' || LPAD(rec.next_day, 3) ||
                ' | Change: ' || LPAD(rec.daily_change, 4) ||
                ' | Running: ' || LPAD(rec.running_total, 5)
            );
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('analyze_trends_with_lag_lead', SQLCODE, SQLERRM, NULL);
            RAISE;
    END analyze_trends_with_lag_lead;

    PROCEDURE calculate_running_aggregates IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('RUNNING AGGREGATES BY SECTION');
        DBMS_OUTPUT.PUT_LINE('═════════════════════════════');
        DBMS_OUTPUT.PUT_LINE('');

        -- Calculate running aggregates with OVER clause
        FOR rec IN (
            SELECT 
                section_name,
                child_count,
                ROUND(child_count * 100.0 / total_children, 2) AS section_percent,
                SUM(child_count) OVER (
                    ORDER BY child_count DESC 
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS running_total,
                ROUND(SUM(child_count) OVER (
                    ORDER BY child_count DESC 
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) * 100.0 / total_children, 2) AS cumulative_percent
            FROM (
                SELECT 
                    s.section_name,
                    COUNT(c.child_id) AS child_count,
                    SUM(COUNT(c.child_id)) OVER () AS total_children
                FROM sections s
                LEFT JOIN children c ON s.section_id = c.section_id
                GROUP BY s.section_name, s.section_id
                ORDER BY child_count DESC
            )
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Section: ' || RPAD(rec.section_name, 25) ||
                ' | Children: ' || LPAD(rec.child_count, 3) ||
                ' | % of total: ' || LPAD(rec.section_percent, 6) || '%' ||
                ' | Running total: ' || LPAD(rec.running_total, 4) ||
                ' | Cum. %: ' || LPAD(rec.cumulative_percent, 6) || '%'
            );
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('calculate_running_aggregates', SQLCODE, SQLERRM, NULL);
            RAISE;
    END calculate_running_aggregates;

    -- ========== CHILD MANAGEMENT PROCEDURES ==========

    PROCEDURE register_new_child(
        p_full_name IN VARCHAR2,
        p_dob IN DATE,
        p_gender IN VARCHAR2,
        p_disability IN VARCHAR2 DEFAULT 'No',
        p_section_name IN VARCHAR2 DEFAULT NULL,
        p_child_id OUT NUMBER
    ) IS
        v_section_id NUMBER;
        v_age_months NUMBER;
    BEGIN
        -- Validate input
        IF NOT validate_child_data(p_full_name, p_dob, p_gender) THEN
            RAISE e_invalid_data;
        END IF;

        -- Calculate age
        v_age_months := MONTHS_BETWEEN(SYSDATE, p_dob);

        IF v_age_months < 0 OR v_age_months > 216 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Age must be between 0-18 years');
        END IF;

        -- Determine section
        IF p_section_name IS NULL THEN
            -- Auto-determine section based on age and disability
            IF p_disability = 'Yes' THEN
                SELECT section_id INTO v_section_id
                FROM sections
                WHERE UPPER(section_name) = 'SPECIAL NEEDS UNIT';
            ELSE
                -- Age-based section assignment
                IF v_age_months <= 24 THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%INFANTS%';
                ELSIF v_age_months <= 48 THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%TODDLERS%';
                ELSIF v_age_months <= 72 THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%KINDERGARTEN%';
                ELSIF v_age_months <= 108 THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%PRIMARY 1-3%';
                ELSIF v_age_months <= 144 THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%PRIMARY 4-6%';
                ELSIF p_gender = 'Female' THEN
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%ADOLESCENT GIRLS%';
                ELSE
                    SELECT section_id INTO v_section_id
                    FROM sections
                    WHERE UPPER(section_name) LIKE '%ADOLESCENT BOYS%';
                END IF;
            END IF;
        ELSE
            -- Use provided section
            BEGIN
                SELECT section_id INTO v_section_id
                FROM sections
                WHERE UPPER(section_name) = UPPER(p_section_name);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20007, 'Invalid section name: ' || p_section_name);
            END;
        END IF;

        -- Insert child record
        INSERT INTO children (
            full_name, date_of_birth, gender, 
            disability_status, section_id
        ) VALUES (
            p_full_name, p_dob, p_gender, 
            p_disability, v_section_id
        ) RETURNING child_id INTO p_child_id;

        g_success_count := g_success_count + 1;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Child registered successfully. ID: ' || p_child_id);

    EXCEPTION
        WHEN e_invalid_data THEN
            log_error('register_new_child', -20002, 'Invalid child data provided', NULL);
            RAISE;
        WHEN DUP_VAL_ON_INDEX THEN
            log_error('register_new_child', -20004, 'Duplicate child record', NULL);
            RAISE e_duplicate_record;
        WHEN OTHERS THEN
            log_error('register_new_child', SQLCODE, SQLERRM, NULL);
            ROLLBACK;
            RAISE;
    END register_new_child;

    PROCEDURE update_child_status(
        p_child_id IN NUMBER,
        p_new_disability_status IN VARCHAR2,
        p_new_section_name IN VARCHAR2 DEFAULT NULL
    ) IS
        v_child_exists NUMBER;
        v_current_section_id NUMBER;
        v_new_section_id NUMBER;
    BEGIN
        -- Check if child exists
        SELECT COUNT(*) INTO v_child_exists
        FROM children
        WHERE child_id = p_child_id;

        IF v_child_exists = 0 THEN
            RAISE e_child_not_found;
        END IF;

        -- Validate disability status
        IF p_new_disability_status NOT IN ('Yes', 'No') THEN
            RAISE e_invalid_data;
        END IF;

        -- Get current section
        SELECT section_id INTO v_current_section_id
        FROM children
        WHERE child_id = p_child_id;

        -- Determine new section
        IF p_new_section_name IS NOT NULL THEN
            BEGIN
                SELECT section_id INTO v_new_section_id
                FROM sections
                WHERE UPPER(section_name) = UPPER(p_new_section_name);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20008, 'Invalid section name: ' || p_new_section_name);
            END;
        ELSIF p_new_disability_status = 'Yes' THEN
            -- Move to Special Needs Unit if disabled
            SELECT section_id INTO v_new_section_id
            FROM sections
            WHERE UPPER(section_name) = 'SPECIAL NEEDS UNIT';
        ELSE
            v_new_section_id := v_current_section_id;
        END IF;

        -- Update child record
        UPDATE children
        SET disability_status = p_new_disability_status,
            section_id = v_new_section_id
        WHERE child_id = p_child_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Child ' || p_child_id || ' status updated successfully');

    EXCEPTION
        WHEN e_child_not_found THEN
            log_error('update_child_status', -20001, 'Child not found: ' || p_child_id, p_child_id);
            RAISE;
        WHEN e_invalid_data THEN
            log_error('update_child_status', -20002, 'Invalid disability status', p_child_id);
            RAISE;
        WHEN OTHERS THEN
            log_error('update_child_status', SQLCODE, SQLERRM, p_child_id);
            ROLLBACK;
            RAISE;
    END update_child_status;

    -- ========== SERVICE MANAGEMENT PROCEDURES ==========

    PROCEDURE record_service(
        p_child_id IN NUMBER,
        p_service_type IN VARCHAR2,
        p_description IN VARCHAR2,
        p_staff_id IN NUMBER DEFAULT NULL,
        p_service_date IN DATE DEFAULT SYSDATE,
        p_service_id OUT NUMBER
    ) IS
        v_recent_services NUMBER;
        v_child_exists NUMBER;
    BEGIN
        -- Check child exists
        SELECT COUNT(*) INTO v_child_exists
        FROM children
        WHERE child_id = p_child_id;

        IF v_child_exists = 0 THEN
            RAISE e_child_not_found;
        END IF;

        -- Check service frequency limit
        SELECT COUNT(*)
        INTO v_recent_services
        FROM support_services
        WHERE child_id = p_child_id
        AND service_type = p_service_type
        AND service_date >= ADD_MONTHS(SYSDATE, -1);

        IF v_recent_services >= 5 THEN
            RAISE e_service_limit_reached;
        END IF;

        -- Insert service record
        INSERT INTO support_services (
            service_type, description, child_id,
            staff_id, service_date
        ) VALUES (
            p_service_type, p_description, p_child_id,
            p_staff_id, p_service_date
        ) RETURNING service_id INTO p_service_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Service recorded. ID: ' || p_service_id);

    EXCEPTION
        WHEN e_child_not_found THEN
            log_error('record_service', -20001, 'Child not found', p_child_id);
            RAISE;
        WHEN e_service_limit_reached THEN
            log_error('record_service', -20003, 'Service limit reached for child', p_child_id);
            RAISE;
        WHEN OTHERS THEN
            log_error('record_service', SQLCODE, SQLERRM, p_child_id);
            ROLLBACK;
            RAISE;
    END record_service;

    -- ========== ANALYTICAL FUNCTIONS ==========

    FUNCTION get_child_rank(p_child_id IN NUMBER) RETURN NUMBER IS
        v_rank NUMBER;
    BEGIN
        SELECT service_rank INTO v_rank
        FROM (
            SELECT 
                child_id,
                RANK() OVER (ORDER BY COUNT(service_id) DESC) AS service_rank
            FROM support_services
            GROUP BY child_id
        )
        WHERE child_id = p_child_id;

        RETURN v_rank;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            log_error('get_child_rank', SQLCODE, SQLERRM, p_child_id);
            RETURN 0;
    END get_child_rank;

    FUNCTION calculate_service_gap(p_child_id IN NUMBER) RETURN NUMBER IS
        v_last_service_date DATE;
        v_gap_days NUMBER;
    BEGIN
        SELECT MAX(service_date) INTO v_last_service_date
        FROM support_services
        WHERE child_id = p_child_id;

        IF v_last_service_date IS NULL THEN
            RETURN NULL;
        END IF;

        v_gap_days := SYSDATE - v_last_service_date;
        RETURN v_gap_days;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('calculate_service_gap', SQLCODE, SQLERRM, p_child_id);
            RETURN NULL;
    END calculate_service_gap;

    -- ========== REPORTING FUNCTIONS ==========

    FUNCTION generate_child_summary(p_child_id IN NUMBER) RETURN VARCHAR2 IS
        v_summary VARCHAR2(2000);
        v_child_name VARCHAR2(100);
        v_dob DATE;
        v_gender VARCHAR2(10);
        v_disability VARCHAR2(3);
        v_section_name VARCHAR2(50);
        v_service_count NUMBER;
        v_last_service DATE;
    BEGIN
        -- Get child details
        BEGIN
            SELECT 
                c.full_name,
                c.date_of_birth,
                c.gender,
                c.disability_status,
                s.section_name,
                COUNT(ss.service_id),
                MAX(ss.service_date)
            INTO 
                v_child_name,
                v_dob,
                v_gender,
                v_disability,
                v_section_name,
                v_service_count,
                v_last_service
            FROM children c
            JOIN sections s ON c.section_id = s.section_id
            LEFT JOIN support_services ss ON c.child_id = ss.child_id
            WHERE c.child_id = p_child_id
            GROUP BY c.full_name, c.date_of_birth, c.gender, 
                     c.disability_status, s.section_name;

            -- Build summary
            v_summary := 'CHILD SUMMARY REPORT' || CHR(10) ||
                        '════════════════════' || CHR(10) ||
                        'ID: ' || p_child_id || CHR(10) ||
                        'Name: ' || v_child_name || CHR(10) ||
                        'Date of Birth: ' || TO_CHAR(v_dob, 'DD-MON-YYYY') || CHR(10) ||
                        'Age: ' || ROUND(MONTHS_BETWEEN(SYSDATE, v_dob)/12, 1) || ' years' || CHR(10) ||
                        'Gender: ' || v_gender || CHR(10) ||
                        'Disability Status: ' || v_disability || CHR(10) ||
                        'Section: ' || v_section_name || CHR(10) ||
                        'Services Received: ' || v_service_count || CHR(10) ||
                        'Service Rank: ' || get_child_rank(p_child_id) || CHR(10);

            IF v_last_service IS NOT NULL THEN
                v_summary := v_summary || 'Last Service: ' || 
                            TO_CHAR(v_last_service, 'DD-MON-YYYY') || CHR(10) ||
                            'Days Since Last Service: ' || 
                            calculate_service_gap(p_child_id) || CHR(10);
            END IF;

            RETURN v_summary;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'Child not found with ID: ' || p_child_id;
        END;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('generate_child_summary', SQLCODE, SQLERRM, p_child_id);
            RETURN 'Error generating summary: ' || SQLERRM;
    END generate_child_summary;

    FUNCTION generate_section_report(p_section_id IN NUMBER) RETURN CLOB IS
        v_report CLOB;
    BEGIN
        v_report := 'SECTION REPORT' || CHR(10);
        v_report := v_report || '══════════════' || CHR(10) || CHR(10);

        -- Section details
        FOR rec IN (
            SELECT 
                section_name,
                COUNT(c.child_id) AS child_count,
                ROUND(AVG(MONTHS_BETWEEN(SYSDATE, c.date_of_birth)/12), 1) AS avg_age,
                SUM(CASE WHEN c.disability_status = 'Yes' THEN 1 ELSE 0 END) AS disabled_count
            FROM sections s
            LEFT JOIN children c ON s.section_id = c.section_id
            WHERE s.section_id = p_section_id
            GROUP BY s.section_name
        ) LOOP
            v_report := v_report || 'Section: ' || rec.section_name || CHR(10);
            v_report := v_report || 'Total Children: ' || rec.child_count || CHR(10);
            v_report := v_report || 'Average Age: ' || rec.avg_age || ' years' || CHR(10);
            v_report := v_report || 'Children with Disabilities: ' || rec.disabled_count || CHR(10);
            v_report := v_report || CHR(10);
        END LOOP;

        RETURN v_report;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('generate_section_report', SQLCODE, SQLERRM, NULL);
            RETURN 'Error generating section report: ' || SQLERRM;
    END generate_section_report;

        -- ========== UTILITY FUNCTIONS ==========

    FUNCTION validate_child_data(
        p_full_name IN VARCHAR2,
        p_dob IN DATE,
        p_gender IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF p_full_name IS NULL OR LENGTH(TRIM(p_full_name)) < 2 THEN
            RETURN FALSE;
        END IF;

        IF p_dob IS NULL OR p_dob > SYSDATE THEN
            RETURN FALSE;
        END IF;

        IF p_gender NOT IN ('Male', 'Female') THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    END validate_child_data;

    -- ========== ERROR HANDLING ==========

    PROCEDURE log_error(
        p_procedure_name IN VARCHAR2,
        p_error_code IN NUMBER DEFAULT NULL,
        p_error_message IN VARCHAR2,
        p_child_id IN NUMBER DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        g_error_count := g_error_count + 1;
        g_last_error_date := SYSDATE;

        -- Insert into error_log
        INSERT INTO error_log (
            error_id, procedure_name, error_code, 
            error_message, child_id, error_date, user_name
        ) VALUES (
            COALESCE((SELECT MAX(error_id) + 1 FROM error_log), 1), 
            p_procedure_name, p_error_code,
            p_error_message, p_child_id, SYSDATE, USER
        );

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Error logged: ' || p_procedure_name || ' - ' || p_error_message);

    EXCEPTION
        WHEN OTHERS THEN
            -- If error logging fails, at least output
            DBMS_OUTPUT.PUT_LINE('Error logging failed: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Original error: ' || p_error_message);
    END log_error;

    PROCEDURE cleanup_error_log(p_days_to_keep IN NUMBER DEFAULT 30) IS
    BEGIN
        DELETE FROM error_log
        WHERE error_date < SYSDATE - p_days_to_keep;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Error log cleaned up. Removed records older than ' || 
                           p_days_to_keep || ' days.');

    EXCEPTION
        WHEN OTHERS THEN
            log_error('cleanup_error_log', SQLCODE, SQLERRM, NULL);
            RAISE;
    END cleanup_error_log;

END child_welfare_management_pkg;  -- ← This is the main package END

