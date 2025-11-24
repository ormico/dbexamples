# Schema Design Guide

This guide teaches AI agents how to write platform-agnostic database specifications in SCHEMA_DESIGN.md files.

## Purpose

SCHEMA_DESIGN.md documents the **technical specification** of a database using platform-agnostic language. This allows the same specification to be implemented on MySQL, SQL Server, PostgreSQL, and other platforms without modification.

## Companion Document

Every SCHEMA_DESIGN.md has a companion DEVELOPMENT_SCENARIO.md that explains:
- HOW the database was built collaboratively
- WHY design decisions were made
- WHO made the decisions and WHEN

**Always cross-reference both documents at the top:**

```markdown
# Employee Database - Schema Design

> **📖 Companion Document:** This document provides platform-agnostic technical specifications.  
> For the collaborative development story and rationale, see [DEVELOPMENT_SCENARIO.md](DEVELOPMENT_SCENARIO.md).
```

## Document Structure

### 1. Introduction Section
Explain the database purpose and scope:

```markdown
# Employee Database - Schema Design

> **📖 Companion Document:** [DEVELOPMENT_SCENARIO.md](DEVELOPMENT_SCENARIO.md)

## Overview

This database manages employee information for a mid-sized company, including:
- Employee and department organization
- Role assignments and salary history
- Leave tracking and performance reviews
- Project assignments and team structure

The schema evolves through 8 layers, demonstrating incremental deployment patterns.
```

### 2. Layer Hierarchy Section
List all layers with their dependencies:

```markdown
## Layer Structure

- **Layer 0**: Foundation (Employee, Department) - Circular reference pattern
- **Layer 1a**: Employee Roles (depends on Layer 0)
- **Layer 1b**: Salary Tracking (depends on Layer 0)
- **Layer 1c**: Leave Management (depends on Layer 0)
- **Layer 2**: Performance Reviews (depends on ALL Layer 1)
- **Layer 3**: Projects (depends on Layer 2)
- **Layer 4**: Technical Debt Resolution (depends on Layer 3)
- **Layer 5**: Soft Delete (depends on Layer 4)

**Implementation Status:**
- ✅ Layers 0-3: Implemented
- 📋 Layers 4-7: Specified (not yet implemented)
```

### 3. Layer Detail Sections
For each layer, provide complete specifications:

```markdown
## Layer 0: Foundation

### Description
Core employee and department tables with circular reference pattern.

### Tables

#### Employee
- **EmployeeId**: identifier, auto-generated
- **FirstName**: text, up to 50 characters, required
- **LastName**: text, up to 50 characters, required
- **Email**: text, up to 100 characters, required, unique
- **Phone**: text, up to 20 characters, nullable
- **HireDate**: date, required
- **DepartmentId**: foreign key to Department, nullable
- **ManagerId**: foreign key to Employee (self-reference), nullable

#### Department
- **DepartmentId**: identifier, auto-generated
- **Name**: text, up to 100 characters, required, unique
- **DepartmentHeadId**: foreign key to Employee, nullable

### Relationships
- Employee → Department (many-to-one via DepartmentId)
- Department → Employee (one-to-one via DepartmentHeadId)
- Employee → Employee (self-reference via ManagerId)

**⚠️ Circular Reference:** Employee.DepartmentId → Department, Department.DepartmentHeadId → Employee

### Implementation Order
1. Create Employee table WITHOUT DepartmentId foreign key
2. Create Department table WITHOUT DepartmentHeadId foreign key
3. Add Department.DepartmentHeadId foreign key (references Employee)
4. Add Employee.DepartmentId foreign key (references Department)

### Indexes
- Employee: Email (unique), DepartmentId, ManagerId
- Department: Name (unique), DepartmentHeadId

### Business Rules
- Department head must be an employee in that department
- Employees can exist without a department (nullable)
- Manager must be another employee (no circular self-reference)
```

## Platform-Agnostic Language

### Data Types

Use **logical descriptions**, not platform-specific syntax:

| ✅ Use This | ❌ Not This |
|------------|-------------|
| identifier, auto-generated | INT AUTO_INCREMENT |
| text, up to X characters | VARCHAR(X) |
| text, unlimited | TEXT |
| boolean | TINYINT(1) or BIT |
| datetime | DATETIME or TIMESTAMP |
| date | DATE |
| decimal(P,S) | DECIMAL(P,S) |
| integer | INT |

