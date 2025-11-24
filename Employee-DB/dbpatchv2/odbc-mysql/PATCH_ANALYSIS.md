# Employee Database - Logical Schema Design

**Analysis Date:** November 23, 2025  
**Purpose:** Platform-agnostic database design specification

## Overview

This document describes the logical structure of an Employee Database designed to track employee information, organizational hierarchy, compensation, performance evaluations, and project assignments. The design uses a layered patch approach where each layer builds upon previous ones through explicit dependencies, allowing incremental implementation on any database platform.

## Patch Dependency Structure

The database is built in layers, where each patch layer depends on the completion of previous layers. This allows for safe, incremental deployment and clear separation of concerns.

```
Layer 0: Foundation
└── Create Employees and Departments
    │
    ├── Layer 1: Employee Details (can be deployed in parallel)
    │   ├── Add Employee Roles
    │   ├── Add Salary Tracking
    │   └── Add Leave Management
    │       │
    │       └── Layer 2: Performance Management
    │           └── Add Performance Reviews
    │               │
    │               └── Layer 3: Project Management
    │                   └── Add Projects and Assignments
```

**Key Principles:**
- Each layer must be fully deployed before the next layer can begin
- Within Layer 1, all three patches can be deployed independently and in any order
- Performance reviews require all employee detail systems to be in place
- Project management is the final layer, building on the complete employee system

---

## Layer 0: Foundation - Employees and Departments

**Purpose:** Establish the core organizational structure with employees and departments that have a bidirectional relationship.

**Dependencies:** None (starting point)

### Tables to Create

#### Table: Employee
Stores individual employee information including personal details and contact information.

**Columns:**
- **EmployeeId** (identifier, auto-generated) - Primary key
- **FirstName** (text, up to 50 characters) - Required
- **LastName** (text, up to 50 characters) - Required
- **Email** (text, up to 100 characters) - Optional
- **HireDate** (date) - Required, when employee joined
- **Status** (text, up to 50 characters) - Optional, current employment status
- **StreetAddress** (text, up to 255 characters) - Optional
- **City** (text, up to 100 characters) - Optional
- **State** (text, up to 100 characters) - Optional, or province/region
- **ZipCode** (text, up to 20 characters) - Optional, postal code
- **Country** (text, up to 100 characters) - Optional
- **DepartmentId** (identifier) - Optional foreign key, links to Department

#### Table: Department
Represents organizational departments within the company.

**Columns:**
- **DepartmentId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 100 characters) - Required, department name
- **Description** (text, up to 255 characters) - Optional
- **DepartmentHeadId** (identifier) - Optional foreign key, links to Employee

### Relationships to Create

This layer creates a circular reference between employees and departments:

1. **Employee belongs to Department**
   - Employee.DepartmentId references Department.DepartmentId
   - Optional relationship (employee may not have assigned department initially)

2. **Department has head Employee**
   - Department.DepartmentHeadId references Employee.EmployeeId
   - Optional relationship (department may not have head assigned initially)

### Implementation Notes

**Critical:** The tables must be created before the foreign key constraints are added. This is because the relationships are circular (each table references the other).

**Suggested implementation order:**
1. Create Employee table without the DepartmentId foreign key constraint
2. Create Department table without the DepartmentHeadId foreign key constraint
3. Add foreign key constraint from Department.DepartmentHeadId to Employee.EmployeeId
4. Add foreign key constraint from Employee.DepartmentId to Department.DepartmentId

**Why this design:** 
- Departments can have one employee designated as the department head
- Employees can belong to one department
- This allows tracking both organizational hierarchy and employee assignments
- The optional nature allows flexibility during initial data setup

---

## Layer 1: Employee Details

This layer adds three independent subsystems that extend employee information. All three can be implemented in parallel or in any order.

---

### Layer 1a: Employee Roles

**Purpose:** Classify employees by job roles and titles.

**Dependencies:** Layer 0 (Employees and Departments must exist)

#### Table to Create

**Table: Role**
Defines job roles that can be assigned to employees.

**Columns:**
- **RoleId** (identifier, auto-generated) - Primary key
- **Title** (text, up to 100 characters) - Required, job title
- **Description** (text, up to 255 characters) - Optional, role details

#### Changes to Existing Tables

**Modify Employee table:**
- Add column **RoleId** (identifier) - Foreign key to Role, eventually required

#### Relationships to Create

