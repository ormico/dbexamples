---
name: generate-layer-data
description: Derive per-layer test data from root CSVs by projecting to the schema state at each layer. Handles column additions, drops, and migrations (e.g., text column → FK reference). Use this skill when preparing test data for incremental layer implementation — it ensures each layer has exactly the right data for its schema state, and migration SQL has real data to transform.
disable-model-invocation: true
argument-hint: "<layer-name-or-number> [scenario-path]"
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

# Generate Layer Data

You are deriving per-layer test data for a specific layer from the root test data CSVs. The layer (and optional scenario path) is: **$ARGUMENTS**

If no layer is specified, ask the user which layer to generate data for. If no scenario path is given, find `SCHEMA_DESIGN.md` by walking up from the current directory.

---

## Key Concept: Layer Data Is a Projection of Root Data

Root test data (`test-data/*.csv`) represents the end-state schema after ALL layers. Layer data is a **mechanical derivation** — not new data. You are projecting root data down to the schema state that exists at a specific point in the layer sequence.

This matters because:
- Every value in layer data must trace back to a root data value (or a deterministic transformation of one)
- The same employee with ID 1 has the same name, hire date, etc. in every layer
- If you can't derive a value from root data, that's a signal the root data needs updating first

**Output location:** `<scenario-root>/test-data/layers/<layer-name>/`

---

## Phase 0: Locate and Read

1. Find the **scenario root** (contains `SCHEMA_DESIGN.md`).
2. Read `SCHEMA_DESIGN.md` fully — you need the complete layer dependency graph and every table/column definition.
3. Read all root test data CSVs from `test-data/` and `test-data/data-manifest.json`.
4. If an implementation directory exists (contains `patches.json` and `Patches/`), read the actual SQL files for the target layer and any earlier layers. The SQL reveals the precise migration operations — column adds, drops, renames, data transforms.
5. Identify the target layer and all layers it depends on (its full dependency chain).

---

## Phase 1: Build the Schema Evolution Model

This is the core of the skill. You need to understand what the database looks like at each point in the layer sequence.

### Step 1: Determine the cumulative layer sequence

The target layer has a dependency chain. For example, Layer 4 depends on Layer 1c, which depends on Layer 0. The cumulative sequence is: Layer 0 → Layer 1c → Layer 4.

But other layers may also need to be included if the target layer depends on them. Read the dependency graph from `SCHEMA_DESIGN.md` and compute the full ordered set of layers that must be applied before (and including) the target layer.

### Step 2: For each layer in the sequence, determine schema changes

Read `SCHEMA_DESIGN.md` and (if available) the patch SQL to determine what each layer does:

- **Tables created** — new tables introduced by this layer
- **Columns added** — new columns on existing tables (e.g., Layer 1a adds `RoleId` to Employee)
- **Columns dropped** — columns removed by migration (e.g., Layer 4 drops `LeaveType` text from EmployeeLeave)
- **Columns replaced** — a column is dropped and a new one takes its role (e.g., `LeaveType` text → `LeaveTypeId` FK)
- **Column constraints changed** — nullable → not-null transitions (e.g., Layer 1a makes `RoleId` NOT NULL after data population)

### Step 3: Compute the cumulative schema state

Starting from nothing, apply each layer's changes in order to build the schema state after the target layer. The result is:
- Which tables exist
- Which columns each table has (with types and nullability)
- Which FK relationships are active

---

## Phase 2: Plan the Layer Data

Use `EnterPlanMode` before generating files.

For each table in the cumulative schema state:

1. **List the columns** that exist at this point. These are the columns for the layer CSV.
2. **Map each column to root data:**
   - Column exists in root CSV with same name → direct copy
   - Column was replaced in a later layer (root has the replacement) → reverse-map. See "Handling Migrations" below.
   - Column doesn't exist in root data → this shouldn't happen. If it does, the root data needs updating first. Stop and tell the user.
3. **Determine which rows to include.** Generally, include all rows from the root CSV. But if a table didn't exist before this layer, it only appears in layers where it has been created.

### Handling Migrations (Reverse-Mapping)

This is the most important part. When a later layer replaces a column (e.g., Layer 4 replaces `LeaveType` text with `LeaveTypeId` FK), layers BEFORE that migration need the OLD column format.

**The algorithm:**

1. Identify the migration: `SCHEMA_DESIGN.md` says Layer 4 adds `LeaveTypeId` and drops `LeaveType`.
2. The root data has the end-state column (`LeaveTypeId` integer).
3. The reference table (LeaveType) maps IDs to names (root data: `1=Vacation`, `2=Sick Leave`, etc.).
4. For layers before the migration: reverse-map `LeaveTypeId` → `LeaveType` text using the reference table CSV.
   - Root row has `LeaveTypeId=1` → Layer data gets `LeaveType=Vacation`

**Where to find the mapping:**
- Read the reference table's root CSV (e.g., `test-data/leave_types.csv`)
- Match the FK value to the reference table's primary key
- Use the `Name` column (or equivalent) as the text value

**If the reverse mapping is ambiguous or the reference table doesn't exist yet in root data**, stop and tell the user — the root data likely needs to be updated first (using `generate-test-data`).

