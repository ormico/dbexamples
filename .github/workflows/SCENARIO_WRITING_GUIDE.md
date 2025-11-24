# Scenario Writing Guide

This guide teaches AI agents how to write realistic development narratives in DEVELOPMENT_SCENARIO.md files.

## Purpose

DEVELOPMENT_SCENARIO.md documents the **collaborative development story** showing:
- HOW the database was built by a team
- WHY design decisions were made
- WHO made the decisions and WHEN
- Real conversations, code reviews, and iterations

This is NOT a tutorial. It's a realistic scenario that could have happened.

## Companion Document

Every DEVELOPMENT_SCENARIO.md has a companion SCHEMA_DESIGN.md with technical specifications.

**Always cross-reference both documents at the top:**

```markdown
# Employee Database - Development Scenario

> **📋 Companion Document:** This document describes HOW the database was built collaboratively and WHY decisions were made.  
> For technical specifications and platform-agnostic implementation details, see [SCHEMA_DESIGN.md](SCHEMA_DESIGN.md).
```

## Document Structure

### 1. Introduction Section
Brief context about the project and team:

```markdown
# Employee Database - Development Scenario

> **📋 Companion Document:** [SCHEMA_DESIGN.md](SCHEMA_DESIGN.md)

## Project Context

Acme Corp needed to modernize their employee management system. The legacy system was a monolithic application with a tangled database schema. The development team decided to build a new system incrementally, deploying features as they were completed.

**Team:**
- Sarah Chen - Senior Database Engineer
- Marcus Rodriguez - Backend Developer
- Priya Patel - Full-Stack Developer
- David Kim - DevOps Engineer

**Timeline:** January 2024 - February 2024
```

### 2. Layer Implementation Sections
Each layer gets its own section with:
- Date and time stamps
- Team member conversations
- Code reviews
- Design decisions
- Implementation notes

```markdown
## Layer 0: Foundation (January 27, 2024)

**2:30 AM** - Sarah couldn't sleep. She'd been thinking about the circular reference between Employee and Department all evening...

[Continue with realistic narrative...]
```

## Using Team Personas

All team members come from `DEVELOPERS.md`:

### Sarah Chen - Senior Database Engineer
- Deep expertise in schema design
- Mentors junior developers
- Advocates for best practices
- Thinks about edge cases and performance

**Use Sarah for:**
- Complex design decisions
- Performance optimization
- Schema patterns and migrations
- Code reviews with detailed feedback

**Sarah's voice:**
```markdown
Sarah reviewed Marcus's pull request at 10:45 AM:

"The circular reference handling looks good, but we need to think about what happens when someone tries to delete a department. Should we SET NULL on Employee.DepartmentId, or CASCADE the delete? Let's discuss this as a team."
```

### Marcus Rodriguez - Backend Developer
- Pragmatic and solution-oriented
- Strong API design skills
- Questions over-engineering
- Focuses on developer experience

**Use Marcus for:**
- API integration concerns
- Developer experience feedback
- Practical implementation questions
- Pushing back on complexity

**Marcus's voice:**
```markdown
"Wait," Marcus interrupted. "If we store LeaveBalance on every EmployeeLeave record, won't that create inconsistencies? What if someone has multiple leave requests?"

Sarah nodded. "You're right. That's technical debt we'll address in Layer 4."
```

### Priya Patel - Full-Stack Developer
- Thinks about UI/UX implications
- Security-conscious
- Asks clarifying questions
- Bridges backend and frontend concerns

**Use Priya for:**
- UI/UX requirements
- Security considerations
- Cross-cutting concerns
- Questions about business logic

**Priya's voice:**
```markdown
Priya raised a concern during the standup: "How will the UI know which salary is current? Should we add an IsCurrent flag, or always query for the most recent EffectiveDate?"

"Good question," Sarah replied. "Let's add IsCurrent for performance. The UI shouldn't have to calculate that every time."
```

### David Kim - DevOps Engineer
- Deployment and operations focus
- Performance monitoring expertise
- Thinks about scalability
- Practical deployment concerns

**Use David for:**
- Deployment planning
- Performance concerns
- Monitoring and observability
- Infrastructure questions

**David's voice:**
```markdown
David's deployment checklist (sent at 4:45 PM):
- ✅ Backup production database
- ✅ Test rollback procedure
- ✅ Monitor query performance during deployment
- ⚠️ Watch for FK constraint violations on existing data
```

## Realistic Timestamps

### Business Hours
Use realistic timestamps for a professional team:

**Morning (9 AM - 12 PM):**
- 9:00 AM - Team standup
- 9:15 AM - Start of focused work
- 10:30 AM - Mid-morning check-ins
- 11:45 AM - Pre-lunch PR reviews

**Afternoon (1 PM - 5 PM):**
- 1:00 PM - Post-lunch meetings
- 2:00 PM - Afternoon work block
- 3:30 PM - Code reviews
- 4:45 PM - End-of-day deploys

**Evening/Weekend (Rare):**
- 2:30 AM - Sarah's late-night realization (exceptional)
- 8:00 PM - Marcus fixing production bug (incident)
- Saturday 10:00 AM - David's weekend deploy prep (planned maintenance)

