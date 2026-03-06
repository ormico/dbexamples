#Requires -Version 5.1
<#
.SYNOPSIS
    Loads demo test data into the Employee database (odbc-mysql2 implementation).

.DESCRIPTION
    Reads CSVs and data-manifest.json from ../../test-data/ and inserts rows into
    the running MySQL database via ODBC.

    See the odbc-mysql implementation for the full loader:
    ../odbc-mysql/load-test-data.ps1

    This stub will be implemented once odbc-mysql2 reaches a stable state.
    See: https://github.com/ormico/dbexamples — Open Question #2 (odbc-mysql2 direction).

.NOTES
    Status: STUB — not yet implemented
#>

Write-Host "load-test-data.ps1 is not yet implemented for odbc-mysql2." -ForegroundColor Yellow
Write-Host ""
Write-Host "Reference implementation: Employee-DB/dbpatchv2/odbc-mysql/load-test-data.ps1"
Write-Host "Test data:                Employee-DB/test-data/"
Write-Host "Manifest:                 Employee-DB/test-data/data-manifest.json"
