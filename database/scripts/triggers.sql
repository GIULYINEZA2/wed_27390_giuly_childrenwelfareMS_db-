--TRIGGER 1

create or replace TRIGGER trg_children_dml_restrict
BEFORE INSERT OR UPDATE OR DELETE ON children
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_values CLOB;
    v_new_values CLOB;
    v_dummy NUMBER; -- Variable to capture function return value
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_values := 'ID: ' || :NEW.child_id || ', Name: ' || :NEW.full_name ||
                       ', DOB: ' || TO_CHAR(:NEW.date_of_birth, 'DD-MON-YYYY') ||
                       ', Gender: ' || :NEW.gender || ', Disability: ' || :NEW.disability_status;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_values := 'ID: ' || :OLD.child_id || ', Name: ' || :OLD.full_name ||
                       ', DOB: ' || TO_CHAR(:OLD.date_of_birth, 'DD-MON-YYYY') ||
                       ', Gender: ' || :OLD.gender || ', Disability: ' || :OLD.disability_status;
        v_new_values := 'ID: ' || :NEW.child_id || ', Name: ' || :NEW.full_name ||
                       ', DOB: ' || TO_CHAR(:NEW.date_of_birth, 'DD-MON-YYYY') ||
                       ', Gender: ' || :NEW.gender || ', Disability: ' || :NEW.disability_status;
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_old_values := 'ID: ' || :OLD.child_id || ', Name: ' || :OLD.full_name ||
                       ', DOB: ' || TO_CHAR(:OLD.date_of_birth, 'DD-MON-YYYY') ||
                       ', Gender: ' || :OLD.gender || ', Disability: ' || :OLD.disability_status;
    END IF;

    -- Check if DML is allowed
    IF NOT is_dml_allowed THEN
        -- Log denied attempt
        v_dummy := log_dml_audit(
            p_table_name => 'CHILDREN',
            p_operation_type => v_operation,
            p_old_values => v_old_values,
            p_new_values => v_new_values,
            p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
        );

        RAISE_APPLICATION_ERROR(-20050, 
            'DML operation denied on CHILDREN table. ' || get_restriction_message);
    END IF;

    -- If allowed, log successful attempt
    v_dummy := log_dml_audit(
        p_table_name => 'CHILDREN',
        p_operation_type => v_operation,
        p_old_values => v_old_values,
        p_new_values => v_new_values,
        p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        v_dummy := log_dml_audit(
            p_table_name => 'CHILDREN',
            p_operation_type => v_operation,
            p_old_values => v_old_values,
            p_new_values => v_new_values,
            p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
        );
        RAISE;
END trg_children_dml_restrict;




--TRIGGER 2



create or replace TRIGGER trg_services_dml_restrict
BEFORE INSERT OR UPDATE OR DELETE ON support_services
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_values CLOB;
    v_new_values CLOB;
    v_dummy NUMBER; -- Variable to capture function return value
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_values := 'Service ID: ' || :NEW.service_id || ', Type: ' || :NEW.service_type ||
                       ', Child ID: ' || :NEW.child_id || ', Date: ' || TO_CHAR(:NEW.service_date, 'DD-MON-YYYY');
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_values := 'Service ID: ' || :OLD.service_id || ', Type: ' || :OLD.service_type ||
                       ', Child ID: ' || :OLD.child_id || ', Date: ' || TO_CHAR(:OLD.service_date, 'DD-MON-YYYY');
        v_new_values := 'Service ID: ' || :NEW.service_id || ', Type: ' || :NEW.service_type ||
                       ', Child ID: ' || :NEW.child_id || ', Date: ' || TO_CHAR(:NEW.service_date, 'DD-MON-YYYY');
    ELSE -- DELETING
        v_operation := 'DELETE';
        v_old_values := 'Service ID: ' || :OLD.service_id || ', Type: ' || :OLD.service_type ||
                       ', Child ID: ' || :OLD.child_id || ', Date: ' || TO_CHAR(:OLD.service_date, 'DD-MON-YYYY');
    END IF;

    -- Check if DML is allowed
    IF NOT is_dml_allowed THEN
        -- Log denied attempt
        v_dummy := log_dml_audit(
            p_table_name => 'SUPPORT_SERVICES',
            p_operation_type => v_operation,
            p_old_values => v_old_values,
            p_new_values => v_new_values,
            p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
        );

        RAISE_APPLICATION_ERROR(-20051, 
            'DML operation denied on SUPPORT_SERVICES table. ' || get_restriction_message);
    END IF;

    -- If allowed, log successful attempt
    v_dummy := log_dml_audit(
        p_table_name => 'SUPPORT_SERVICES',
        p_operation_type => v_operation,
        p_old_values => v_old_values,
        p_new_values => v_new_values,
        p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
    );

EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        v_dummy := log_dml_audit(
            p_table_name => 'SUPPORT_SERVICES',
            p_operation_type => v_operation,
            p_old_values => v_old_values,
            p_new_values => v_new_values,
            p_child_id => CASE WHEN INSERTING OR UPDATING THEN :NEW.child_id ELSE :OLD.child_id END
        );
        RAISE;
END trg_services_dml_restrict;





--TRIGGER 3



create or replace TRIGGER trg_staff_dml_compound
FOR INSERT OR UPDATE OR DELETE ON staff
COMPOUND TRIGGER

    -- Global variables
    TYPE staff_rec IS RECORD (
        staff_id staff.staff_id%TYPE,
        full_name staff.full_name%TYPE,
        position staff.position%TYPE,
        contact staff.contact_number%TYPE
    );

    TYPE staff_array IS TABLE OF staff_rec;

    g_inserted_staff staff_array := staff_array();
    g_updated_staff_old staff_array := staff_array();
    g_updated_staff_new staff_array := staff_array();
    g_deleted_staff staff_array := staff_array();

    g_operation_type VARCHAR2(10);
    v_dummy NUMBER; -- Variable to capture function return value

    -- BEFORE EACH ROW: Collect row-level data
    BEFORE EACH ROW IS
    BEGIN
        -- Check if DML is allowed
        IF NOT is_dml_allowed THEN
            -- Determine operation type for error message
            IF INSERTING THEN
                g_operation_type := 'INSERT';
            ELSIF UPDATING THEN
                g_operation_type := 'UPDATE';
            ELSE
                g_operation_type := 'DELETE';
            END IF;

            RAISE_APPLICATION_ERROR(-20052, 
                'DML operation denied on STAFF table. ' || get_restriction_message);
        END IF;

        -- Collect row data
        IF INSERTING THEN
            g_inserted_staff.EXTEND;
            g_inserted_staff(g_inserted_staff.COUNT) := staff_rec(
                :NEW.staff_id, :NEW.full_name, :NEW.position, :NEW.contact_number
            );
        ELSIF UPDATING THEN
            g_updated_staff_old.EXTEND;
            g_updated_staff_old(g_updated_staff_old.COUNT) := staff_rec(
                :OLD.staff_id, :OLD.full_name, :OLD.position, :OLD.contact_number
            );

            g_updated_staff_new.EXTEND;
            g_updated_staff_new(g_updated_staff_new.COUNT) := staff_rec(
                :NEW.staff_id, :NEW.full_name, :NEW.position, :NEW.contact_number
            );
        ELSE -- DELETING
            g_deleted_staff.EXTEND;
            g_deleted_staff(g_deleted_staff.COUNT) := staff_rec(
                :OLD.staff_id, :OLD.full_name, :OLD.position, :OLD.contact_number
            );
        END IF;
    END BEFORE EACH ROW;

    -- AFTER STATEMENT: Log all changes in bulk
    AFTER STATEMENT IS
        v_old_values CLOB;
        v_new_values CLOB;
        v_operation VARCHAR2(10);
    BEGIN
        -- Determine operation type
        IF INSERTING THEN
            v_operation := 'INSERT';
            -- Build new values
            FOR i IN 1..g_inserted_staff.COUNT LOOP
                v_new_values := v_new_values || 'Staff ' || i || ': ID=' || 
                              g_inserted_staff(i).staff_id || ', Name=' || 
                              g_inserted_staff(i).full_name || ', Position=' || 
                              g_inserted_staff(i).position || CHR(10);
            END LOOP;

            -- Log successful inserts
            v_dummy := log_dml_audit(
                p_table_name => 'STAFF',
                p_operation_type => v_operation,
                p_old_values => NULL,
                p_new_values => v_new_values,
                p_affected_rows => g_inserted_staff.COUNT,
                p_child_id => NULL
            );

        ELSIF UPDATING THEN
            v_operation := 'UPDATE';
            -- Build old and new values
            FOR i IN 1..g_updated_staff_old.COUNT LOOP
                v_old_values := v_old_values || 'Staff ' || i || ': OLD ID=' || 
                              g_updated_staff_old(i).staff_id || ', Name=' || 
                              g_updated_staff_old(i).full_name || CHR(10);
                v_new_values := v_new_values || 'Staff ' || i || ': NEW ID=' || 
                              g_updated_staff_new(i).staff_id || ', Name=' || 
                              g_updated_staff_new(i).full_name || CHR(10);
            END LOOP;

            -- Log successful updates
            v_dummy := log_dml_audit(
                p_table_name => 'STAFF',
                p_operation_type => v_operation,
                p_old_values => v_old_values,
                p_new_values => v_new_values,
                p_affected_rows => g_updated_staff_old.COUNT,
                p_child_id => NULL
            );

        ELSE -- DELETING
            v_operation := 'DELETE';
            -- Build old values
            FOR i IN 1..g_deleted_staff.COUNT LOOP
                v_old_values := v_old_values || 'Staff ' || i || ': ID=' || 
                              g_deleted_staff(i).staff_id || ', Name=' || 
                              g_deleted_staff(i).full_name || ', Position=' || 
                              g_deleted_staff(i).position || CHR(10);
            END LOOP;

            -- Log successful deletes
            v_dummy := log_dml_audit(
                p_table_name => 'STAFF',
                p_operation_type => v_operation,
                p_old_values => v_old_values,
                p_new_values => NULL,
                p_affected_rows => g_deleted_staff.COUNT,
                p_child_id => NULL
            );
        END IF;

        -- Clear collections
        g_inserted_staff.DELETE;
        g_updated_staff_old.DELETE;
        g_updated_staff_new.DELETE;
        g_deleted_staff.DELETE;

    EXCEPTION
        WHEN OTHERS THEN
            v_dummy := log_dml_audit(
                p_table_name => 'STAFF',
                p_operation_type => v_operation,
                p_old_values => v_old_values,
                p_new_values => v_new_values,
                p_affected_rows => NULL,
                p_child_id => NULL
            );
            RAISE;
    END AFTER STATEMENT;

END trg_staff_dml_compound;




