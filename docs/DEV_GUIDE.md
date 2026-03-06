# Developer Guide

> **Start here if you want to contribute to this repository.**
> Read `README.md` first if you haven't already — it explains what this repo is and how to use the examples.

---

## What Do You Want to Do?

### Add a new database scenario

You want to model a new domain (e.g., e-commerce, hospital, school) from scratch.

1. Read [SCHEMA_AND_SCENARIO_GUIDE.md](SCHEMA_AND_SCENARIO_GUIDE.md) to write the two canonical docs.
2. Then read [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) to build the first implementation.

### Add a new implementation to an existing scenario

You want to implement an existing scenario (e.g., Employee-DB) on a different platform or tool (e.g., SQL Server, PostgreSQL, DBPatch v3).

1. Skip straight to [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md).
2. The scenario's `SCHEMA_DESIGN.md` and `SCENARIO.md` are already written — do not modify them.

### Implement more layers in an existing implementation

You want to add layers to an existing implementation (e.g., Employee-DB Layers 4-7 in `odbc-mysql`).

1. Read the scenario's `SCHEMA_DESIGN.md` for the target layer spec.
2. Follow [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for the per-layer workflow.

### Fix or extend a canonical document

You want to correct a design flaw in `SCHEMA_DESIGN.md` or extend it with new layers.

1. Read [SCHEMA_AND_SCENARIO_GUIDE.md](SCHEMA_AND_SCENARIO_GUIDE.md) for authoring conventions.
2. Both `SCHEMA_DESIGN.md` and `SCENARIO.md` must stay synchronized — if a layer changes in one, update the other.

---

## The Two-Document Pattern

Every database scenario is defined by two canonical documents at the **scenario root** (e.g., `Employee-DB/`):

| Document | What it contains | Who reads it |
|---|---|---|
| `SCHEMA_DESIGN.md` | Platform-agnostic technical spec: tables, columns, relationships, layer dependencies | AI agents and developers implementing on any platform |
| `SCENARIO.md` | Realistic team narrative: who built it, why decisions were made, when things happened | Humans understanding context; AI agents writing realistic histories |

**Rules:**

- Both documents live at the **scenario root**, not inside any implementation folder.
- They are shared by all implementations. Never modify them for platform-specific reasons.
- Always keep them synchronized: when `SCHEMA_DESIGN.md` gains a layer, `SCENARIO.md` should have the corresponding team story.
- Cross-reference each other at the top of each file.

---

## Repository Structure

```
/
├── docs/                            <- You are here
│   ├── DEV_GUIDE.md
│   ├── SCHEMA_AND_SCENARIO_GUIDE.md
│   └── IMPLEMENTATION_GUIDE.md
├── DEVELOPERS.md                    <- Cast of actors for all scenarios
├── README.md                        <- Public-facing overview
│
├── Employee-DB/
│   ├── SCHEMA_DESIGN.md             <- Canonical, shared across all implementations
│   ├── SCENARIO.md                  <- Canonical, shared across all implementations
│   ├── test-data/                   <- Shared CSV + manifest
│   └── dbpatchv2/
│       ├── odbc-mysql/              <- Implementation: DBPatch v2 + MySQL via ODBC
│       └── odbc-mysql2/             <- Implementation: AI-driven POC
│
└── ECommerce-DB/                    <- Future scenario
    ├── SCHEMA_DESIGN.md
    ├── SCENARIO.md
    └── ...
```

**Key structural rules:**

- `SCHEMA_DESIGN.md`, `SCENARIO.md`, and `test-data/` are at the **scenario root** — shared by all implementations.
- `load-test-data.ps1` is per-implementation (platform-specific) but reads from `../../test-data/`.
- `DEVELOPERS.md` is at the repo root — the actor cast is cross-scenario.
- Claude skills are in `.claude/skills/` — Claude Code auto-discovers them.
- `.github/workflows/` is reserved for GitHub Actions YAML only.

---

## The Cast of Characters

All scenarios share a common team of fictional developers. Do not invent new team members — use the existing cast from [`DEVELOPERS.md`](../DEVELOPERS.md).

| Name | Role | When to use |
|---|---|---|
| **Sarah Chen** | Senior Database Architect | Schema design decisions, code reviews, performance guidance, patterns |
| **Marcus Rodriguez** | Backend Developer | API concerns, implementation questions, pragmatic pushback on complexity |
| **Priya Patel** | Full-Stack Developer | UI/UX implications, security, cross-cutting concerns, clarifying questions |
| **David Kim** | DevOps Engineer | Deployment checklists, monitoring, infrastructure, rollback planning |

Each character has a distinct voice and perspective. See `DEVELOPERS.md` for full descriptions and [SCHEMA_AND_SCENARIO_GUIDE.md](SCHEMA_AND_SCENARIO_GUIDE.md) for how to write their dialogue.

---

## Example Creation Process

```
Phase 1: Concept
  └── Domain, company/org, problem to solve, rough entities, scale

Phase 2: Schema Design --> SCHEMA_DESIGN.md
  └── All planned layers (platform-agnostic), dependency graph, status markers

Phase 3: Scenario Writing --> SCENARIO.md
  └── Pick actors from DEVELOPERS.md, team narrative, realistic timestamps

Phase 3b: Test Data --> test-data/
  └── CSV per table + data-manifest.json (load order, column type hints)
  └── 5-20 rows/table for demo; generator script for volume data

Phase 4: First Implementation
  └── Scaffold folder + infrastructure (Docker, config, ScriptOverrides)
  └── Per layer: addpatch -> rename -> SQL -> build -> validate
  └── CRUD stored procedures, seed data in patches, load-test-data.ps1

Phase 5: Additional Implementations
  └── Same SCHEMA_DESIGN.md, SCENARIO.md, test-data/ -- no changes
  └── Fresh SQL per platform, new load-test-data.ps1

Phase 6: Iteration (re-enter at any phase)
  +-- New layers: SCHEMA_DESIGN.md -> SCENARIO.md -> SQL -> test
  +-- New test data: update CSVs + manifest, update loaders
  +-- Design fix: new corrective patch -> update both docs
  +-- New implementation: Phase 5
```

For Phases 1-3, see [SCHEMA_AND_SCENARIO_GUIDE.md](SCHEMA_AND_SCENARIO_GUIDE.md).
For Phases 4-5, see [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md).

---

## Available Claude Skills

The following skills are in `.claude/skills/` and can be invoked during implementation:

| Skill | When to use |
|---|---|
| `dbpatch-v2-implement-layer` | Implementing a layer from `SCHEMA_DESIGN.md` into a DBPatch v2 project |
| `create-example` | Starting a new scenario (Phases 1-3: concept -> schema -> scenario) |
| `new-implementation` | Scaffolding a new tool+platform implementation of an existing scenario |

---

## Scenario Index

| Scenario | Layers | Tables | Implementations |
|---|---|---|---|
| Employee-DB | 8 (Layers 0-7) | ~14 tables | `odbc-mysql` (Layers 0-3 done), `odbc-mysql2` (POC) |
| ECommerce-DB | TBD | TBD | None yet |
