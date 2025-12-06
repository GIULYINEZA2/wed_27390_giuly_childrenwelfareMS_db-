
-- SWITCH TO YOUR TABLESPACE
ALTER SESSION SET CONTAINER = wedns_27390_giuly_childwelfare_db;
ALTER SESSION SET CURRENT_SCHEMA = giuly_admin_27390;

--------------------------------------------------------------------
-- 1. INSERT DATA INTO SECTIONS TABLE (10 sections)
--------------------------------------------------------------------
INSERT INTO sections (section_name) VALUES ('Infants (0-2 years)');
INSERT INTO sections (section_name) VALUES ('Toddlers (2-4 years)');
INSERT INTO sections (section_name) VALUES ('Kindergarten (4-6 years)');
INSERT INTO sections (section_name) VALUES ('Primary 1-3 (6-9 years)');
INSERT INTO sections (section_name) VALUES ('Primary 4-6 (9-12 years)');
INSERT INTO sections (section_name) VALUES ('Adolescent Girls (13-18 years)');
INSERT INTO sections (section_name) VALUES ('Adolescent Boys (13-18 years)');
INSERT INTO sections (section_name) VALUES ('Special Needs Unit');
INSERT INTO sections (section_name) VALUES ('Transition (17-18 years)');
INSERT INTO sections (section_name) VALUES ('Nursery (0-3 years)');

COMMIT;

--------------------------------------------------------------------
-- 2. INSERT DATA INTO CHILDREN TABLE (150 children)
--------------------------------------------------------------------
DECLARE
    TYPE name_array IS VARRAY(30) OF VARCHAR2(50);
    boy_names name_array := name_array(
        'James', 'John', 'Robert', 'Michael', 'William',
        'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
        'Christopher', 'Daniel', 'Matthew', 'Anthony', 'Donald',
        'Mark', 'Paul', 'Steven', 'Andrew', 'Kenneth',
        'Joshua', 'Kevin', 'Brian', 'George', 'Edward',
        'Ronald', 'Timothy', 'Jason', 'Jeffrey', 'Frank'
    );
    
    girl_names name_array := name_array(
        'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth',
        'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen',
        'Nancy', 'Lisa', 'Margaret', 'Betty', 'Sandra',
        'Ashley', 'Dorothy', 'Kimberly', 'Emily', 'Donna',
        'Michelle', 'Carol', 'Amanda', 'Melissa', 'Deborah',
        'Stephanie', 'Rebecca', 'Laura', 'Sharon', 'Cynthia'
    );
    
    last_names name_array := name_array(
        'Smith', 'Johnson', 'Williams', 'Brown', 'Jones',
        'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
        'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
        'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
        'Lee', 'Perez', 'Thompson', 'White', 'Harris',
        'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson'
    );
    
    v_child_id NUMBER;
    v_full_name VARCHAR2(100);
    v_dob DATE;
    v_gender VARCHAR2(10);
    v_disability VARCHAR2(3);
    v_section_id NUMBER;
    v_random NUMBER;
