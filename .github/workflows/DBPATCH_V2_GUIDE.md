# DBPatch v2 Framework Guide

This guide teaches AI agents how to use the dbpatch v2 framework to create database patches from SCHEMA_DESIGN.md specifications.

## Overview

DBPatch v2 is a .NET Core command-line database migration tool that executes SQL patches in dependency order. Each patch is a folder containing SQL files (executed alphabetically), and a `patches.json` file defines patches and their dependencies. DBPatch uses a graph-based algorithm to install patches in the correct order based on their `dependsOn` relationships.

## Command Line Interface

DBPatch is installed as the `dbpatch` command:

```bash
# Initialize a new database project
dbpatch init --dbtype sqlserver

# Add a new patch
dbpatch addpatch -n <patch-name>

# Build (apply all missing patches and code files)
dbpatch build
```

## Core Concepts

### Patch Structure

```
Patches/
├── 202401270230-6495-create-employees-and-departments/
│   ├── 1_employee.sql
│   ├── 2_department.sql
│   ├── 3_departments_fk_*.sql
│   └── 4_employees_fk_*.sql
├── 202401280915-7823-add-employee-roles/
│   ├── 1_employeerole.sql
│   └── 2_constraints.sql
└── ...
```

### Patch ID Format

`YYYYMMDDHHMMSS-RAND-description`

- **YYYYMMDDHHMMSS**: Timestamp (use realistic business hours: 9 AM - 5 PM, Monday-Friday)
- **RAND**: 4-digit random number for uniqueness
- **description**: Kebab-case description of the patch (e.g., `create-employees-and-departments`)

**Examples:**
- `202401270230-6495-create-employees-and-departments` (2:30 AM is a late night fix)
- `202401290915-3421-add-employee-roles` (9:15 AM is morning work)
- `202402011400-8765-create-performance-reviews` (2:00 PM is afternoon work)

### patches.json Structure

```json
{
  "DatabaseType": "sqlserver",
  "ConnectionString": null,
  "PatchFolder": "Patches",
  "CodeFolder": "Code",
  "CodeFiles": [
    "*.view.sql",
    "*.udf.sql",
    "*.view2.sql",
    "*.udf2.sql",
    "*.view3.sql",
    "*.udf3.sql",
    "*.sproc.sql",
    "*.sproc2.sql",
    "*.sproc3.sql",
    "*.trigger.sql",
    "*.trigger2.sql",
    "*.trigger3.sql"
  ],
  "patches": [
    {
      "id": "202401270230-6495-create-employees-and-departments",
      "dependsOn": []
    },
    {
      "id": "202401290915-3421-add-employee-roles",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    },
    {
      "id": "202401291030-5678-add-salary-tracking",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    },
    {
      "id": "202402011400-8765-create-performance-reviews",
      "dependsOn": [
        "202401290915-3421-add-employee-roles",
        "202401291030-5678-add-salary-tracking"
      ]
    }
  ]
}
```

**Key Points:**
- `DatabaseType`: Plugin to use (e.g., "sqlserver", "odbc")
- `ConnectionString`: Database connection (typically in patches.local.json, not checked into source control)
- `PatchFolder`: Where patch folders are stored (default: "Patches")
- `CodeFolder`: Where code files are stored (default: "Code")
- `CodeFiles`: Glob patterns for code files, executed in order by suffix
- `patches`: Array of patch objects with id and dependsOn
  - `id`: Unique patch identifier
  - `dependsOn`: Array of patch ID strings that must execute first
  - Empty `dependsOn: []` means the patch has no dependencies
  - Multiple dependencies create a directed acyclic graph (DAG)
  
**Note:** The `description` field shown in some examples is NOT part of the actual dbpatch v2 schema. Use comments in your SQL files for documentation.

## Execution Order

### 1. Patch Dependency Resolution
DBPatch uses a graph-based algorithm (depth-first traversal) starting from patches with no dependencies:

1. Find patch(es) with empty `dependsOn: []`
2. Add to execution queue
3. For each patch, check if all dependencies are already installed
4. If dependencies missing, add dependencies to front of queue first
5. Install patch only when all dependencies are satisfied
6. Add patch's children to queue
7. Continue until all patches processed

**Example execution flow:**
```
Layer 0: create-employees-and-departments (no dependencies, installs first)
Layer 1: add-employee-roles, add-salary-tracking, add-leave-tracking (depend on Layer 0, install in graph traversal order)
Layer 2: create-performance-reviews (depends on ALL Layer 1, installs last)
```