**Employee has Role:**
- Employee.RoleId references Role.RoleId
- This is a required relationship - every employee must have a role

#### Implementation Notes

**Phased approach required:**
1. Create the Role table
2. Add RoleId column to Employee table as optional (nullable)
3. Create foreign key constraint from Employee.RoleId to Role.RoleId
4. Populate role data and assign roles to existing employees
5. Make RoleId required (non-nullable) on Employee table

**Why this design:**
- Separating roles into their own table allows reuse (multiple employees can have the same role)
- Centralized role management makes it easier to update role information
- Phased implementation allows updating existing employee records before enforcing the requirement

---

### Layer 1b: Salary Tracking

**Purpose:** Track employee compensation history with effective dates and review scheduling.

**Dependencies:** Layer 0 (Employees must exist)

#### Table to Create

**Table: Salary**
Maintains historical salary records for each employee.

**Columns:**
- **SalaryId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **Amount** (decimal number, 10 digits with 2 decimal places) - Required, salary amount
- **EffectiveDate** (date) - Required, when this salary becomes/became effective
- **NextReviewDate** (date) - Optional, when salary should be reviewed next

#### Relationships to Create

**Salary belongs to Employee:**
- Salary.EmployeeId references Employee.EmployeeId
- Required relationship (every salary record must be for a specific employee)

#### Indexes to Create

For query performance, create these indexes:

1. **Index on NextReviewDate**
   - Enables fast queries for upcoming salary reviews
   - Useful for reports showing which salaries need review soon

2. **Composite index on (SalaryId, NextReviewDate)**
   - Optimizes queries that filter by salary ID and check review dates
   - Supports efficient lookups combining both fields

#### Implementation Notes

**Why this design:**
- Maintains complete salary history for each employee (multiple records per employee)
- EffectiveDate allows tracking when salary changes took effect
- NextReviewDate enables proactive salary review scheduling
- Historical tracking supports auditing and compensation analysis

**Data characteristics:**
- One employee can have many salary records over time
- Each salary record is for exactly one employee
- Sample test data is available (salary.csv files)

---

### Layer 1c: Leave Management

**Purpose:** Track employee leave requests and time off.

**Dependencies:** Layer 0 (Employees must exist)

#### Table to Create

**Table: EmployeeLeave**
Records leave requests and absences for employees.

**Columns:**
- **LeaveId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **StartDate** (date) - Required, first day of leave
- **EndDate** (date) - Required, last day of leave
- **LeaveType** (text, up to 50 characters) - Required, type of leave (vacation, sick, etc.)
- **LeaveBalance** (integer) - Optional, remaining leave balance

#### Relationships to Create

**EmployeeLeave belongs to Employee:**
- EmployeeLeave.EmployeeId references Employee.EmployeeId
- Required relationship (every leave record must be for a specific employee)

#### Implementation Notes

**Why this design:**
- Tracks leave periods with explicit start and end dates
- LeaveType categorizes different kinds of leave
- Historical record of all leave taken

**Known design issue:**
- The LeaveBalance column may need to be refactored in a future update
- Currently tracks balance per leave record, which may not be the most logical approach
- Consider moving balance tracking to the Employee level or a separate balance table

**Data characteristics:**
- One employee can have many leave records
- Each leave record covers a specific date range
- Leave types should be consistent across the system (consider using a reference table in production)

---

## Layer 2: Performance Management

**Purpose:** Enable tracking and management of employee performance evaluations.

**Dependencies:** All of Layer 1 must be complete (Employee Roles, Salary Tracking, and Leave Management)

### Why This Dependency Structure

Performance reviews logically require the complete employee picture:
- Employee role context (what responsibilities are being evaluated)
- Salary history (performance often impacts compensation)
- Leave records (attendance and time-off may factor into reviews)

This layer serves as a convergence point where all the employee detail systems come together.

### Table to Create

**Table: PerformanceReview**
Stores performance evaluation records for employees.

**Columns:**
- **ReviewId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **ReviewDate** (date) - Required, when review was conducted
- **PerformanceRating** (integer) - Required, numeric rating score
- **Comments** (text, up to 255 characters) - Optional, reviewer feedback
- **PerformanceGoals** (large text) - Optional, goals set for employee

### Relationships to Create

**PerformanceReview belongs to Employee:**
- PerformanceReview.EmployeeId references Employee.EmployeeId
- Required relationship (every review must be for a specific employee)

### Implementation Notes

