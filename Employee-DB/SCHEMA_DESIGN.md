# Employee Database - Logical Schema Design

**Analysis Date:** November 23, 2025  
**Purpose:** Platform-agnostic database design specification

> **📖 Companion Document:** This document provides technical specifications and implementation details.  
> For collaborative development context, team stories, and lessons learned, see [SCENARIO.md](SCENARIO.md).

## Overview

This document describes the logical structure of an Employee Database designed to track employee information, organizational hierarchy, compensation, performance evaluations, and project assignments. The design uses a layered patch approach where each layer builds upon previous ones through explicit dependencies, allowing incremental implementation on any database platform.

## Patch Dependency Structure

The database is built in layers, where each patch layer depends on the completion of previous layers. This allows for safe, incremental deployment and clear separation of concerns.

```
Layer 0: Foundation
└── Create Employees and Departments
    │
    ├── Layer 1: Employee Details (can be deployed in parallel)
    │   ├── Layer 1a: Add Employee Roles ──────┐
    │   ├── Layer 1b: Add Salary Tracking      │
    │   └── Layer 1c: Add Leave Management ────┤
    │           │                              │
    │           ├──────────────────────────────┤
    │           │                              │
    │           └─→ Layer 2: Performance Reviews
    │                       │
    │                       ├─→ Layer 3: Project Management
    │                       │           │
    │                       │           └─→ Layer 7: Skills Tracking
    │                       │
    │                       └─→ Layer 4: Technical Debt (refactor Layer 1c)
    │                                   │
    │                                   └─→ Layer 5: Soft Delete (all tables)
    │
    └─→ Layer 6: Teams & Management (uses Layer 0, Layer 1a)
```

**Key Principles:**
- Each layer must be fully deployed before dependent layers can begin
- Within Layer 1, all three patches (1a, 1b, 1c) can be deployed independently and in any order
- Layer 2 depends on ALL of Layer 1 (needs roles, salary, and leave data)
- Layer 3 builds on Layer 2 (project management needs performance context)
- Layer 4 refactors Layer 1c and adds reference tables
- Layer 5 modifies ALL tables (must wait for Layers 0-4)
- Layer 6 is independent, only needing Layer 0 and Layer 1a
- Layer 7 needs Layer 1a (roles) and Layer 3 (projects)

### Layer Summary

| Layer | Patch Name | Dependencies | Tables Added | Purpose |
|-------|-----------|--------------|--------------|---------|
| **0** | Foundation | None | Employee, Department | Core organizational structure |
| **1a** | Employee Roles | Layer 0 | Role | Job function classification |
| **1b** | Salary Tracking | Layer 0 | Salary | Compensation history |
| **1c** | Leave Management | Layer 0 | EmployeeLeave | Time-off tracking |
| **2** | Performance Reviews | Layers 1a, 1b, 1c | PerformanceReview | Employee evaluations |
| **3** | Project Management | Layer 2 | Project, EmployeeProjectAssignment | Project tracking and staffing |
| **4** | Technical Debt | Layer 1c | LeaveType, ProjectStatus, PerformanceRating | Reference data + Leave refactor |
| **5** | Soft Delete | Layers 0-4 | *(modifies existing)* | Logical deletion pattern |
| **6** | Organizational Extensions | Layers 0, 1a | Team, EmployeeTeam, ManagerAssignment | Matrix org and management |
| **7** | Skills Tracking | Layers 1a, 3 | Skill, EmployeeSkill, ProjectSkillRequirement | Competency management |

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

**Important note on audit vs business patterns:**

Modern databases provide native audit capabilities that are superior to adding audit columns:
- **SQL Server:** Temporal Tables (system-versioned tables with automatic history)
- **PostgreSQL:** Audit trigger frameworks, pgAudit extension
- **MySQL 8.0+:** Audit plugins, binary log analysis

**Use database audit systems for:** Compliance, security investigations, change tracking (WHO changed WHAT and WHEN at a technical level)

**Use soft delete (Layer 5) for:** Business operations where "deletion" is reversible (employee sabbaticals, cancelled projects)

**Missing features to consider adding:**

1. **Concurrency control:**
   - Add RowVersion or Timestamp field
   - Prevents lost updates in multi-user scenarios

2. **Additional indexes:**
   - Consider indexes on frequently queried fields
   - Index foreign key columns if not automatically indexed
   - Common queries: Employee by LastName, Department by Name

