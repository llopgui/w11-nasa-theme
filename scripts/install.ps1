<#
.SYNOPSIS
    Instala, repara o desinstala NASA Space Theme para Windows 11.

.DESCRIPTION
    Ejecuta una operación transaccional sobre los assets y la personalización del
    usuario. La primera instalación migra el layout antiguo mediante un clean reset.
    Las reinstalaciones posteriores conservan wallpapers no administrados.

.PARAMETER Action
    Install instala o actualiza. Repair reconstruye y vuelve a aplicar. Uninstall
    elimina los assets administrados y restaura la personalización original.

.PARAMETER Theme
    Variante dark o light.

.PARAMETER RestartExplorer
    Reinicia Explorer al terminar. Normalmente no es necesario porque el instalador
    transmite los cambios de configuración a Windows.

.PARAMETER ThemeApplyTimeoutSeconds
    Tiempo máximo para conseguir tres verificaciones consecutivas del estado final.

.PARAMETER Help
    Muestra la ayuda completa sin modificar el sistema.

.EXAMPLE
    .\install.ps1 -Theme dark

.EXAMPLE
    .\install.ps1 -Action Repair -Theme light

.EXAMPLE
    .\install.ps1 -Action Uninstall

.EXAMPLE
    .\install.ps1 -Theme dark -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Install", "Repair", "Uninstall")]
    [string]$Action = "Install",
    [Parameter(Mandatory = $false)]
    [ValidateSet("dark", "light")]
    [string]$Theme = "dark",
    [Parameter(Mandatory = $false)]
    [ValidateRange(5, 120)]
    [int]$ThemeApplyTimeoutSeconds = 30,
    [Parameter(Mandatory = $false)]
    [switch]$RestartExplorer,
    [Parameter(Mandatory = $false)]
    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Get-Help -Full $PSCommandPath
    exit 0
}

$scriptDirectory = Split-Path -Parent $PSCommandPath
$projectRoot = Split-Path -Parent $scriptDirectory
$modulePath = Join-Path $scriptDirectory "NasaThemeInstaller.psm1"
Import-Module $modulePath -Force

try {
    $paths = Get-NasaThemePaths -ProjectRoot $projectRoot
    $target = if ($Action -eq "Uninstall") {
        "NASA Space Theme y la personalización original"
    } else {
        "NASA Space Theme ($Theme, acento automático)"
    }

    if (-not $PSCmdlet.ShouldProcess($target, $Action)) {
        Write-Host "Plan completado: no se modificó el sistema." -ForegroundColor Cyan
        exit 0
    }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  NASA Space Theme - $Action" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Invoke-NasaThemeAction `
        -Action $Action `
        -Paths $paths `
        -Theme $Theme `
        -TimeoutSeconds $ThemeApplyTimeoutSeconds `
        -RestartExplorer:$RestartExplorer

    Write-Host ""
    Write-Host "[OK] Operación completada." -ForegroundColor Green
    if ($Action -ne "Uninstall") {
        Write-Host "     Tema: $Theme | Acento: automático" -ForegroundColor White
        Write-Host "     Wallpapers: $($paths.SlideshowRoot)" -ForegroundColor White
    }
    exit 0
} catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Se intentó restaurar el estado anterior automáticamente." -ForegroundColor Yellow
    exit 1
}
