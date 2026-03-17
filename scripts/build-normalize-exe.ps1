<#
.SYNOPSIS
    Genera el ejecutable NASA-Normalize-Wallpapers.exe a partir del script Python.

.DESCRIPTION
    Usa PyInstaller para crear un .exe standalone que no requiere Python instalado.
    El ejecutable se genera en dist/NASA-Normalize-Wallpapers.exe

.EXAMPLE
    .\scripts\build-normalize-exe.ps1
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SourceScript = Join-Path $ScriptDir "normalize-wallpapers.py"
$ExeName = "NASA-Normalize-Wallpapers"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build: NASA Normalize Wallpapers (.exe)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SourceScript)) {
    Write-Host "Error: No se encuentra normalize-wallpapers.py" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Python no esta instalado o no esta en PATH." -ForegroundColor Red
    Write-Host "  Instala Python desde https://www.python.org/ y asegurate de anadirlo al PATH." -ForegroundColor White
    exit 1
}

# Instalar PyInstaller y Pillow si no están
Write-Host "[1/3] Comprobando dependencias..." -ForegroundColor Cyan
$pipPackages = @("pyinstaller", "pillow")
foreach ($pkg in $pipPackages) {
    $installed = python -m pip show $pkg 2>$null
    if (-not $installed) {
        Write-Host "      Instalando $pkg..." -ForegroundColor Gray
        python -m pip install --upgrade $pkg
    }
}
Write-Host "      [OK] Dependencias listas" -ForegroundColor Green
Write-Host ""

# Ejecutar PyInstaller
Write-Host "[2/3] Compilando con PyInstaller..." -ForegroundColor Cyan
Push-Location $ProjectRoot

try {
    python -m PyInstaller `
        --onefile `
        --name $ExeName `
        --console `
        --clean `
        --noconfirm `
        "scripts/normalize-wallpapers.py"

    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller falló con código $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Host "      [OK] Compilación completada" -ForegroundColor Green
Write-Host ""

# Resultado
$ExePath = Join-Path $ProjectRoot "dist" "$ExeName.exe"
if (Test-Path $ExePath) {
    Write-Host "[3/3] Ejecutable generado:" -ForegroundColor Cyan
    Write-Host "      $ExePath" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Listo! Copia el .exe donde quieras." -ForegroundColor Green
    Write-Host "  Ejemplo: al escritorio o a la carpeta NASA Wallpapers." -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "Error: No se generó el ejecutable." -ForegroundColor Red
    exit 1
}