3. **Data validation:**
   - Add CHECK constraints for valid value ranges
   - Email format validation
   - Date logic (EndDate >= StartDate)

4. **Business rules:**
   - Prevent salary decreases without explanation
   - Validate performance review frequency
   - Enforce project budget limits

**Note:** Layers 4-7 address many of these concerns:
- Layer 4 fixes LeaveBalance and adds reference tables
- Layer 5 implements soft delete pattern
- Layer 6 extends organizational modeling
- Layer 7 adds skills tracking

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

---

## Layer 4: Technical Debt - Reference Tables and Refactoring

**Purpose:** Address known design issues from earlier layers and normalize reference data that was initially stored as free text.

**Dependencies:** Layer 1c (Leave Management)

**What gets fixed:**
1. LeaveBalance column location (acknowledged TODO in README)
2. Free-text fields that should be reference data
3. Numeric ratings without defined scales

### Tables to Create

#### Table: LeaveType
Reference table for standardized leave categories.

**Columns:**
- **LeaveTypeId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 50 characters) - Required, unique (e.g., "Vacation", "Sick", "Personal", "Bereavement", "Jury Duty")
- **Description** (text, up to 255 characters) - Optional
- **IsPaid** (boolean) - Required, whether this leave type is paid time off
- **RequiresApproval** (boolean) - Required, whether manager approval is needed
- **IsActive** (boolean) - Required, whether this type can be used for new requests

**Data to seed:**
```
- Vacation (paid, requires approval)
- Sick Leave (paid, auto-approved)
- Personal Day (paid, requires approval)
- Unpaid Leave (unpaid, requires approval)
- Bereavement (paid, auto-approved)
- Jury Duty (paid, auto-approved)
```

#### Table: ProjectStatus
Reference table for project lifecycle states.

**Columns:**
- **ProjectStatusId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 50 characters) - Required, unique (e.g., "Planning", "Active", "On Hold", "Completed", "Cancelled")
- **Description** (text, up to 255 characters) - Optional
- **IsActive** (boolean) - Required, whether projects in this status are considered active
- **SortOrder** (integer) - Required, display order in UI

**Data to seed:**
```
- Planning (active, sort 10)
- Active (active, sort 20)
- On Hold (active, sort 30)
- Completed (inactive, sort 40)
- Cancelled (inactive, sort 50)
```

#### Table: PerformanceRating
Reference table defining the performance rating scale.

**Columns:**
- **PerformanceRatingId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 50 characters) - Required, unique (e.g., "Exceptional", "Exceeds Expectations", "Meets Expectations", "Needs Improvement", "Unsatisfactory")
- **NumericValue** (decimal, 2 decimal places) - Required, numeric equivalent (1.0-5.0)
- **Description** (text, up to 500 characters) - Optional, criteria for this rating
- **Color** (text, up to 20 characters) - Optional, hex color for UI (e.g., "#00AA00")
- **IsActive** (boolean) - Required

**Data to seed:**
```
- Exceptional (5.0, green)
- Exceeds Expectations (4.0, light green)
- Meets Expectations (3.0, yellow)
- Needs Improvement (2.0, orange)
- Unsatisfactory (1.0, red)
```

### Tables to Modify

#### EmployeeLeave (modifications)
**Add:**
- **LeaveTypeId** (identifier) - Foreign key to LeaveType, initially optional

**Remove (future):**
- **LeaveBalance** - This column doesn't logically belong on individual leave records

**Migration strategy:**
1. Add LeaveTypeId as optional column
2. Create LeaveType records
3. Migrate existing LeaveType text values to reference LeaveType.LeaveTypeId
4. Make LeaveTypeId required
5. Drop old LeaveType text column
6. Consider moving LeaveBalance to Employee table or separate EmployeeLeaveBalance table

#### Project (modifications)
**Add:**
- **ProjectStatusId** (identifier) - Foreign key to ProjectStatus, initially optional

**Migration strategy:**
1. Add ProjectStatusId as optional column
2. Create ProjectStatus records
3. Migrate existing Status text values to reference ProjectStatus.ProjectStatusId
4. Make ProjectStatusId required
5. Drop old Status text column

#### PerformanceReview (modifications)
**Add:**
- **PerformanceRatingId** (identifier) - Foreign key to PerformanceRating, initially optional

**Keep:**
- **PerformanceRating** (numeric) - Keep this for backward compatibility and ad-hoc ratings

**Migration strategy:**
1. Add PerformanceRatingId as optional column
2. Create PerformanceRating records
3. Map existing numeric ratings to closest PerformanceRatingId
4. New reviews can use either numeric or reference (or both)

