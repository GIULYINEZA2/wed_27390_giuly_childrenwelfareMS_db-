## Children Welfare Management System

**Student Name:** NDAYISHIMIYE INEZA GIULY  
**Student ID:** 27390  
**Course:** Database Development with PL/SQL (INSY 8311)  
**Institution:** Adventist University of Central Africa (AUCA)  
**Academic Year:** 2025-2026 | Semester I  
**Project Completion Date:** December 7, 2025  
**Lecturer:** Eric Maniraguha 

---

## Project Overview

The **Children Welfare Management System (CWMS)** is a PL/SQL-based Oracle system for managing children under 18 in orphanages. It centralizes child records, monitors educational progress, and tracks support services, especially for children with disabilities. The system replaces manual record-keeping with automated, accurate, and secure data management.

---

## Problem Statement

Manual record-keeping in orphanages is prone to errors, inconsistent updates, and inefficient reporting. There is a need for a secure, automated system that ensures accurate tracking of child welfare, education, and support services.

---

## Key Objectives

- Improve accuracy of child records and documentation  
- Track children’s welfare and educational progress  
- Provide effective support for children with special needs  
- Enhance coordination and accountability among staff  
- Generate automated reports for decision-making  

---

## Key Features

- Child registration and disability classification  
- Education tracking  
- Monitoring of support services  
- Staff involvement tracking  
- Centralized secure database with automated reporting


## PHASE II: Business Process Modeling

###  Objective
Model the real-life business processes that the *Children Welfare Management System (CWMS)* automates, based on the actual database entities:
- SECTIONS  
- CHILDREN  
- EDUCATION  
- STAFF  
- SUPPORT_SERVICES  

---

### 1. Define Scope

The CWMS manages all welfare-related processes for children under 18 in an orphanage.  
The system automates:

- Child registration  
- Disability classification  
- Section assignment  
- Education tracking  
- Support services provided by staff  
- Staff activity monitoring  
- Report generation for decision-making  

**MIS Relevance:**  
The process demonstrates how PL/SQL stored procedures, triggers, and tables replace manual registers with an automated, reliable system.

---

### 2. Identify Key Entities & Actors

###  Users / Actors
- Social Workers (register children, update welfare information)  
- Education Officers (enter school progress)  
- Support Staff (record services offered)  
- System Administrator (manage users, verify records, generate reports)  

###  Departments Involved
- Child Welfare Unit  
- Education Unit  
- Support/Medical Services  
- Administration  

###  Data Sources
- Registration forms  
- Education/progress reports  
- Support service logs  
- Staff activity reports  

### Roles & Responsibilities
- **Social Workers** → Create children records, update disability status, assign sections  
- **Education Officers** → Maintain EDUCATION table  
- **Support Staff** → Insert into SUPPORT_SERVICES table  
- **Admin** → Approve records, view summaries, generate reports  

---

### 3. Business Process Diagram (Swimlanes)


