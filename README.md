# NASA Space Theme for Windows 11

Tema para Windows 11 con temática espacial inspirado en el **NASA Web Design System**. Incluye variantes oscuro y claro, paleta de colores oficial NASA, cursores personalizados y soporte para sonidos y wallpapers.

![Windows 11](https://img.shields.io/badge/Windows-11-0078D4?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell)
![License](https://img.shields.io/badge/License-WTFPL-blue)

## Características

- **Tema oscuro y claro** con paleta NASA
- **Slideshow de wallpapers** cada 10 minutos
- **Cursores W11 Tail Cursor** (Jepri Creations)
- **Sonidos personalizables**
- **Modo oscuro/claro** del sistema activado automáticamente
- **Color de énfasis** automático desde el wallpaper

## Instalación rápida

Desde la **raíz del repositorio**, el archivo `install.ps1` es un **lanzador** que ejecuta `scripts/install.ps1` con los mismos argumentos. Podés usar indistintamente:

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

# Modo de acento fijo NASA (consistencia de marca)
.\install.ps1 -Theme dark -AccentMode fixed

# Modo de acento automático (dinámico por wallpaper)
.\install.ps1 -Theme dark -AccentMode auto

# Opcional: reinicio completo de Explorer (cierra todas las ventanas del Explorador de archivos)
.\install.ps1 -Theme dark -RestartExplorer
```

Por defecto **no** se reinicia Explorer; los cambios suelen verse al cambiar de ventana. Usá `-RestartExplorer` solo si necesitás forzar el reinicio.
Por defecto, el instalador usa `-AccentMode auto` (acento dinámico). Si priorizás coherencia visual NASA, usá `-AccentMode fixed`.

## Estructura del proyecto

```text
w11-nasa-theme/
├── install.ps1                    # Lanzador → delega en scripts/install.ps1
├── pyproject.toml                 # Metadatos Python (Pillow; grupo opcional build)
├── scripts/
│   ├── install.ps1                # Instalador completo del tema
│   ├── normalize-wallpapers.py    # Homogeneiza wallpapers (requiere Python + Pillow)
│   └── build-normalize-exe.ps1    # Genera .exe del normalizador (venv + PyInstaller)
├── themes/
│   ├── NASA_Tema_Oscuro.theme
│   └── NASA_Tema_Claro.theme
├── assets/
│   ├── wallpapers/
│   │   ├── README.md
│   │   └── (opcional) NASA-Normalize-Wallpapers.exe  # copiar desde dist/ tras build
│   ├── cursors/
│   │   ├── README.md
│   │   └── w11-tail-cursor-concept-free/
│   └── sounds/
│       └── README.md
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
|------------------|------|
| Instalar o actualizar el tema | `.\install.ps1 -Theme dark` o `-Theme light` |
| Elegir acento automático o fijo NASA | `.\install.ps1 -Theme dark -AccentMode auto|fixed` |
| Igualar tamaño/formato de wallpapers nuevos | Ver [README de wallpapers](assets/wallpapers/README.md) (`normalize-wallpapers.py` o el `.exe` opcional) |
| Validar contraste de colores del tema | Revisión manual con los criterios indicados en este README |
| Generar `NASA-Normalize-Wallpapers.exe` | `.\scripts\build-normalize-exe.ps1` (salida en `dist/`) |

## Criterio de contraste y paleta

- **Texto principal vs fondo**: mínimo `4.5:1`.
- **Texto secundario vs fondo de superficie**: mínimo `4.5:1`.
- **Referencia de paleta**: NASA Web Design System (ver créditos).

Actualmente, la validación de contraste se realiza de forma manual con esos criterios.

## Personalización

- **`assets/wallpapers/`**: imágenes jpg, jpeg, png, bmp, tif, tiff, webp en la **raíz** de esa carpeta para la copia inicial del instalador. Detalles y normalización: [assets/wallpapers/README.md](assets/wallpapers/README.md).
- **`assets/sounds/`**: archivos `.wav`; el instalador los copia a la carpeta del tema. Ver [README de sonidos](assets/sounds/README.md).
- **`assets/cursors/`**: pack W11 Tail Cursor; el instalador copia cursores según oscuro/claro. **Importante:** si clonás el repo y en `dark/` y `light/` solo ves metadatos (p. ej. `Install.inf`) sin `.cur`/`.ani`, descargá el pack completo desde [DeviantArt (Jepri Creations)](https://www.deviantart.com/jepricreations) y colocá los binarios en la estructura indicada en [README de cursores](assets/cursors/README.md).

## Créditos

- **Cursores:** [W11 Tail Cursor Concept Free](https://www.deviantart.com/jepricreations) por Jepri Creations
- **Paleta:** [NASA Web Design System](https://nasa.github.io/nasawds-site/components/colors/)

Ver [CREDITS.md](CREDITS.md) para detalles completos.

## Licencia

[WTFPL](LICENSE) - Haz lo que quieras con este proyecto.

**Nota:** Los cursores tienen su propia licencia (ver `assets/cursors/w11-tail-cursor-concept-free/Agreement.txt`). Se requiere atribución al autor.