### Relationships to Create

1. **EmployeeLeave references LeaveType**
   - EmployeeLeave.LeaveTypeId → LeaveType.LeaveTypeId
   - Required relationship after migration

2. **Project references ProjectStatus**
   - Project.ProjectStatusId → ProjectStatus.ProjectStatusId
   - Required relationship after migration

3. **PerformanceReview references PerformanceRating**
   - PerformanceReview.PerformanceRatingId → PerformanceRating.PerformanceRatingId
   - Optional relationship (numeric rating still supported)

### Implementation Notes

**Why this is Layer 4:**
- Fixes acknowledged technical debt (LeaveBalance location)
- Normalizes data that should have been reference tables from the start
- Requires careful migration to avoid breaking existing data
- Can't be done until the base tables are stable and in production

**Breaking changes:**
- Applications querying EmployeeLeave.LeaveType (text) must update to join LeaveType table
- Applications querying Project.Status (text) must update to join ProjectStatus table
- Applications may optionally use PerformanceRating table

**Rollback considerations:**
- Keep old text columns during migration period
- Support both old and new columns in application code during transition
- Drop old columns only after confirming all applications updated

---

## Layer 5: Soft Delete Pattern

**Purpose:** Implement logical deletion instead of physical deletion to preserve referential integrity and enable data recovery.

**Dependencies:** All previous layers (0-4)

**Philosophy:** Instead of deleting records with `DELETE` statements, mark them as deleted. This preserves historical data, maintains foreign key relationships, and enables "undelete" functionality.

### Tables to Modify

Add the following columns to ALL primary tables:

#### Core Tables (Layer 0)
- **Employee:** IsDeleted, DeletedAt, DeletedBy
- **Department:** IsDeleted, DeletedAt, DeletedBy

#### Detail Tables (Layer 1)
- **Role:** IsDeleted, DeletedAt, DeletedBy
- **Salary:** IsDeleted, DeletedAt, DeletedBy
- **EmployeeLeave:** IsDeleted, DeletedAt, DeletedBy

#### Review Tables (Layer 2)
- **PerformanceReview:** IsDeleted, DeletedAt, DeletedBy

#### Project Tables (Layer 3)
- **Project:** IsDeleted, DeletedAt, DeletedBy
- **EmployeeProjectAssignment:** IsDeleted, DeletedAt, DeletedBy

#### Reference Tables (Layer 4)
- **LeaveType:** IsDeleted, DeletedAt, DeletedBy
- **ProjectStatus:** IsDeleted, DeletedAt, DeletedBy
- **PerformanceRating:** IsDeleted, DeletedAt, DeletedBy

### Columns to Add

**All tables receive:**
- **IsDeleted** (boolean) - Required, default FALSE, whether record is logically deleted
- **DeletedAt** (datetime) - Optional, when the record was deleted
- **DeletedBy** (identifier) - Optional, foreign key to Employee who deleted the record

### Implementation Notes

**Query pattern changes:**
- All SELECT queries must add `WHERE IsDeleted = FALSE` (or `WHERE IsDeleted = 0`)
- Delete operations become UPDATE: `UPDATE Employee SET IsDeleted = TRUE, DeletedAt = NOW(), DeletedBy = @CurrentUserId WHERE EmployeeId = @Id`
- "Undelete" operations: `UPDATE Employee SET IsDeleted = FALSE, DeletedAt = NULL, DeletedBy = NULL WHERE EmployeeId = @Id`

**Index considerations:**
- Consider adding indexes on IsDeleted column for tables with high delete rates
- Consider filtered indexes (where supported): `CREATE INDEX IX_Employee_Active ON Employee(EmployeeId) WHERE IsDeleted = FALSE`

**Cascade behavior:**
- When "deleting" Employee, consider cascading soft delete to related records:
  - Salary records
  - EmployeeLeave records
  - PerformanceReview records
  - EmployeeProjectAssignment records

**Application layer:**
- Create database views filtering IsDeleted = FALSE for common queries
- Stored procedures should handle soft delete logic
- Consider separate "archive" queries that include deleted records for audit purposes

**Why not audit tables instead:**
- Soft delete is a business pattern (employees leave, projects get cancelled)
- Database audit systems track WHO changed WHAT and WHEN at a technical level
- Soft delete preserves referential integrity; audit systems are separate shadow tables
- Use database-native audit features (SQL Server: Temporal Tables, PostgreSQL: audit triggers, MySQL: 8.0 audit plugins) for compliance tracking

