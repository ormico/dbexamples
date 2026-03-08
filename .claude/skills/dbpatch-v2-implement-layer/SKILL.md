---
name: dbpatch-v2-implement-layer
description: Implement one layer from SCHEMA_DESIGN.md into a DBPatch v2 project. Reads the layer spec and SCENARIO.md timestamp, creates and renames the patch, writes platform SQL, builds against Docker, validates, and marks the layer complete in SCHEMA_DESIGN.md.
disable-model-invocation: true
argument-hint: "<layer-name> [path/to/implementation]"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(docker *)
  - Bash(docker compose *)
  - Bash(dbpatch *)
  - Bash(pwsh *)
  - Bash(mkdir *)
  - Bash(ls *)
  - Bash(mv *)
  - Edit
  - Write
  - Read
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - EnterPlanMode
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Implement a DBPatch v2 Layer

You are implementing one layer from a scenario's `SCHEMA_DESIGN.md` into a DBPatch v2 implementation. The layer name or number is: **$ARGUMENTS**

If no layer is specified, ask the user which layer to implement and in which implementation directory before proceeding.

---

## Phase 0: Locate Files

Identify the working paths. If `$ARGUMENTS` includes a path, use it. Otherwise, infer from the current directory:

1. **Scenario root** — contains `SCHEMA_DESIGN.md` and `SCENARIO.md`. Walk up from the current directory until found.
2. **Implementation root** — the current directory if it contains `patches.json`, or ask the user.

```bash
# Confirm you are in the right implementation directory
ls patches.json
```

If `patches.json` is not found, ask the user for the implementation path before continuing.

---

## Phase 1: Read the Specification

Read both canonical documents:

1. **`SCHEMA_DESIGN.md`** — Find the target layer. Note:
   - All tables to create and their columns, types, constraints
   - ALTER TABLE changes to existing tables
   - Foreign keys and indexes to add
   - Seed data to insert (reference/lookup tables)
   - Layer dependencies (which patches this layer must `dependsOn`)
   - Current layer status (must be `📋` — do not re-implement a `✅` layer)

2. **`SCENARIO.md`** — Find the date/time this layer was implemented. You will use this for the patch ID timestamp.

If the layer status is already `✅`, stop and tell the user — do not re-implement.

---

## Phase 2: Plan

Use `EnterPlanMode` before writing any SQL or creating any files:

- Identify each SQL file needed (tables, FKs, indexes, seed data)
- Determine the correct file numbering order (circular references require two-phase pattern — see below)
- Confirm which existing patches this layer `dependsOn` (must match `SCHEMA_DESIGN.md` dependency graph)
- Confirm the timestamp from `SCENARIO.md`

Present the plan. Do not proceed to Phase 3 without user approval or unless the plan is unambiguous.

---

## Phase 3: Create and Rename the Patch

```bash
# From the implementation root
dbpatch addpatch -n <layer-description>
```

This creates the patch folder with the current timestamp and updates `patches.json`. Then:

1. **Rename the folder** to use the SCENARIO.md timestamp:
   ```bash
   # Example: old name was 202503051423-7812-add-employee-roles
   # SCENARIO.md says this layer was implemented 2024-01-29 at 09:15
   mv Patches/202503051423-7812-add-employee-roles Patches/202401290915-7812-add-employee-roles
   ```
   Keep the random 4-digit suffix — only change the timestamp portion.

2. **Update `patches.json`** — this is the only permitted manual edit, scoped strictly to the rename:
   - Change this patch's `id` to match the renamed folder name
   - Update any `dependsOn` entries in *other* patches that reference the old `id`
   - Do not add, remove, reorder, or change any other fields — the CLI owns everything else

---

## Phase 4: Write the SQL Files

Add numbered `.sql` files to the new patch folder. Files execute alphabetically — use numeric prefixes to control order.

**Translate SCHEMA_DESIGN.md logical types to platform SQL:**

