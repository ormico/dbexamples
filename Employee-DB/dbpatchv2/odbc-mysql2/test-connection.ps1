# Test MySQL ODBC Connection
# Run this script after the MySQL container is running

$ErrorActionPreference = "Stop"

Write-Host "Testing MySQL ODBC Connection..." -ForegroundColor Cyan

# Connection parameters
$server = "localhost"
$port = "3307"
$database = "employeedb2"
$user = "dbpatch"
$password = "dbpatch123"

# Test 1: Check if container is running
Write-Host "`n[1/4] Checking MySQL container status..." -ForegroundColor Yellow
try {
    $container = docker ps --filter "name=employeedb-mysql2" --format "{{.Status}}"
    if ($container -match "Up") {
        Write-Host "✓ Container is running: $container" -ForegroundColor Green
    } else {
        Write-Host "✗ Container is not running" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error checking container: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check ODBC Driver
Write-Host "`n[2/4] Checking for MySQL ODBC Driver..." -ForegroundColor Yellow
$drivers = Get-OdbcDriver -Name "MySQL ODBC*" -ErrorAction SilentlyContinue
if ($drivers) {
    foreach ($driver in $drivers) {
        Write-Host "✓ Found: $($driver.Name)" -ForegroundColor Green
    }
    $driverName = $drivers[0].Name
} else {
    Write-Host "✗ MySQL ODBC Driver not found!" -ForegroundColor Red
    Write-Host "Please install from: https://dev.mysql.com/downloads/connector/odbc/" -ForegroundColor Yellow
    exit 1
}

# Test 3: Test TCP connectivity
Write-Host "`n[3/4] Testing TCP connectivity to MySQL..." -ForegroundColor Yellow
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($server, $port)
    $tcpClient.Close()
    Write-Host "✓ TCP connection successful to ${server}:${port}" -ForegroundColor Green
} catch {
    Write-Host "✗ Cannot connect to ${server}:${port}" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Test ODBC Connection
Write-Host "`n[4/4] Testing ODBC connection..." -ForegroundColor Yellow
$connectionString = "Driver={$driverName};Server=$server;Port=$port;Database=$database;Uid=$user;Pwd=$password;"

try {
    $connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT VERSION() as version, DATABASE() as current_db"
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $version = $reader["version"]
        $currentDb = $reader["current_db"]
        Write-Host "✓ ODBC connection successful!" -ForegroundColor Green
        Write-Host "  MySQL Version: $version" -ForegroundColor Cyan
        Write-Host "  Current Database: $currentDb" -ForegroundColor Cyan
    }
    
    $reader.Close()
    $connection.Close()
    
    Write-Host "`n✓ All tests passed! Ready for DBPatch." -ForegroundColor Green
    
} catch {
    Write-Host "✗ ODBC connection failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nConnection String (for debugging):" -ForegroundColor Yellow
    Write-Host $connectionString.Replace($password, "***") -ForegroundColor Gray
    exit 1
}
