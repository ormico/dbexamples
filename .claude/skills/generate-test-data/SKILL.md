---
name: generate-test-data
description: Generate root test data CSVs and data-manifest.json for a scenario from SCHEMA_DESIGN.md. Root data represents the END STATE after all layers. Supports full generation and incremental updates when new layers add tables or columns. Use this skill whenever root/base test data needs to be created or updated for a database scenario.
disable-model-invocation: true
argument-hint: "[scenario-path]"
allowed-tools:
  - Bash(git *)
  - Bash(ls *)
  - Bash(mkdir *)
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

# Generate Root Test Data

You are generating root test data CSVs and a `data-manifest.json` for a database scenario. The scenario path (if provided) is: **$ARGUMENTS**

If no scenario path is provided, look for a `SCHEMA_DESIGN.md` in the current directory or walk up until found.

---

## Key Concept: What Is Root Test Data?

Root test data represents the **end-state schema** — after ALL layers are applied. Every table and every column from every layer is included, even columns added in later layers.

Root data is the **source of truth** from which per-layer data is derived (see `generate-layer-data` skill). It is never loaded directly into the database during incremental layer implementation — it exists so that layer data can be mechanically derived from it.

**Location:** `<scenario-root>/test-data/`

---

## Phase 0: Locate and Read

1. Find the **scenario root** — the directory containing `SCHEMA_DESIGN.md`.
2. Read `SCHEMA_DESIGN.md` fully. Extract every table, every column (across all layers), and all relationships.
3. Read `DEVELOPERS.md` from the repo root (if it exists) for character names to use in realistic data.
4. Check if `test-data/` already exists with CSVs and `data-manifest.json`:
   - **If yes** → this is an **incremental update** (Phase 2b).
   - **If no** → this is a **full generation** (Phase 2a).

---

## Phase 1: Plan the Data Model

Use `EnterPlanMode` before generating any data.

For each table in `SCHEMA_DESIGN.md` (across ALL layers), determine:

1. **Columns** — the full end-state column set. This means the FINAL state of each column after all layers have been applied. If a layer drops a column and replaces it (e.g., Layer 4 drops `LeaveType` text and adds `LeaveTypeId` FK), the end-state has only the replacement column.
2. **Column types** — from the logical type in `SCHEMA_DESIGN.md`
3. **Foreign key relationships** — which columns reference other tables
4. **Load order** — tables must be ordered so that referenced tables are loaded before referencing tables. Circular references (like Employee <-> Department) require deferred updates.
5. **Row count** — aim for 8-15 rows per table. Enough to exercise relationships and edge cases, not so many that the data is hard to review.
6. **Deferred updates** — identify circular FK relationships that require loading one table with NULLs, then updating after the referenced table is loaded.

### Consistency and Determinism Rules

These rules exist because root data is the single source of truth. Layer data is derived from it mechanically. If root data is inconsistent, every layer derivation inherits those problems.

- **Seed data is authoritative.** If `SCHEMA_DESIGN.md` specifies seed data for a reference table (e.g., LeaveType values, PerformanceRating scale), use those EXACT values — do not invent alternatives.
- **FK values must be valid.** Every FK column must reference an ID that exists in the target table's CSV. Check this during generation, not just validation.
- **Required columns must have values.** No empty fields in NOT NULL columns.
- **Cross-table consistency.** Related data must tell a coherent story:
  - Employee HireDate must precede their first Salary EffectiveDate
  - Leave dates must fall within employment period
  - Performance review dates must be after hire date
  - Project assignment dates must be after project start date
- **Use `DEVELOPERS.md` names** for employee data when available. This keeps the data recognizable across the repo.
- **Date ranges:** Span 1-3 years of realistic history. Use concrete dates, not placeholders.
- **Enum-like text columns** (before they become FK references in later layers) should use values that exactly match the seed data from future reference tables. Example: if Layer 4 defines a LeaveType table with "Vacation", "Sick Leave", "Personal Day" — the root data's LeaveType text values (for pre-Layer-4 columns) must use those exact strings. This ensures clean migration.

Present the plan showing: tables, row counts, load order, deferred updates, and any design decisions. Get user approval before proceeding.

---

## Phase 2a: Full Generation

