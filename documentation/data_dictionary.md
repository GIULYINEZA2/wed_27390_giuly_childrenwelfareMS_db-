## Table: CHILDREN
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| child_id | NUMBER(10) | PK, NOT NULL | Unique child identifier |
| full_name | VARCHAR2(100) | NOT NULL | Child's full name |
| date_of_birth | DATE | NOT NULL | Date of birth |
| gender | VARCHAR2(10) | CHECK ('Male','Female') | Gender |
| disability_status | VARCHAR2(3) | DEFAULT 'No', CHECK ('Yes','No') | Disability indicator |
| section_id | NUMBER(10) | FK → SECTIONS | Assigned section |
| created_date | DATE | DEFAULT SYSDATE | Record creation date |

## Table: STAFF
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| staff_id | NUMBER(10) | PK, NOT NULL | Unique staff identifier |
| full_name | VARCHAR2(100) | NOT NULL | Staff member's full name |
| position | VARCHAR2(50) | NOT NULL | Job title/position |
| department | VARCHAR2(50) | | Department assignment |
| hire_date | DATE | DEFAULT SYSDATE | Date hired |
| email | VARCHAR2(100) | UNIQUE | Contact email |
| phone_number | VARCHAR2(15) | | Contact phone |
| status | VARCHAR2(20) | DEFAULT 'Active', CHECK ('Active','Inactive','On Leave') | Employment status |

## Table: SECTIONS
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| section_id | NUMBER(10) | PK, NOT NULL | Unique section identifier |
| section_name | VARCHAR2(50) | NOT NULL, UNIQUE | Name of the section/unit |
| description | VARCHAR2(200) | | Description of section |
| capacity | NUMBER(3) | CHECK (capacity > 0) | Maximum children capacity |
| current_count | NUMBER(3) | DEFAULT 0 | Current number of children |
| supervisor_id | NUMBER(10) | FK → STAFF | Staff supervisor |
| created_date | DATE | DEFAULT SYSDATE | Creation date |

## Table: EDUCATION
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| education_id | NUMBER(10) | PK, NOT NULL | Unique education record identifier |
| child_id | NUMBER(10) | FK → CHILDREN, NOT NULL | Child reference |
| school_name | VARCHAR2(100) | NOT NULL | Name of school/institution |
| grade_level | VARCHAR2(30) | | Current grade/level |
| performance_notes | VARCHAR2(500) | | Academic performance notes |
| enrollment_date | DATE | DEFAULT SYSDATE | Date of enrollment |
| last_updated | DATE | DEFAULT SYSDATE | Last update timestamp |

## Table: SUPPORT_SERVICES
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| service_id | NUMBER(10) | PK, NOT NULL | Unique service identifier |
| service_type | VARCHAR2(50) | NOT NULL | Type of service (Medical, Psychological, etc.) |
| description | VARCHAR2(500) | | Service details |
| child_id | NUMBER(10) | FK → CHILDREN | Child receiving service |
| staff_id | NUMBER(10) | FK → STAFF | Staff providing service |
| service_date | DATE | DEFAULT SYSDATE | Service date |
| duration_minutes | NUMBER(4) | CHECK (duration_minutes > 0) | Service duration in minutes |
| status | VARCHAR2(20) | DEFAULT 'Completed', CHECK ('Scheduled','Completed','Cancelled') | Service status |
| created_date | DATE | DEFAULT SYSDATE | Record creation date |

## Table: HOLIDAYS
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| holiday_id | NUMBER(10) | PK, NOT NULL | Unique holiday identifier |
| holiday_date | DATE | NOT NULL, UNIQUE | Date of the holiday |
| holiday_name | VARCHAR2(100) | NOT NULL | Name of the holiday |
| holiday_type | VARCHAR2(30) | DEFAULT 'Public', CHECK ('Public','Religious','National') | Type of holiday |
| is_recurring | VARCHAR2(1) | DEFAULT 'Y', CHECK ('Y','N') | Recurring holiday flag |
| description | VARCHAR2(200) | | Holiday description |
| created_date | DATE | DEFAULT SYSDATE | Creation date |

## Table: DML_AUDIT_LOG
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| audit_id | NUMBER(10) | PK, NOT NULL | Unique audit log identifier |
| table_name | VARCHAR2(50) | NOT NULL | Name of the table modified |
| operation_type | VARCHAR2(6) | CHECK ('INSERT','UPDATE','DELETE','CHECK') | Type of DML operation |
| user_name | VARCHAR2(100) | DEFAULT USER | User who performed operation |
| operation_timestamp | TIMESTAMP | DEFAULT SYSTIMESTAMP | Time of operation |
| old_values | CLOB | | Previous values (for UPDATE/DELETE) |
| new_values | CLOB | | New values (for INSERT/UPDATE) |
| affected_rows | NUMBER | | Number of rows affected |
| operation_status | VARCHAR2(10) | CHECK ('SUCCESS','DENIED','ERROR') | Success/failure status |
| error_message | VARCHAR2(1000) | | Error message if failed |
| business_rule_violated | VARCHAR2(200) | | Business rule that was violated |
| child_id | NUMBER(10) | FK → CHILDREN | Related child (if applicable) |
| staff_id | NUMBER(10) | FK → STAFF | Related staff (if applicable) |

## Table: ERROR_LOG
| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| error_id | NUMBER(10) | PK, NOT NULL | Unique error identifier |
| procedure_name | VARCHAR2(100) | | Name of procedure/function that errored |
| error_code | NUMBER | | Oracle/SQL error code |
| error_message | VARCHAR2(1000) | NOT NULL | Error description |
| child_id | NUMBER(10) | FK → CHILDREN | Related child (if applicable) |
| error_date | DATE | DEFAULT SYSDATE | Date/time error occurred |
| user_name | VARCHAR2(100) | DEFAULT USER | User who encountered error |
| stack_trace | CLOB | | Complete error stack trace |

## Table Relationships Summary
1. **CHILDREN → SECTIONS** (Many-to-One)
2. **CHILDREN → EDUCATION** (One-to-Many)
3. **CHILDREN → SUPPORT_SERVICES** (One-to-Many)
4. **STAFF → SUPPORT_SERVICES** (One-to-Many)
5. **STAFF → SECTIONS** (One-to-One for supervisor)
6. **DML_AUDIT_LOG** references **CHILDREN** and **STAFF**
