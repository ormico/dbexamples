# Implementation Guide

This guide covers how to add a new tool+platform implementation to an existing scenario, or how to add layers to an existing implementation.

**Prerequisites:** The scenario's `SCHEMA_DESIGN.md` and `SCENARIO.md` must already exist. If they don't, start with [SCHEMA_AND_SCENARIO_GUIDE.md](SCHEMA_AND_SCENARIO_GUIDE.md).

---

## Scaffolding a New Implementation

### Folder structure

```
<Scenario-DB>/
+-- <tool>/<platform>/
    +-- docker-compose.yml          <- Spins up the database server
    +-- test-connection.ps1         <- Verifies connectivity before first build
    +-- patches.json                <- DBPatch config (managed by CLI, do not hand-edit)
    +-- patches.local.json          <- Connection string (gitignored)
    +-- load-test-data.ps1          <- Reads from ../../test-data/, loads CSVs
    +-- Patches/                    <- One folder per patch
    +-- Code/                       <- Stored procedures, views, functions, triggers
    +-- ScriptOverrides/            <- Platform-specific DBPatch internals (ODBC only)
    +-- README.md                   <- Implementation notes, how to run, known issues
```

**Naming convention for tool/platform folders:**

- `dbpatchv2/odbc-mysql` — DBPatch v2 using the ODBC plugin, targeting MySQL
- `dbpatchv2/odbc-sqlserver` — DBPatch v2 using the ODBC plugin, targeting SQL Server
- `dbpatchv3/native-postgresql` — DBPatch v3 using its native PostgreSQL driver
- `rawsql/mysql` — Raw SQL scripts with no migration tool

### ScriptOverrides decision tree

ScriptOverrides contain platform-specific SQL that DBPatch uses internally to track installed patches.

```
Are you using the ODBC plugin (--dbtype odbc)?
|
+-- YES: Does an existing implementation already exist for this same database platform?
|   |
|   +-- YES (e.g., second odbc-mysql): COPY ScriptOverrides from that implementation.
|   |
|   +-- NO (e.g., first time using Oracle via ODBC): CREATE new ScriptOverrides.
|       See: ScriptOverrides reference section below.
|
+-- NO (native driver: sqlserver, postgresql, mysql-native):
    NO ScriptOverrides needed. DBPatch has built-in support.
```

**Never copy ScriptOverrides from a different database platform.** MySQL syntax differs fundamentally from Oracle, DB2, or PostgreSQL — the SQL will not work.

### patches.local.json (gitignored)

Each developer or environment has their own connection string. This file is never committed.

```json
{
  "ConnectionString": "Driver={MySQL ODBC 8.0 Driver};Server=localhost;Port=3306;Database=EmployeeDB;Uid=root;Pwd=yourpassword;"
}
```

Add `patches.local.json` to `.gitignore` if it isn't already there.

---

## Per-Layer Workflow

This is the workflow for implementing one layer from `SCHEMA_DESIGN.md`.

### Step 1: Read the specification

Open the scenario's `SCHEMA_DESIGN.md`. Find the target layer. Note:

- Tables to create (and their columns, types, constraints, indexes)
- Changes to existing tables (ALTER TABLE additions)
- Relationships to add (foreign keys)
- Implementation order (especially for circular references or phased column additions)
- Any seed data to insert

### Step 2: Determine the timestamp to use

Patch IDs include a timestamp. Use the timestamp that matches the layer's date in `SCENARIO.md` — this makes the patch history readable as a timeline.

For example, if `SCENARIO.md` says Layer 1a was implemented on January 29, 2024 at 9:15 AM:

```
Patch ID: 202401290915-<RAND>-add-employee-roles
```

To get the right timestamp:
1. Run `dbpatch addpatch -n <name>` to create the patch (it uses the current time).
2. Rename the generated folder to match the date/time from `SCENARIO.md`.
3. Update `patches.json` to reflect the renamed ID.

### Step 3: Create the patch

```bash
dbpatch addpatch -n <layer-description>
```

This creates the patch folder and updates `patches.json` automatically. Do not edit `patches.json` by hand.

Then rename the folder (and the ID in `patches.json`) to match the SCENARIO.md timeline.

### Step 4: Write the SQL files

Add numbered SQL files to the new patch folder. Files execute alphabetically — use numeric prefixes to control order.

