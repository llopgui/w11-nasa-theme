<#
.SYNOPSIS
    Script de instalación del tema NASA para Windows 11.

.DESCRIPTION
    Copia los wallpapers, aplica el tema y activa el modo oscuro/claro del sistema
    (elige tu modo en Configuración > Personalización > Colores).

.PARAMETER Theme
    "dark" para tema oscuro, "light" para tema claro.

.PARAMETER AccentMode
    "auto" para acento dinámico según wallpaper, "fixed" para acento fijo NASA (#105bd8).

.PARAMETER RestartExplorer
    Reinicia el proceso Explorer (cierra todas las ventanas del Explorador; puede interrumpir
    trabajo en curso). Por defecto no se reinicia; los cambios suelen aplicarse al cambiar de ventana.

.PARAMETER ThemeApplyTimeoutSeconds
    Tiempo máximo (en segundos) para esperar que Windows confirme CurrentTheme tras abrir el .theme.
    Incrementa este valor en equipos lentos para evitar falsos fallos.

.EXAMPLE
    .\install.ps1 -Theme dark
    .\install.ps1 -Theme light
    .\install.ps1 -Theme dark -AccentMode fixed
    .\install.ps1 -Theme dark -RestartExplorer
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dark", "light")]
    [string]$Theme = "dark",
    [Parameter(Mandatory=$false)]
    [ValidateSet("auto", "fixed")]
    [string]$AccentMode = "auto",
    [Parameter(Mandatory=$false)]
    [ValidateRange(5, 120)]
    [int]$ThemeApplyTimeoutSeconds = 30,
    [Parameter(Mandatory=$false)]
    [switch]$RestartExplorer
)

$ErrorActionPreference = "Stop"

if (-not $env:LOCALAPPDATA) {
    Write-Host "Error: LOCALAPPDATA no está definido. Ejecuta el script desde una sesión de usuario normal de Windows." -ForegroundColor Red
    exit 1
}

# Rutas: ProjectRoot = directorio raíz del repo (parent de scripts/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ThemesPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Themes"
$NASA_DesktopPath = Join-Path $ThemesPath "NASA_Desktop"
$WallpapersSourcePath = Join-Path $ProjectRoot "assets\wallpapers"
$CursorsSourcePath = Join-Path $ProjectRoot "assets\cursors"
$CursorsDestPath = Join-Path $NASA_DesktopPath "Cursors"
$SoundsSourcePath = Join-Path $ProjectRoot "assets\sounds"
$SoundsDestPath = Join-Path $NASA_DesktopPath "Sounds"
$ThemesSourcePath = Join-Path $ProjectRoot "themes"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  NASA Theme - Instalador para Windows 11" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Crear directorio y copiar wallpapers
Write-Host "[1/5] Wallpapers..." -ForegroundColor Cyan
if (Test-Path -LiteralPath $NASA_DesktopPath) {
    $nasaItem = Get-Item -LiteralPath $NASA_DesktopPath
    if (-not $nasaItem.PSIsContainer) {
        Write-Host "Error: Existe un archivo (no carpeta) en $NASA_DesktopPath. Elimínalo o renómbralo y vuelve a ejecutar el instalador." -ForegroundColor Red
        exit 1
    }
} else {
    New-Item -ItemType Directory -Path $NASA_DesktopPath -Force | Out-Null
    Write-Host "      Directorio creado: $NASA_DesktopPath" -ForegroundColor Gray
}

$imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.tif", "*.tiff", "*.webp")
$wallpaperCount = 0
$wallpaperCopyErrors = 0

