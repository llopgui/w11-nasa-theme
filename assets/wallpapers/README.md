# Wallpapers

Colocá aquí tus wallpapers (**jpg, jpeg, png, bmp, tif, tiff, webp**) en la **raíz** de esta carpeta para la **instalación inicial** (`install.ps1` solo copia imágenes de la raíz, no subcarpetas).

El tema cambiará el fondo automáticamente cada **10 minutos** en orden aleatorio.

Después de instalar, en el escritorio aparece el acceso directo **«NASA Wallpapers»**, que apunta a la carpeta que Windows usa para el slideshow (típicamente `%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop`). **Las imágenes nuevas** conviene añadirlas ahí (o en esta carpeta del repo y volver a ejecutar el instalador).

---

## Normalizar wallpapers (imágenes nuevas)

Cuando añadas imágenes nuevas a la carpeta del slideshow, ejecutá el normalizador para unificar tamaño, formato y calidad. El slideshow rinde mejor con JPG homogéneos.

### Requisitos de las imágenes

- **Se descarta** la imagen si el **ancho es menor que 1920** o el **alto es menor que 1080** (valores por defecto; cambian con `--width` y `--height` en la línea de comandos). Hace falta cumplir **los dos** mínimos a la vez.
- **Si ancho ≥ 1920 y alto ≥ 1080:** se genera un JPG 1920×1080 (calidad 90 por defecto) y el original va a la subcarpeta `backup/`.

Las dimensiones se evalúan **después de aplicar la orientación EXIF** (fotos de móvil), igual que en el procesamiento final.

En la **raíz** de la carpeta de trabajo pueden convivir varios formatos de entrada; la salida homogénea son **JPG** en esa misma raíz. Las carpetas `backup/` y `descartadas/` no suelen usarse en el patrón del slideshow del `.theme`.

### Cómo ejecutarlo

**1. Desde el repositorio (Python 3.10+, con Pillow instalado)**

`pip install -e .` requiere el `pyproject.toml` en la raíz del clon (incluido en el repositorio).

```powershell
cd ruta\al\repo\w11-nasa-theme
pip install -e .
python scripts/normalize-wallpapers.py --dry-run   # simular sin tocar archivos
python scripts/normalize-wallpapers.py             # carpeta instalada del tema NASA
python scripts/normalize-wallpapers.py --path "D:\MisWallpapers"
```

**2. Ejecutable opcional** (sin Python en la máquina de destino)

Generalo en tu entorno de desarrollo:

```powershell
.\scripts\build-normalize-exe.ps1
```

Copiá `dist\NASA-Normalize-Wallpapers.exe` donde quieras (por ejemplo junto a tus wallpapers o al escritorio). Al ejecutarlo, por defecto usa la carpeta instalada del tema.

**Códigos de salida (Python):** `0` éxito (incluye «no había imágenes que procesar»); `1` si hubo errores al procesar; `130` si cancelaste con Ctrl+C. No conviene lanzar dos instancias a la vez sobre la misma carpeta.
