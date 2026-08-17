# NASA Space Theme for Windows 11

Tema para Windows 11 con temática espacial inspirado en el **NASA Web Design System**. Incluye variantes oscuro y claro, paleta de colores oficial NASA, cursores personalizados y soporte para sonidos y wallpapers.

![Windows 11](https://img.shields.io/badge/Windows-11-0078D4?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell)
![License](https://img.shields.io/badge/License-WTFPL-blue)

## Características

- **Tema oscuro y claro** con paleta NASA
- **Slideshow de wallpapers** cada 10 minutos
- **Cursores W11 Tail Cursor** (Jepri Creations)
- **Sonidos personalizables opcionales**
- **Modo oscuro/claro** del sistema activado automáticamente
- **Color de énfasis** automático desde el wallpaper

## Instalación rápida

Desde la **raíz del repositorio**, `install.ps1` delega en el instalador
transaccional de `scripts/`. Podés usar indistintamente:

- `.\install.ps1` (recomendado si estás en la raíz)
- `.\scripts\install.ps1` (misma lógica)

```powershell
# Clonar o descargar el repositorio
git clone https://github.com/llopgui/w11-nasa-theme.git
cd w11-nasa-theme

# Instalar tema oscuro
.\install.ps1 -Theme dark

# O tema claro
.\install.ps1 -Theme light

# Reparar/reaplicar una instalación existente
.\install.ps1 -Action Repair -Theme dark

# Ver qué operación se ejecutaría sin modificar Windows
.\install.ps1 -Theme dark -WhatIf

# Desinstalar y restaurar la personalización anterior
.\install.ps1 -Action Uninstall

# Opcional: reinicio completo de Explorer (cierra todas las ventanas del Explorador de archivos)
.\install.ps1 -Theme dark -RestartExplorer

# Ver ayuda
.\install.ps1 --help
```

Por defecto **no** se reinicia Explorer: el instalador transmite los cambios a
Windows y verifica tres veces que modo, acento y cursores permanezcan aplicados.
Usá `-RestartExplorer` sólo como último recurso.

Ambas variantes usan siempre el acento automático calculado por Windows desde el
wallpaper. Ese color puede mostrarse como **Naranja** en Configuración; no indica
que se haya activado el modo claro.

## Seguridad, reparación y desinstalación

- La primera instalación guarda tema, modo, acento, cursores y acceso directo
  anteriores en `%LOCALAPPDATA%\NASAThemeManager\state.json`.
- Los assets se construyen primero en staging y se intercambian sólo cuando están
  completos. Un fallo restaura los archivos y la personalización de la transacción.
- `Repair` vuelve a sincronizar las fuentes actuales y reaplica el tema.
- `Uninstall` restaura la instantánea original. Los wallpapers añadidos por el
  usuario se copian antes a `Imágenes\NASA Wallpapers Backup`.

## Estructura del proyecto

```text
w11-nasa-theme/
├── install.ps1                    # Lanzador → delega en scripts/install.ps1
├── pyproject.toml                 # Metadatos Python (Pillow; grupo opcional build)
├── scripts/
│   ├── install.ps1                # Instalador completo del tema
│   ├── NasaThemeInstaller.psm1    # Operaciones transaccionales y verificaciones
│   ├── normalize-wallpapers.py    # Homogeneiza wallpapers (requiere Python + Pillow)
│   └── build-normalize-exe.ps1    # Genera y publica .exe + SHA-256
├── themes/
│   ├── NASA_Tema_Oscuro.theme
│   └── NASA_Tema_Claro.theme
├── assets/
│   ├── wallpapers/
│   │   ├── README.md
│   │   ├── NASA-Normalize-Wallpapers.exe
│   │   └── NASA-Normalize-Wallpapers.exe.sha256
│   ├── cursors/
│   │   ├── README.md
│   │   └── w11-tail-cursor-concept-free/
│   └── sounds/
│       └── README.md
├── tests/                          # Pester y pytest
├── CREDITS.md
├── LICENSE
└── README.md
```

## Requisitos

- **Windows 11**
- **PowerShell 5.1+** (incluido en Windows)

**Opcional** (solo si usás el normalizador o generás el `.exe`):

- **Python 3.10+** y dependencias del proyecto (`pip install -e .` o el script de build, que crea `.venv`). El archivo `pyproject.toml` está en la **raíz del repositorio** en el clon público; si tu editor no lo muestra, puede estar oculto por reglas locales (`.cursorignore` / equivalentes).

## Scripts y flujo habitual

| Qué querés hacer | Cómo |
| ---------------- | ----- |
| Instalar o actualizar el tema | `.\install.ps1 -Theme dark` o `-Theme light` |
| Reparar la instalación | `.\install.ps1 -Action Repair -Theme dark` |
| Desinstalar y restaurar | `.\install.ps1 -Action Uninstall` |
| Simular una operación | Añadir `-WhatIf` |
| Recalcular el acento automático | Reparar el tema después de cambiar wallpapers |
| Igualar tamaño/formato de wallpapers nuevos | Ver [README de wallpapers](assets/wallpapers/README.md) (`normalize-wallpapers.py` o el `.exe` opcional) |
| Validar contraste de colores del tema | Revisión manual con los criterios indicados en este README |
| Generar `NASA-Normalize-Wallpapers.exe` | `.\scripts\build-normalize-exe.ps1` (publica también checksum) |
| Actualizar dependencias del build | `.\scripts\build-normalize-exe.ps1 -RefreshLock` |

## Criterio de contraste y paleta

- **Texto principal vs fondo**: mínimo `4.5:1`.
- **Texto secundario vs fondo de superficie**: mínimo `4.5:1`.
- **Referencia de paleta**: NASA Web Design System (ver créditos).

Actualmente, la validación de contraste se realiza de forma manual con esos criterios.

## Personalización

- **`assets/wallpapers/`**: imágenes jpg, jpeg, png, bmp, tif, tiff, webp que el instalador sincroniza con `NASA_Desktop\Slideshow`. El manifiesto permite preservar imágenes añadidas por el usuario en reparaciones posteriores.
- **`assets/sounds/`**: archivos `.wav` opcionales. La sincronización refleja exactamente la fuente actual: si quitás un WAV y reparás, deja de formar parte del tema.
- **`assets/cursors/`**: pack W11 Tail Cursor; el instalador copia cursores según oscuro/claro. **Importante:** si clonás el repo y en `dark/` y `light/` solo ves metadatos (p. ej. `Install.inf`) sin `.cur`/`.ani`, descargá el pack completo desde [DeviantArt (Jepri Creations)](https://www.deviantart.com/jepricreations) y colocá los binarios en la estructura indicada en [README de cursores](assets/cursors/README.md).

## Créditos

- **Cursores:** [W11 Tail Cursor Concept Free](https://www.deviantart.com/jepricreations) por Jepri Creations
- **Paleta:** [NASA Web Design System](https://nasa.github.io/nasawds-site/components/colors/)

Ver [CREDITS.md](CREDITS.md) para detalles completos.

## Licencia

[WTFPL](LICENSE) - Haz lo que quieras con este proyecto.

**Nota:** Los cursores tienen su propia licencia (ver `assets/cursors/w11-tail-cursor-concept-free/Agreement.txt`). Se requiere atribución al autor.
