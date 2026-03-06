# Schema and Scenario Guide

This guide covers how to write the two canonical documents for any database scenario:

- **`SCHEMA_DESIGN.md`** — the platform-agnostic technical specification (the *what*)
- **`SCENARIO.md`** — the realistic team development narrative (the *why* and *who*)

Both documents live at the scenario root (e.g., `Employee-DB/`) and are shared by all implementations.

---

## Authoring Sequence

### Phase 1: Concept

Before writing any document, define:

- **Domain:** What is being modeled? (employee management, e-commerce, hospital scheduling...)
- **Organization:** What company or context makes this realistic?
- **Problem:** What business problem does this database solve?
- **Entities:** Rough list of nouns — these become tables.
- **Scale:** Small (~8 layers, ~10 tables), large (~15 layers, ~25 tables)?
- **Team:** Pick your actors from `DEVELOPERS.md` and note which will be primary contributors.

### Phase 2: Schema Design --> SCHEMA_DESIGN.md

1. Group entities into **layers** based on dependencies — what must exist before what.
2. Draw the dependency graph (ASCII tree is fine).
3. For each layer: define tables, columns, relationships, indexes, business rules, implementation order.
4. Mark all layers with a status: `📋 Planned` or `✅ Implemented`.
5. Document any intentional technical debt (design flaws that will be fixed in a later layer).

### Phase 3: Scenario Writing --> SCENARIO.md

1. Introduce the project context and team.
2. Write one section per layer, in order.
3. Use the cast from `DEVELOPERS.md`. Assign work to them realistically.
4. Use timestamps that match the patch IDs in the implementation (if it exists).
5. Show real questions, code review feedback, design debates, and deployment notes.

### Phase 3b: Test Data --> test-data/

1. Create one CSV per table (5-20 rows for the demo set).
2. Create `data-manifest.json` with load order and column type hints.
3. For volume data: write a generator script, do not commit large files.

### Iteration (Phase 6)

When extending existing documents:

- **New layer in schema:** Update the dependency graph, add the new layer section, update the status table.
- **New layer in scenario:** Add a section following the same timeline conventions.
- **Design fix:** Add a corrective patch section explaining what changed and why.
- **Keep them in sync:** A layer in `SCHEMA_DESIGN.md` must have a corresponding story in `SCENARIO.md`.

---

## Writing SCHEMA_DESIGN.md

### Document structure

```markdown
# <Scenario Name> - Schema Design

> **Companion Document:** For the collaborative development story, see [SCENARIO.md](SCENARIO.md).

## Overview
<2-3 paragraphs: purpose, scope, what the database tracks>

## Layer Structure (dependency graph)
<ASCII tree showing which layers depend on which>

## Layer Summary Table
| Layer | Name | Dependencies | Tables Added | Status |

---

## Layer 0: <Name>
<description, tables, relationships, implementation notes, indexes, business rules>

## Layer 1a: <Name>
...
```

### Layer dependency patterns

**No dependencies (Layer 0):**
```
## Layer 0: Foundation

**Dependencies:** None
```

**Parallel layers (Layer 1a/b/c):**
```
## Layer 1 Overview

Layers 1a, 1b, and 1c can be deployed in any order — they have no interdependencies.
Each depends only on Layer 0.

## Layer 1a: Employee Roles
**Dependencies:** Layer 0
```

**Convergence (Layer 2 depends on ALL of Layer 1):**
```
## Layer 2: Performance Reviews
**Dependencies:** All of Layer 1 (1a, 1b, 1c)
```

**Diamond dependencies (Layer 6 skips ahead):**
```
## Layer 6: Teams and Management
**Dependencies:** Layer 0, Layer 1a only
```

### Platform-agnostic language

Use logical descriptions everywhere. Translate to platform SQL only in the implementation.

| Use this | Not this |
|---|---|
| `identifier, auto-generated` | `INT AUTO_INCREMENT` or `INT IDENTITY` |
| `text, up to 50 characters` | `VARCHAR(50)` |
| `text, unlimited` | `TEXT` or `VARCHAR(MAX)` |
| `boolean` | `TINYINT(1)` or `BIT` |
| `datetime` | `DATETIME` or `TIMESTAMP` |
| `date` | `DATE` |
| `decimal(10,2)` | `DECIMAL(10,2)` (OK — this notation is cross-platform) |
| `integer` | `INT` |

