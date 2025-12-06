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




--CURSOR 2


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



---CURSOR 3



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






---CURSOR 4




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






