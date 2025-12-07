# 📘 Design Decisions – Children Welfare Management System

This document explains the major technical and architectural decisions made while implementing the Children Welfare Management System across all 8 project phases. Each decision was made to satisfy performance, security, PL/SQL functionality, BI requirements, and Oracle best practices.

---

## 1. Choice of System Architecture
- The system uses a **modular relational database** separating children, education, services, and staff data.  
- Oracle was selected because it supports:
  - Identity columns for automatic IDs  
  - Advanced PL/SQL features  
  - Strong security (roles, auditing)  
  - BI-friendly analytical functions  
- Tablespaces were separated (`tw_data` for data, `tw_index` for indexes) for performance.

---

## 2. Table Design Decisions
### a. Normalized Structure (3NF)
- Each major entity (children, staff, sections, education, support services) was separated into its own table.
- No repeating groups.  
- No multi-valued attributes.  
- Foreign keys enforce relationships.

### b. Column & Constraint Decisions
- `gender` uses a CHECK constraint (`Male`, `Female`) for data consistency.  
- `disability_status` restricted to `Yes/No` for clean analytics.  
- Used **VARCHAR2** for text fields to support flexible input.  
- Automatically generated primary keys using **IDENTITY** for stability and simplicity.  

---

## 3. Indexing Strategy
Indexes were added for **all foreign keys** to speed up joins:

- `idx_children_section` → speeds child–section lookups  
- `idx_edu_child` → speeds child–education queries  
- `idx_service_child` and `idx_service_staff` → speeds service history retrieval  

Reason:
- Dashboards and analytics use JOINs heavily.  
- Indexes reduce full table scans.

---

## 4. Referential Integrity Decisions
- All foreign keys use **ON DELETE RESTRICT** (default) to prevent accidental orphaned records.  
- This preserves historical data for audits and BI.

---

## 5. PL/SQL Logic Decisions
### a. Procedures & Functions
- CRUD operations use parameterized procedures for:
  - reusability  
  - security  
  - consistent validation  
- Functions used to:
  - calculate child age  
  - validate disability status  
  - lookup education progress  

### b. Packages
- Related procedures grouped into packages for modular structure and maintainability.

### c. Exception Handling
- Custom exceptions used for:
  - missing child records  
  - invalid staff-service assignments  
- All exceptions logged to an audit table (Phase VII requirement).

---

## 6. Trigger Design Decisions
- Triggers block INSERT/UPDATE/DELETE on:
  - Weekdays  
  - Public holidays  
- Simple triggers used for basic row-level enforcement.  
- Compound triggers used where multi-step validations are required.

Reason:
- Required by instructor  
- Ensures strict compliance with orphanage record management rules.

---

## 7. Business Intelligence (BI) Design Decisions
### a. KPI Selection
KPIs chosen because they directly support management decisions:
- Total children by section  
- Children with disabilities  
- Service frequency & staff workload  
- Education performance distribution  
- Monthly service trends  

### b. Dashboard Layout Choices
- Executive dashboard: high-level KPIs  
- Audit dashboard: violations, holiday restrictions, staff actions  
- Performance dashboard: service patterns & education trends  

### c. Data Structure for BI
- Tables designed to support analytical queries using:
  - `ROW_NUMBER()`, `LAG()`, `LEAD()`  
  - Aggregations (COUNT, AVG)  
  - Partitions (child, section, staff)  

---

## 8. Security & Auditing Decisions
- Dedicated **audit_log** table (Phase VII).  
- Every DML attempt (allowed or denied) recorded with:
  - user  
  - timestamp  
  - operation type  
  - status (ALLOWED/DENIED)  
  - reason  

Reason:
- Requirement for advanced PL/SQL  
- Enhances system transparency  
- Supports compliance reporting

---

## 9. Scalability & Extensibility
- Tables were structured so system can later include:
  - health module  
  - nutrition module  
  - sponsorship module  
- Child ID serves as a universal link across all future modules.

---

## 10. Data Quality & Validation Rules
- Mandatory fields (name, DOB, section) enforce completeness.  
- CHECK constraints ensure data stays clean for BI reporting.  
- Default values (e.g., `service_date = SYSDATE`) ensure consistency.

---

## 11. Naming Conventions
- All tables use singular nouns (`child`, `staff`, `education`).  
- All constraints follow:  
  - `pk_` for primary keys  
  - `fk_` for foreign keys  
  - `idx_` for indexes  

Reason:
- Improves readability  
- Matches Oracle best practices  
- Professional GitHub documentation

---