if (Test-Path -LiteralPath $WallpapersSourcePath) {
    foreach ($ext in $imageExtensions) {
        Get-ChildItem -LiteralPath $WallpapersSourcePath -Filter $ext -File -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Copy-Item -LiteralPath $_.FullName -Destination $NASA_DesktopPath -Force -ErrorAction Stop
                Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
                $wallpaperCount++
            } catch {
                $wallpaperCopyErrors++
                Write-Host "      ADVERTENCIA: No se pudo copiar $($_.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

if ($wallpaperCount -eq 0) {
    Write-Host "      ADVERTENCIA: No hay wallpapers en assets\wallpapers\" -ForegroundColor Yellow
    Write-Host "      Coloca imágenes (jpg, png, bmp, webp, etc.) en esa carpeta." -ForegroundColor White
} else {
    Write-Host "      [OK] $wallpaperCount wallpapers instalados" -ForegroundColor Green
}
if ($wallpaperCopyErrors -gt 0) {
    Write-Host "      ADVERTENCIA: $wallpaperCopyErrors wallpaper(s) no se pudieron copiar." -ForegroundColor Yellow
}

# Acceso directo en el escritorio hacia la carpeta de wallpapers
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "NASA Wallpapers.lnk"
$WshShell = $null
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $NASA_DesktopPath
    $Shortcut.WorkingDirectory = $NASA_DesktopPath
    $Shortcut.Description = "Carpeta de wallpapers del tema NASA. Añade aquí nuevas imágenes para el slideshow."
    $Shortcut.Save()
    Write-Host "      [OK] Acceso directo creado en el escritorio: NASA Wallpapers" -ForegroundColor Green
} catch {
    Write-Host "      ADVERTENCIA: No se pudo crear el acceso directo en el escritorio." -ForegroundColor Yellow
} finally {
    if ($null -ne $WshShell) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    }
}
Write-Host ""

# 1b. Copiar cursores W11 Tail Cursor (Jepri Creations)
Write-Host "[2/5] Cursores..." -ForegroundColor Cyan
$CursorPackPath = Join-Path $CursorsSourcePath "w11-tail-cursor-concept-free\cursor"
$CursorThemePath = if ($Theme -eq "dark") { Join-Path $CursorPackPath "dark" } else { Join-Path $CursorPackPath "light" }
$cursorCount = 0
$cursorCopyErrors = 0
$cursorSetComplete = $false
$missingCursorThemeFiles = @()
# Nombres requeridos por los .theme para evitar falsos OK con packs parciales.
$requiredCursorThemeFiles = @(
    "arrow.cur",
    "help.cur",
    "hand.cur",
    "appstarting.ani",
    "wait.ani",
    "nwpen.cur",
    "no.cur",
    "sizens.cur",
    "sizewe.cur",
    "crosshair.cur",
    "ibeam.cur",
    "sizenwse.cur",
    "sizenesw.cur",
    "sizeall.cur",
    "uparrow.cur",
    "person.cur",
    "pin.cur"
)
if (Test-Path -LiteralPath $CursorThemePath) {
    if (-not (Test-Path -LiteralPath $CursorsDestPath)) {
        New-Item -ItemType Directory -Path $CursorsDestPath -Force | Out-Null
    }
    $cursorFiles = Get-ChildItem -LiteralPath $CursorThemePath -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension.ToLowerInvariant() -in '.cur', '.ani' }
    $cursorFileNames = @($cursorFiles | ForEach-Object { $_.Name.ToLowerInvariant() })
    $missingCursorThemeFiles = @($requiredCursorThemeFiles | Where-Object { $_ -notin $cursorFileNames })
    $cursorFiles | ForEach-Object {
            try {
                Copy-Item -LiteralPath $_.FullName -Destination $CursorsDestPath -Force -ErrorAction Stop
                Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
                $cursorCount++
            } catch {
                $cursorCopyErrors++
                Write-Host "      ADVERTENCIA: No se pudo copiar $($_.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    if ($cursorCount -gt 0 -and $missingCursorThemeFiles.Count -eq 0) {
        $cursorSetComplete = $true
        Write-Host "      [OK] $cursorCount cursores instalados" -ForegroundColor Green
        Write-Host ""
        Write-Host "      --- Atribución (requerida por licencia) ---" -ForegroundColor Yellow
        Write-Host "      Pack: W11 Tail Cursor Concept Free" -ForegroundColor White
        Write-Host "      Autor: Jepri Creations" -ForegroundColor White
        Write-Host "      DeviantArt: https://www.deviantart.com/jepricreations" -ForegroundColor Cyan
        Write-Host "      -------------------------------------------" -ForegroundColor Yellow
    } elseif ($cursorCount -gt 0) {
        Write-Host "      ADVERTENCIA: Se copiaron $cursorCount cursores, pero faltan archivos requeridos por el .theme: $($missingCursorThemeFiles -join ', ')." -ForegroundColor Yellow
    } else {
        Write-Host "      ADVERTENCIA: La carpeta del pack no contiene .cur/.ani copiables. El .theme puede referir cursores que no existan (instala el pack completo o ignora entradas rotas en Temas)." -ForegroundColor Yellow
    }
} else {
    Write-Host "      Pack de cursores no encontrado en assets\cursors\w11-tail-cursor-concept-free\" -ForegroundColor Yellow
}
if ($cursorCopyErrors -gt 0) {
    Write-Host "      ADVERTENCIA: $cursorCopyErrors cursor(es) no se pudieron copiar." -ForegroundColor Yellow
}
Write-Host ""