**Examples:**

```markdown
- **EmployeeId**: identifier, auto-generated
- **FirstName**: text, up to 50 characters, required
- **Email**: text, up to 100 characters, required, unique
- **HireDate**: date, required
- **IsActive**: boolean, required, default true
- **Salary**: decimal(10,2), required
- **Notes**: text, unlimited, nullable
```

### Nullability

Be explicit about nullable vs required:

```markdown
- **DepartmentId**: foreign key to Department, nullable
- **FirstName**: text, up to 50 characters, required
- **MiddleName**: text, up to 50 characters, nullable
```

### Constraints

Describe constraints logically:

```markdown
- **Email**: text, up to 100 characters, required, unique
- **StartDate**: date, required, must be <= EndDate
- **EffectiveDate**: date, required, default current date
- **IsActive**: boolean, required, default true
```

### Foreign Keys

Use clear references:

```markdown
- **EmployeeId**: foreign key to Employee, required
- **DepartmentId**: foreign key to Department, nullable
- **ManagerId**: foreign key to Employee (self-reference), nullable
- **ReviewedById**: foreign key to Employee (references EmployeeId), required
```

### Self-References

Always clarify self-referencing foreign keys:

```markdown
- **ManagerId**: foreign key to Employee (self-reference), nullable
  - References the employee's direct manager
  - Employees at the top of the hierarchy have NULL ManagerId
```

## Critical Patterns

### Circular References

When two tables reference each other, document the implementation order:

```markdown
### ⚠️ Circular Reference Pattern

**Problem:** Employee → Department, Department → Employee

**Solution:**
1. Create Employee table WITHOUT DepartmentId foreign key
2. Create Department table WITHOUT DepartmentHeadId foreign key
3. Add Department.DepartmentHeadId foreign key
4. Add Employee.DepartmentId foreign key

**Rationale:** Both tables must exist before either foreign key can be created.
```

### Parallel Dependencies

When multiple layers depend on the same parent:

```markdown
## Layer 1 Dependencies

Layer 1 consists of three independent modules that can be deployed in any order:

- **Layer 1a**: Employee Roles (depends on Layer 0)
- **Layer 1b**: Salary Tracking (depends on Layer 0)
- **Layer 1c**: Leave Management (depends on Layer 0)

**No interdependencies:** 1a, 1b, 1c do NOT reference each other.

**Layer 2 depends on ALL Layer 1:** Performance Reviews require roles, salary, and leave data.
```

### Junction Tables

For many-to-many relationships:

```markdown
#### EmployeeProjectAssignment (Junction Table)
- **AssignmentId**: identifier, auto-generated
- **EmployeeId**: foreign key to Employee, required
- **ProjectId**: foreign key to Project, required
- **Role**: text, up to 100 characters, required
- **AllocationPercentage**: decimal(5,2), required
- **StartDate**: date, required
- **EndDate**: date, nullable

**Unique Constraint:** (EmployeeId, ProjectId) must be unique

**Relationships:**
- Employee ← EmployeeProjectAssignment → Project (many-to-many)
```

## Design Patterns

### Historical Tracking

For audit trails and history:

```markdown
#### Salary
- **SalaryId**: identifier, auto-generated
- **EmployeeId**: foreign key to Employee, required
- **Amount**: decimal(10,2), required
- **Currency**: text, up to 3 characters, required, default 'USD'
- **EffectiveDate**: date, required
- **EndDate**: date, nullable
- **IsCurrent**: boolean, required, default true

**Business Rules:**
- Only one salary record per employee can have IsCurrent = true
- EndDate should be set when a new salary becomes effective
- Historical records preserved for audit purposes
```

### Soft Delete

For logical deletion without data loss:

```markdown
#### Soft Delete Pattern (Layer 5)

Add to ALL tables:
- **IsDeleted**: boolean, required, default false
- **DeletedAt**: datetime, nullable
- **DeletedBy**: foreign key to Employee, nullable

**Business Rules:**
- IsDeleted = true indicates logically deleted record
- DeletedAt records deletion timestamp
- DeletedBy tracks who performed the deletion
- Queries should filter WHERE IsDeleted = false by default
```