**Why this design:**
- Maintains complete review history for each employee
- Standardized rating system using integers
- Flexible text fields for qualitative feedback
- Goals can be tracked over time

**Data characteristics:**
- One employee can have many performance reviews over time
- Each review is for exactly one employee
- Reviews are point-in-time snapshots of performance
- Historic reviews provide trend data for compensation and promotion decisions

---

## Layer 3: Project Management

**Purpose:** Enable tracking of projects and employee assignments to those projects.

**Dependencies:** Layer 2 (Performance Management) must be complete

### Why This Dependency Structure

Project assignments represent the final layer because:
- Projects need fully-detailed employee records (from Layer 0 and Layer 1)
- Assignment decisions may be based on performance history (from Layer 2)
- This ensures employees have complete profiles before being assigned to projects

### Tables to Create

#### Table: Project
Represents projects or initiatives within the organization.

**Columns:**
- **ProjectId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 100 characters) - Required, project name
- **Description** (text, up to 255 characters) - Optional, project details
- **StartDate** (date) - Optional, when project begins
- **EndDate** (date) - Optional, target or actual completion date
- **Budget** (decimal number, 18 digits with 2 decimal places) - Optional, project budget amount

#### Table: EmployeeProjectAssignment
Links employees to projects, creating a many-to-many relationship.

**Columns:**
- **AssignmentId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **ProjectId** (identifier) - Required foreign key to Project
- **AssignedDate** (date) - Required, when employee was assigned to project
- **Role** (text, up to 100 characters) - Optional, employee's role on this specific project

### Relationships to Create

1. **EmployeeProjectAssignment belongs to Employee**
   - EmployeeProjectAssignment.EmployeeId references Employee.EmployeeId
   - Required relationship

2. **EmployeeProjectAssignment belongs to Project**
   - EmployeeProjectAssignment.ProjectId references Project.ProjectId
   - Required relationship

### Implementation Notes

**Why this design:**
- Projects can have multiple employees assigned
- Employees can work on multiple projects simultaneously
- Junction table pattern enables this many-to-many relationship
- Project-specific role differs from employee's general job role (from Layer 1a)
- Assignment dates track when employees joined each project

**Data characteristics:**
- One project can have many employee assignments
- One employee can have many project assignments
- The Role field in EmployeeProjectAssignment is project-specific (e.g., "Team Lead" on one project, "Developer" on another)
- This is separate from the employee's general Role from Layer 1a (their job title in the organization)

**Budget tracking:**
- Budget is tracked at the project level
- Future enhancements could add cost tracking per assignment or time tracking

---

## Complete Database Schema Summary

After all layers are implemented, the database contains the following entities and relationships:

### Tables (8 total)

1. **Employee** - Core employee information with personal details and address
2. **Department** - Organizational departments
3. **Role** - Job roles and titles
4. **Salary** - Historical salary records
5. **EmployeeLeave** - Leave requests and time off
6. **PerformanceReview** - Performance evaluation records
7. **Project** - Projects and initiatives
8. **EmployeeProjectAssignment** - Links employees to projects

### Relationships (9 total)

1. Employee → Department (employee belongs to department)
2. Department → Employee (department has head employee)
3. Employee → Role (employee has role)
4. Salary → Employee (salary record for employee)
5. EmployeeLeave → Employee (leave record for employee)
6. PerformanceReview → Employee (review for employee)
7. EmployeeProjectAssignment → Employee (assignment for employee)
8. EmployeeProjectAssignment → Project (assignment for project)

### Indexes (2 total)

Performance optimization indexes on the Salary table:
1. Index on NextReviewDate - for review scheduling queries
2. Composite index on (SalaryId, NextReviewDate) - for combined lookups

### Data Operations

The system includes comprehensive Create, Read, Update, and Delete (CRUD) operations for all tables. These operations enable:
- Creating new records
- Retrieving existing records
- Updating record information
- Deleting records when needed

Each entity has these operations implemented in multiple versions, providing flexibility in implementation approach.

---

## Database Design Patterns

### Pattern: Circular Reference (Layer 0)
Employees belong to departments, and departments have employee heads. This creates an intentional circular reference that requires careful implementation order (create tables first, then add constraints).

### Pattern: Historical Tracking (Layer 1b, Layer 2)
Both Salary and PerformanceReview tables maintain historical records over time. This allows tracking changes and trends rather than just current state.

### Pattern: Phased Column Addition (Layer 1a)
The RoleId column is added to Employee in phases: first as optional, then made required after data population. This enables safe migration of existing data.