**Important:** DBPatch does NOT do parallel execution. Patches install sequentially based on dependency resolution.

### 2. SQL File Execution (Within Each Patch)
Within each patch folder, `.sql` files execute **alphabetically** by filename:

```
1_employee.sql           -- First
2_department.sql         -- Second
3_departments_fk.sql     -- Third  
4_employees_fk.sql       -- Fourth
```

**Naming Convention:**
- Use numeric prefixes: `1_`, `2_`, `3_`, etc.
- Use descriptive names: `1_employee.sql`, not `1_table1.sql`
- Avoid special characters that might affect alphabetical sorting

### 3. Code Folder Execution (After All Patches)
After all patches complete, files in the `Code/` folder execute by matching glob patterns in `CodeFiles` array order:

**Default order from patches.json:**
1. `*.view.sql` - Views
2. `*.udf.sql` - User Defined Functions
3. `*.view2.sql` - Views (second pass for dependencies)
4. `*.udf2.sql` - Functions (second pass)
5. `*.view3.sql` - Views (third pass)
6. `*.udf3.sql` - Functions (third pass)
7. `*.sproc.sql` - Stored Procedures
8. `*.sproc2.sql` - Stored Procedures (second pass)
9. `*.sproc3.sql` - Stored Procedures (third pass)
10. `*.trigger.sql` - Triggers
11. `*.trigger2.sql` - Triggers (second pass)
12. `*.trigger3.sql` - Triggers (third pass)

**Example:**
```
Code/
├── EmployeeSummary.view.sql       -- Runs in *.view.sql pass
├── GetEmployeeName.udf.sql        -- Runs in *.udf.sql pass
├── CreateEmployee.sproc.sql       -- Runs in *.sproc.sql pass
└── AuditChanges.trigger.sql       -- Runs in *.trigger.sql pass
```

**Note:** The multiple passes (2, 3) handle dependencies between code objects of the same type.

## Critical Pattern: Circular References

### The Problem
When two tables reference each other:

```
Employee
  - DepartmentId → Department.Id

Department
  - DepartmentHeadId → Employee.Id
```

You **cannot** create both tables with foreign keys in one step because:
- Employee FK requires Department to exist
- Department FK requires Employee to exist

### The Solution: Two-Phase Creation

**Phase 1: Create tables WITHOUT foreign keys**
```sql
-- 1_employee.sql
CREATE TABLE Employee (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    DepartmentId INT NULL  -- No FK yet
);

-- 2_department.sql
CREATE TABLE Department (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    DepartmentHeadId INT NULL  -- No FK yet
);
```

**Phase 2: Add foreign keys AFTER both tables exist**
```sql
-- 3_departments_fk_*.sql
ALTER TABLE Department
ADD CONSTRAINT FK_Department_DepartmentHeadId
    FOREIGN KEY (DepartmentHeadId) REFERENCES Employee(Id)
    ON DELETE SET NULL;

-- 4_employees_fk_*.sql
ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_DepartmentId
    FOREIGN KEY (DepartmentId) REFERENCES Department(Id)
    ON DELETE SET NULL;
```

**Why This Works:**
1. Both tables exist before any FK is created
2. FK creation happens in dependency order (Department FK first, then Employee FK)
3. ON DELETE SET NULL prevents cascade issues

## Creating a New Patch from SCHEMA_DESIGN.md

### Using dbpatch addpatch Command

The recommended way to create patches is using the `dbpatch addpatch` command:

```bash
dbpatch addpatch -n add-employee-roles
```

This automatically:
- Generates timestamp-based patch ID (e.g., `202401290915-3421-add-employee-roles`)
- Creates patch folder in `Patches/`
- Updates `patches.json` with new patch
- Sets `dependsOn` to all current "open" patches (patches with no other dependencies)

Then add your SQL files to the created folder.

### Manual Patch Creation Process

If creating patches manually (for understanding or special cases):

### Step 1: Read the Specification
From SCHEMA_DESIGN.md, find the layer specification:

```markdown
### Layer 1a: Employee Roles

**Tables:**
- EmployeeRole
  - RoleId: identifier, auto-generated
  - EmployeeId: foreign key to Employee
  - JobTitle: text, up to 100 characters
  - StartDate: date
  - EndDate: date, nullable
  - IsCurrent: boolean
```

### Step 2: Determine Dependencies
- **Layer 1a depends on Layer 0** (needs Employee table)
- Find Layer 0's patch ID from patches.json: `202401270230-6495-create-employees-and-departments`