### Timeline Progression

**Layer 0:** January 27, 2024 (Saturday night/Sunday - initial spike)
- 2:30 AM Sunday - Sarah's late-night design work
- 11:00 AM Sunday - Team review session

**Layer 1a:** January 29, 2024 (Monday morning - first workday)
- 9:00 AM - Standup and planning
- 9:15 AM - Implementation begins
- 3:30 PM - PR submitted
- 4:00 PM - Code review

**Layer 1b:** January 29, 2024 (Monday afternoon - parallel work)
- 10:30 AM - Priya starts salary tracking
- 2:00 PM - Implementation complete
- 3:45 PM - PR submitted

**Layer 1c:** January 30, 2024 (Tuesday)
- 9:15 AM - Marcus picks up leave tracking
- 1:30 PM - Questions about LeaveBalance
- 4:30 PM - PR merged with technical debt note

**Layer 2:** February 1, 2024 (Thursday - waiting for Layer 1 to settle)
- 9:00 AM - Planning meeting
- 10:00 AM - Sarah starts performance reviews
- 2:00 PM - Implementation complete
- 4:45 PM - Deployment planning

## Writing Style

### ✅ DO: Write Like a Real Developer

```markdown
**9:15 AM** - Marcus started implementing the EmployeeRole table. He created the patch folder and began writing SQL:

"Should we enforce that only one role can have IsCurrent = true per employee?" he asked in Slack.

Sarah replied: "Good thinking. Add a unique index on (EmployeeId, IsCurrent) where IsCurrent = 1. That'll prevent duplicates at the database level."

Marcus added the constraint and updated the PR description with the rationale.
```

**Why this works:**
- Specific timestamps
- Real questions and concerns
- Technical decision with rationale
- Shows collaboration
- Natural conversation flow

### ❌ DON'T: Write Like a Tutorial

```markdown
## Why Employee Roles Matter

Employee roles are important because they track job titles over time. This provides several benefits:
- Historical accuracy
- Audit trails
- Reporting capabilities

Key takeaway: Always store historical role data for compliance purposes.
```

**Why this fails:**
- Sounds like a textbook
- "Key takeaway" is pedagogical
- No specific people or dates
- Not a realistic scenario

### ✅ DO: Show Real Code Reviews

```markdown
**3:30 PM** - Sarah reviewed Priya's PR for salary tracking:

"Overall this looks great. Two suggestions:

1. Add a check constraint: `EndDate IS NULL OR EndDate > EffectiveDate`
2. Consider indexing EffectiveDate for historical queries

Also, should we enforce that IsCurrent salaries have NULL EndDate?"

Priya replied: "Good catches! I'll add the constraint. For #3, I think we should enforce it at the application level - gives us more flexibility if we need to backdate corrections."

Sarah approved: "Fair point. Let's document that in the business rules."
```

### ❌ DON'T: List Generic Best Practices

```markdown
The team followed these best practices:
- Code reviews before merge
- Testing on staging first
- Documentation updates
- Performance monitoring

This ensured high code quality.
```

### ✅ DO: Show Real Concerns and Iterations

```markdown
**10:30 AM** - Marcus was implementing the ReviewedById field when he realized something:

"Wait, can an employee review themselves? Should we add a check constraint to prevent EmployeeId = ReviewedById?"

Sarah considered this: "In theory yes, but I've seen edge cases where a new manager backdates their own review during transition periods. Let's enforce it at the application level with a warning, not a hard constraint."

"Makes sense," Marcus agreed. "I'll add a comment in the schema docs about this."
```

### ❌ DON'T: Explain Why Things Matter

```markdown
The team added the ReviewedById field. This was important because:
- Accountability: Know who conducted each review
- Audit trail: Track reviewer changes over time
- Reporting: Analyze reviewer patterns

Key takeaway: Always track who performs important actions.
```

## Layer Implementation Template

Use this structure for each layer:

```markdown
## Layer X: [Name] ([Date])

**[Time]** - [Developer] [action and context]

[Realistic narrative showing]:
- Initial implementation
- Questions that arise
- Team discussions
- Code review feedback
- Iterations and refinements
- Final decision and rationale

**[Time]** - Deployment notes:
- [What was deployed]
- [Any monitoring concerns]
- [Production considerations]
```

**Example:**

```markdown
## Layer 1a: Employee Roles (January 29, 2024)

**9:00 AM** - Morning standup. Sarah assigned the employee roles feature to Marcus.

"This should be straightforward," Sarah explained. "EmployeeRole tracks job titles over time. Key thing is the IsCurrent flag - only one role per employee should be current."

**9:15 AM** - Marcus created the patch folder `202401290915-3421-add-employee-roles` and started implementing the table.

**10:30 AM** - Question in Slack:

> **Marcus:** Should we enforce unique (EmployeeId, IsCurrent) where IsCurrent = 1?

> **Sarah:** Yes! That's the right approach. MySQL can do partial unique indexes. I'll review the PR.

**2:00 PM** - Marcus submitted the PR. Implementation included:
- EmployeeRole table with all required fields
- Unique index on (EmployeeId, IsCurrent) where IsCurrent = 1
- Standard indexes on foreign keys
- CRUD stored procedures

**3:30 PM** - Sarah's code review:

"Looks solid. One suggestion: add an index on StartDate for timeline queries. Also, the unique constraint is perfect - this prevents data integrity issues at the database level."

Marcus pushed the update and Sarah approved.

**4:15 PM** - Merged to main. David scheduled deployment for 5:00 PM after Layer 0 stabilized in production.
```