---

## Layer 6: Organizational Extensions - Teams and Management

**Purpose:** Extend the organizational model to support matrix organizations, cross-functional teams, and management hierarchies beyond department heads.

**Dependencies:** Layer 0 (Foundation), Layer 1a (Roles)

**What gets added:**
1. Teams that cut across department boundaries
2. Explicit management chains (beyond department heads)
3. Team membership with roles within teams

### Tables to Create

#### Table: Team
Represents cross-functional teams or working groups.

**Columns:**
- **TeamId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 100 characters) - Required, unique
- **Description** (text, up to 500 characters) - Optional
- **Purpose** (text, up to 255 characters) - Optional, team mission
- **TeamLeadId** (identifier) - Optional foreign key to Employee
- **IsActive** (boolean) - Required, whether team is currently active
- **CreatedDate** (date) - Required
- **DisbandedDate** (date) - Optional, when team was dissolved

**Examples:**
```
- Mobile App Team (cross-functional: iOS, Android, Backend, QA)
- Security Guild (experts from multiple departments)
- Hiring Committee (rotating membership)
```

#### Table: EmployeeTeam
Many-to-many relationship between employees and teams with role context.

**Columns:**
- **EmployeeTeamId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **TeamId** (identifier) - Required foreign key to Team
- **TeamRole** (text, up to 100 characters) - Optional, role within this team (e.g., "Lead Developer", "Scrum Master", "Member")
- **JoinedDate** (date) - Required, when employee joined this team
- **LeftDate** (date) - Optional, when employee left this team
- **IsActive** (boolean) - Required, whether employee is currently on this team

**Unique constraint:** (EmployeeId, TeamId, JoinedDate) - Same employee can rejoin same team later

#### Table: ManagerAssignment
Explicit management relationships beyond department heads, supporting dotted-line reporting.

**Columns:**
- **ManagerAssignmentId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee (the person being managed)
- **ManagerId** (identifier) - Required foreign key to Employee (the manager)
- **ManagerType** (text, up to 50 characters) - Required (e.g., "Direct", "Dotted-Line", "Project", "Mentor")
- **StartDate** (date) - Required, when management relationship began
- **EndDate** (date) - Optional, when management relationship ended
- **IsActive** (boolean) - Required, whether relationship is current

**Examples:**
```
- Alice reports directly to Bob (Direct, active)
- Alice has dotted-line reporting to Carol for project X (Dotted-Line, active)
- Dave mentors Alice (Mentor, active)
```

### Relationships to Create

1. **Team has lead Employee**
   - Team.TeamLeadId → Employee.EmployeeId
   - Optional relationship

2. **EmployeeTeam links Employee and Team**
   - EmployeeTeam.EmployeeId → Employee.EmployeeId (required)
   - EmployeeTeam.TeamId → Team.TeamId (required)

3. **ManagerAssignment defines management relationships**
   - ManagerAssignment.EmployeeId → Employee.EmployeeId (required, the person managed)
   - ManagerAssignment.ManagerId → Employee.EmployeeId (required, the manager)

### Implementation Notes

**Why this design:**
- Supports matrix organizations where employees work on multiple teams
- Tracks team membership over time (employees join and leave teams)
- Explicit manager relationships beyond Department.DepartmentHeadId
- Supports multiple management types (direct reports, dotted-line, mentorship)

**Query patterns:**
- "Show all active teams for employee X": `SELECT Team.* FROM Team JOIN EmployeeTeam ON ... WHERE EmployeeTeam.EmployeeId = X AND EmployeeTeam.IsActive = TRUE`
- "Show direct reports for manager Y": `SELECT Employee.* FROM Employee JOIN ManagerAssignment ON ... WHERE ManagerAssignment.ManagerId = Y AND ManagerAssignment.ManagerType = 'Direct' AND ManagerAssignment.IsActive = TRUE`
- "Show org chart": Recursive query on ManagerAssignment with ManagerType = 'Direct'

**Department vs Team:**
- Department: Official org structure, payroll, budget allocation
- Team: Fluid, project-based, cross-functional collaboration
- Employee can be in one Department but multiple Teams

---

## Layer 7: Skills Tracking

**Purpose:** Track employee competencies and match skills to project requirements for better resource planning.

**Dependencies:** Layer 1a (Roles), Layer 3 (Projects)

