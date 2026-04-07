<#
.SYNOPSIS
    Genera el ejecutable NASA-Normalize-Wallpapers.exe a partir del script Python.

.DESCRIPTION
    Usa PyInstaller para crear un .exe standalone que no requiere Python instalado.
    El ejecutable se genera en dist/NASA-Normalize-Wallpapers.exe

    Resuelve el intérprete con Python Launcher para Windows (`py -3`) cuando exista,
    para evitar el alias equivocado de la Microsoft Store; si no, usa `python` en PATH.

.EXAMPLE
    .\scripts\build-normalize-exe.ps1
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SourceScript = Join-Path $ScriptDir "normalize-wallpapers.py"
$ExeName = "NASA-Normalize-Wallpapers"

# Mínimo alineado con pyproject.toml (requires-python).
$MinPython = [Version]"3.10"

<#
.SYNOPSIS
    Devuelve la ruta absoluta a python.exe con versión >= 3.10, o $null.
.DESCRIPTION
    Prueba primero `py -3` (launcher oficial en Windows); luego `python` si cumple versión.
#>
function Get-Python310Executable {
    $candidates = @()

    if (Get-Command py -ErrorAction SilentlyContinue) {
        $pyPath = & py -3 -c "import sys; print(sys.executable)" 2>$null
        if ($LASTEXITCODE -eq 0 -and $pyPath) {
            $candidates += $pyPath.Trim()
        }
    }

    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pyExe = (Get-Command python).Source
        if ($candidates -notcontains $pyExe) {
            $candidates += $pyExe
        }
    }

    foreach ($exe in $candidates) {
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        # Comparación por tupla (3, 10), válida también con versiones alpha/beta.
        & $exe -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return $exe
        }
    }
    return $null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build: NASA Normalize Wallpapers (.exe)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SourceScript)) {
    Write-Host "Error: No se encuentra normalize-wallpapers.py" -ForegroundColor Red
    exit 1
}

$BasePython = Get-Python310Executable
if ($null -eq $BasePython) {
    Write-Host "Error: Se requiere Python $MinPython o superior." -ForegroundColor Red
    Write-Host "  Instalá Python desde https://www.python.org/ y marcá ""Add to PATH"", o usá el launcher ""py""." -ForegroundColor White
    Write-Host "  Si tenés varias versiones, preferí: py -3 -m venv .venv" -ForegroundColor White
    exit 1
}

Write-Host "      Intérprete: $BasePython" -ForegroundColor Gray

$VenvDir = Join-Path $ProjectRoot ".venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    Write-Host "[1/4] Creando entorno virtual .venv..." -ForegroundColor Cyan
    & $BasePython -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) {
        throw "creación de venv falló con código $LASTEXITCODE"
    }
} else {
    Write-Host "[1/4] Usando entorno virtual .venv existente" -ForegroundColor Gray
}

& $VenvPython -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: .venv usa un Python < 3.10. Elimina la carpeta .venv y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] Instalando dependencias del proyecto (pyproject, grupo build)..." -ForegroundColor Cyan
& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw "pip upgrade falló con código $LASTEXITCODE"
}
Push-Location $ProjectRoot
try {
    & $VenvPython -m pip install -q -e ".[build]"
    if ($LASTEXITCODE -ne 0) {
        throw "pip install -e '.[build]' falló con código $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

$importCheck = & $VenvPython -c "import PyInstaller; import PIL" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: No se pudieron importar PyInstaller y Pillow tras instalar." -ForegroundColor Red
    Write-Host $importCheck
    exit 1
}
Write-Host "      [OK] Dependencias listas (.venv)" -ForegroundColor Green
Write-Host ""

# Ejecutar PyInstaller
Write-Host "[3/4] Compilando con PyInstaller..." -ForegroundColor Cyan
Push-Location $ProjectRoot

try {
    & $VenvPython -m PyInstaller `
        --onefile `
        --name $ExeName `
        --console `
        --clean `
        --noconfirm `
        "scripts/normalize-wallpapers.py"

    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller falló con código $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "      [OK] Compilación completada" -ForegroundColor Green
Write-Host ""

# Resultado
# Windows PowerShell 5.1 solo admite dos segmentos por llamada a Join-Path; anidar para dist\*.exe
$DistDir = Join-Path $ProjectRoot "dist"
$ExePath = Join-Path $DistDir "$ExeName.exe"
if (Test-Path $ExePath) {
    Write-Host "[4/4] Ejecutable generado:" -ForegroundColor Cyan
    Write-Host "      $ExePath" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Listo! Copia el .exe donde quieras." -ForegroundColor Green
    Write-Host "  Ejemplo: al escritorio o a la carpeta NASA Wallpapers." -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "[4/4] Error: No se generó el ejecutable." -ForegroundColor Red
    exit 1
}
