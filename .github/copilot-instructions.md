# Database Examples - AI Agent Instructions

## Repository Purpose

This repository contains **reference database implementations** designed to test cross-platform database migration tools (dbpatch v2 and v3). Each example demonstrates incremental schema evolution through layered patches with comprehensive documentation enabling reproduction across MySQL, SQL Server, PostgreSQL, and other platforms.

## Architecture: Two-Document Pattern

Every database example uses a **dual documentation approach**:

1. **`SCHEMA_DESIGN.md`** - Platform-agnostic technical specification
   - Logical schema designs (e.g., "identifier, auto-generated" not "INT AUTO_INCREMENT")
   - Table definitions, relationships, implementation order
   - Design patterns and migration strategies
   - Target audience: AI agents, developers reproducing on any platform

2. **`DEVELOPMENT_SCENARIO.md`** - Collaborative development narrative
   - Realistic team stories showing HOW and WHY decisions were made
   - Developer personalities, timestamps, conversations, code reviews
   - Demonstrates incremental patch evolution through team collaboration
   - Target audience: Humans learning database design, AI understanding context

**Critical:** Keep both documents synchronized. SCHEMA_DESIGN provides technical specs; DEVELOPMENT_SCENARIO provides the human story. Cross-reference them at the top of each file.

## DBPatch Framework Structure

### Patch Organization
- `patches.json` - Defines patch order and dependencies (directed acyclic graph)
- `Patches/{timestamp-id}/` - Each folder contains numbered SQL files (1_table.sql, 2_fk.sql)
- `Code/` - Stored procedures, views, functions (`.sproc.sql`, `.view.sql`, `.udf.sql`)
- Patch IDs format: `YYYYMMDDHHMMSS-RAND-description` (e.g., `202401270230-6495-create-employees-and-departments`)

### Execution Order
1. Patches run in dependency order (topological sort of `dependsOn` graph)
2. Within each patch: SQL files execute alphabetically (1_*, 2_*, 3_*)
3. After all patches: Code folder files run by suffix order (.view.sql → .sproc.sql → .trigger.sql)

### Critical Pattern: Circular References
**Example:** Employee ↔ Department (Layer 0)
- Departments have DepartmentHeadId (FK to Employee)
- Employees have DepartmentId (FK to Department)

**Solution:** Create tables first, add FKs second
```
1_employee.sql       -- CREATE TABLE Employee (no FK)
2_department.sql     -- CREATE TABLE Department (no FK)  
3_departments_fk_*.sql    -- ALTER TABLE Department ADD CONSTRAINT FK_DepartmentHeadId
4_employees_fk_*.sql      -- ALTER TABLE Employee ADD CONSTRAINT FK_DepartmentId
```

## Layer-Based Schema Evolution

### Current Example: Employee Database (8 Layers)
- **Layer 0:** Foundation (Employee, Department) - Circular reference demo
- **Layer 1a/b/c:** Parallel deployment (Roles, Salary, Leave) - No interdependencies
- **Layer 2:** Performance Reviews - Depends on ALL Layer 1
- **Layer 3:** Projects - Builds on Layer 2
- **Layer 4:** Technical Debt - Reference tables (LeaveType, ProjectStatus, PerformanceRating)
- **Layer 5:** Soft Delete - Adds IsDeleted/DeletedAt/DeletedBy to all tables
- **Layer 6:** Teams & Management - Matrix org, dotted-line reporting
- **Layer 7:** Skills Tracking - Employee competencies, project requirements

**Status:** Only Layers 0-3 implemented. Layers 4-7 documented in SCHEMA_DESIGN.md for future implementation.

### Intentional Technical Debt
`EmployeeLeave.LeaveBalance` is acknowledged poor design (should be per-employee not per-leave-record). Documented as TODO in README and addressed in Layer 4 specs. This demonstrates realistic refactoring scenarios.

## When Creating New Examples

1. **Start with SCHEMA_DESIGN.md:** Define logical schema platform-agnostically
2. **Create DEVELOPMENT_SCENARIO.md:** Write realistic dev story using team from `DEVELOPERS.md`
3. **Implement patches progressively:** Layer 0 → 1 → 2, documenting as you go
4. **Use realistic timestamps:** Business hours (9 AM - 5 PM), Monday-Friday
5. **Avoid pedagogical sections:** No "Key Takeaways" or "Why it mattered" - keep it as a real scenario

## Platform Translation Guidelines

From SCHEMA_DESIGN.md to platform SQL:
- "identifier, auto-generated" → MySQL: `INT AUTO_INCREMENT`, SQL Server: `INT IDENTITY`, PostgreSQL: `SERIAL`
- "text, up to X characters" → `VARCHAR(X)`
- "boolean" → MySQL: `TINYINT(1)`, SQL Server: `BIT`, PostgreSQL: `BOOLEAN`
- "datetime" → Platform-specific timestamp types

## Tools & Utilities

- `tools/create-plantumlErd.ps1` - Generates ERD using SchemaCrawler Docker image
- Requires `sc_username` and `sc_password` environment variables
- Output: PlantUML diagrams in `docs/` folders

## Key File Locations

- `/README.md` - Repository overview, current/planned implementations
- `/DEVELOPERS.md` - Reusable developer personas for scenarios
- `/Employee-DB/dbpatchv2/odbc-mysql/` - Current MySQL implementation (Layers 0-3)
- `/Employee-DB/dbpatchv2/odbc-mysql/patches.json` - Patch dependency graph
- `/Employee-DB/dbpatchv2/odbc-mysql/SCHEMA_DESIGN.md` - Technical specs (all 8 layers)
- `/Employee-DB/dbpatchv2/odbc-mysql/DEVELOPMENT_SCENARIO.md` - Team collaboration story

## Development Philosophy

This is a **teaching and testing repository**, not production code. Design decisions (like LeaveBalance placement) are sometimes intentionally suboptimal to demonstrate refactoring patterns and real-world technical debt scenarios.
