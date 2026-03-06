# Employee Database - MySQL ODBC Implementation (Example 2)

**Database Platform:** MySQL 8.0  
**Connection Method:** ODBC Driver  
**Framework:** DBPatch v2  
**Status:** In Development

This is a reference implementation of the Employee Database using MySQL with ODBC connectivity, created from the specifications in SCHEMA_DESIGN.md and SCENARIO.md.

## Purpose

This example demonstrates:
- Platform-specific implementation of the logical schema design
- DBPatch v2 migration framework usage
- MySQL-specific SQL syntax and features
- ODBC driver connectivity

## Prerequisites

- Docker Desktop (for MySQL container)
- MySQL ODBC Driver 8.0+
- DBPatch v2.1.2+ installed at `C:\dbpatch-v2\`
- PowerShell 7+

## Quick Start

### 1. Start MySQL Container

```powershell
docker-compose up -d
```

### 2. Verify Connection

```powershell
# Test ODBC connectivity
.\test-connection.ps1
```

### 3. Initialize DBPatch

```powershell
C:\dbpatch-v2\dbpatch.exe init --dbtype odbc
```

### 4. Run Migrations

```powershell
C:\dbpatch-v2\dbpatch.exe build
```

## Database Configuration

- **Host:** localhost
- **Port:** 3307
- **Database:** employeedb2
- **User:** dbpatch
- **Password:** dbpatch123

## Implementation Status

### Infrastructure
- [x] Docker container running (MySQL 8.0 on port 3307)
- [x] Database created (employeedb2)
- [x] User configured (dbpatch/dbpatch123)
- [ ] MySQL ODBC Driver installed (see INSTALL_ODBC_DRIVER.md)
- [ ] DBPatch initialized

### Schema Layers
- [ ] Layer 0: Foundation (Employees and Departments)
- [ ] Layer 1a: Employee Roles
- [ ] Layer 1b: Salary Tracking
- [ ] Layer 1c: Leave Management
- [ ] Layer 2: Performance Reviews
- [ ] Layer 3: Project Management
- [ ] Layer 4: Technical Debt
- [ ] Layer 5: Soft Delete
- [ ] Layer 6: Organizational Extensions
- [ ] Layer 7: Skills Tracking

## Documentation

- [SCHEMA_DESIGN.md](../../SCHEMA_DESIGN.md) - Technical specifications (platform-agnostic)
- [SCENARIO.md](../../SCENARIO.md) - Team collaboration story

## Notes

This is a teaching and testing repository. The database will be built incrementally following the patch layers defined in the schema design documents.