![Business Process Diagram](https://github.com/GIULYINEZA2/wed_27390_giuly_childrenwelfareMS_db-/blob/976d1576b88e4866c87f0c04503e63bf605d433e/screenshots/BPMN.png)


### 4. BPMN/UML Notations Used

- **Start Event** → Green circle  
- **End Event** → Red circle  
- **Task** → Rounded rectangle  
- **Decision (Gateway)** → Diamond  
- **Swimlanes** → Social Worker, Education Officer, Support Staff, Admin  
- **Data Objects** → Represent CHILDREN, EDUCATION, STAFF, SUPPORT_SERVICES tables  
- **Arrows** → Flow between tasks  

---

### 5. Logical Process Flow

1. Start → Child arrives at the orphanage  
2. Social Worker registers the child (CHILDREN table)  
3. Trigger assigns child to section (SECTIONS table) based on disability  
4. Education Officer enters school details (EDUCATION table)  
5. Support Staff logs services provided (SUPPORT_SERVICES table)  
6. Admin reviews data and validates entries  
7. System stores and updates dashboards  
8. End → Reports available for management  

---

##  Phase III: Logical Model Design  
### Entity–Relationship (ER) Model

![Entity Relationship Diagram](https://github.com/GIULYINEZA2/wed_27390_giuly_childrenwelfareMS_db-/blob/5a99f73691e182fdcc3f28073cb61ae000e2e713/screenshots/ERD.png)
---

### 1️ Entities, Attributes, Data Types, and Keys

###  **sections**
| Attribute     | Data Type       | Key / Constraint |
|---------------|------------------|------------------|
| section_id    | NUMBER           | Primary Key (PK) |
| section_name  | VARCHAR2(50)     | NOT NULL, UNIQUE |

---

###  **children**
| Attribute         | Data Type        | Key / Constraint |
|------------------|-------------------|------------------|
| child_id         | NUMBER            | Primary Key (PK) |
| full_name        | VARCHAR2(100)     | NOT NULL |
| date_of_birth    | DATE              | NOT NULL |
| gender           | VARCHAR2(10)      | CHECK (gender IN ('Male','Female')) |
| disability_status| VARCHAR2(3)       | CHECK (disability_status IN ('Yes','No')) |
| section_id       | NUMBER            | Foreign Key (FK → sections.section_id) |

---

###  **education**
| Attribute        | Data Type        | Key / Constraint |
|------------------|-------------------|------------------|
| education_id     | NUMBER            | Primary Key (PK) |
| child_id         | NUMBER            | Foreign Key (FK → children.child_id) |
| school_name      | VARCHAR2(100)     | NOT NULL |
| grade_level      | VARCHAR2(30)      |  |
| performance_notes| VARCHAR2(200)     |  |

---

###  **staff**
| Attribute      | Data Type        | Key / Constraint |
|----------------|-------------------|------------------|
| staff_id       | NUMBER            | Primary Key (PK) |
| full_name      | VARCHAR2(100)     | NOT NULL |
| position       | VARCHAR2(50)      | NOT NULL |
| contact_number | VARCHAR2(15)      | UNIQUE |

---

###  **support_services**
| Attribute      | Data Type         | Key / Constraint |
|----------------|--------------------|------------------|
| service_id     | NUMBER             | Primary Key (PK) |
| service_type   | VARCHAR2(50)       | NOT NULL |
| description    | VARCHAR2(200)      |  |
| child_id       | NUMBER             | Foreign Key (FK → children.child_id) |
| staff_id       | NUMBER             | Foreign Key (FK → staff.staff_id) |
| service_date   | DATE               | DEFAULT SYSDATE |

---

### 2️ Relationships & Constraints

| Relationship | Type | Description |
|-------------|------|-------------|
| Section → Children | 1:M | One section contains many children |
| Child → Education  | 1:1 | Each child has one education record |
| Child → Support Services | 1:M | A child can receive many services |
| Staff → Support Services | 1:M | Staff can serve many children |

###  **Constraints Used**
- **NOT NULL** → essential fields (child name, gender, staff name…)  
- **UNIQUE** → section_name, staff.contact_number  
- **CHECK** → gender, disability_status  
- **DEFAULT** → service_date = SYSDATE  

---

###  Normalization (Up to 3NF)

| Normal Form | How Achieved |
|-------------|--------------|
| **1NF** | No repeating groups; all values are atomic |
| **2NF** | All non-key attributes fully depend on PK |
| **3NF** | No transitive dependencies |

###  Result:  
All tables are fully normalized to **Third Normal Form (3NF)**.

---

###  Why 3NF?  
Using **3NF** helps to:

- Reduce redundancy  
- Keep each table focused → *single purpose*  
- Strengthen relationships using proper FK constraints  
- Make the system easier to maintain, scale, and report on  

---

### 4️ Handling Data Scenarios

Your model supports:

- Assigning each child to a section  
- Handling disability vs non-disability children  
- Tracking school and grade information  
- Multiple services per child  
- Staff–child assignment for services  
- Audit control via triggers (e.g., block inserts on holidays)  
- Using procedures/packages to generate reports  

---


## Quick Start

Follow these steps to set up and run the **Children Welfare Management System** locally:

### 1. Open Your Project 

- Open **Oracle SQL Developer**   


- All SQL scripts are in `database/scripts/`.

---

### 2. Create the Database (PDB)

- Open and run: [create_pdb.sql](database/scripts/create_pdb.sql)  

> This creates the main database for your system.

---

### 3. Create Tables

- Open and run: [create_tables.sql](database/scripts/create_tables.sql)  

> Creates all tables like `CHILDREN`, `EDUCATION`, `SUPPORT_SERVICES`, etc.

---

### 4. Insert Sample Data

- Open and run: [insert_data.sql](database/scripts/insert_data.sql)  

> Adds example children, education records, and support services.

---

### 5. Run Functions

- Open and run: [functions.sql](database/scripts/functions.sql)  

> Functions perform calculations, validations, and lookups.

---

### 6. Run Cursors

- Open and run: [cursors.sql](database/scripts/cursors.sql)  

> Cursors handle multi-row processing and optimized data retrieval.

---

### 7. Run Packages

- Open and run: [packages.sql](database/scripts/packages.sql)  

> Packages group related procedures and functions for automation.

---

### 8. Run Triggers

- Open and run: [triggers.sql](database/scripts/triggers.sql)  

> Triggers track changes and log actions automatically for auditing.

---

## Documentation

You can find detailed documentation for the project in the following files:

- [Data Dictionary](documentation/data_dictionary.md) – Details of all tables, columns, types, and constraints.
- [Architecture](documentation/architecture.md) – Overview of the system design and database structure.
- [Design Decisions](documentation/design_decisions.md) – Explanation of key design choices made during development.
- [BI Requirements](business_intelligence/bi_requirements.md) – KPIs, dashboards, and analytical queries.
- [Dashboards](business_intelligence/dashboards.md) – Mockups of BI dashboards.
- [KPI Definitions](business_intelligence/kpi_definitions.md) – Detailed description of KPIs used in the system.