```
Patches/202401290915-3421-add-employee-roles/
+-- 1_role.sql              <- CREATE TABLE Role
+-- 2_employee_roleid.sql   <- ALTER TABLE Employee ADD COLUMN RoleId
+-- 3_fk_roleid.sql         <- ALTER TABLE Employee ADD CONSTRAINT FK_RoleId
```

**Translate SCHEMA_DESIGN.md logical types to platform SQL** using the platform translation table at the end of this guide.

**Handle circular references** using the two-phase pattern: create tables first, add foreign keys in separate files afterward.

**Add indexes** on all foreign key columns (unless the platform indexes FKs automatically).

### Step 5: Write seed data (if the layer includes reference tables)

Seed data belongs in the patch, not in `test-data/`. Add a numbered file at the end of the patch:

```
+-- 4_seed_leave_types.sql
```

```sql
INSERT INTO LeaveType (Name, IsPaid, RequiresApproval, IsActive)
VALUES
    ('Vacation',     1, 1, 1),
    ('Sick Leave',   1, 0, 1),
    ('Personal Day', 1, 1, 1),
    ('Unpaid Leave', 0, 1, 1),
    ('Bereavement',  1, 0, 1),
    ('Jury Duty',    1, 0, 1);
```

### Step 6: Verify dependencies in patches.json

After `dbpatch addpatch`, check that `dependsOn` in `patches.json` lists the correct parent patches. The CLI adds all current "open" patches as dependencies by default — verify this matches the layer dependency graph in `SCHEMA_DESIGN.md`.

For example, Layer 2 must depend on all three Layer 1 patches:

```json
{
  "id": "202402011400-8765-create-performance-reviews",
  "dependsOn": [
    "202401290915-3421-add-employee-roles",
    "202401291030-5678-add-salary-tracking",
    "202401291115-9012-add-leave-tracking"
  ]
}
```

### Step 7: Build and validate

```bash
# Bring up the database container
docker compose up -d

# Apply patches
dbpatch build

# Confirm the patch is in InstalledPatches
# (run a validation query against the target database)
```

Run validation queries to confirm the tables, columns, and constraints are correct. Check that foreign keys work by inserting test rows.

If `dbpatch build` fails:

- Read the error message — it usually identifies the failing SQL file.
- Fix the SQL file and re-run `dbpatch build`.
- Do not retry the same failing build without a change.

### Step 8: Add CRUD stored procedures

For each new table, add stored procedures to `Code/`. These run on every `dbpatch build` (idempotent — they drop and recreate on each run).

See the Code folder section below for naming conventions.

### Step 9: Update layer status in SCHEMA_DESIGN.md

Change the layer's status from `📋` to `✅` in the layer summary table.

---

## DBPatch v2 Reference

### Critical rules

**DO NOT manually edit `patches.json`.** The CLI manages this file. Manual edits will be overwritten or cause conflicts. Always use `dbpatch addpatch -n <name>`.

**DO generate SQL from `SCHEMA_DESIGN.md`.** Never copy SQL files from another implementation — generate fresh SQL for the target platform.

**DO copy ScriptOverrides only for matching ODBC platforms.** See the decision tree above.

### Patch ID format

```
YYYYMMDDHHMMSS-RAND-description
```

- `YYYYMMDDHHMMSS` — Timestamp (match SCENARIO.md)
- `RAND` — 4-digit random number (generated by CLI)
- `description` — Kebab-case patch name

Examples:
```
202401270230-6495-create-employees-and-departments
202401290915-3421-add-employee-roles
202402011400-8765-create-performance-reviews
```

### patches.json structure

```json
{
  "DatabaseType": "odbc",
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
    }
  ]
}
```

The `description` field is NOT part of the DBPatch v2 schema. Use SQL comments for documentation.

### Execution order

1. **Patches:** Run once, in dependency order (topological sort of `dependsOn` graph). Tracked in `InstalledPatches` table — never re-run.
2. **Within each patch:** SQL files run alphabetically. Use `1_`, `2_`, `3_` prefixes.
3. **Code folder:** Runs on every `dbpatch build`, after all patches. Files run by suffix order (`.view.sql` -> `.udf.sql` -> `.sproc.sql` -> `.trigger.sql`). Not tracked — always executed. Scripts must be idempotent.

### Code folder naming

Format: `<ObjectName>.<suffix>.sql`

