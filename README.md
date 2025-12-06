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