Generate all files from scratch.

### Step 1: Generate CSVs

For each table (in load order):

1. Create `test-data/<table_name>.csv` (snake_case filename, e.g., `employee_leaves.csv`)
2. Header row = all end-state columns for that table
3. Data rows = realistic test data following the plan

**CSV format rules:**
- Use commas as delimiters, no quoting unless a value contains commas
- No trailing commas or whitespace
- Dates in `YYYY-MM-DD` format
- Decimals with appropriate precision (e.g., `75000.00` for salary)
- NULL/empty optional values = empty field (two adjacent commas)
- Boolean values as `1`/`0`
- First column should be the primary key with sequential integers starting at 1

### Step 2: Generate data-manifest.json

Create `test-data/data-manifest.json` with this structure:

```json
{
  "loadOrder": ["table_key_1", "table_key_2", ...],
  "deferredUpdates": [
    {
      "description": "Why this deferred update is needed",
      "sql": ["UPDATE ... SET ... WHERE ..."]
    }
  ],
  "tables": {
    "table_key": {
      "file": "filename.csv",
      "table": "ActualTableName",
      "columns": {
        "ColumnName": "type|nullable"
      },
      "notes": "Optional notes about loading this table"
    }
  }
}
```

**Column type values in manifest:** `integer`, `text`, `date`, `decimal`, `boolean`. Append `|nullable` for optional columns.

**Load order:** Must match the FK dependency order — referenced tables before referencing tables.

**Deferred updates:** SQL statements to run after all CSVs are loaded. Used for circular FK resolution (e.g., setting Department.DepartmentHeadId after employees are loaded).

---

## Phase 2b: Incremental Update

When root test data already exists and new layers have added tables or columns:

1. Read existing `data-manifest.json` and all existing CSVs.
2. Compare against current `SCHEMA_DESIGN.md` to find:
   - **New tables** — tables in the schema not yet in the manifest
   - **New columns** — columns added to existing tables by later layers
   - **Replaced columns** — columns dropped and replaced by a migration (e.g., `LeaveType` text → `LeaveTypeId` FK). The old column should be removed from the CSV and the new one added.
3. For new tables: generate new CSVs with data that is consistent with existing data (FK values must reference existing rows).
4. For new columns on existing tables: add the column to the CSV header and populate values for all existing rows.
5. For replaced columns: remove the old column, add the new one. Populate the new column with values that are consistent with what the old values would have mapped to. Example: if row had `LeaveType="Vacation"` and the LeaveType reference table maps Vacation to ID 1, the new `LeaveTypeId` column gets `1`.
6. Update `data-manifest.json` to include new tables/columns and remove dropped columns.
7. **Do NOT regenerate existing data** — preserve all existing rows, IDs, and values that are not directly affected by the column changes.

Present what will change before making edits. Get user approval.

---

## Phase 3: Validate

After generating/updating:

1. **FK integrity check** — for every FK column in every CSV, verify the referenced ID exists in the target table's CSV.
2. **Required column check** — verify no required columns have empty values.
3. **Uniqueness check** — verify primary keys are unique within each CSV.
4. **Load order check** — verify that `loadOrder` in the manifest has referenced tables before referencing tables.
5. **Deferred update check** — verify deferred update SQL references valid IDs from the CSVs.
6. **Cross-table consistency check** — verify date ordering and logical relationships hold (see Consistency Rules in Phase 1).

Report any issues found. Fix them before completing.

---

## Phase 4: Summary

Report:
- Tables generated/updated (with row counts)
- Load order
- Deferred updates
- Any data design decisions made
- If incremental: what changed vs. what was preserved

---

## Important Reminders

- Root data is the END STATE — include only columns that exist after ALL layers, not intermediate states
- Never hand-author layer-specific data here — that is the `generate-layer-data` skill's job
- FK values must be valid across all CSVs
- Use `DEVELOPERS.md` characters for employee names when available
- Keep row counts manageable (8-15 per table) — enough to test, easy to review
- Dates should be internally consistent (hire before salary, leave within employment period, etc.)
- Use exact seed data values from `SCHEMA_DESIGN.md` — do not invent alternatives
- Existing data is sacred during incremental updates — never regenerate rows that haven't changed