| Suffix | Object type | Pass |
|---|---|---|
| `.view.sql` | Views | 1 |
| `.udf.sql` | User-defined functions | 2 |
| `.view2.sql` | Views with view dependencies | 3 |
| `.udf2.sql` | Functions with function dependencies | 4 |
| `.sproc.sql` | Stored procedures | 7 |
| `.sproc2.sql` | Stored procedures that call other sprocs | 8 |
| `.trigger.sql` | Triggers | 10 |

Use numbered suffixes (`.view2.sql`, `.sproc2.sql`) only when an object depends on another object of the same type. Most objects use the base suffix.

All Code folder scripts must use `DROP ... IF EXISTS` or `CREATE OR REPLACE` patterns.

### Patches vs Code folder

| Use Patches/ for | Use Code/ for |
|---|---|
| CREATE TABLE | Stored procedures |
| ALTER TABLE | Views |
| CREATE INDEX | User-defined functions |
| Data migrations | Triggers |
| One-time seed data | |

### Circular reference pattern

When two tables reference each other:

```sql
-- 1_employee.sql -- Create Employee WITHOUT the DepartmentId FK
CREATE TABLE Employee (
    EmployeeId INT AUTO_INCREMENT PRIMARY KEY,
    FirstName  VARCHAR(50) NOT NULL,
    DepartmentId INT NULL       -- column exists, FK added later
);

-- 2_department.sql -- Create Department WITHOUT the DepartmentHeadId FK
CREATE TABLE Department (
    DepartmentId    INT AUTO_INCREMENT PRIMARY KEY,
    Name            VARCHAR(100) NOT NULL,
    DepartmentHeadId INT NULL    -- column exists, FK added later
);

-- 3_department_fk.sql -- Add FK now that both tables exist
ALTER TABLE Department
ADD CONSTRAINT FK_Department_DepartmentHeadId
    FOREIGN KEY (DepartmentHeadId) REFERENCES Employee(EmployeeId)
    ON DELETE SET NULL;

-- 4_employee_fk.sql
ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_DepartmentId
    FOREIGN KEY (DepartmentId) REFERENCES Department(DepartmentId)
    ON DELETE SET NULL;
```

### ScriptOverrides reference

Required for ODBC projects. Three files:

**`InitPatchTable.sql`** — Creates the InstalledPatches tracking table (MySQL example):

```sql
CREATE TABLE IF NOT EXISTS InstalledPatches (
    PatchId      INT AUTO_INCREMENT PRIMARY KEY,
    PatchName    VARCHAR(255) NOT NULL,
    InstalledDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**`AddInstalledPatch.sql`** — Records a completed patch:

```sql
INSERT INTO InstalledPatches (PatchName) VALUES (?);
```

**`GetInstalledPatches.sql`** — Returns the list of installed patches:

```sql
SELECT PatchName FROM InstalledPatches;
```

For new ODBC platforms, write these using the target platform's DDL syntax. For a second ODBC MySQL implementation, copy from the existing one.

### Configuration files

| File | Check in? | Contains |
|---|---|---|
| `patches.json` | Yes | Patch graph, code file patterns, database type |
| `patches.local.json` | No (gitignore) | Connection string |
| `ScriptOverrides/` | Yes | Platform-specific DBPatch internals |

---

## DBPatch v3

> **Stub** — DBPatch v3 support is planned but not yet implemented in this repository.

When implemented, this section will cover:

- v3 configuration format differences from v2
- Native driver setup (no ODBC, no ScriptOverrides)
- Migration path from a v2 implementation

---

## Raw SQL (No Migration Tool)

> **Stub** — Raw SQL implementations are planned for scenarios where DBPatch is not in scope.

When implemented, this section will cover:

- Folder structure for ordered SQL scripts
- Naming conventions for execution order
- Manual tracking of applied scripts
- CI/CD approach without a migration framework

---

## Test Data Loading

### Structure

Test data lives at the **scenario root**, shared by all implementations:

```
<Scenario-DB>/
+-- test-data/
    +-- data-manifest.json      <- Load order + column type hints
    +-- employees.csv
    +-- departments.csv
    +-- roles.csv
    +-- ...
