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

### 1. Open Project
- Open **Oracle SQL Developer**

- All SQL scripts are in `database/scripts/`.

### 2. Create the Pluggable Database (PDB)

```sql
-- Run the PDB creation script
@database/scripts/create_pdb.sql

-- Execute table creation scripts
@database/scripts/create_tables.sql

-- Populate tables with example data
@database/scripts/insert_data.sql

-- Execute PL/SQL procedures
@database/scripts/procedures.sql

-- Execute PL/SQL functions
@database/scripts/functions.sql

-- Execute PL/SQL packages
@database/scripts/packages.sql

-- Implement triggers 
@database/scripts/triggers.sql 























