<#
.SYNOPSIS
    Script de instalacion del tema NASA para Windows 11.

.DESCRIPTION
    Copia los wallpapers, aplica el tema y activa el modo oscuro/claro del sistema
    (Elige tu modo en Configuracion > Personalizacion > Colores).

.PARAMETER Theme
    "dark" para tema oscuro, "light" para tema claro.

.PARAMETER NoRestart
    No reinicia Explorer. Los cambios se aplicaran al cambiar de ventana.

.EXAMPLE
    .\install.ps1 -Theme dark
    .\install.ps1 -Theme light
    .\install.ps1 -Theme dark -NoRestart
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dark", "light")]
    [string]$Theme = "dark",
    [Parameter(Mandatory=$false)]
    [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

if (-not $env:LOCALAPPDATA) {
    Write-Host "Error: LOCALAPPDATA no esta definido. Ejecuta el script desde una sesion de usuario normal de Windows." -ForegroundColor Red
    exit 1
}

# Rutas: ProjectRoot = directorio raiz del repo (parent de scripts/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ThemesPath = "$env:LOCALAPPDATA\Microsoft\Windows\Themes"
$NASA_DesktopPath = "$ThemesPath\NASA_Desktop"
$WallpapersSourcePath = Join-Path $ProjectRoot "assets\wallpapers"
$CursorsSourcePath = Join-Path $ProjectRoot "assets\cursors"
$CursorsDestPath = "$NASA_DesktopPath\Cursors"
$SoundsSourcePath = Join-Path $ProjectRoot "assets\sounds"
$SoundsDestPath = "$NASA_DesktopPath\Sounds"
$ThemesSourcePath = Join-Path $ProjectRoot "themes"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NASA Theme - Instalador para Windows 11" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Crear directorio y copiar wallpapers
Write-Host "[1/5] Wallpapers..." -ForegroundColor Cyan
if (-not (Test-Path $NASA_DesktopPath)) {
    New-Item -ItemType Directory -Path $NASA_DesktopPath -Force | Out-Null
    Write-Host "      Directorio creado: $NASA_DesktopPath" -ForegroundColor Gray
}

$imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.tif", "*.tiff")
$wallpaperCount = 0

if (Test-Path $WallpapersSourcePath) {
    foreach ($ext in $imageExtensions) {
        Get-ChildItem -Path $WallpapersSourcePath -Filter $ext -File -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName $NASA_DesktopPath -Force
            Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
            $wallpaperCount++
        }
    }
}

if ($wallpaperCount -eq 0) {
    Write-Host "      ADVERTENCIA: No hay wallpapers en assets\wallpapers\" -ForegroundColor Yellow
    Write-Host "      Coloca imagenes (jpg, png, bmp) en esa carpeta." -ForegroundColor White
} else {
    Write-Host "      [OK] $wallpaperCount wallpapers instalados" -ForegroundColor Green
}

# Acceso directo en el escritorio hacia la carpeta de wallpapers
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "NASA Wallpapers.lnk"
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $NASA_DesktopPath
    $Shortcut.WorkingDirectory = $NASA_DesktopPath
    $Shortcut.Description = "Carpeta de wallpapers del tema NASA. Añade aquí nuevas imágenes para el slideshow."
    $Shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    Write-Host "      [OK] Acceso directo creado en el escritorio: NASA Wallpapers" -ForegroundColor Green
} catch {
    Write-Host "      ADVERTENCIA: No se pudo crear el acceso directo en el escritorio." -ForegroundColor Yellow
}
Write-Host ""

# 1b. Copiar cursores W11 Tail Cursor (Jepri Creations)
Write-Host "[2/5] Cursores..." -ForegroundColor Cyan
$CursorPackPath = Join-Path $CursorsSourcePath "w11-tail-cursor-concept-free\cursor"
$CursorThemePath = if ($Theme -eq "dark") { Join-Path $CursorPackPath "dark" } else { Join-Path $CursorPackPath "light" }
$cursorCount = 0
if (Test-Path $CursorThemePath) {
    if (-not (Test-Path $CursorsDestPath)) {
        New-Item -ItemType Directory -Path $CursorsDestPath -Force | Out-Null
    }
    Get-ChildItem -Path $CursorThemePath -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.cur','.ani' } |
        ForEach-Object {
            Copy-Item $_.FullName $CursorsDestPath -Force
            Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
            $cursorCount++
        }
    if ($cursorCount -gt 0) {
        Write-Host "      [OK] $cursorCount cursores instalados" -ForegroundColor Green
        Write-Host ""
        Write-Host "      --- Atribucion (requerida por licencia) ---" -ForegroundColor Yellow
        Write-Host "      Pack: W11 Tail Cursor Concept Free" -ForegroundColor White
        Write-Host "      Autor: Jepri Creations" -ForegroundColor White
        Write-Host "      DeviantArt: https://www.deviantart.com/jepricreations" -ForegroundColor Cyan
        Write-Host "      -------------------------------------------" -ForegroundColor Yellow
    }
} else {
    Write-Host "      Pack de cursores no encontrado en assets\cursors\w11-tail-cursor-concept-free\" -ForegroundColor Yellow
}
Write-Host ""

