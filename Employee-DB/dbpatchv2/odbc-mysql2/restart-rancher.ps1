# Restart Rancher Desktop Services
# This script attempts to restart Rancher Desktop without a full reboot

$ErrorActionPreference = "Continue"

Write-Host "Attempting to restart Rancher Desktop..." -ForegroundColor Cyan

# Step 1: Stop Rancher Desktop processes
Write-Host "`n[1/4] Stopping Rancher Desktop processes..." -ForegroundColor Yellow
$processes = @("rancher-desktop", "dockerd", "containerd", "wsl-helper", "wsl-service")
foreach ($proc in $processes) {
    $running = Get-Process $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc..." -ForegroundColor Gray
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

# Step 2: Check WSL2 backend
Write-Host "`n[2/4] Checking WSL2 status..." -ForegroundColor Yellow
try {
    $wslStatus = wsl --list --running
    Write-Host $wslStatus -ForegroundColor Gray
    
    # Terminate rancher-desktop distro if running
    if ($wslStatus -match "rancher-desktop") {
        Write-Host "  Terminating rancher-desktop WSL2..." -ForegroundColor Gray
        wsl --terminate rancher-desktop
        Start-Sleep -Seconds 3
    }
} catch {
    Write-Host "  WSL not available or error: $_" -ForegroundColor Yellow
}

# Step 3: Restart Rancher Desktop
Write-Host "`n[3/4] Starting Rancher Desktop..." -ForegroundColor Yellow
$rdPath = "C:\Program Files\Rancher Desktop\Rancher Desktop.exe"
if (Test-Path $rdPath) {
    Start-Process $rdPath
    Write-Host "  Rancher Desktop started. Waiting for initialization..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
} else {
    Write-Host "  ✗ Could not find Rancher Desktop executable at: $rdPath" -ForegroundColor Red
    exit 1
}

# Step 4: Test Docker connection
Write-Host "`n[4/4] Testing Docker connection..." -ForegroundColor Yellow
$maxAttempts = 12
$attempt = 0
$connected = $false

while ($attempt -lt $maxAttempts -and -not $connected) {
    $attempt++
    Write-Host "  Attempt $attempt of $maxAttempts..." -ForegroundColor Gray
    
    try {
        $dockerInfo = docker info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ Docker is now responding!" -ForegroundColor Green
            $connected = $true
        } else {
            Start-Sleep -Seconds 5
        }
    } catch {
        Start-Sleep -Seconds 5
    }
}

if ($connected) {
    Write-Host "`n✓ Rancher Desktop successfully restarted!" -ForegroundColor Green
    docker version
} else {
    Write-Host "`n✗ Docker still not responding after $maxAttempts attempts" -ForegroundColor Red
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "  1. Open Rancher Desktop UI and check for errors" -ForegroundColor Yellow
    Write-Host "  2. Try Settings > Reset Kubernetes/Container Runtime" -ForegroundColor Yellow
    Write-Host "  3. Check Windows Event Viewer for errors" -ForegroundColor Yellow
    exit 1
}