### Column specification format

```markdown
**Columns:**
- **ColumnName** (type) - Required/Optional, description
- **EmployeeId** (identifier, auto-generated) - Primary key
- **FirstName** (text, up to 50 characters) - Required
- **Email** (text, up to 100 characters) - Optional
- **HireDate** (date) - Required, when employee joined
- **IsActive** (boolean) - Required, default true
- **Salary** (decimal, 10 digits with 2 decimal places) - Required
- **Notes** (text, unlimited) - Optional
- **DepartmentId** (identifier) - Optional foreign key to Department
- **ManagerId** (identifier) - Optional foreign key to Employee (self-reference)
```

Always be explicit: every column is either Required or Optional (not NULL/NOT NULL — that's platform-specific).

### Relationships

```markdown
**Relationships:**
- Employee belongs to Department (Employee.DepartmentId -> Department.DepartmentId, optional)
- Department has head employee (Department.DepartmentHeadId -> Employee.EmployeeId, optional)
- Salary belongs to Employee (Salary.EmployeeId -> Employee.EmployeeId, required)
```

### Circular reference pattern

When two tables reference each other, document the implementation order explicitly:

```markdown
**Circular Reference:** Employee.DepartmentId -> Department, Department.DepartmentHeadId -> Employee

**Implementation Order:**
1. Create Employee table WITHOUT the DepartmentId foreign key
2. Create Department table WITHOUT the DepartmentHeadId foreign key
3. Add Department.DepartmentHeadId foreign key (references Employee)
4. Add Employee.DepartmentId foreign key (references Department)

**Rationale:** Both tables must exist before either foreign key can be created.
```

### Phased column addition

When adding a column to an existing table in phases (e.g., adding a FK as nullable first, then making it required after data migration):

```markdown
**Implementation Phases:**
1. Add RoleId to Employee as optional (nullable)
2. Create the Role table
3. Add foreign key constraint from Employee.RoleId to Role.RoleId
4. Populate role data and assign roles to all existing employees
5. Make RoleId required (not nullable) on Employee table
```

### Documenting technical debt

Be explicit about known design problems. Real projects accumulate debt. Documenting it is required.

```markdown
### Known Technical Debt

**LeaveBalance Column Location**

The `EmployeeLeave.LeaveBalance` column records the employee's remaining leave balance on each
individual leave request. This is the wrong location — balance is a property of the employee,
not of an individual leave record. Multiple leave requests for the same employee will have
inconsistent balances.

**Planned fix:** Layer 4 will introduce an `EmployeeLeaveBalance` table and migrate data.

**Why it's here now:** Demonstrates realistic technical debt and the refactoring patterns needed
to address it without data loss.
```

### Status markers

Use consistent markers in the layer summary table:

| Marker | Meaning |
|---|---|
| `✅` | Implemented — SQL patches exist in at least one implementation |
| `📋` | Planned — specified in this document, not yet implemented |

### Indexes

Specify indexes by logical description, not platform syntax:

```markdown
**Indexes:**
- Employee.Email (unique)
- Employee.DepartmentId (for FK lookup performance)
- Salary.NextReviewDate (for review scheduling queries)
- Salary: composite on (SalaryId, NextReviewDate)
```

### Business rules

Include rules that belong to the database layer (constraints, validation) separately from application logic:

```markdown
**Business Rules:**
- Only one salary record per employee should reflect the current rate (IsCurrent = true)
- EndDate must be greater than or equal to StartDate on leave records
- Department head must be an employee in that department (enforced at application layer)
- Self-review: an employee cannot review themselves (enforced at application layer with a warning)
```

---

## Writing SCENARIO.md

### Document structure

```markdown
# <Scenario Name> - Development Scenario

> **Companion Document:** For technical specifications, see [SCHEMA_DESIGN.md](SCHEMA_DESIGN.md).

## Project Context
<Brief background: company, problem being solved, team introduction>

---

## Layer 0: Foundation (January 27, 2024)

**2:30 AM** - Sarah couldn't sleep...

[Realistic narrative with timestamps, conversations, code reviews, deployment notes]

---

## Layer 1a: Employee Roles (January 29, 2024)

...
```

### Tone and style

Write in past tense. This is a project history, not a tutorial.

**DO write like a project retrospective:**

> **9:15 AM** - Marcus started implementing the EmployeeRole table. He created the patch folder
> and began writing the SQL.
>
> "Should we enforce that only one role can have IsCurrent = true per employee?" he asked in Slack.
>
> Sarah replied: "Yes — add a unique index on (EmployeeId, IsCurrent) where IsCurrent = 1. That
> prevents duplicates at the database level."
>
> Marcus added the constraint and updated the PR description with the rationale.

**DON'T write like a tutorial:**

> ## Why Employee Roles Matter
> Employee roles are important because they track job titles over time. This provides several benefits:
> - Historical accuracy
> - Audit trails
> - Key takeaway: Always store historical role data for compliance purposes.

The test: if a sentence starts with "This is important because..." or ends with "Key takeaway:", cut it.

### Realistic timestamps

Use specific times, not vague labels. Business hours on weekdays for normal work; reserve off-hours for exceptional moments.

**Normal work:**
- `9:00 AM` — standup
- `9:15 AM` — work begins
- `10:30 AM` — mid-morning check-in
- `2:00 PM` — afternoon implementation
- `3:30 PM` — code review
- `4:15 PM` — PR merged, deployment scheduled
- `4:45 PM` — end-of-day deploy

**Exceptional moments (use sparingly):**
- `2:30 AM` — Sarah's late-night realization about a tricky design problem
- `8:00 PM` — Marcus fixing a production incident
- `Saturday 10:00 AM` — David's planned weekend maintenance window

### Using the cast

Every named character comes from `DEVELOPERS.md`. Do not invent new people.

**Sarah Chen** (Senior Database Architect):

- Assigns work, reviews PRs, makes final design calls
- Catches edge cases others miss
- Mentors through specific feedback, not lectures

```markdown
Sarah reviewed Marcus's PR at 10:45 AM:

"The circular reference handling looks good. One thing to think about: what happens when
someone tries to delete a department that still has employees? Should we SET NULL on
Employee.DepartmentId, or fail the delete? Let's discuss before merging."
```

**Marcus Rodriguez** (Backend Developer):

- Asks practical questions during implementation
- Pushes back on over-engineering
- Catches design problems while writing the code

```markdown
"Wait," Marcus interrupted. "If we store LeaveBalance on every EmployeeLeave record,
won't that create inconsistencies? What if someone has three leave requests in one month?"

Sarah nodded. "You're right. That's technical debt we'll address in Layer 4."
```

**Priya Patel** (Full-Stack Developer):

- Raises UI/UX and security concerns
- Bridges backend and frontend thinking
- Asks clarifying questions about business rules

```markdown
Priya raised a concern during standup: "How will the frontend know which salary record
is current? Should we query for the most recent EffectiveDate, or add an IsCurrent flag?"

"Let's add IsCurrent for performance," Sarah replied. "The frontend shouldn't have to
calculate that on every request."
```

**David Kim** (DevOps Engineer):

- Writes deployment checklists
- Monitors deployments and raises performance concerns
- Plans rollbacks and maintenance windows

```markdown
David's deployment checklist (sent at 4:45 PM):
- Backup production database
- Test rollback procedure on staging
- Monitor query performance during migration
- Watch for FK constraint violations on existing data
- Sarah on call for first 30 minutes post-deploy
```

### Code review conversations

Show specific technical feedback, not generic approval.

```markdown
**3:30 PM** - Sarah reviewed Priya's salary tracking PR:

"Overall this looks great. Two suggestions:

1. Add a check constraint: `EndDate IS NULL OR EndDate > EffectiveDate`
2. Index EffectiveDate for historical queries — this table will grow large

Also, should we enforce that IsCurrent = true rows have NULL EndDate?"

Priya replied: "Good catches. I'll add the constraint and index. For the IsCurrent/EndDate
rule — I think application-layer enforcement gives us more flexibility if we need to
backdate corrections later."

Sarah approved: "Fair point. Let's document that decision in the business rules."
```

### Documenting technical debt in the narrative

Show the discovery organically — through code review or implementation, not a dedicated "Known Issues" section:

```markdown
**1:30 PM** - Marcus was implementing the leave tracking table when he noticed something odd:

"Sarah, why is LeaveBalance on the EmployeeLeave table? Shouldn't that be per-employee,
not per-leave-request? If someone takes three vacations, each record will have a different
balance."

Sarah sighed. "You're absolutely right — it's the wrong location. But let's document it
as technical debt and fix it in Layer 4 with a proper EmployeeLeaveBalance table. We need
to ship this now."

"Won't it cause inconsistencies?" Marcus pressed.

"Yes. That's actually useful — real projects accumulate debt like this. We'll refactor
it properly with a migration when we get to Layer 4."

Marcus added a comment in the schema and noted it in the README.
```

### Deployment sections

End each layer with a short deployment note:

```markdown
**4:45 PM** - David prepared the deployment:

1. Backup production
2. Run patches in staging first
3. Monitor FK constraint errors
4. Verify CRUD stored procedures work end-to-end
5. Test rollback procedure

**5:00 PM** - Deployment began. All patches applied cleanly.

**5:15 PM** - Sarah ran validation:

```sql
-- Verify no orphaned salary records
SELECT s.SalaryId FROM Salary s
LEFT JOIN Employee e ON s.EmployeeId = e.EmployeeId
WHERE e.EmployeeId IS NULL;
-- Result: 0 rows
```

**5:20 PM** - Deployment complete.
```

### Sections to avoid

Cut these entirely:

```markdown
## Key Takeaways          <- Cut
## Why It Mattered        <- Cut
## Best Practices Learned <- Cut
## Lessons Learned        <- Cut
```

Let the story show the lessons. If the reader can't figure out why something matters from the narrative, improve the narrative.

---

## Keeping Both Documents Synchronized

Every layer in `SCHEMA_DESIGN.md` must have a corresponding section in `SCENARIO.md`, and vice versa.

| If you... | Then you must... |
|---|---|
| Add a new layer to `SCHEMA_DESIGN.md` | Add the team story for that layer to `SCENARIO.md` |
| Fix a design flaw in `SCHEMA_DESIGN.md` | Add a corrective patch section to `SCENARIO.md` explaining the discovery |
| Rename a layer in `SCHEMA_DESIGN.md` | Update the heading in `SCENARIO.md` |
| Change layer dependencies | Update both the dependency graph in `SCHEMA_DESIGN.md` and the context in `SCENARIO.md` |

Cross-references at the top of each file must use the correct relative path:

- From `Employee-DB/SCHEMA_DESIGN.md`, link to `[SCENARIO.md](SCENARIO.md)`
- From `Employee-DB/SCENARIO.md`, link to `[SCHEMA_DESIGN.md](SCHEMA_DESIGN.md)`

---

## Checklists

### SCHEMA_DESIGN.md checklist

- [ ] Overview and purpose (2-3 paragraphs)
- [ ] Dependency graph (ASCII tree)
- [ ] Layer summary table with status markers
- [ ] Each layer: description, tables, columns, relationships, implementation order
- [ ] Platform-agnostic language throughout (no SQL syntax)
- [ ] Nullability explicit on every column (Required or Optional)
- [ ] Circular references: implementation order documented
- [ ] Phased column additions: migration steps documented
- [ ] Indexes: listed by table and purpose
- [ ] Business rules: listed per table
- [ ] Known technical debt: documented with planned fix
- [ ] Cross-reference to SCENARIO.md at the top

### SCENARIO.md checklist

- [ ] Project context and team introduction
- [ ] Actors from DEVELOPERS.md only (no invented team members)
- [ ] Specific timestamps (not "morning" or "later")
- [ ] Real conversations and implementation questions
- [ ] Code review feedback with specific technical comments
- [ ] Design decisions with rationale shown through dialogue
- [ ] Technical debt discovered organically through story
- [ ] Deployment notes for each layer
- [ ] No pedagogical sections (no "Key Takeaways")
- [ ] Past tense throughout
- [ ] Cross-reference to SCHEMA_DESIGN.md at the top

---

## Examples

- `Employee-DB/SCHEMA_DESIGN.md` — 8-layer schema with circular reference, parallel dependencies, technical debt
- `Employee-DB/SCENARIO.md` — corresponding team narrative using the DEVELOPERS.md cast