**What gets added:**
1. Catalog of technical and soft skills
2. Employee skill proficiencies
3. Project skill requirements

### Tables to Create

#### Table: Skill
Master list of skills tracked by the organization.

**Columns:**
- **SkillId** (identifier, auto-generated) - Primary key
- **Name** (text, up to 100 characters) - Required, unique (e.g., "Python", "Project Management", "Public Speaking")
- **Category** (text, up to 50 characters) - Optional (e.g., "Programming Language", "Framework", "Soft Skill", "Tool")
- **Description** (text, up to 500 characters) - Optional
- **IsActive** (boolean) - Required, whether skill is actively tracked

**Examples:**
```
- Python (Programming Language)
- React (Framework)
- AWS (Cloud Platform)
- Leadership (Soft Skill)
- SQL (Query Language)
```

#### Table: EmployeeSkill
Tracks which employees have which skills and their proficiency levels.

**Columns:**
- **EmployeeSkillId** (identifier, auto-generated) - Primary key
- **EmployeeId** (identifier) - Required foreign key to Employee
- **SkillId** (identifier) - Required foreign key to Skill
- **ProficiencyLevel** (integer) - Required, 1-5 scale (1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert, 5=Master)
- **YearsOfExperience** (decimal, 1 decimal place) - Optional, years worked with this skill
- **LastUsedDate** (date) - Optional, when skill was last applied in work
- **IsEndorsed** (boolean) - Optional, whether skill is verified by manager
- **EndorsedBy** (identifier) - Optional foreign key to Employee (who endorsed)
- **AcquiredDate** (date) - Optional, when employee learned this skill
- **Notes** (text, up to 500 characters) - Optional, certifications, projects where used

**Unique constraint:** (EmployeeId, SkillId) - One proficiency record per employee per skill

#### Table: ProjectSkillRequirement
Defines what skills are needed for a project.

**Columns:**
- **ProjectSkillRequirementId** (identifier, auto-generated) - Primary key
- **ProjectId** (identifier) - Required foreign key to Project
- **SkillId** (identifier) - Required foreign key to Skill
- **RequiredProficiency** (integer) - Required, minimum proficiency level (1-5)
- **IsMandatory** (boolean) - Required, whether skill is required or just preferred
- **Notes** (text, up to 255 characters) - Optional

**Unique constraint:** (ProjectId, SkillId) - One requirement per skill per project

### Relationships to Create

1. **EmployeeSkill links Employee and Skill**
   - EmployeeSkill.EmployeeId → Employee.EmployeeId (required)
   - EmployeeSkill.SkillId → Skill.SkillId (required)
   - EmployeeSkill.EndorsedBy → Employee.EmployeeId (optional)

2. **ProjectSkillRequirement links Project and Skill**
   - ProjectSkillRequirement.ProjectId → Project.ProjectId (required)
   - ProjectSkillRequirement.SkillId → Skill.SkillId (required)

### Implementation Notes

**Why this design:**
- Enables skills-based resource allocation ("find all employees with Python proficiency 3+")
- Tracks skill growth over time (update ProficiencyLevel as employees develop)
- Matches project requirements to available talent
- Identifies skill gaps in the organization

**Query patterns:**
- "Find employees with skill X at proficiency Y+": `SELECT Employee.* FROM Employee JOIN EmployeeSkill ON ... WHERE EmployeeSkill.SkillId = X AND EmployeeSkill.ProficiencyLevel >= Y`
- "Show skill gaps for project Z": `SELECT Skill.* FROM ProjectSkillRequirement JOIN Skill ON ... WHERE ProjectSkillRequirement.ProjectId = Z AND NOT EXISTS (SELECT 1 FROM EmployeeProjectAssignment JOIN EmployeeSkill ON ... WHERE proficiency matches)`
- "Employee skill profile": `SELECT Skill.Name, EmployeeSkill.ProficiencyLevel FROM EmployeeSkill JOIN Skill ON ... WHERE EmployeeSkill.EmployeeId = @EmployeeId`

**Proficiency scale:**
- 1 = Beginner: Basic knowledge, needs supervision
- 2 = Intermediate: Can work independently on routine tasks
- 3 = Advanced: Can handle complex tasks, mentors others
- 4 = Expert: Go-to person, handles critical issues
- 5 = Master: Industry recognition, defines best practices

**Business value:**
- Career development: Identify training needs
- Hiring: Identify skill gaps to inform job postings
- Project staffing: Match skills to requirements
- Succession planning: Identify skill concentrations/risks