### Step 3: Create Patch ID
- Generate realistic timestamp (business hours, weekday)
- Example: `202401290915-3421-add-employee-roles`
  - Date: 2024-01-29 (Monday after Layer 0)
  - Time: 09:15 (morning work)
  - Random: 3421
  - Description: add-employee-roles

### Step 4: Create SQL Files
**File: `1_employeerole.sql`**
```sql
-- Layer 1a: Employee Roles
-- CREATE TABLE: EmployeeRole

CREATE TABLE EmployeeRole (
    RoleId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    JobTitle VARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    IsCurrent TINYINT(1) NOT NULL DEFAULT 1,
    
    CONSTRAINT FK_EmployeeRole_EmployeeId
        FOREIGN KEY (EmployeeId) REFERENCES Employee(Id)
        ON DELETE CASCADE
);

CREATE INDEX IX_EmployeeRole_EmployeeId ON EmployeeRole(EmployeeId);
CREATE INDEX IX_EmployeeRole_IsCurrent ON EmployeeRole(IsCurrent);
```

**Translation Rules Applied:**
- "identifier, auto-generated" → `INT AUTO_INCREMENT PRIMARY KEY`
- "foreign key to Employee" → `INT NOT NULL` + `FOREIGN KEY` constraint
- "text, up to X characters" → `VARCHAR(X)`
- "date" → `DATE`
- "nullable" → `NULL`
- "boolean" → `TINYINT(1)` (MySQL specific)

### Step 5: Update patches.json (if creating manually)

**Note:** `dbpatch addpatch` handles this automatically. Only needed if creating patches manually.

```json
{
  "DatabaseType": "sqlserver",
  "PatchFolder": "Patches",
  "CodeFolder": "Code",
  "patches": [
    {
      "id": "202401270230-6495-create-employees-and-departments",
      "dependsOn": []
    },
    {
      "id": "202401290915-3421-add-employee-roles",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    }
  ]
}
```

**Important:** Do NOT include a `description` field - it's not part of the dbpatch v2 schema. Use SQL comments for documentation.

## Advanced Patterns

### Parallel Dependencies (Layer 1a, 1b, 1c)
When multiple patches depend on the same parent but NOT each other:

```json
{
  "patches": [
    {
      "id": "202401270230-6495-create-employees-and-departments",
      "description": "Layer 0",
      "dependsOn": []
    },
    {
      "id": "202401290915-3421-add-employee-roles",
      "description": "Layer 1a",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    },
    {
      "id": "202401291030-5678-add-salary-tracking",
      "description": "Layer 1b",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    },
    {
      "id": "202401291115-9012-add-leave-tracking",
      "description": "Layer 1c",
      "dependsOn": ["202401270230-6495-create-employees-and-departments"]
    }
  ]
}
```

**Execution:** Layer 1a, 1b, 1c will execute sequentially (not in parallel) in the order determined by the graph traversal algorithm. The specific order between independent patches may vary, but they will all complete before Layer 2 begins.

### Multiple Dependencies (Layer 2)
When a patch requires ALL previous layers:

```json
{
  "id": "202402011400-8765-create-performance-reviews",
  "description": "Layer 2: Performance Reviews",
  "dependsOn": [
    "202401290915-3421-add-employee-roles",
    "202401291030-5678-add-salary-tracking",
    "202401291115-9012-add-leave-tracking"
  ]
}
```

**Execution:** DBPatch's graph algorithm ensures this patch won't install until ALL three dependencies are already in the InstalledPatches table. The algorithm checks each dependency before installing.

### Multi-File Patches
For complex schemas, split into multiple files:

```
Patches/202402011400-8765-create-performance-reviews/
├── 1_performancereview.sql       -- Main table
├── 2_reviewmetric.sql            -- Child table
├── 3_reviewcomment.sql           -- Child table
└── 4_constraints.sql             -- Foreign keys and indexes
```

Files execute in order: 1 → 2 → 3 → 4

## Platform Translation Reference

When implementing SCHEMA_DESIGN.md for different platforms:

| Logical Type | MySQL | SQL Server | PostgreSQL |
|--------------|-------|------------|------------|
| identifier, auto-generated | INT AUTO_INCREMENT | INT IDENTITY | SERIAL |
| text, up to X characters | VARCHAR(X) | VARCHAR(X) | VARCHAR(X) |
| text, unlimited | TEXT | VARCHAR(MAX) | TEXT |
| boolean | TINYINT(1) | BIT | BOOLEAN |
| datetime | DATETIME | DATETIME2 | TIMESTAMP |
| date | DATE | DATE | DATE |
| decimal(P,S) | DECIMAL(P,S) | DECIMAL(P,S) | NUMERIC(P,S) |

