# Rancher Desktop Troubleshooting Guide

## Quick Fixes (No Reboot)

### Option 1: Restart via Task Manager
1. Open Task Manager (Ctrl+Shift+Esc)
2. Find "Rancher Desktop" in the Processes tab
3. Right-click → End Task
4. Launch Rancher Desktop from Start Menu
5. Wait 30-60 seconds for Docker daemon to initialize

### Option 2: PowerShell Restart
```powershell
# Run the restart script
.\restart-rancher.ps1
```

### Option 3: WSL2 Reset
```powershell
# Restart WSL2 backend
wsl --shutdown
# Wait 10 seconds
Start-Sleep -Seconds 10
# Start Rancher Desktop
Start-Process "C:\Program Files\Rancher Desktop\Rancher Desktop.exe"
```

### Option 4: Rancher Desktop UI Reset
1. Open Rancher Desktop
2. Go to Settings (gear icon)
3. Choose one of:
   - **Kubernetes** → Reset Kubernetes
   - **Container Engine** → Reset to Factory Defaults
4. Wait for restart

## Check Status

```powershell
# Check if processes are running
Get-Process rancher-desktop,dockerd,containerd -ErrorAction SilentlyContinue

# Check WSL2 distros
wsl --list --verbose

# Test Docker
docker version
docker ps
```

## Common Error: "Insufficient buffer space"

This specific error often indicates:
- Network port exhaustion
- WSL2 networking issues
- Corrupted WSL2 state

**Quick fix:**
```powershell
# Restart networking
wsl --shutdown
netsh winsock reset
# Then restart Rancher Desktop
```

## If All Else Fails

```powershell
# Nuclear option (preserves images/containers)
wsl --shutdown
Stop-Process -Name "Rancher Desktop" -Force -ErrorAction SilentlyContinue
Start-Process "C:\Program Files\Rancher Desktop\Rancher Desktop.exe"
```

## Alternative: Use Different Port

If port conflicts are suspected:
```yaml
# In docker-compose.yml, change port mapping
ports:
  - "3308:3306"  # Use different host port
```