# 1c. Copiar sonidos (opcional)
Write-Host "[3/5] Sonidos..." -ForegroundColor Cyan
$soundCount = 0
$soundCopyErrors = 0
if (Test-Path -LiteralPath $SoundsSourcePath) {
    if (-not (Test-Path -LiteralPath $SoundsDestPath)) {
        New-Item -ItemType Directory -Path $SoundsDestPath -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $SoundsSourcePath -Filter "*.wav" -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Copy-Item -LiteralPath $_.FullName -Destination $SoundsDestPath -Force -ErrorAction Stop
            Write-Host "      Copiado: $($_.Name)" -ForegroundColor Gray
            $soundCount++
        } catch {
            $soundCopyErrors++
            Write-Host "      ADVERTENCIA: No se pudo copiar $($_.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
if ($soundCount -gt 0) {
    Write-Host "      [OK] $soundCount sonidos instalados" -ForegroundColor Green
} else {
    Write-Host "      Ningún sonido en assets\sounds\ (opcional)" -ForegroundColor Gray
}
if ($soundCopyErrors -gt 0) {
    Write-Host "      ADVERTENCIA: $soundCopyErrors sonido(s) no se pudieron copiar." -ForegroundColor Yellow
}
Write-Host ""

# 2. Copiar y aplicar tema
Write-Host "[4/5] Tema..." -ForegroundColor Cyan
$themeFile = if ($Theme -eq "dark") { "NASA_Tema_Oscuro.theme" } else { "NASA_Tema_Claro.theme" }
$themeSource = Join-Path $ThemesSourcePath $themeFile
$themeDest = Join-Path $ThemesPath $themeFile

if (-not (Test-Path -LiteralPath $themeSource)) {
    Write-Host "      Error: No se encuentra $themeFile en themes\" -ForegroundColor Red
    exit 1
}
try {
    Copy-Item -LiteralPath $themeSource -Destination $themeDest -Force -ErrorAction Stop
} catch {
    Write-Host "      Error: No se pudo copiar ${themeFile}: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "      Copiado: $themeFile" -ForegroundColor Gray
Write-Host "      [OK] Tema listo" -ForegroundColor Green
Write-Host ""

# 3. Aplicar tema PRIMERO (puede resetear el modo de color)
Write-Host "[5/5] Configuración del sistema..." -ForegroundColor Cyan
Write-Host "      Aplicando tema NASA ($Theme)..." -ForegroundColor Gray
$criticalFailures = [System.Collections.Generic.List[string]]::new()
$themeApplied = $false
try {
    Start-Process -FilePath $themeDest -ErrorAction Stop | Out-Null

    # Espera activa para evitar condición de carrera: continúa solo cuando Windows confirma el tema.
    $themeStatePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes"
    # Timeout configurable para tolerar equipos lentos sin bloquear indefinidamente.
    $themeApplyDeadline = (Get-Date).AddSeconds($ThemeApplyTimeoutSeconds)
    do {
        $currentTheme = $null
        try {
            $currentTheme = (Get-ItemProperty -LiteralPath $themeStatePath -Name "CurrentTheme" -ErrorAction Stop).CurrentTheme
        } catch {
            $currentTheme = $null
        }

        if ($currentTheme -and $currentTheme.EndsWith($themeFile, [System.StringComparison]::OrdinalIgnoreCase)) {
            $themeApplied = $true
            break
        }

        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $themeApplyDeadline)

    if (-not $themeApplied) {
        throw "Windows no confirmó la aplicación de $themeFile dentro de ${ThemeApplyTimeoutSeconds}s."
    }
} catch {
    $criticalFailures.Add("No se pudo aplicar el tema automáticamente: $($_.Exception.Message)")
    Write-Host "      ERROR: No se pudo abrir/aplicar el tema automáticamente. Ábrelo manualmente desde Configuración > Personalización > Temas." -ForegroundColor Red
}

# Fail-fast: si el tema no se aplicó, no continuar con cambios de registro (modo/acento).
if (-not $themeApplied) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Instalación incompleta" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Errores críticos:" -ForegroundColor Red
    foreach ($failure in $criticalFailures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    Write-Host ""
    exit 1
}

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
    $criticalFailures.Add("No se pudo configurar el modo del sistema: $($_.Exception.Message)")
    Write-Host "      ERROR: No se pudo cambiar el modo del sistema." -ForegroundColor Red
}

# 4b. Color de énfasis configurable (auto o fijo NASA)
if ($AccentMode -eq "fixed") {
    $accentOk = $false
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 0 -Type DWord -Force -ErrorAction Stop
        $accentOk = $true
    } catch {
        Write-Host "      (AutoColorization: $($_.Exception.Message))" -ForegroundColor DarkGray
    }

    if ($accentOk) {
        Write-Host "      Color de énfasis: fijo NASA (#105bd8)" -ForegroundColor Gray
        Write-Host "      [OK] Color de énfasis configurado" -ForegroundColor Green
    } else {
        $criticalFailures.Add("No se pudo fijar el color de énfasis NASA.")
        Write-Host "      ERROR: No se pudo fijar el color de énfasis." -ForegroundColor Red
    }
} else {
    $accentOk = $false
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoColorization" -Value 1 -Type DWord -Force -ErrorAction Stop
        $accentOk = $true
    } catch {
        Write-Host "      (AutoColorization: $($_.Exception.Message))" -ForegroundColor DarkGray
    }
    if (-not $accentOk) {
        try {
            $AccentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
            if (-not (Test-Path $AccentPath)) { New-Item -Path $AccentPath -Force | Out-Null }
            Set-ItemProperty -Path $AccentPath -Name "AccentColorSet" -Value 0 -Type DWord -Force -ErrorAction Stop
            $accentOk = $true
        } catch {
            Write-Host "      (AccentColorSet: $($_.Exception.Message))" -ForegroundColor DarkGray
        }
    }
    if ($accentOk) {
        Write-Host "      Color de énfasis: automático (del wallpaper)" -ForegroundColor Gray
        Write-Host "      [OK] Color de énfasis configurado" -ForegroundColor Green
    } else {
        $criticalFailures.Add("No se pudo activar el color de énfasis automático.")
        Write-Host "      ERROR: No se pudo activar color automático." -ForegroundColor Red
    }
}