## Configuration Files

### patches.json
Main configuration file checked into source control. Contains:
- Database type plugin
- Patch folder and code folder paths
- Code file execution patterns
- All patches and their dependencies

**Do check into source control.**

### patches.local.json
Local configuration overrides, typically contains:
```json
{
  "ConnectionString": "Server=.;Database=TestDatabase;Trusted_Connection=True;"
}
```

**Do NOT check into source control** - add to `.gitignore`. Each developer/environment has their own connection string.

### ScriptOverrides/
Optional folder for customizing SQL scripts used by plugins:
- `AddInstalledPatch.sql` - Custom script to log patch installation
- `GetInstalledPatches.sql` - Custom script to retrieve installed patches
- `InitPatchTable.sql` - Custom script to create InstalledPatches table

Used primarily with ODBC plugin for databases that need custom tracking table implementations.

## Common Mistakes to Avoid

1. **❌ Creating tables with circular FK references in one file**
   - ✅ Create tables first, add FKs in separate files

2. **❌ Using platform-specific syntax in SCHEMA_DESIGN.md**
   - ✅ Use logical descriptions, translate during implementation

3. **❌ Forgetting to update patches.json**
   - ✅ Use `dbpatch addpatch -n <name>` to automatically update

4. **❌ Adding a 'description' field to patches.json**
   - ✅ DBPatch v2 doesn't use description field; use SQL comments

5. **❌ Wrong dependency order**
   - ✅ Check SCHEMA_DESIGN.md for layer dependencies

6. **❌ Missing dependsOn entries**
   - ✅ Every patch needs a dependsOn array (even if empty)

7. **❌ Manually creating patch IDs**
   - ✅ Use `dbpatch addpatch` to auto-generate proper IDs

8. **❌ Poor file naming within patches**
   - ✅ Use numeric prefixes for execution order

9. **❌ Missing indexes on foreign keys**
   - ✅ Add indexes for performance

10. **❌ Checking patches.local.json into source control**
    - ✅ Add to .gitignore, contains sensitive connection strings

## Checklist for Creating a Patch

- [ ] Read SCHEMA_DESIGN.md specification
- [ ] Identify layer dependencies
- [ ] Run `dbpatch addpatch -n <patch-name>` to create patch
- [ ] Verify patches.json updated with correct dependsOn
- [ ] Write numbered SQL files (1_, 2_, 3_...) in patch folder
- [ ] Handle circular references if needed (tables first, FKs second)
- [ ] Add indexes for foreign keys
- [ ] Test with `dbpatch build` on test database
- [ ] Verify InstalledPatches table shows patch installed
- [ ] Update DEVELOPMENT_SCENARIO.md with implementation story
- [ ] Commit patches.json and Patches/ folder to source control
- [ ] Do NOT commit patches.local.json

## Examples

See `Employee-DB/dbpatchv2/odbc-mysql/` for complete examples:
- Layer 0: Circular reference pattern (Employee ↔ Department)
- Layer 1a/b/c: Parallel dependencies
- Layer 2: Multiple dependencies
- patches.json: Full dependency graph

## Questions?

- **How do I know the execution order?** - DBPatch uses graph traversal from patches with no dependencies. Check InstalledPatches table to see actual execution order.
- **Can patches have circular dependencies?** - No, that would cause the graph traversal to fail with unmet dependencies
- **What if I need to modify an existing table?** - Create a new patch with ALTER TABLE statements that depends on the patch that created the table
- **Should I create one large patch or multiple small ones?** - Follow the layer structure from SCHEMA_DESIGN.md; one patch per logical feature or layer
- **What about rollback/down migrations?** - DBPatch v2 doesn't support rollbacks; patches are one-way only
- **How does dbpatch track installed patches?** - Creates an `InstalledPatches` table with PatchId and InstalledDate columns
- **Can I re-run a patch?** - No, once in InstalledPatches table, dbpatch skips it. Delete from table to re-run (use with caution)
- **What's the difference between Patches and Code folders?** - Patches run once and are tracked; Code files run on every `dbpatch build` (for stored procedures, views, etc.)

## Additional Resources

- [DBPatch Manager Repository](https://github.com/ormico/dbpatchmanager)
- [SQL Server Plugin](https://github.com/ormico/dbpatchmanager-sqlserver)
