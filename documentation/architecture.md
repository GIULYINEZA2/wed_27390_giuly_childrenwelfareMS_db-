# System Architecture – Children Welfare Management System

## 1. Overview
The Children Welfare Management System (CWMS) uses a layered, modular Oracle-based architecture designed for secure data storage, efficient processing, and scalable reporting.  
It separates database logic, application logic, and presentation logic to ensure maintainability and future extensibility (health, nutrition, sponsorship modules).

---

## 2. Architectural Layers

### **2.1 Presentation Layer**
This is the user-facing interface where administrators and staff interact with the system.

- Oracle SQL Developer (used for data entry, queries, validations)
- BI Dashboard tools (Power BI / Tableau mockups)
- PL/SQL Developer (for executing stored procedures)

**Responsibilities**
- Data entry (child registration, staff, services)
- Running reports and dashboard visualizations
- Viewing audit logs and performance summaries

---

### **2.2 Application/Logic Layer (PL/SQL Layer)**
All business logic is implemented in Oracle PL/SQL packages, procedures, functions, and triggers.

**Core Responsibilities**
- Data validation
- Automated operations
- Enforcement of business rules
- Transaction management
- Error handling and audit logging

**Components**
- **Procedures:** For inserting/updating child records, education, staff, services  
- **Functions:** For lookups, validation logic, computing ages, counting services  
- **Packages:** Group related procedures and functions  
- **Triggers:**  
  - Restrict INSERT/UPDATE/DELETE on weekdays and holidays  
  - Auto-assign sections  
  - Log audit events  

---

## 3. Data Layer (Oracle Database)

### **3.1 Physical Database Structure**
The database consists of one pluggable database configured as:

- **Data Tablespace:** `tw_data`
- **Index Tablespace:** `tw_index`
- **Admin User:** `giuly_admin`
- **Storage Features:** autoextend enabled, archivelog enabled

### **3.2 Core Tables**
| Table | Purpose |
|-------|---------|
| **SECTIONS** | Stores all sections (e.g., Early Age, Youth Section, Disability Care) |
| **CHILDREN** | Main profile of children under 18 |
| **EDUCATION** | School records, grades, and performance notes |
| **STAFF** | Staff profiles and positions |
| **SUPPORT_SERVICES** | Services provided to each child (counselling, medical aid, tutoring) |

---

## 4. System Workflow Architecture

### **4.1 Data Flow**
1. **Administrator/Staff enters data**  
   → Through SQL Developer or forms  
2. **PL/SQL procedures validate data**  
   → Check correct age, gender, section, staff/child relationships  
3. **Triggers enforce rules**  
   → Example: block actions on weekdays or holidays  
4. **Data stored in the Oracle tables**  
   → With FK constraints ensuring relational integrity  
5. **BI Layer aggregates data**  
   → KPIs like number of children, services provided, performance distribution  
6. **Dashboards visualize insights**  
   → Executive, audit, and performance dashboards  

---

## 5. Security Architecture

### **5.1 Role-Based Access (RBA)**
- **ADMIN ROLE**  
  - Full privileges (DDL, DML, auditing)  
- **STAFF ROLE**  
  - Limited privileges (insert services, view children)  

### **5.2 Business Rule Enforcement**
- No INSERT/UPDATE/DELETE on weekdays  
- No modifications on public holidays  
- All actions logged in **AUDIT_LOG** table  

### **5.3 Error Handling & Logging**
PL/SQL packages automatically:
- Capture errors
- Insert logs into audit tables
- Record user, timestamp, attempted action, and result

---

## 6. BI & Reporting Architecture

### **6.1 Fact & Dimension Design**
- **Fact Table:** SUPPORT_SERVICES (measurable events)
- **Dimensions:** CHILDREN, STAFF, SECTIONS, EDUCATION

### **6.2 KPIs Calculated**
- Total children by gender/disability
- Services provided per child
- Staff performance
- Education grade trends
- Section population distribution

### **6.3 Reporting Frequency**
- Daily operations reports
- Weekly performance reports
- Monthly welfare summaries

---

## 7. Scalability & Future Expansion

The system is designed for expansion:
- Health module (medical check-ups + vaccination tracking)
- Nutrition module (meal plans, feeding records)
- Sponsorship module (donor–child relationship tracking)
- REST API integration layer
- Mobile application UI

The modular data model supports horizontal growth without redesign.

---

## 8. Architecture Diagram (Conceptual)
                          CHILDREN WELFARE MANAGEMENT SYSTEM
--------------------------------------------------------------------------------

                                   [ USERS ]
        (Admin, Staff, Case Workers, Supervisors, System Auditor)

                                         |
                                         v
--------------------------------------------------------------------------------
                           PRESENTATION / CLIENT LAYER
--------------------------------------------------------------------------------
  • Oracle SQL Developer  
  • SQL*Plus  
  • Optional UI: Oracle APEX  
  • Dashboards (Executive, Audit, Performance)

  Responsibilities:
  - Capturing user input  
  - Displaying results and reports  
  - Sending requests to PL/SQL layer  
                                         |
                                         v
--------------------------------------------------------------------------------
                         APPLICATION / LOGIC (PL/SQL) LAYER
--------------------------------------------------------------------------------
  • Stored Procedures  
  • Functions  
  • Packages  
  • Triggers  
  • Cursors / Bulk Processing  
  • Validation Routines  
  • Exception Handling  
  • Transaction Control (COMMIT / ROLLBACK)

  Responsibilities:
  - Apply business rules  
  - Validate operations  
  - Audit restricted actions  
  - Manage data workflows  
                                         |
                                         v
--------------------------------------------------------------------------------
                                  DATA LAYER
                           (Oracle Database Objects)
--------------------------------------------------------------------------------
  • Tablespaces  
       - tw_data  
       - tw_index  

  • Core Tables  
       - children  
       - sections  
       - education  
       - staff  
       - support_services  
       - audit_log  

  • Indexes (performance optimization)  
  • Sequences / Identity columns  
  • Constraints (PK, FK, CHECK, NOT NULL)  
  • Views for reporting (optional)

--------------------------------------------------------------------------------
                                       DATA FLOW
--------------------------------------------------------------------------------
  1. User sends request (SQL/APEX)  
  2. PL/SQL layer processes logic + triggers  
  3. Database stores/retrieves data  
  4. Results returned to user interface  
  5. Dashboards visualize KPIs, trends, violations  
--------------------------------------------------------------------------------


---

## 8. Justification of Architecture
- **Modular** → Separation of data, logic, and presentation
- **Secure** → Role-based access & auditing triggers
- **Scalable** → New modules (health, nutrition) can be added easily
- **Performance Optimized** → Indexes + bulk operations
- **Reliable** → Enforced constraints ensure high data quality

---

# End of Architecture Documentation

