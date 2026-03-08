#Requires -Version 5.1
<#
.SYNOPSIS
    Loads demo test data into the Employee database (odbc-mysql implementation).

.DESCRIPTION
    Reads CSVs and data-manifest.json from ../../test-data/ and inserts rows into
    the running MySQL database via ODBC. Handles the Department <-> Employee
    circular FK by loading departments first (DepartmentHeadId NULL) and then
    running deferred UPDATE statements after employees are inserted.

    Requires:
    - MySQL ODBC 8.0 Driver installed
    - patches.local.json present in the same directory with a valid ConnectionString
    - Database built with dbpatch build (all Layers 0-3 applied)

.PARAMETER Truncate
    If specified, truncates all tables before loading. Useful for re-running the script.

.EXAMPLE
    .\load-test-data.ps1
    .\load-test-data.ps1 -Truncate
#>

param(
    [switch]$Truncate
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptDir    = $PSScriptRoot
$testDataDir  = Join-Path $scriptDir "..\..\test-data"
$manifestPath = Join-Path $testDataDir "data-manifest.json"
$localConfigPath = Join-Path $scriptDir "patches.local.json"

# Validate prerequisites
if (-not (Test-Path $localConfigPath)) {
    Write-Error "patches.local.json not found at $localConfigPath. Create it with your connection string."
}
if (-not (Test-Path $manifestPath)) {
    Write-Error "data-manifest.json not found at $manifestPath."
}

# Load connection string
$localConfig = Get-Content $localConfigPath | ConvertFrom-Json
$connectionString = $localConfig.ConnectionString
if (-not $connectionString) {
    Write-Error "ConnectionString is empty in patches.local.json."
}

# Load manifest
$manifest = Get-Content $manifestPath | ConvertFrom-Json

Write-Host "Employee DB -- Load Test Data" -ForegroundColor Cyan
Write-Host "Data directory: $testDataDir"
Write-Host ""

# Open ODBC connection
$conn = New-Object System.Data.Odbc.OdbcConnection($connectionString)
$conn.Open()

try {

    function Invoke-Sql {
        param([string]$Sql)
        $cmd = New-Object System.Data.Odbc.OdbcCommand($Sql, $conn)
        try { return $cmd.ExecuteNonQuery() }
        finally { $cmd.Dispose() }
    }

    # Optionally truncate tables (reverse load order to respect FKs)
    if ($Truncate) {
        Write-Host "Truncating tables..." -ForegroundColor Yellow
        Invoke-Sql "SET FOREIGN_KEY_CHECKS = 0" | Out-Null

        $reverseOrder = [System.Linq.Enumerable]::Reverse($manifest.loadOrder)
        foreach ($tableKey in $reverseOrder) {
            $tableDef = $manifest.tables.$tableKey
            Invoke-Sql "TRUNCATE TABLE $($tableDef.table)" | Out-Null
            Write-Host "  Truncated $($tableDef.table)"
        }

        Invoke-Sql "SET FOREIGN_KEY_CHECKS = 1" | Out-Null
        Write-Host ""
    }

    # Load tables in manifest order
    $totalRows = 0
    foreach ($tableKey in $manifest.loadOrder) {
        $tableDef = $manifest.tables.$tableKey
        $csvPath  = Join-Path $testDataDir $tableDef.file
        $tableName = $tableDef.table

        if (-not (Test-Path $csvPath)) {
            Write-Warning "CSV not found, skipping: $csvPath"
            continue
        }

        $rows = Import-Csv $csvPath
        $columnNames = $tableDef.columns.PSObject.Properties.Name

        # For departments: skip DepartmentHeadId (circular FK, handled by deferredUpdates)
        if ($tableName -eq "Department") {
            $columnNames = $columnNames | Where-Object { $_ -ne "DepartmentHeadId" }
        }

        $colList     = $columnNames -join ", "
        $placeholders = ($columnNames | ForEach-Object { "?" }) -join ", "
        $insertSql   = "INSERT INTO $tableName ($colList) VALUES ($placeholders)"

        $count = 0
        $tx = $conn.BeginTransaction()
        $cmd = $conn.CreateCommand()
        try {
            $cmd.CommandText = $insertSql
            $cmd.Transaction = $tx

            # Define one parameter per column (reused across rows)
            foreach ($col in $columnNames) {
                [void]$cmd.Parameters.Add($col, [System.Data.Odbc.OdbcType]::VarChar, 4000)
            }

            foreach ($row in $rows) {
                for ($i = 0; $i -lt $columnNames.Count; $i++) {
                    $val = $row.($columnNames[$i])
                    $cmd.Parameters[$i].Value = if ($val -eq "" -or $null -eq $val) {
                        [System.DBNull]::Value
                    } else {
                        $val
                    }
                }
                [void]$cmd.ExecuteNonQuery()
                $count++
            }

            $tx.Commit()
        } catch {
            $tx.Rollback()
            throw
        } finally {
            $cmd.Dispose()
        }

        Write-Host "  [OK] $tableName -- $count rows" -ForegroundColor Green
        $totalRows += $count
    }

    # Run deferred updates (e.g., set DepartmentHeadId after employees exist)
    if ($manifest.deferredUpdates -and $manifest.deferredUpdates.Count -gt 0) {
        Write-Host ""
        Write-Host "Running deferred updates..." -ForegroundColor Yellow
        foreach ($update in $manifest.deferredUpdates) {
            Write-Host "  $($update.description)"
            foreach ($sql in $update.sql) {
                $affected = Invoke-Sql $sql
                Write-Host "    $sql -- $affected row(s)" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
    Write-Host "Done. $totalRows total rows loaded." -ForegroundColor Green

} finally {
    $conn.Close()
    $conn.Dispose()
}
