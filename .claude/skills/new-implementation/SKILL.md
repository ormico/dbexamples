---
name: new-implementation
description: Scaffold a new tool+platform implementation of an existing scenario — creates the folder structure, docker-compose.yml, ScriptOverrides, test-connection.ps1, load-test-data.ps1, and then implements each layer using the dbpatch-v2-implement-layer skill.
disable-model-invocation: true
argument-hint: "<scenario-path> <tool/platform> (e.g., Employee-DB dbpatchv2/odbc-mysql)"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(docker *)
  - Bash(docker compose *)
  - Bash(dbpatch *)
  - Bash(pwsh *)
  - Bash(mkdir *)
  - Bash(ls *)
  - Bash(cp *)
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

# Scaffold a New Implementation

You are scaffolding a new tool+platform implementation for an existing scenario. The arguments are: **$ARGUMENTS**

Expected format: `<scenario-path> <tool/platform>`
Example: `Employee-DB dbpatchv2/odbc-mysql`

If arguments are missing or ambiguous, ask the user for:
1. **Scenario path** — e.g., `Employee-DB` (must have `SCHEMA_DESIGN.md` and `SCENARIO.md`)
2. **Tool** — e.g., `dbpatchv2`, `dbpatchv3`, `rawsql`
3. **Platform** — e.g., `odbc-mysql`, `odbc-sqlserver`, `native-postgresql`
4. **Database name** — what to name the database (e.g., `EmployeeDB`)
5. **Database credentials** — root password for docker-compose and test-connection.ps1

This skill handles DBPatch v2 implementations. For v3 or raw SQL, the skill will note what needs adaptation.

---

## Phase 0: Read the Scenario

Before creating anything, read:

1. `<scenario>/SCHEMA_DESIGN.md` — understand all layers, tables, and dependency graph
2. `<scenario>/SCENARIO.md` — understand the timeline (used by layer implementation)
3. If an existing implementation of the same platform exists, read its folder structure for reference (e.g., if adding `odbc-mysql2`, read `odbc-mysql/`)

Identify:
- Total number of layers to implement
- Whether a reference implementation already exists for this platform (affects ScriptOverrides)
- The database platform (MySQL, SQL Server, PostgreSQL)

---

## Phase 1: Create the Folder Structure

```bash
mkdir -p <scenario>/dbpatchv2/<platform>/Patches
mkdir -p <scenario>/dbpatchv2/<platform>/Code
mkdir -p <scenario>/dbpatchv2/<platform>/ScriptOverrides
```

---

## Phase 2: Initialize DBPatch

```bash
cd <scenario>/dbpatchv2/<platform>
dbpatch init --dbtype odbc
```

This creates `patches.json`. Verify it was created with the correct `DatabaseType`.

---

## Phase 3: ScriptOverrides

Determine which ScriptOverrides to use:

```
Is this ODBC (--dbtype odbc)?
|
+-- YES: Does an existing implementation for the SAME database platform already exist in this repo?
|   |
|   +-- YES (e.g., second odbc-mysql): COPY ScriptOverrides from that implementation.
|   |
|   +-- NO (first time with this platform via ODBC): CREATE new ScriptOverrides.
|
+-- NO (native driver): No ScriptOverrides needed.
```

**Copy from existing ODBC MySQL implementation:**
```bash
cp <scenario>/dbpatchv2/odbc-mysql/ScriptOverrides/* ScriptOverrides/
```

**Create new for a new ODBC platform** — three files required:

`ScriptOverrides/InitPatchTable.sql` — creates the tracking table using target platform DDL
`ScriptOverrides/AddInstalledPatch.sql` — inserts a completed patch record
`ScriptOverrides/GetInstalledPatches.sql` — returns all installed patch names

See `docs/IMPLEMENTATION_GUIDE.md` for the MySQL reference implementation of these files.
Never copy ScriptOverrides from a different database platform.

---

## Phase 4: docker-compose.yml

Create `docker-compose.yml` to spin up the database. Use the existing `odbc-mysql/docker-compose.yml` as a reference if one exists.

MySQL example:
```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: <scenario-lower>-mysql
    environment:
      MYSQL_ROOT_PASSWORD: yourpassword
      MYSQL_DATABASE: <DatabaseName>
    ports:
      - "3306:3306"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
```

Add `init-scripts/01-init.sql` if initial setup SQL is needed (e.g., character set, timezone).

---

## Phase 5: patches.local.json

Create a **template** that the developer fills in locally (this file is gitignored):

```json
{
  "ConnectionString": "Driver={MySQL ODBC 8.0 Driver};Server=localhost;Port=3306;Database=<DatabaseName>;Uid=root;Pwd=yourpassword;"
}
```

Add `patches.local.json` to the implementation's `.gitignore` if not already present.

---

## Phase 6: test-connection.ps1

Create a PowerShell script that verifies the database is reachable before running `dbpatch build`.

Use the existing `odbc-mysql/test-connection.ps1` as a reference if one exists. If not, write a script that:
- Reads the connection string from `patches.local.json`
- Attempts a simple query (`SELECT 1`)
- Reports success or failure with a clear message

---

## Phase 7: load-test-data.ps1 (stub)

Create a stub `load-test-data.ps1` that will load CSVs from `../../test-data/`:

```powershell
# load-test-data.ps1
# Loads demo test data from ../../test-data/ into the database.
# Reads ../../test-data/data-manifest.json for load order and column type hints.
#
# TODO: Implement after test-data/ CSVs and data-manifest.json are created (Step 6b).

Write-Host "Test data loader not yet implemented for this implementation."
Write-Host "See: Employee-DB/test-data/data-manifest.json for the data manifest."
```

Mark it as a stub — do not implement until `test-data/` CSVs exist.

---

## Phase 8: .gitignore

Create or update `.gitignore` in the implementation root:

```
patches.local.json
*.log
```

---

## Phase 9: README.md

Create a brief `README.md` for this implementation:

```markdown
# <Scenario> — DBPatch v2 / ODBC MySQL

Implementation of <Scenario> using DBPatch v2 with the ODBC plugin targeting MySQL 8.0.

## Requirements

- Docker Desktop
- DBPatch v2 CLI (`C:\dbpatch-v2\dbpatch.exe`)
- MySQL ODBC 8.0 Driver

## How to run

1. `docker compose up -d`
2. Copy `patches.local.json.example` to `patches.local.json` and set your connection string
3. `dbpatch build`

## Layers implemented

| Layer | Status |
|---|---|
| (populate as layers are implemented) |
```

---

## Phase 10: Implement Layers

For each layer in `SCHEMA_DESIGN.md` (in dependency order), invoke the `dbpatch-v2-implement-layer` skill:

```
/dbpatch-v2-implement-layer <layer-name>
```

Work through layers one at a time. Do not start a new layer until the previous one builds successfully.

After all layers are implemented, update the README.md layers table with final status.

---

## Phase 11: Summary

Report to the user:
- Implementation path created
- Layers implemented (count, names)
- Docker container status
- Any deviations or issues encountered
- Next step: create test data (`test-data/` CSVs + manifest) and implement `load-test-data.ps1`

---

## Important Reminders

- **NEVER copy ScriptOverrides from a different database platform**
- **NEVER edit `patches.json` manually** (except to rename a patch ID after a folder rename)
- **NEVER copy SQL from another implementation** — generate fresh from `SCHEMA_DESIGN.md`
- **Ask the user** before starting layer implementation if there are ambiguities in the spec
- **Leave Docker running** between layers — do not tear down the database mid-implementation