BEGIN
    FOR i IN 1..150 LOOP
        -- Generate random gender
        v_random := DBMS_RANDOM.VALUE(0, 1);
        IF v_random < 0.48 THEN
            v_gender := 'Male';
            v_full_name := boy_names(MOD(i, 30) + 1) || ' ' || last_names(MOD(i*2, 30) + 1);
        ELSIF v_random < 0.96 THEN
            v_gender := 'Female';
            v_full_name := girl_names(MOD(i, 30) + 1) || ' ' || last_names(MOD(i*3, 30) + 1);
        ELSE
            v_gender := 'Female'; -- Default
            v_full_name := 'Child ' || i || ' ' || last_names(MOD(i, 30) + 1);
        END IF;
        
        -- Generate random date of birth (0-18 years)
        v_dob := SYSDATE - DBMS_RANDOM.VALUE(1, 365*18);
        
        -- Generate random disability status (10% with disability)
        v_random := DBMS_RANDOM.VALUE(0, 1);
        IF v_random < 0.1 THEN
            v_disability := 'Yes';
        ELSE
            v_disability := 'No';
        END IF;
        
        -- Assign section based on age
        DECLARE
            v_age_months NUMBER := MONTHS_BETWEEN(SYSDATE, v_dob);
        BEGIN
            IF v_age_months <= 24 THEN
                v_section_id := 1; -- Infants
            ELSIF v_age_months <= 48 THEN
                v_section_id := 2; -- Toddlers
            ELSIF v_age_months <= 72 THEN
                v_section_id := 3; -- Kindergarten
            ELSIF v_age_months <= 108 THEN
                v_section_id := 4; -- Primary 1-3
            ELSIF v_age_months <= 144 THEN
                v_section_id := 5; -- Primary 4-6
            ELSIF v_gender = 'Female' THEN
                v_section_id := 6; -- Adolescent Girls
            ELSE
                v_section_id := 7; -- Adolescent Boys
            END IF;
            
            -- Override for children with disabilities
            IF v_disability = 'Yes' THEN
                v_section_id := 8; -- Special Needs Unit
            END IF;
        END;
        
        INSERT INTO children (
            full_name, date_of_birth, gender, disability_status, section_id
        ) VALUES (
            v_full_name, v_dob, v_gender, v_disability, v_section_id
        );
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------
-- 3. INSERT DATA INTO STAFF TABLE (25 staff members)
--------------------------------------------------------------------
DECLARE
    TYPE staff_rec IS RECORD (
        full_name VARCHAR2(100),
        position VARCHAR2(50),
        contact VARCHAR2(15)
    );
    
    TYPE staff_array IS VARRAY(25) OF staff_rec;
    
    staff_data staff_array := staff_array(
        staff_rec('Dr. Alice Uwase', 'Medical Director', '0783123456'),
        staff_rec('John Niyomugabo', 'Social Worker', '0783123457'),
        staff_rec('Marie Claire Kayitesi', 'Psychologist', '0783123458'),
        staff_rec('Peter Gatete', 'Education Coordinator', '0783123459'),
        staff_rec('Sarah Mukamana', 'Nurse', '0783123460'),
        staff_rec('James Habimana', 'Security Officer', '0783123461'),
        staff_rec('Grace Uwimana', 'Cook', '0783123462'),
        staff_rec('David Nkurunziza', 'Administrator', '0783123463'),
        staff_rec('Annette Mutoni', 'Special Needs Teacher', '0783123464'),
        staff_rec('Eric Nsengimana', 'Sports Coach', '0783123465'),
        staff_rec('Chantal Iradukunda', 'House Mother', '0783123466'),
        staff_rec('Frank Bizimana', 'Maintenance', '0783123467'),
        staff_rec('Rose Mutesi', 'Counselor', '0783123468'),
        staff_rec('Samuel Kwizera', 'Driver', '0783123469'),
        staff_rec('Jeanne d''Arc Nyirahabimana', 'Accountant', '0783123470'),
        staff_rec('Patrick Ndayisaba', 'IT Support', '0783123471'),
        staff_rec('Immaculee Uwambajimana', 'Nutritionist', '0783123472'),
        staff_rec('Robert Mugisha', 'Legal Advisor', '0783123473'),
        staff_rec('Bella Tuyishime', 'Volunteer Coordinator', '0783123474'),
        staff_rec('Joseph Kalisa', 'Gardener', '0783123475'),
        staff_rec('Louise Mukankusi', 'Laundry Attendant', '0783123476'),
        staff_rec('Emmanuel Nshuti', 'Night Watch', '0783123477'),
        staff_rec('Solange Uwase', 'Receptionist', '0783123478'),
        staff_rec('Alexis Niyonzima', 'Fundraiser', '0783123479'),
        staff_rec('Claire Kankindi', 'Intern', '0783123480')
    );
