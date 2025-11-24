# AI Agent Guidance for Database Examples

This repository contains reference database implementations for testing cross-platform migration tools. This document provides high-level guidance for AI agents working with this codebase.

## Quick Reference

For detailed instructions on specific tasks, see these specialized guides:

- **[DBPatch v2 Guide](.github/workflows/DBPATCH_V2_GUIDE.md)** - How to use the dbpatch v2 framework to create patches, manage dependencies, and handle migrations
- **[Schema Design Guide](.github/workflows/SCHEMA_DESIGN_GUIDE.md)** - Writing platform-agnostic database specifications
- **[Scenario Writing Guide](.github/workflows/SCENARIO_WRITING_GUIDE.md)** - Creating realistic development narratives

## Core Principles

1. **Two-Document Pattern**: Every database example has both a technical specification (SCHEMA_DESIGN.md) and a collaborative narrative (DEVELOPMENT_SCENARIO.md)

2. **Platform Agnostic**: Schema designs use logical descriptions, not platform-specific syntax

3. **Incremental Evolution**: Databases evolve through layered patches with clear dependencies

4. **Realistic Scenarios**: Development narratives show real team dynamics, not pedagogical lessons

5. **Testing Focus**: This repository exists to test migration tools (dbpatch v2→v3) across platforms

## File Organization

```
/
├── AGENTS.md (this file)
├── DEVELOPERS.md (team personas for scenarios)
├── README.md (repository overview)
├── .github/
│   ├── copilot-instructions.md (GitHub Copilot specific guidance)
│   └── workflows/
│       ├── DBPATCH_V2_GUIDE.md
│       ├── SCHEMA_DESIGN_GUIDE.md
│       └── SCENARIO_WRITING_GUIDE.md
└── Employee-DB/
    └── dbpatchv2/
        └── odbc-mysql/
            ├── SCHEMA_DESIGN.md (technical specs)
            ├── DEVELOPMENT_SCENARIO.md (team story)
            ├── patches.json (dependency graph)
            └── Patches/ (SQL implementations)
```

## Common Tasks

### Implementing a New Layer

1. Read SCHEMA_DESIGN.md for the layer's technical specifications
2. Review DEVELOPMENT_SCENARIO.md for context and team decisions
3. Follow **[DBPatch v2 Guide](.github/workflows/DBPATCH_V2_GUIDE.md)** to create patches
4. Use realistic timestamps (business hours, Monday-Friday)
5. Update DEVELOPMENT_SCENARIO.md with the implementation story

### Creating a New Database Example

1. Start with **[Schema Design Guide](.github/workflows/SCHEMA_DESIGN_GUIDE.md)** to write SCHEMA_DESIGN.md
2. Use **[Scenario Writing Guide](.github/workflows/SCENARIO_WRITING_GUIDE.md)** to write DEVELOPMENT_SCENARIO.md
3. Implement patches progressively using **[DBPatch v2 Guide](.github/workflows/DBPATCH_V2_GUIDE.md)**
4. Keep both documents synchronized as you build

### Analyzing Existing Implementations

1. Check patches.json for the dependency graph
2. Read SCHEMA_DESIGN.md for what SHOULD be implemented
3. Read DEVELOPMENT_SCENARIO.md for WHY decisions were made
4. Inspect Patches/ folders for actual SQL implementations
5. Look for intentional technical debt (documented in README)

## Key Patterns

### Circular References
When tables reference each other (e.g., Employee ↔ Department):
- Create tables without foreign keys first
- Add foreign keys in separate SQL files afterward

### Layer Dependencies
- Layer 0: Foundation tables (may have circular refs)
- Layer 1a/b/c: Parallel deployments (no interdependencies)
- Layer 2+: Sequential, depends on previous layers

### Platform Translation
- "identifier, auto-generated" → MySQL: INT AUTO_INCREMENT, SQL Server: INT IDENTITY, PostgreSQL: SERIAL
- "text, up to X characters" → VARCHAR(X)
- "boolean" → MySQL: TINYINT(1), SQL Server: BIT, PostgreSQL: BOOLEAN
- "datetime" → Platform-specific timestamp types

## Getting Started

If you're new to this codebase:

1. Read the [README](README.md) for repository overview
2. Review [DEVELOPERS.md](DEVELOPERS.md) to meet the team personas
3. Explore `Employee-DB/dbpatchv2/odbc-mysql/` as the reference implementation
4. Read the specialized guides for your specific task
5. Look at existing patches to understand the pattern

## Questions or Unclear Tasks?

- Check if there's a specialized guide for your task
- Review existing implementations in Employee-DB for examples
- Consult SCHEMA_DESIGN.md for technical details
- Check DEVELOPMENT_SCENARIO.md for context and rationale
- Look at patches.json to understand dependencies