### Reference Data

For lookup tables:

```markdown
#### LeaveType (Reference Data)
- **LeaveTypeId**: identifier, auto-generated
- **Code**: text, up to 20 characters, required, unique
- **Name**: text, up to 100 characters, required
- **Description**: text, unlimited, nullable
- **DefaultDays**: integer, required
- **RequiresApproval**: boolean, required, default true
- **IsActive**: boolean, required, default true

**Seed Data:**
- VACATION: Vacation Leave (15 days)
- SICK: Sick Leave (10 days)
- PERSONAL: Personal Leave (5 days)
- MATERNITY: Maternity Leave (90 days)
```

## Documenting Technical Debt

Be explicit about known design issues:

```markdown
### Known Technical Debt

#### LeaveBalance Field Location
**Issue:** `EmployeeLeave.LeaveBalance` is stored per-leave-record instead of per-employee.

**Why This Is Wrong:**
- Leave balance applies to the employee's annual allocation, not individual leave requests
- Current design allows inconsistent balances across multiple requests
- Should be in a separate EmployeeLeaveBalance table

**Planned Fix:** Layer 4 will introduce EmployeeLeaveBalance table and migrate data.

**Rationale for Keeping:** This intentional poor design demonstrates realistic technical debt and refactoring scenarios.
```

## Translation Reference

When implementing SCHEMA_DESIGN.md specifications on specific platforms:

### MySQL
```sql
-- identifier, auto-generated
EmployeeId INT AUTO_INCREMENT PRIMARY KEY

-- text, up to X characters
FirstName VARCHAR(50)

-- boolean
IsActive TINYINT(1)

-- datetime
CreatedAt DATETIME

-- decimal(P,S)
Salary DECIMAL(10,2)
```

### SQL Server
```sql
-- identifier, auto-generated
EmployeeId INT IDENTITY PRIMARY KEY

-- text, up to X characters
FirstName VARCHAR(50)

-- boolean
IsActive BIT

-- datetime
CreatedAt DATETIME2

-- decimal(P,S)
Salary DECIMAL(10,2)
```

### PostgreSQL
```sql
-- identifier, auto-generated
EmployeeId SERIAL PRIMARY KEY

-- text, up to X characters
FirstName VARCHAR(50)

-- boolean
IsActive BOOLEAN

-- datetime
CreatedAt TIMESTAMP

-- decimal(P,S)
Salary NUMERIC(10,2)
```

## Checklist for Writing SCHEMA_DESIGN.md

- [ ] Start with overview and purpose
- [ ] Document all layers and dependencies
- [ ] Mark implementation status (✅ done, 📋 planned)
- [ ] Use platform-agnostic language for all types
- [ ] Be explicit about nullable vs required
- [ ] Document circular references with implementation order
- [ ] Specify all indexes (especially on foreign keys)
- [ ] Include business rules for each table
- [ ] Document known technical debt
- [ ] Cross-reference DEVELOPMENT_SCENARIO.md at the top
- [ ] Provide translation examples for multiple platforms
- [ ] Include relationship diagrams or descriptions
- [ ] Specify unique constraints
- [ ] Document self-references clearly
- [ ] Include seed data for reference tables

## Examples

See complete examples in:
- `Employee-DB/dbpatchv2/odbc-mysql/SCHEMA_DESIGN.md` (8 layers, circular references, parallel dependencies)

## Common Mistakes to Avoid

1. **❌ Using platform-specific syntax**
   - ✅ Use logical descriptions

2. **❌ Forgetting to document implementation order for circular refs**
   - ✅ Always include step-by-step order

3. **❌ Missing nullability specifications**
   - ✅ Explicitly state "nullable" or "required"

4. **❌ Not documenting layer dependencies**
   - ✅ Show which layers depend on which

5. **❌ Omitting indexes**
   - ✅ Specify indexes for FKs and frequently queried columns

6. **❌ No business rules**
   - ✅ Include validation and constraint rules

7. **❌ Missing companion document reference**
   - ✅ Always cross-link to DEVELOPMENT_SCENARIO.md

8. **❌ Inconsistent naming conventions**
   - ✅ Use consistent table/column naming throughout