BEGIN
    FOR i IN 1..staff_data.COUNT LOOP
        INSERT INTO staff (full_name, position, contact_number)
        VALUES (
            staff_data(i).full_name,
            staff_data(i).position,
            staff_data(i).contact
        );
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------
-- 4. INSERT DATA INTO EDUCATION TABLE (250 education records)
--------------------------------------------------------------------
DECLARE
    TYPE school_array IS VARRAY(15) OF VARCHAR2(100);
    schools school_array := school_array(
        'Hope Primary School', 'Bright Future Academy', 'New Dawn School',
        'Unity Primary School', 'Excellence Academy', 'St. Mary''s School',
        'Rainbow Elementary', 'Sunshine School', 'Mountain View Academy',
        'Lakeview Primary', 'Green Hills School', 'Royal Academy',
        'Vision School', 'Heritage Academy', 'Community Primary School'
    );
    
    TYPE grade_array IS VARRAY(12) OF VARCHAR2(30);
    grades grade_array := grade_array(
        'Nursery', 'KG1', 'KG2', 'P1', 'P2', 'P3',
        'P4', 'P5', 'P6', 'S1', 'S2', 'S3'
    );
    
    v_child_count NUMBER;
    v_random_child NUMBER;
    v_school VARCHAR2(100);
    v_grade VARCHAR2(30);
    v_performance VARCHAR2(200);
    v_random NUMBER;
BEGIN
    -- Get total children
    SELECT COUNT(*) INTO v_child_count FROM children;
    
    FOR i IN 1..250 LOOP
        -- Select random child
        v_random_child := TRUNC(DBMS_RANDOM.VALUE(1, v_child_count + 1));
        
        -- Select random school
        v_school := schools(MOD(i, 15) + 1);
        
        -- Select random grade
        v_grade := grades(MOD(i, 12) + 1);
        
        -- Generate performance notes
        v_random := DBMS_RANDOM.VALUE(0, 1);
        IF v_random < 0.3 THEN
            v_performance := 'Excellent performance, top of class';
        ELSIF v_random < 0.6 THEN
            v_performance := 'Good progress, participates actively';
        ELSIF v_random < 0.8 THEN
            v_performance := 'Average performance, needs more practice';
        ELSIF v_random < 0.95 THEN
            v_performance := 'Needs improvement, struggling with some subjects';
        ELSE
            v_performance := 'Requires special attention and tutoring';
        END IF;
        
        INSERT INTO education (child_id, school_name, grade_level, performance_notes)
        VALUES (v_random_child, v_school, v_grade, v_performance);
        
        -- Every 10th record gets NULL performance notes
        IF MOD(i, 10) = 0 THEN
            UPDATE education SET performance_notes = NULL WHERE education_id = i;
        END IF;
    END LOOP;
    COMMIT;
END;
/

