# Ormico Database Examples

Example databases demonstrating patch-based schema migration patterns across multiple database platforms. These examples are designed to test and validate database migration tools (dbpatch v2 and v3) by providing realistic, progressively complex database schemas with comprehensive documentation.

## Purpose

This repository serves as:
- **Reference implementations** of database design patterns
- **Test cases** for cross-platform database migration tools
- **Reproduction specifications** enabling database recreation across MySQL, SQL Server, PostgreSQL, and other platforms
- **Development scenarios** showing collaborative, incremental database evolution

## Repository Structure

Each example database includes:
- **Platform-agnostic specifications** - Logical schema designs that can be implemented on any database
- **Platform-specific implementations** - Actual database code for MySQL, SQL Server, PostgreSQL, etc.
- **Development scenarios** - Collaborative stories showing how the database evolved through team decisions
- **Multiple versions** - Implementations using both dbpatch v2 and v3 migration frameworks

## Current Examples

### Employee Database

A comprehensive employee management system demonstrating layered schema evolution through 8 patch layers.

**Current implementations:**
- [MySQL - DB Patch v2 with ODBC](Employee-DB/dbpatchv2/odbc-mysql/README.md) (Layers 0-3 implemented)

**Planned implementations:**
- MySQL - DB Patch v3
- SQL Server - DB Patch v2 and v3
- PostgreSQL - DB Patch v2 and v3

**Features across layers:**
- Layer 0: Foundation (Employee, Department)
- Layer 1: Employee details (Roles, Salary, Leave tracking)
- Layer 2: Performance reviews
- Layer 3: Project management
- Layer 4: Technical debt cleanup (reference tables)
- Layer 5: Soft delete pattern
- Layer 6: Teams and management hierarchy
- Layer 7: Skills tracking

**Known design decisions:**
- LeaveBalance column location (Layer 1c) is intentional technical debt, addressed in Layer 4
- Circular reference between Employee and Department demonstrates constraint ordering
- Phased migrations show safe production deployment patterns

See [SCHEMA_DESIGN.md](Employee-DB/dbpatchv2/odbc-mysql/SCHEMA_DESIGN.md) for technical specifications and [DEVELOPMENT_SCENARIO.md](Employee-DB/dbpatchv2/odbc-mysql/DEVELOPMENT_SCENARIO.md) for the collaborative development story.

![Employee Database ERD](Employee-DB/dbpatchv2/odbc-mysql/docs/employee-db-mysql.png)

## Future Examples

Additional database examples are planned to demonstrate different design patterns and migration scenarios:
- E-commerce database (product catalog, orders, inventory)
- Healthcare records (patients, appointments, medical history)
- Educational system (students, courses, enrollments, grades)

## Usage

These examples can be used to:
1. **Learn database design patterns** - Study the documented design decisions and evolution
2. **Test migration tools** - Reproduce databases across platforms using dbpatch v2 and v3
3. **Validate cross-platform compatibility** - Compare implementations across MySQL, SQL Server, PostgreSQL
4. **Practice incremental deployment** - Follow the layered patch approach for safe schema evolution