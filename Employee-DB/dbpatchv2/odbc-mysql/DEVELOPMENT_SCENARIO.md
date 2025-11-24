# Employee Database - Development Scenario

**Project:** Employee Management System Database  
**Timeline:** January 2024  
**Team:** See [DEVELOPERS.md](../../../DEVELOPERS.md) for team member details

> **📋 Companion Document:** This document describes HOW the database was built collaboratively and WHY decisions were made.  
> For technical specifications and platform-agnostic implementation details, see [SCHEMA_DESIGN.md](SCHEMA_DESIGN.md).

## Background

TechCorp, a growing software company, needed a new employee management system to replace their aging spreadsheet-based approach. The development team decided to build the database incrementally using a patch-based approach, allowing different developers to work on features in parallel while maintaining clear dependencies.

### Development Roadmap

| Week | Layers | Developer(s) | Focus Areas |
|------|--------|-------------|-------------|
| **1** | 0-1 | Sarah, Marcus, Priya | Foundation, Roles, Salary, Leave |
| **2** | 2-3 | Priya, David | Performance Reviews, Project Management |
| **3** | 4-5 | Marcus, Sarah | Technical Debt Cleanup, Soft Delete |
| **4** | 6-7 | Sarah, Priya, Marcus | Teams/Management, Skills Tracking |

## Development Timeline

### Week 1: Foundation (January 27, 9:00 AM)

**Developer:** Sarah Chen  
**Patch:** Layer 0 - Employees and Departments

Sarah started the project by designing the core foundation. Beginning her work week fresh on Monday morning, she created the basic employee and department structure. Her biggest challenge was handling the circular reference - departments need employee heads, but employees belong to departments.

"The key insight," Sarah explained in the design review, "was to create the tables first and add the foreign key constraints afterward. This lets us build the circular relationship safely."

Sarah's foundation patch included:
- Employee table with personal details and address information
- Department table with basic organizational data
- Bidirectional relationships allowing departments to have employee heads and employees to belong to departments

---

### Week 1: Employee Details (January 27, Afternoon)

With the foundation in place, three developers began working on different aspects of employee information in parallel.

#### Feature: Employee Roles (1:15 PM)

**Developer:** Marcus Rodriguez  
**Patch:** Layer 1a - Employee Roles

Marcus, reviewing Sarah's work after lunch, realized they needed a way to classify employees by their job functions. Rather than using free-text job titles, he designed a Role reference table.

"We kept seeing the same job titles over and over in our planning documents - Software Engineer, Product Manager, Designer," Marcus noted. "A lookup table made more sense than letting each employee record have arbitrary text."

Marcus implemented a phased approach:
1. Created the Role table
2. Added RoleId to Employee as optional initially
3. Added the foreign key constraint
4. Left a final step to make it required after data migration

#### Feature: Salary Tracking (2:30 PM)

**Developer:** Priya Patel  
**Patch:** Layer 1b - Salary Tracking

Priya tackled compensation tracking, one of the most sensitive and important aspects of the system. She designed the Salary table to maintain complete historical records rather than just storing current salary.

"Finance and HR needed to see salary progression over time," Priya explained. "Plus, we needed to track when raises took effect and when the next review was due."

Priya added two strategic indexes:
- One on NextReviewDate for generating review schedules
- A composite index for efficient combined lookups

She also prepared sample CSV files with realistic salary data for testing, knowing that testing compensation calculations would be critical.

#### Feature: Leave Management (2:45 PM)

**Developer:** Sarah Chen  
**Patch:** Layer 1c - Leave Management

After finishing the foundation, Sarah took on leave tracking. The team needed to record when employees took time off and track different leave types (vacation, sick, personal, etc.).

Sarah's design tracked leave as date ranges with start and end dates. She included a LeaveBalance column for tracking remaining days, though she left a TODO note questioning whether balance belonged per-leave-record or per-employee.

"I'm not entirely happy with the balance column location," Sarah admitted in code review. "It works for now, but we might want to refactor this in a future patch."

---

### Week 2: Performance Management (January 29, 10:30 AM)

**Developer:** Priya Patel  
**Patch:** Layer 2 - Performance Reviews

With all the employee details in place, Priya designed the performance review system. She made this patch dependent on all three Layer 1 patches because performance reviews need the complete employee context.

"You can't evaluate performance without knowing someone's role, their compensation history, and their attendance record," Priya reasoned. "The reviews sit at the intersection of all that data."

Her design included:
- Numeric performance ratings for consistent measurement
- Free-text comments for qualitative feedback
- Performance goals tracked over time
- Historical record of all reviews

Priya worked with the HR team to understand their review process and ensured the database structure supported their workflow.

