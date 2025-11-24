# Employee Database - Development Scenario

**Project:** Employee Management System Database  
**Timeline:** January 2024  
**Team:** See [DEVELOPERS.md](../../../DEVELOPERS.md) for team member details

## Background

TechCorp, a growing software company, needed a new employee management system to replace their aging spreadsheet-based approach. The development team decided to build the database incrementally using a patch-based approach, allowing different developers to work on features in parallel while maintaining clear dependencies.

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

**Why it mattered:** This patch established the core entities that everything else would build upon. Sarah made sure the design was flexible enough to accommodate future extensions without requiring modifications to the base tables.

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

**Why it mattered:** This pattern became the template for other developers when they needed to modify existing tables. Marcus's careful phased approach meant existing data wouldn't break when the new column was added.

#### Feature: Salary Tracking (2:30 PM)

**Developer:** Priya Patel  
**Patch:** Layer 1b - Salary Tracking

Priya tackled compensation tracking, one of the most sensitive and important aspects of the system. She designed the Salary table to maintain complete historical records rather than just storing current salary.

"Finance and HR needed to see salary progression over time," Priya explained. "Plus, we needed to track when raises took effect and when the next review was due."

Priya added two strategic indexes:
- One on NextReviewDate for generating review schedules
- A composite index for efficient combined lookups

She also prepared sample CSV files with realistic salary data for testing, knowing that testing compensation calculations would be critical.

**Why it mattered:** The historical approach meant TechCorp could analyze compensation trends, prove compliance during audits, and generate accurate reports. The review date tracking automated a previously manual HR process.

#### Feature: Leave Management (2:45 PM)

**Developer:** Sarah Chen  
**Patch:** Layer 1c - Leave Management

After finishing the foundation, Sarah took on leave tracking. The team needed to record when employees took time off and track different leave types (vacation, sick, personal, etc.).

Sarah's design tracked leave as date ranges with start and end dates. She included a LeaveBalance column for tracking remaining days, though she left a TODO note questioning whether balance belonged per-leave-record or per-employee.

"I'm not entirely happy with the balance column location," Sarah admitted in code review. "It works for now, but we might want to refactor this in a future patch."

**Why it mattered:** Leave tracking was essential for payroll and resource planning. The historical record also protected both employees and the company by maintaining a clear audit trail.

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

The Employee Database is now in production at TechCorp, successfully tracking:
- 150+ employees across 12 departments
- Salary records with automatic review notifications
- Leave requests integrated with the time-tracking system
- Performance reviews conducted quarterly
- 30+ active projects with clear team assignments

The database has proven scalable, maintainable, and easy to understand - exactly what the team hoped for when they started with Sarah's late-night foundation patch.

---

## Key Takeaways for Database Development Teams

1. **Layered patches enable parallel work:** Multiple developers can work simultaneously on independent features.

2. **Dependencies prevent conflicts:** Explicit dependencies ensure features build on complete foundations.

3. **Circular references need special handling:** Create tables first, constraints second.

4. **Historical data is valuable:** Track changes over time rather than just current state.

5. **Phased migrations are safer:** When modifying existing tables, use nullable-then-required patterns.

6. **Junction tables solve many-to-many:** Standard pattern for complex relationships.

7. **Index strategically:** Think about query patterns during design, not just after performance problems emerge.

8. **Document design decisions:** Notes about "why" are as important as the code itself.

9. **Acknowledge technical debt:** TODO comments help future developers understand what needs improvement.

10. **Real-world testing matters:** Priya's salary CSV files showed the importance of realistic test data.
