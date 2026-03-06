# MySQL ODBC Driver Installation Guide

## Status: ❌ MySQL ODBC Driver Not Installed

The MySQL ODBC driver is required for DBPatch to connect to MySQL databases using ODBC connectivity.

**Note:** This guide is specifically for installing the **MySQL ODBC driver** (also known as MySQL Connector/ODBC), not the MySQL server itself.

## Installation Steps

### Option 1: Download from MySQL (Recommended)

1. **Download the installer:**
   - Visit: https://dev.mysql.com/downloads/connector/odbc/
   - Select "Windows (x86, 64-bit), MSI Installer"
   - Version 8.0 or higher recommended
   - Download the 64-bit version (matches your PowerShell)

2. **Run the installer:**
   - Double-click the downloaded `.msi` file
   - Follow the installation wizard
   - Choose "Typical" installation

3. **Verify installation:**
   ```powershell
   Get-OdbcDriver | Where-Object { $_.Name -like "*MySQL*" }
   ```

### Option 2: WinGet (Command Line)

```powershell
winget search mysql odbc
# Install the appropriate package
winget install Oracle.MySQLODBCDriver
```

### Option 3: Chocolatey

```powershell
choco install mysql-odbc-connector
```

## After Installation

Once installed, the driver will appear as something like:
- "MySQL ODBC 8.0 ANSI Driver" (32-bit)
- "MySQL ODBC 8.0 Unicode Driver" (64-bit)

Then run the connection test:
```powershell
.\test-connection.ps1
```

## Current System Info

- **PowerShell:** 64-bit
- **Installed ODBC Drivers:** SQL Server drivers only (no MySQL)
- **MySQL Container:** ✅ Running on port 3307