**Why it mattered:** Performance reviews drive many downstream processes - promotions, raises, project assignments, and terminations. Having a solid review history was crucial for fair management decisions and legal protection.

---

### Week 2: Project Management (January 30, 3:45 PM)

**Developer:** Marcus Rodriguez  
**Patch:** Layer 3 - Projects and Assignments

Marcus completed the database with project management capabilities. This final layer brought everything together, allowing TechCorp to track who was working on what.

The key design decision was the EmployeeProjectAssignment junction table, which created the many-to-many relationship between employees and projects. Marcus added a project-specific Role field, recognizing that someone might be a Senior Engineer (their job title) but work as a Tech Lead on one project and a Developer on another.

"The same person wears different hats on different projects," Marcus explained. "We needed to capture both their organizational role and their project role."

Marcus also included budget tracking at the project level, anticipating future needs for financial reporting and project cost analysis.

**Why it mattered:** Project assignments answered the critical question: "Who's working on what?" This enabled resource planning, project staffing, and workload balancing across the organization.

---

## Development Insights

### Collaboration Patterns

**Parallel Development:** Layer 1 demonstrated the power of the dependency system. Marcus, Priya, and Sarah all worked on different features simultaneously without conflicts because their patches only depended on Layer 0, not on each other.

**Sequential Development:** Layers 2 and 3 had to wait for previous layers to complete, ensuring data integrity and logical consistency.

**Code Review Benefits:** Sarah's TODO note about LeaveBalance showed the team's commitment to acknowledging technical debt rather than pretending everything was perfect.

### Technical Decisions

**Circular References:** Sarah's deferred constraint approach became a teaching example for the team about handling complex relationships.

**Historical Data:** Both Priya's salary design and performance review design chose historical tracking over point-in-time snapshots, giving TechCorp valuable longitudinal data.

**Phased Changes:** Marcus's role implementation showed how to safely modify existing tables in production environments.

**Junction Tables:** Marcus's EmployeeProjectAssignment demonstrated the standard pattern for many-to-many relationships.

### Lessons Learned

1. **Start with the foundation:** Sarah's Layer 0 provided a stable base that didn't need changes as new features were added.

2. **Plan dependencies carefully:** The team could have made performance reviews depend only on Layer 0, but Priya correctly identified that reviews logically need the complete employee picture.

3. **Leave room for improvement:** Sarah's honest assessment of the LeaveBalance design showed professional maturity - shipping something that works while acknowledging future improvements.

4. **Think about queries early:** Priya's strategic indexes on the Salary table showed proactive performance planning rather than reactive optimization.

## Post-Development

After completing all patches, David Kim (DevOps Engineer) took over to:
- Create deployment automation
- Set up database monitoring
- Implement backup and recovery procedures
- Generate CRUD stored procedures for all tables

The stored procedures came in two versions (-1d and -2c), giving application developers flexibility in how they accessed the data.

## Current Status

The team celebrated the successful deployment of project management features. However, as they reviewed the system in production, they identified several areas for improvement and new requirements from stakeholders.

---

### Week 3: Technical Debt and Soft Delete (February 3-6)

#### Layer 4: Reference Tables and Refactoring (February 3, 9:00 AM)

**Developer:** Marcus Rodriguez  
**Patch:** Layer 4 - Technical Debt

Marcus had been keeping a list of design issues since the initial launch. "We've got some technical debt to pay down," he announced in the retrospective meeting. "Let's clean this up before we add more features."

His audit revealed three problem areas:

**Issue 1: LeaveBalance doesn't belong on EmployeeLeave**
Sarah had flagged this in her original code with a TODO. "Each leave record has its own balance, which doesn't make sense," Marcus explained. "Balance should be per-employee, not per-vacation."

**Issue 2: Free-text fields that should be lookup tables**
- EmployeeLeave.LeaveType was just text - leading to inconsistent values ("vacation" vs "Vacation" vs "PTO")
- Project.Status was text - no validation, no defined workflow
- PerformanceReview.Rating was numeric with no scale definition

Marcus created three reference tables:
- **LeaveType:** Vacation, Sick, Personal, Unpaid, Bereavement, Jury Duty (with IsPaid and RequiresApproval flags)
- **ProjectStatus:** Planning, Active, On Hold, Completed, Cancelled (with IsActive flag and sort order)
- **PerformanceRating:** 1-5 scale with names, descriptions, and even UI colors

"The colors are a nice touch," Priya commented. "HR will love seeing red/yellow/green in their dashboard."

**Migration strategy:**
Marcus used a phased approach to avoid breaking production:
1. Add new FK columns as optional
2. Populate reference tables
3. Migrate data from text to FKs
4. Make FKs required
5. Drop old text columns (future release)

