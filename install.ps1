# Launcher: ejecuta el script de instalación desde la raíz del proyecto.
# Se relanza en un proceso hijo del mismo host para preservar correctamente el exit code.
$HelpTokens = @("--help", "-help", "-h", "help", "/?", "-?")

if (@($args | Where-Object { $_ -in $HelpTokens }).Count -gt 0) {
    Get-Help "$PSScriptRoot\scripts\install.ps1" -Full
    exit 0
}

$PowerShellHostPath = (Get-Process -Id $PID).Path

if (-not $PowerShellHostPath) {
    Write-Host "Error: No se pudo resolver la ruta del host de PowerShell actual." -ForegroundColor Red
    exit 1
}

& $PowerShellHostPath -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\scripts\install.ps1" @args
exit $LASTEXITCODE