## Technical Debt Documentation

When documenting intentional technical debt:

```markdown
**1:30 PM** - During implementation, Marcus noticed something odd:

"Sarah, why is LeaveBalance on the EmployeeLeave table? Shouldn't that be per-employee, not per-leave-request?"

Sarah sighed. "You're absolutely right. That's a design flaw. But let's document it as technical debt and fix it in Layer 4 when we have reference data tables."

"Won't that cause inconsistencies?" Marcus pressed.

"Yes," Sarah admitted. "But it's a teaching opportunity. Real projects accumulate technical debt. We'll refactor it properly in Layer 4 with EmployeeLeaveBalance as a separate table."

Marcus added a TODO comment in the schema and a note in the README.
```

## Deployment Narratives

Show realistic deployment planning:

```markdown
**4:45 PM** - David prepared the deployment checklist:

1. Backup production database
2. Run patches in test environment first
3. Monitor foreign key constraint violations
4. Watch query performance during deployment
5. Verify CRUD stored procedures work
6. Test rollback procedure

"Layer 2 has complex dependencies," David noted. "We'll deploy after hours to minimize user impact. Sarah, can you be on call in case we need to rollback?"

Sarah agreed: "I'll monitor the deployment. If we see any FK constraint errors on existing data, we'll pause and investigate."

**5:00 PM** - Deployment began. All patches applied successfully. No errors.

**5:15 PM** - Sarah ran validation queries:

```sql
-- Verify performance reviews link correctly
SELECT pr.ReviewId, pr.EmployeeId, pr.ReviewedById
FROM PerformanceReview pr
LEFT JOIN Employee e ON pr.EmployeeId = e.EmployeeId
WHERE e.EmployeeId IS NULL;

-- Result: 0 rows (good - no orphaned reviews)
```

**5:30 PM** - Deployment complete. David updated the runbook with lessons learned.
```

## Avoiding Pedagogical Sections

### ❌ REMOVE These Sections:

```markdown
## Key Takeaways
- Always use foreign keys for referential integrity
- Circular references require two-phase creation
- Document technical debt as you go

## Why It Mattered
This layer taught us important lessons about schema design...

## Best Practices Learned
1. Index all foreign keys
2. Use check constraints
3. Plan for historical data
```

### ✅ INSTEAD: Show Learning Through Story

```markdown
**2:00 PM** - Marcus submitted his first PR. Sarah's review included detailed feedback about indexing foreign keys.

"I noticed you forgot to index DepartmentId," Sarah commented. "Foreign keys should always be indexed - otherwise queries joining these tables will be slow."

Marcus thanked her and added the index. "I'll remember that for next time."
```

The learning happens naturally through code review, not through a "lessons learned" section.

## Checklist for Writing DEVELOPMENT_SCENARIO.md

- [ ] Start with project context and team introduction
- [ ] Reference DEVELOPERS.md for accurate personas
- [ ] Use realistic timestamps (business hours, weekdays)
- [ ] Show actual conversations and questions
- [ ] Include code review feedback
- [ ] Document design decisions with rationale
- [ ] Show iterations and refinements
- [ ] Include deployment planning
- [ ] Document technical debt discussions
- [ ] Avoid pedagogical sections (no "Key Takeaways")
- [ ] Write in past tense (this already happened)
- [ ] Cross-reference SCHEMA_DESIGN.md at the top
- [ ] Show team collaboration and dynamics
- [ ] Include specific technical details
- [ ] Make it feel like reading a project history

## Examples

See complete example:
- `Employee-DB/dbpatchv2/odbc-mysql/DEVELOPMENT_SCENARIO.md` (8 layers, realistic team interactions)

## Common Mistakes to Avoid

1. **❌ Adding "Key Takeaways" or "Why It Mattered" sections**
   - ✅ Let the story show the lessons naturally

2. **❌ Explaining why things are important**
   - ✅ Show the team discussing concerns

3. **❌ Generic timestamps like "Morning" or "Later"**
   - ✅ Use specific times: "9:15 AM", "2:30 PM"

4. **❌ No named team members**
   - ✅ Use personas from DEVELOPERS.md

5. **❌ Perfect implementation without questions**
   - ✅ Show real concerns and iterations

6. **❌ Writing in future tense**
   - ✅ Write in past tense (this already happened)

7. **❌ Skipping code review conversations**
   - ✅ Show specific feedback and responses

8. **❌ No deployment planning**
   - ✅ Include checklists and monitoring plans

9. **❌ Teaching tone**
   - ✅ Documentary/historical tone

10. **❌ Missing technical details**
    - ✅ Include SQL snippets, specific decisions, actual queries
