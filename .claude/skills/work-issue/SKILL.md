---
name: work-issue
description: Work on a GitHub issue end-to-end — reads the issue, creates a feature branch, plans the implementation, implements, validates with Docker + dbpatch, self-reviews, and commits.
disable-model-invocation: true
argument-hint: "<issue-number>"
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
  - Bash(mv *)
  - Edit
  - Write
  - Read
  - Glob
  - Grep
  - Agent
  - EnterPlanMode
  - EnterWorktree
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
---

# Work on GitHub Issue

You are implementing a GitHub issue end-to-end. The issue number is: **$ARGUMENTS**

If no issue number is provided, ask the user for one before proceeding.

---

## Phase 0: Setup — Branch

1. **Read the issue:**
   ```bash
   gh issue view $ARGUMENTS
   ```

2. **Create a feature branch** from `main`:
   ```bash
   git checkout main && git pull
   git checkout -b feature/<descriptive-branch-name>
   ```
   Branch name must follow `feature/<kebab-case-description>` format.

3. **Assign and label the issue:**
   ```bash
   gh issue edit $ARGUMENTS --add-assignee @me
   gh issue edit $ARGUMENTS --add-label in-progress
   ```

4. **Link the branch to the issue:**
   ```bash
   gh issue develop $ARGUMENTS --branch feature/<descriptive-branch-name>
   ```

---

## Phase 1: Plan

Use `EnterPlanMode` to design the implementation before writing any files:

- Read the relevant canonical docs (`SCHEMA_DESIGN.md`, `SCENARIO.md`, `docs/`) to understand the context
- Identify all files that need to change
- Determine if this is schema work (use `dbpatch-v2-implement-layer` skill), scaffolding (use `new-implementation` skill), or another type of change
- Consider edge cases and doc updates
- Present the plan for user approval before proceeding

Do NOT skip planning. The plan catches design mistakes before any files are touched.

---

## Phase 2: Implement

Follow the appropriate workflow based on issue type:

**Schema / layer work:** Use the `dbpatch-v2-implement-layer` skill for each layer.

**Scaffolding a new implementation:** Use the `new-implementation` skill.

**New scenario:** Use the `create-example` skill.

**Documentation or tooling changes:**
- Follow existing patterns in the codebase
- Keep changes focused — do not refactor unrelated files
- Update only files directly related to the issue

All work must follow the conventions in `docs/IMPLEMENTATION_GUIDE.md` and `.claude/CLAUDE.md`.

---

## Phase 3: Validate

For schema changes, validate against a running database:

```bash
# Start Docker if not already running
docker compose up -d

# Apply all patches
dbpatch build

# Run validation queries (tables, columns, constraints, seed data)
# See docs/IMPLEMENTATION_GUIDE.md — Phase 5 of the per-layer workflow
```

For documentation or tooling changes, review the output manually.

If `dbpatch build` fails, fix the SQL and re-run. Do not retry without a change.

---

## Phase 4: Self Code Review

Before declaring done:

- [ ] SQL generated fresh from `SCHEMA_DESIGN.md` — not copied from another implementation
- [ ] `patches.json` not hand-edited (only patch ID updated after folder rename)
- [ ] ScriptOverrides not copied from a different database platform
- [ ] Layer status updated in `SCHEMA_DESIGN.md` (📋 → ✅) if layers were implemented
- [ ] Timestamps in patch folder names match `SCENARIO.md` timeline
- [ ] `dependsOn` in `patches.json` matches the dependency graph in `SCHEMA_DESIGN.md`
- [ ] `patches.local.json` not committed (gitignored)
- [ ] README.md or docs updated if the change adds or changes something user-visible
- [ ] No platform-specific content added to `SCHEMA_DESIGN.md` or `SCENARIO.md`

---

## Phase 5: Commit

Create a well-structured commit:

```bash
git add <specific-files>
git commit -m "feat: descriptive message (closes #$ARGUMENTS)"
```

**Do NOT push** unless the user explicitly asks.
**Do NOT merge the PR** — PR merging is always a manual action by the developer.
**Do NOT add Co-Authored-By or Claude attribution.**

---

## Important Reminders

- **Ask before proceeding** if requirements are ambiguous
- **Never merge PRs** — the developer does that manually
- **Read canonical docs first** — `SCHEMA_DESIGN.md` is the source of truth for all SQL
- **Another reviewer will check this work** — quality matters
