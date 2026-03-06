# dbexamples — Claude Code Entry Point

## What This Repo Is

A **database example factory**: scenarios with canonical docs (`SCHEMA_DESIGN.md` + `SCENARIO.md`) that drive AI-generated implementations using DBPatch v2/v3, raw SQL, or other migration tools, targeting MySQL, SQL Server, PostgreSQL, and others.

Every scenario is defined by two canonical documents at the **scenario root** (e.g., `Employee-DB/`):

| Document | Contains | Purpose |
|---|---|---|
| `SCHEMA_DESIGN.md` | Platform-agnostic tables, columns, relationships, layer dependencies | Source of truth for SQL generation |
| `SCENARIO.md` | Team narrative: who built it, why decisions were made, when | Context for realistic timestamps and commit stories |

Both documents are shared across all implementations. Never modify them for platform-specific reasons.

---

## Guides (Read These)

| Guide | When to read |
|---|---|
| [`docs/DEV_GUIDE.md`](../docs/DEV_GUIDE.md) | Start here — contributor orientation, structure, cast of characters |
| [`docs/SCHEMA_AND_SCENARIO_GUIDE.md`](../docs/SCHEMA_AND_SCENARIO_GUIDE.md) | Writing or extending `SCHEMA_DESIGN.md` / `SCENARIO.md` |
| [`docs/IMPLEMENTATION_GUIDE.md`](../docs/IMPLEMENTATION_GUIDE.md) | Adding a new platform+tool implementation or implementing new layers |

---

## Critical Rules

### patches.json
- **NEVER** edit `patches.json` manually — the dbpatch CLI owns this file
- Use `dbpatch addpatch -n <name>` to create patches; it generates the ID and updates dependencies

### ScriptOverrides
- **ODBC MySQL**: Copy `ScriptOverrides/` from an existing ODBC MySQL implementation
- **New ODBC platform** (Oracle, DB2, etc.): Write new ScriptOverrides from scratch — do not copy from MySQL
- **Native driver** (sqlserver, postgresql): No ScriptOverrides needed

### SQL Generation
- Always generate SQL from `SCHEMA_DESIGN.md` — never copy SQL between implementations
- Translate logical types to platform syntax:
  - `"identifier, auto-generated"` → MySQL: `INT AUTO_INCREMENT`, SQL Server: `INT IDENTITY`, PostgreSQL: `SERIAL`
  - `"boolean"` → MySQL: `TINYINT(1)`, SQL Server: `BIT`, PostgreSQL: `BOOLEAN`
  - `"datetime"` → MySQL: `DATETIME`, SQL Server: `DATETIME2`, PostgreSQL: `TIMESTAMP`
- Full type mapping table: see `docs/IMPLEMENTATION_GUIDE.md`

---

## Available Skills

Skills in `.claude/skills/` are auto-discovered by Claude Code.

| Skill | When to invoke |
|---|---|
| `dbpatch-v2-implement-layer` | Implementing a layer from `SCHEMA_DESIGN.md` into a DBPatch v2 project |
| `create-example` | Starting a new scenario (Phases 1–3: concept → schema → narrative) |
| `new-implementation` | Scaffolding a new tool+platform implementation of an existing scenario |

---

## Scenario Index

| Scenario | Path | Layers | Status |
|---|---|---|---|
| Employee-DB | `Employee-DB/` | 8 (Layers 0–7) | Layers 0–3 done in `odbc-mysql`; `odbc-mysql2` is AI-driven POC |
| ECommerce-DB | `ECommerce-DB/` (planned) | TBD | Not started |

---

## Key File Locations

- `Employee-DB/SCHEMA_DESIGN.md` — canonical schema spec (all 8 layers, platform-agnostic)
- `Employee-DB/SCENARIO.md` — team narrative (timestamps, decisions, developer stories)
- `Employee-DB/dbpatchv2/odbc-mysql/` — reference implementation (Layers 0–3 complete)
- `DEVELOPERS.md` — shared cast of characters for all scenarios