| Logical Type | MySQL |
|---|---|
| `identifier, auto-generated` | `INT AUTO_INCREMENT PRIMARY KEY` |
| `text, up to X characters` | `VARCHAR(X)` |
| `text, unlimited` | `TEXT` |
| `boolean` | `TINYINT(1)` |
| `date` | `DATE` |
| `datetime` | `DATETIME` |
| `decimal(P,S)` | `DECIMAL(P,S)` |
| `integer` | `INT` |
| Required field | `NOT NULL` |
| Optional field | `NULL` |

**Full type mapping for other platforms:** see `docs/IMPLEMENTATION_GUIDE.md`.

**Circular reference pattern** (e.g., Employee <-> Department):
```
1_employee.sql        -- CREATE TABLE Employee (DepartmentId INT NULL -- no FK yet)
2_department.sql      -- CREATE TABLE Department (DepartmentHeadId INT NULL -- no FK yet)
3_department_fk.sql   -- ALTER TABLE Department ADD CONSTRAINT FK_DeptHead FOREIGN KEY ...
4_employee_fk.sql     -- ALTER TABLE Employee ADD CONSTRAINT FK_Dept FOREIGN KEY ...
```

**Add indexes** on all FK columns (MySQL does not auto-index FKs).

**Seed data** (reference/lookup tables): add as the last numbered file in the patch.

**Never copy SQL from another implementation.** Always generate fresh from `SCHEMA_DESIGN.md`.

---

## Phase 5: Build and Validate

```bash
# Start the database container (leave it running after — do not run docker compose down)
docker compose up -d

# Apply all patches
dbpatch build
```

If `dbpatch build` fails:
- Read the error message — it identifies the failing SQL file
- Fix the SQL and re-run `dbpatch build`
- Do not retry the same build without a change

**Validation queries** — after a successful build, run queries to confirm the layer is correct:

```bash
# Confirm tables were created (MySQL example)
docker exec <container-name> mysql -u root -p<password> <database> -e "SHOW TABLES;"

# Confirm columns and types
docker exec <container-name> mysql -u root -p<password> <database> -e "DESCRIBE <table>;"

# Confirm foreign keys
docker exec <container-name> mysql -u root -p<password> <database> \
  -e "SELECT * FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='<database>' AND REFERENCED_TABLE_NAME IS NOT NULL;"

# Confirm patch was recorded
docker exec <container-name> mysql -u root -p<password> <database> -e "SELECT * FROM InstalledPatches;"
```

Surface any errors or unexpected results to the user before continuing.

Leave the container running. Never run `docker compose down` during implementation.

---

## Phase 6: Add CRUD Stored Procedures (if tables were created)

For each new table in this layer, add stored procedures to `Code/`. These run on every `dbpatch build` (idempotent — drop and recreate each time).

Naming: `<Operation><TableName>.<suffix>.sql`

| Operation | File suffix | Pattern |
|---|---|---|
| Create | `.sproc.sql` | `DROP PROCEDURE IF EXISTS Create<Table>; DELIMITER $$ CREATE PROCEDURE Create<Table>(params) BEGIN INSERT ...; END $$ DELIMITER ;` |
| Read | `.sproc.sql` | SELECT by primary key |
| Update | `.sproc.sql` | UPDATE by primary key |
| Delete | `.sproc.sql` | DELETE by primary key |

All Code files must use `DROP ... IF EXISTS` before `CREATE`.

---

## Phase 7: Update SCHEMA_DESIGN.md

Change the layer's status from `📋` to `✅` in the layer summary table.

---

## Phase 8: Summary

Report to the user:
- Layer implemented: name, patch ID, files created
- Validation results (tables, row counts if seed data was inserted)
- Any deviations from the spec and why
- Next layer to implement (from the dependency graph in SCHEMA_DESIGN.md)

---

## Important Reminders

- **NEVER edit `patches.json` directly** except to update the ID after a rename
- **NEVER copy SQL from another implementation** — generate fresh from `SCHEMA_DESIGN.md`
- **NEVER copy ScriptOverrides from a different database platform**
- **Ask before proceeding** if the spec is ambiguous or dependencies are unclear
- **Leave Docker running** — do not tear down the database between layers