"We're keeping both columns for now," Marcus explained. "Gives us a safe rollback path if something goes wrong."

---

#### Layer 5: Soft Delete Pattern (February 5, 2:00 PM)

**Developer:** Sarah Chen  
**Patch:** Layer 5 - Soft Delete

Sarah tackled a problem that kept the legal team up at night: when employees left the company, their records were being deleted - which broke foreign keys, lost history, and potentially violated record retention policies.

"We can't actually delete employees," Sarah explained to the team. "When we try, we either violate foreign key constraints or lose critical historical data."

She proposed soft delete: instead of `DELETE FROM Employee WHERE EmployeeId = 42`, the application would run `UPDATE Employee SET IsDeleted = TRUE, DeletedAt = NOW(), DeletedBy = @CurrentUserId WHERE EmployeeId = 42`.

Sarah added three columns to every table:
- **IsDeleted** (boolean, default FALSE)
- **DeletedAt** (datetime, nullable)
- **DeletedBy** (FK to Employee, nullable)

"Now every query needs `WHERE IsDeleted = FALSE`," David cautioned. "That's a big application change."

"True," Sarah admitted. "But we gain huge benefits:
- Undelete capability (employee comes back)
- Referential integrity maintained
- Complete audit trail
- Compliance with retention policies"

The team created views for common queries that automatically filtered out deleted records, minimizing application changes.

---

### Week 4: Organizational Extensions (February 10-13)

The database was now stable and clean. The team turned to new feature requests from HR and management.

#### Layer 6: Teams and Management Hierarchy (February 10, 10:00 AM)

**Developer:** Sarah Chen  
**Patch:** Layer 6 - Organizational Extensions

The VP of Engineering approached Sarah with a challenge: "Our org chart only shows departments, but we work in cross-functional teams. Can you track both?"

Sarah designed three new tables:

**Table 1: Team**
Cross-functional teams that span departments:
- Mobile App Team (iOS, Android, Backend, QA from different departments)
- Security Guild (experts who meet monthly)
- Hiring Committee (rotating membership)

"Teams are fluid," Sarah explained. "People join and leave teams without changing departments or affecting payroll."

**Table 2: EmployeeTeam**
Many-to-many junction tracking who's on which teams, with:
- TeamRole (their role *within* the team - might differ from their job Role)
- JoinedDate and LeftDate (temporal tracking)
- IsActive flag

**Table 3: ManagerAssignment**
Explicit management relationships beyond department heads:
- Direct reports (official reporting line)
- Dotted-line reports (matrix reporting for projects)
- Mentorship relationships

"We used to only track department heads," Sarah noted. "Now we can model the real org structure - including matrix management where engineers have both a functional manager and a project manager."

---

#### Layer 7: Skills Tracking (February 12, 9:30 AM)

**Developers:** Priya Patel and Marcus Rodriguez  
**Patch:** Layer 7 - Skills Tracking

The CTO asked a question at the planning meeting: "We have a new Python project starting. Which of our engineers know Python, and at what level?"

Nobody had a good answer. Employee résumés were scattered, self-reported skill lists were outdated, and there was no systematic tracking.

Priya and Marcus paired on a skills tracking system:

**Table 1: Skill**
Master catalog of tracked skills:
- Programming languages (Python, Java, JavaScript)
- Frameworks (React, Django, Spring)
- Cloud platforms (AWS, Azure, GCP)
- Soft skills (Leadership, Public Speaking)
- Tools (Docker, Kubernetes, Git)

**Table 2: EmployeeSkill**
Who knows what, with rich metadata:
- ProficiencyLevel (1-5: Beginner → Master)
- YearsOfExperience
- LastUsedDate (skill freshness)
- IsEndorsed (manager verification)
- Notes (certifications, significant projects)

"The endorsement feature is key," Priya explained. "Anyone can claim they're a Python expert, but manager endorsement adds credibility."

**Table 3: ProjectSkillRequirement**
What skills does this project need:
- RequiredProficiency (minimum level)
- IsMandatory (required vs nice-to-have)

Marcus built a prototype query: "Find all employees with Python proficiency 3+ who aren't currently assigned to a Python project."

The CTO ran the query and got 12 names. "This is gold," she said. "We can finally do skills-based staffing."

---

By mid-February 2025, the Employee Database was fully deployed at TechCorp. What started as Sarah's foundation design had evolved into a comprehensive system tracking 150+ employees across 12 departments, 30+ active projects, cross-functional teams with matrix reporting structures, and over 200 skills across the organization.

The layered patch approach had worked exactly as intended - allowing the team to build incrementally, work in parallel when possible, and address technical debt systematically. The database now reflected how TechCorp actually operated, rather than forcing the company into rigid structures.
