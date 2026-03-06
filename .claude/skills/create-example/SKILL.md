---
name: create-example
description: Create a new scenario from scratch — guides Phases 1-3 (concept, SCHEMA_DESIGN.md, SCENARIO.md), scaffolds the folder structure, stubs test-data/data-manifest.json, and updates README.md.
disable-model-invocation: true
argument-hint: "[scenario-name]"
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(mkdir *)
  - Bash(ls *)
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

# Create a New Scenario

You are creating a new database scenario from scratch. If a scenario name was provided it is: **$ARGUMENTS**

This skill covers **Phases 1–3**: concept → `SCHEMA_DESIGN.md` → `SCENARIO.md`. Phase 4 (first implementation) is handled by the `new-implementation` skill.

If no scenario name was provided, start at Phase 1 and gather it from the user.

---

## Phase 1: Concept

Gather the following from the user (ask if not already provided):

1. **Domain** — What kind of organization or system is this? (e.g., retail, HR, healthcare, logistics)
2. **Company or org name** — Give it a specific, fictional name to ground the narrative
3. **Problem to solve** — What business problem does the database address?
4. **Rough entities** — What are the main things the database tracks? (5–15 entities is a good range)
5. **Scale** — Small (~8 layers, ~10 tables), medium (~12 layers, ~15 tables), or large (~15+ layers, ~20+ tables)?
6. **Scenario folder name** — `PascalCase-DB` format, e.g., `Employee-DB`, `ECommerce-DB`, `Hospital-DB`

Read `DEVELOPERS.md` to see the available cast of characters. These developers will appear in the scenario narrative.

Present a concept summary to the user for approval before proceeding to Phase 2.

---

## Phase 2: Schema Design → `SCHEMA_DESIGN.md`

Use `EnterPlanMode` to design the full layer structure before writing anything.

**Layer design principles:**
- Layer 0: Core tables with no dependencies (the "root" entities)
- Layer 1+: Build on previous layers; each layer adds a coherent capability
- Parallel layers (1a, 1b, 1c): Independent features that can be built in any order
- Dependencies converge: a later layer that requires all of 1a/1b/1c lists all three as dependencies
- Add intentional technical debt: one or two design mistakes that get corrected later (adds realism)
- Aim for 1–3 tables per layer (avoid monolithic layers)

**Platform-agnostic spec conventions:**
- Column types use logical descriptions, not platform SQL:
  - Use `identifier, auto-generated` not `INT AUTO_INCREMENT`
  - Use `text, up to 100 characters` not `VARCHAR(100)`
  - Use `boolean` not `TINYINT(1)` or `BIT`
  - Use `datetime` not `DATETIME` or `DATETIME2`
  - Use `decimal(10,2)` format for decimals
- Mark required/optional explicitly: `required` / `optional, nullable`
- Note default values where they exist
- Note indexes on non-PK columns that will be needed

**Status markers:**
- `📋 Planned` — not yet implemented in any implementation
- `✅ Complete` — implemented in at least one implementation
- `⚠️ Blocked` — depends on something not yet done

Read `docs/SCHEMA_AND_SCENARIO_GUIDE.md` for the full authoring spec before writing.

**File location:** `<Scenario-DB>/SCHEMA_DESIGN.md` (at the scenario root, not inside any implementation folder)

After writing `SCHEMA_DESIGN.md`, present it to the user for review before proceeding to Phase 3.

---

## Phase 3: Scenario Writing → `SCENARIO.md`

Write the team narrative that gives the schema history and context.

**Narrative elements:**
- Pick 3–5 developers from `DEVELOPERS.md` who will "build" this database
- Assign roles: who leads, who implements, who reviews
- Set a realistic start date (past, not future) and a timeline spanning weeks or months
- Each layer has a date/time it was implemented — these become patch folder timestamps
- Include realistic details: design discussions, mistakes made, corrections, reviews
- Write developer conversations (brief exchanges, not essays)
- Make technical debt explicit: show the decision that caused it, and the later correction

**Timestamp rules:**
- Work happens during business hours (9am–6pm)
- Developers work in bursts with gaps (not one layer per hour all day)
- Multiple layers on one day is fine; a few weeks between phases is realistic
- Timestamps must be consistent with the dependency order in `SCHEMA_DESIGN.md`

Read `docs/SCHEMA_AND_SCENARIO_GUIDE.md` for the full scenario authoring spec and `DEVELOPERS.md` for developer profiles.

**File location:** `<Scenario-DB>/SCENARIO.md` (same folder as `SCHEMA_DESIGN.md`)

---

## Phase 4: Scaffold the Folder Structure

After the user approves `SCENARIO.md`, create the initial folder structure:

```bash
mkdir -p <Scenario-DB>/test-data
```

**Stub `test-data/data-manifest.json`:**

```json
{
  "loadOrder": [],
  "tables": {}
}
```

Leave `loadOrder` and `tables` empty — they will be populated when test data CSVs are created (Step 6b of the project plan).

**Do NOT create any implementation folder yet** — that is the `new-implementation` skill's job.

---

## Phase 5: Update `README.md`

Add the new scenario to the scenario index table in the repo root `README.md`:

- Add a row to the "Scenarios" table with: scenario name, description, layer count (from `SCHEMA_DESIGN.md`), status (`In progress`), implementations (`None yet`)
- Do not rewrite other sections of `README.md`

---

## Phase 6: Summary

Report to the user:
- Scenario name and folder created
- Layer count and structure summary
- Developers assigned from `DEVELOPERS.md`
- Timeline span
- Files created: `SCHEMA_DESIGN.md`, `SCENARIO.md`, `test-data/data-manifest.json`
- Next step: use `/new-implementation` to scaffold the first implementation

---

## Important Reminders

- **Both canonical docs are shared** across all implementations — never add platform-specific content to them
- **Get user approval** at the end of Phase 1 (concept) and Phase 2 (schema) before continuing
- **Timestamps in SCENARIO.md** drive patch folder names — make them realistic and consistent with the dependency order
- **Read `DEVELOPERS.md`** before assigning characters — use the defined profiles, don't invent new developers