# 5. Reiniciar Explorer (opt-in: cierra todas las ventanas del Explorador de archivos)
if ($RestartExplorer) {
    Write-Host "      Reiniciando Explorer (todas las ventanas)..." -ForegroundColor Gray
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
} else {
    Write-Host "      Sin reinicio de Explorer; los cambios suelen aplicarse al cambiar de ventana. Usa -RestartExplorer si hace falta." -ForegroundColor Gray
}

Write-Host ""
if ($criticalFailures.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Instalación incompleta" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Errores críticos:" -ForegroundColor Red
    foreach ($failure in $criticalFailures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    Write-Host ""
    exit 1
}
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Instalación completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resumen:" -ForegroundColor Cyan
Write-Host "  - Tema: NASA Space ($Theme)" -ForegroundColor White
if ($AccentMode -eq "fixed") {
    Write-Host "  - Color de énfasis: fijo NASA (#105bd8)" -ForegroundColor White
} else {
    Write-Host "  - Color de énfasis: automático (del wallpaper)" -ForegroundColor White
}
Write-Host "  - Configuración > Personalización > Temas" -ForegroundColor White
if ($wallpaperCount -gt 0) {
    Write-Host "  - Wallpapers: $wallpaperCount imágenes (slideshow cada 10 min)" -ForegroundColor White
}
Write-Host "  - Acceso directo en escritorio: NASA Wallpapers (añade ahí nuevas imágenes)" -ForegroundColor White
if ($cursorSetComplete) {
    Write-Host "  - Cursores: W11 Tail Cursor por Jepri Creations" -ForegroundColor White
    Write-Host "    https://www.deviantart.com/jepricreations" -ForegroundColor Cyan
}
if ($soundCount -gt 0) {
    Write-Host "  - Sonidos: $soundCount personalizados" -ForegroundColor White
}
Write-Host ""
