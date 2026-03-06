# Database Examples - GitHub Copilot Instructions

## Repository Purpose

A database example factory. Every scenario is defined by two canonical documents at the **scenario root** (e.g., `Employee-DB/`):

1. **`SCHEMA_DESIGN.md`** — Platform-agnostic technical specification (the *what*)
2. **`SCENARIO.md`** — Realistic team development narrative (the *why* and *who*)

Both documents are shared across all implementations. Never modify them for platform-specific reasons.

## Guides

- [`docs/DEV_GUIDE.md`](../docs/DEV_GUIDE.md) — Contributor orientation, repo structure, cast of characters
- [`docs/SCHEMA_AND_SCENARIO_GUIDE.md`](../docs/SCHEMA_AND_SCENARIO_GUIDE.md) — Writing the two canonical docs
- [`docs/IMPLEMENTATION_GUIDE.md`](../docs/IMPLEMENTATION_GUIDE.md) — Adding a new implementation or layer

## Critical Rules

**patches.json**: Never edit manually. Use `dbpatch addpatch -n <name>` — the CLI generates the ID and updates dependencies.

**ScriptOverrides**:
- ODBC MySQL: Copy from an existing ODBC MySQL implementation
- New ODBC platform (Oracle, DB2, etc.): Write new scripts from scratch
- Native driver (sqlserver, postgresql): Not needed

**SQL generation**: Always generate from `SCHEMA_DESIGN.md`. Never copy SQL between implementations.

**Platform type mapping:**

| Logical | MySQL | SQL Server | PostgreSQL |
|---|---|---|---|
| identifier, auto-generated | INT AUTO_INCREMENT | INT IDENTITY | SERIAL |
| boolean | TINYINT(1) | BIT | BOOLEAN |
| datetime | DATETIME | DATETIME2 | TIMESTAMP |
| text, up to X chars | VARCHAR(X) | VARCHAR(X) | VARCHAR(X) |

## Repo Structure

```
/
├── docs/                        <- Contributor guides
├── DEVELOPERS.md                <- Shared actor cast (use for all scenarios)
├── Employee-DB/
│   ├── SCHEMA_DESIGN.md         <- Canonical, shared across all implementations
│   ├── SCENARIO.md              <- Canonical, shared across all implementations
│   ├── test-data/               <- Shared CSV + data-manifest.json
│   └── dbpatchv2/
│       ├── odbc-mysql/          <- Reference implementation (Layers 0-3)
│       └── odbc-mysql2/         <- AI-driven POC
└── ECommerce-DB/                <- Future scenario
```

## Scenario Index

| Scenario | Layers | Implementations |
|---|---|---|
| Employee-DB | 8 (Layers 0–7) | `odbc-mysql` (Layers 0–3 done), `odbc-mysql2` (POC) |
| ECommerce-DB | TBD | Planned |