### Handling Columns Not Yet Added

For layers before a column is added, simply omit that column from the CSV. Example:
- Root `employees.csv` has `RoleId` column
- Layer 0 data for employees.csv does NOT include `RoleId` (it's added in Layer 1a)

### Handling Tables Not Yet Created

If a table is created by a layer that comes AFTER the target layer, it does not appear in the layer data at all. Only include tables that exist at the target layer's schema state.

Present the plan: tables, columns per table, any reverse-mappings needed, row counts. Get user approval.

---

## Phase 3: Generate Layer Data

### Step 1: Create the layer directory

```
test-data/layers/<layer-name>/
```

Use the layer name from `SCHEMA_DESIGN.md` (e.g., `layer-0-foundation`, `layer-1a-employee-roles`, `layer-4-technical-debt`).

### Step 2: Generate layer CSVs

For each table in the cumulative schema state:

1. Create `<table_name>.csv` in the layer directory
2. Header = columns that exist at this schema state
3. Data = projected/transformed from root CSV

**Projection rules:**
- Copy columns that exist in both root and layer schema unchanged
- Reverse-map replaced columns using reference table data
- Omit columns that don't exist yet at this layer
- Include ALL rows from the root CSV for tables that exist at this layer

**CSV format:** Same rules as root data — commas, YYYY-MM-DD dates, empty for NULL, `1`/`0` for booleans.

### Step 3: Generate layer-manifest.json

Create `test-data/layers/<layer-name>/layer-manifest.json`:

```json
{
  "layer": "Layer 0: Foundation",
  "cumulativeLayers": ["layer-0-foundation"],
  "description": "Schema state after Layer 0 is applied",
  "loadOrder": ["departments", "employees"],
  "deferredUpdates": [
    {
      "description": "Set DepartmentHeadId after employees are loaded",
      "sql": ["UPDATE Department SET DepartmentHeadId = 1 WHERE DepartmentId = 1"]
    }
  ],
  "tables": {
    "departments": {
      "file": "departments.csv",
      "table": "Department",
      "columns": {
        "DepartmentId": "integer",
        "Name": "text",
        "Description": "text|nullable",
        "DepartmentHeadId": "integer|nullable"
      }
    },
    "employees": {
      "file": "employees.csv",
      "table": "Employee",
      "columns": {
        "EmployeeId": "integer",
        "FirstName": "text",
        "LastName": "text"
      }
    }
  },
  "derivedFrom": {
    "rootManifest": "../../data-manifest.json",
    "reverseMappings": [
      {
        "table": "EmployeeLeave",
        "layerColumn": "LeaveType",
        "rootColumn": "LeaveTypeId",
        "referenceTable": "LeaveType",
        "referenceKey": "LeaveTypeId",
        "referenceValue": "Name"
      }
    ]
  }
}
```

The `derivedFrom` section documents how layer data was derived from root data. This makes the transformation reproducible and auditable. Include it even when there are no reverse mappings (just use an empty array).

### Step 4: Generate deferred updates

Deferred updates in the layer manifest should only include updates that are relevant at this schema state. For example:
- Layer 0: Department.DepartmentHeadId deferred update is needed (circular FK)
- Layer 1a: Same deferred update, plus potentially setting RoleId values on Employee

Deferred update SQL must use IDs that exist in the layer CSVs.

---

## Phase 4: Validate

1. **Column match** — every column in the layer CSV header must exist in the cumulative schema at this layer.
2. **No extra columns** — no columns that don't exist yet at this layer.
3. **FK integrity** — all FK values reference valid IDs within the layer's data set.
4. **Row consistency** — for shared columns, values must match root data exactly. Row with EmployeeId=1 must have the same FirstName in layer data as in root data.
5. **Reverse-mapping accuracy** — for reverse-mapped columns, spot-check that the mapping is correct (e.g., `LeaveTypeId=1` in root → `LeaveType=Vacation` in layer matches the reference table).
6. **Required columns** — no empty values in NOT NULL columns at this schema state.
7. **Deferred update IDs** — all IDs in deferred update SQL exist in the layer CSVs.

Report any issues. Fix before completing.

---

## Phase 5: Summary

Report:
- Layer generated and its cumulative dependency chain
- Tables included (with row counts and column counts)
- Columns omitted (not yet added at this layer)
- Reverse-mappings applied (if any)
- Deferred updates
- Any issues or decisions made

---

## Important Reminders

- Layer data is DERIVED, not invented. Every value traces back to root data.
- If you can't derive a value from root data, stop and tell the user — the root data likely needs updating first.
- Read the actual patch SQL (not just `SCHEMA_DESIGN.md`) when available. The SQL is the ground truth for what columns exist, what migrations happen, and what the exact operations are.
- The same row in different layer CSVs must be internally consistent — same PK, same values for shared columns.
- Migration layers are not special-cased — every layer potentially adds, modifies, or removes columns. The algorithm handles them all the same way: compute cumulative schema state, project root data to that state.
- Reference table seed data (from `SCHEMA_DESIGN.md`) is authoritative for reverse-mappings. Use the exact values specified.