### Pattern: Junction Table (Layer 3)
EmployeeProjectAssignment serves as a junction table implementing a many-to-many relationship between employees and projects.

### Pattern: Deferred Constraints (Layer 0)
Foreign key constraints are added after table creation, allowing tables with circular dependencies to be created successfully.

---

## Implementation Guidance

### Deployment Sequence

Follow this order when implementing the database:

**Phase 1 - Foundation:**
1. Create Employee table (without foreign keys)
2. Create Department table (without foreign keys)
3. Add Department → Employee foreign key
4. Add Employee → Department foreign key

**Phase 2 - Employee Details (parallel):**
5. Create Role table, add RoleId to Employee, create constraint, make RoleId required
6. Create Salary table with foreign key, add indexes
7. Create EmployeeLeave table with foreign key

**Phase 3 - Performance:**
8. Create PerformanceReview table with foreign key

**Phase 4 - Projects:**
9. Create Project table
10. Create EmployeeProjectAssignment table with foreign keys

**Phase 5 - Operations:**
11. Implement CRUD operations for all tables

### Platform Translation Guidelines

When implementing on a specific database platform, translate these concepts:

**Identifiers (auto-generated):**
- SQL Server: Use `INT IDENTITY(1,1)`
- MySQL: Use `INT AUTO_INCREMENT`
- PostgreSQL: Use `SERIAL` or `IDENTITY`
- Oracle: Use `NUMBER` with sequence and trigger

**Text fields:**
- Map "text up to X characters" to `VARCHAR(X)` or platform equivalent
- Map "large text" to `TEXT`, `CLOB`, or `VARCHAR(MAX)` depending on platform

**Decimal numbers:**
- Use `DECIMAL(precision, scale)` or platform equivalent
- Salary amounts: `DECIMAL(10, 2)` - up to 99,999,999.99
- Budget amounts: `DECIMAL(18, 2)` - up to 9,999,999,999,999,999.99

**Dates:**
- Use `DATE` type or platform equivalent
- Consider using `DATETIME` or `TIMESTAMP` if time-of-day is needed

**Required vs Optional:**
- Required fields: Add `NOT NULL` constraint
- Optional fields: Allow `NULL` values

**Foreign keys:**
- Implement using platform's foreign key constraint syntax
- Consider adding indexes on foreign key columns for query performance
- Decide on cascade delete/update behavior based on business rules

### Considerations for Production Use

**Missing features to consider adding:**

1. **Audit fields** - Add to all tables:
   - CreatedDate (when record was created)
   - CreatedBy (who created the record)
   - ModifiedDate (when last updated)
   - ModifiedBy (who last updated)

2. **Soft delete** - Instead of deleting records:
   - Add IsDeleted flag
   - Add DeletedDate and DeletedBy fields
   - Filter deleted records in queries

3. **Concurrency control:**
   - Add RowVersion or Timestamp field
   - Prevents lost updates in multi-user scenarios

4. **Additional indexes:**
   - Consider indexes on frequently queried fields
   - Index foreign key columns if not automatically indexed
   - Common queries: Employee by LastName, Department by Name

5. **LeaveBalance refactoring:**
   - Move to Employee table or separate EmployeeLeaveBalance table
   - Track current balance rather than per-leave-record

6. **Reference data:**
   - Consider creating LeaveType reference table instead of free text
   - Consider creating Status reference table for Employee.Status

---

## Logical Data Flow Examples

### Hiring a New Employee

1. Create Department record (if new department)
2. Create Role record (if new role needed)
3. Create Employee record with FirstName, LastName, HireDate, DepartmentId, RoleId
4. Create initial Salary record with Amount and EffectiveDate
5. Optionally assign to Project via EmployeeProjectAssignment

### Conducting Performance Review

1. Employee must exist with Department and Role assigned
2. Salary history should exist
3. Leave history is available
4. Create PerformanceReview record with ReviewDate, Rating, Comments, Goals
5. Potentially create new Salary record if review results in raise

### Starting a New Project

1. Create Project record with Name, Description, Budget, StartDate
2. For each team member:
   - Create EmployeeProjectAssignment record
   - Specify employee's Role on project
   - Set AssignedDate

### Tracking Employee Leave

1. Employee requests time off
2. Create EmployeeLeave record with StartDate, EndDate, LeaveType
3. Record is maintained in history
4. May be referenced during performance reviews