# 1c. Copiar sonidos (opcional)
Write-Host "[3/5] Sonidos..." -ForegroundColor Cyan
$soundCount = 0
if (Test-Path $SoundsSourcePath) {
    if (-not (Test-Path $SoundsDestPath)) {
        New-Item -ItemType Directory -Path $SoundsDestPath -Force | Out-Null
    }
    Get-ChildItem -Path $SoundsSourcePath -Filter "*.wav" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName $SoundsDestPath -Force
        Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
        $soundCount++
    }
}
if ($soundCount -gt 0) {
    Write-Host "      [OK] $soundCount sonidos instalados" -ForegroundColor Green
} else {
    Write-Host "      Ningun sonido en assets\sounds\ (opcional)" -ForegroundColor Gray
}
Write-Host ""

# 2. Copiar y aplicar tema
Write-Host "[4/5] Tema..." -ForegroundColor Cyan
$themeFile = if ($Theme -eq "dark") { "NASA_Tema_Oscuro.theme" } else { "NASA_Tema_Claro.theme" }
$themeSource = Join-Path $ThemesSourcePath $themeFile
$themeDest = Join-Path $ThemesPath $themeFile

if (-not (Test-Path $themeSource)) {
    Write-Host "      Error: No se encuentra $themeFile en themes\" -ForegroundColor Red
    exit 1
}
Copy-Item $themeSource $themeDest -Force
Write-Host "      Copiado: $themeFile" -ForegroundColor Gray
Write-Host "      [OK] Tema listo" -ForegroundColor Green
Write-Host ""

# 3. Aplicar tema PRIMERO (puede resetear el modo de color)
Write-Host "[5/5] Configuracion del sistema..." -ForegroundColor Cyan
Write-Host "      Aplicando tema NASA ($Theme)..." -ForegroundColor Gray
Start-Process $themeDest
Start-Sleep -Seconds 2

# 4. Activar modo oscuro/claro DESPUES del tema
$PersonalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$lightValue = if ($Theme -eq "dark") { 0 } else { 1 }

try {
    if (-not (Test-Path $PersonalizePath)) {
        New-Item -Path $PersonalizePath -Force | Out-Null
    }
    Set-ItemProperty -Path $PersonalizePath -Name "AppsUseLightTheme" -Value $lightValue -Type DWord -Force
    Set-ItemProperty -Path $PersonalizePath -Name "SystemUsesLightTheme" -Value $lightValue -Type DWord -Force
    $modoTexto = if ($Theme -eq "dark") { "Oscuro" } else { "Claro" }
    Write-Host "      Modo: $modoTexto (Windows + Apps)" -ForegroundColor Gray
    Write-Host "      [OK] Modo del sistema configurado" -ForegroundColor Green
} catch {
    Write-Host "      ADVERTENCIA: No se pudo cambiar el modo." -ForegroundColor Yellow
}

# 4b. Color de enfasis en Automatico
$accentOk = $false
try {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 1 -Type DWord -Force -ErrorAction Stop
    $accentOk = $true
} catch { }
if (-not $accentOk) {
    try {
        $AccentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
        if (-not (Test-Path $AccentPath)) { New-Item -Path $AccentPath -Force | Out-Null }
        Set-ItemProperty -Path $AccentPath -Name "AccentColorSet" -Value 0 -Type DWord -Force -ErrorAction Stop
        $accentOk = $true
    } catch { }
}
if ($accentOk) {
    Write-Host "      Color de enfasis: Automatico (del wallpaper)" -ForegroundColor Gray
    Write-Host "      [OK] Color de enfasis configurado" -ForegroundColor Green
} else {
    Write-Host "      ADVERTENCIA: No se pudo activar color automatico." -ForegroundColor Yellow
}

# 5. Reiniciar Explorer
if (-not $NoRestart) {
    Write-Host "      Reiniciando Explorer..." -ForegroundColor Gray
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
} else {
    Write-Host "      Los cambios se aplicaran al cambiar de ventana." -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Instalacion completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumen:" -ForegroundColor Cyan
Write-Host "  - Tema: NASA Space ($Theme)" -ForegroundColor White
Write-Host "  - Configuracion > Personalizacion > Temas" -ForegroundColor White
if ($wallpaperCount -gt 0) {
    Write-Host "  - Wallpapers: $wallpaperCount imagenes (slideshow cada 10 min)" -ForegroundColor White
}
Write-Host "  - Acceso directo en escritorio: NASA Wallpapers (añade ahí nuevas imagenes)" -ForegroundColor White
if ($cursorCount -gt 0) {
    Write-Host "  - Cursores: W11 Tail Cursor por Jepri Creations" -ForegroundColor White
    Write-Host "    https://www.deviantart.com/jepricreations" -ForegroundColor Cyan
}
if ($soundCount -gt 0) {
    Write-Host "  - Sonidos: $soundCount personalizados" -ForegroundColor White
}
Write-Host ""