--------------------------------------------------------------------
-- 5. INSERT DATA INTO SUPPORT_SERVICES TABLE (300 services)
--------------------------------------------------------------------
DECLARE
    TYPE service_array IS VARRAY(10) OF VARCHAR2(50);
    services service_array := service_array(
        'Medical Checkup', 'Psychological Counseling', 'Educational Support',
        'Nutritional Support', 'Legal Assistance', 'Recreational Activities',
        'Vocational Training', 'Family Reunification', 'Sponsorship',
        'Emergency Shelter'
    );
    
    v_child_count NUMBER;
    v_staff_count NUMBER;
    v_random_child NUMBER;
    v_random_staff NUMBER;
    v_service_type VARCHAR2(50);
    v_description VARCHAR2(200);
    v_service_date DATE;
    v_random NUMBER;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO v_child_count FROM children;
    SELECT COUNT(*) INTO v_staff_count FROM staff;
    
    FOR i IN 1..300 LOOP
        -- Select random child and staff
        v_random_child := TRUNC(DBMS_RANDOM.VALUE(1, v_child_count + 1));
        v_random_staff := TRUNC(DBMS_RANDOM.VALUE(1, v_staff_count + 1));
        
        -- Select random service type
        v_service_type := services(MOD(i, 10) + 1);
        
        -- Generate description based on service type
        CASE v_service_type
            WHEN 'Medical Checkup' THEN
                v_description := 'Routine health examination and vaccination';
            WHEN 'Psychological Counseling' THEN
                v_description := 'Weekly therapy session for trauma recovery';
            WHEN 'Educational Support' THEN
                v_description := 'After-school tutoring and school supplies';
            WHEN 'Nutritional Support' THEN
                v_description := 'Supplemental feeding program';
            WHEN 'Legal Assistance' THEN
                v_description := 'Document processing and legal representation';
            WHEN 'Recreational Activities' THEN
                v_description := 'Sports, arts, and cultural activities';
            WHEN 'Vocational Training' THEN
                v_description := 'Skill development for older children';
            WHEN 'Family Reunification' THEN
                v_description := 'Tracing and reunification efforts';
            WHEN 'Sponsorship' THEN
                v_description := 'Education sponsorship program';
            WHEN 'Emergency Shelter' THEN
                v_description := 'Temporary shelter and protection';
        END CASE;
        
        -- Generate random date within last 2 years (some future dates)
        v_service_date := SYSDATE - DBMS_RANDOM.VALUE(1, 730);
        v_random := DBMS_RANDOM.VALUE(0, 1);
        IF v_random < 0.1 THEN
            v_service_date := SYSDATE + DBMS_RANDOM.VALUE(1, 60); -- Future dates
        END IF;
        
        -- Every 20th record gets NULL staff_id (service not assigned yet)
        IF MOD(i, 20) = 0 THEN
            v_random_staff := NULL;
        END IF;
        
        -- Every 15th record gets NULL child_id (general service)
        IF MOD(i, 15) = 0 THEN
            v_random_child := NULL;
        END IF;
        
        INSERT INTO support_services (
            service_type, description, child_id, staff_id, service_date
        ) VALUES (
            v_service_type, v_description, v_random_child, v_random_staff, v_service_date
        );
    END LOOP;
    COMMIT;
END;
/





-- Insert some sample holidays (upcoming month and common holidays)
DECLARE
    v_current_year NUMBER := EXTRACT(YEAR FROM SYSDATE);
BEGIN
    -- New Year's Day
    INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
    VALUES ('New Year''s Day', TO_DATE(v_current_year || '-01-01', 'YYYY-MM-DD'), 'Public', 'Yes', 'Beginning of the new year');
    
    -- Easter (example - adjust as needed)
    INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
    VALUES ('Easter Monday', TO_DATE(v_current_year || '-04-01', 'YYYY-MM-DD'), 'Religious', 'Yes', 'Day after Easter Sunday');
    
    -- Labor Day
    INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
    VALUES ('Labor Day', TO_DATE(v_current_year || '-05-01', 'YYYY-MM-DD'), 'National', 'Yes', 'International Workers'' Day');
    
    -- Independence Day (Rwanda - July 1)
    INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
    VALUES ('Independence Day', TO_DATE(v_current_year || '-07-01', 'YYYY-MM-DD'), 'National', 'Yes', 'Rwanda Independence Day');
    
    -- Christmas
    INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
    VALUES ('Christmas Day', TO_DATE(v_current_year || '-12-25', 'YYYY-MM-DD'), 'Religious', 'Yes', 'Christmas celebration');
    
    -- Add holidays for next month
    DECLARE
        v_next_month DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1);
        v_next_month_start DATE := TRUNC(v_next_month, 'MM');
        v_next_month_end DATE := LAST_DAY(v_next_month_start);
    BEGIN
        -- Example: Add a test holiday in next month
        INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
        VALUES ('Test Holiday', v_next_month_start + 5, 'Public', 'No', 'Test holiday for auditing system');
        
        -- Add another test holiday
        INSERT INTO holidays (holiday_name, holiday_date, holiday_type, is_recurring, description)
        VALUES ('System Maintenance Day', v_next_month_start + 15, 'National', 'No', 'System maintenance - no operations allowed');
    END;
    
    COMMIT;
END;
/