```

Each implementation has its own loader that reads from `../../test-data/`:

```
<Scenario-DB>/dbpatchv2/odbc-mysql/
+-- load-test-data.ps1
```

### data-manifest.json

```json
{
  "loadOrder": ["roles", "departments", "employees", "salaries"],
  "tables": {
    "employees": {
      "file": "employees.csv",
      "columns": {
        "EmployeeId": "integer",
        "HireDate": "date",
        "IsActive": "boolean",
        "DepartmentId": "integer|nullable"
      }
    }
  }
}
```

### CSV conventions

- Column names match `SCHEMA_DESIGN.md` logical names
- Dates: ISO 8601 (`2024-01-27`)
- Booleans: `1` / `0`
- NULL: empty field
- Encoding: UTF-8

### Self-referencing FKs

Tables with self-references (e.g., `Employee.ManagerId`) require a two-pass load:

1. Insert all rows with `ManagerId = NULL`
2. UPDATE rows to set `ManagerId` based on a second pass

Document this in `data-manifest.json` or `load-test-data.ps1` comments.

### Platform bulk import commands

| Platform | Command |
|---|---|
| MySQL | `LOAD DATA LOCAL INFILE 'file.csv' INTO TABLE ...` |
| PostgreSQL | `COPY tablename FROM 'file.csv' CSV HEADER` |
| SQL Server | `BULK INSERT tablename FROM 'file.csv' WITH (FORMAT = 'CSV', ...)` |

### Data tiers

| Tier | Content | Location | Committed? |
|---|---|---|---|
| Seed / reference | Lookup table values (LeaveType, ProjectStatus, etc.) | SQL INSERT files inside patches | Yes |
| Demo | 5-20 rows per table | `test-data/*.csv` | Yes (keep < 500 KB per scenario) |
| Volume | Realistic large dataset | Generated locally by script | No |

---

## Platform Translation Reference

Translate `SCHEMA_DESIGN.md` logical types to platform-specific SQL:

| Logical Type | MySQL | SQL Server | PostgreSQL |
|---|---|---|---|
| `identifier, auto-generated` | `INT AUTO_INCREMENT` | `INT IDENTITY(1,1)` | `SERIAL` |
| `text, up to X characters` | `VARCHAR(X)` | `VARCHAR(X)` | `VARCHAR(X)` |
| `text, unlimited` | `TEXT` | `VARCHAR(MAX)` | `TEXT` |
| `boolean` | `TINYINT(1)` | `BIT` | `BOOLEAN` |
| `date` | `DATE` | `DATE` | `DATE` |
| `datetime` | `DATETIME` | `DATETIME2` | `TIMESTAMP` |
| `decimal(P,S)` | `DECIMAL(P,S)` | `DECIMAL(P,S)` | `NUMERIC(P,S)` |
| `integer` | `INT` | `INT` | `INTEGER` |
| `large text` | `TEXT` | `VARCHAR(MAX)` | `TEXT` |

**Required/Optional:**
- Required -> `NOT NULL`
- Optional -> `NULL`

**Default values:**
- `boolean, default true` -> MySQL: `TINYINT(1) NOT NULL DEFAULT 1`, SQL Server: `BIT NOT NULL DEFAULT 1`, PostgreSQL: `BOOLEAN NOT NULL DEFAULT TRUE`

---

## Common Mistakes

| Mistake | Correct approach |
|---|---|
| Manually editing `patches.json` | Use `dbpatch addpatch -n <name>` |
| Copying SQL from another implementation | Generate fresh SQL from `SCHEMA_DESIGN.md` |
| Copying ScriptOverrides for the wrong platform | Check the decision tree above |
| Creating tables with circular FKs in one file | Create tables first, add FKs in separate numbered files |
| Missing indexes on foreign key columns | Add `CREATE INDEX` for every FK column |
| Using platform syntax in `SCHEMA_DESIGN.md` | Keep `SCHEMA_DESIGN.md` platform-agnostic |
| Checking in `patches.local.json` | Add to `.gitignore` — it contains connection strings |
| Forgetting to rename patch folder after `addpatch` | Match the timestamp in `SCENARIO.md` |
| Setting wrong `dependsOn` | Verify against the dependency graph in `SCHEMA_DESIGN.md` |

---

## Examples

- `Employee-DB/dbpatchv2/odbc-mysql/` — Reference implementation, Layers 0-3
  - Circular reference pattern (Employee <-> Department)
  - Parallel dependencies (Layers 1a, 1b, 1c)
  - Multiple dependencies converging (Layer 2 depends on all of Layer 1)
  - CRUD stored procedures in `Code/`
