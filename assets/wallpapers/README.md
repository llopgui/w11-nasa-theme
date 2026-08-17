# Wallpapers

Colocá aquí tus wallpapers (**jpg, jpeg, png, bmp, tif, tiff, webp**) en la **raíz** de esta carpeta para la **instalación inicial** (`install.ps1` solo copia imágenes de la raíz, no subcarpetas).

El tema cambiará el fondo automáticamente cada **10 minutos** en orden aleatorio.

Después de instalar, el acceso directo **«NASA Wallpapers»** apunta a
`%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop\Slideshow`, la única raíz
activa. Podés añadir allí imágenes propias: el manifiesto del instalador las
preserva en reparaciones posteriores.

## Procedencia y atribución

El proyecto usa una colección curada de fondos inspirados en material público relacionado con NASA y misiones asociadas. La referencia general de fuentes y política del proyecto está en [NASA-COMPLIANCE.md](../../NASA-COMPLIANCE.md).

Importante:

- Este repositorio **no mantiene todavía un manifiesto exhaustivo por imagen** dentro de `assets/wallpapers/`.
- Si añadís, reemplazás o redistribuís wallpapers, conviene conservar la URL de origen y cualquier crédito o restricción específica de esa obra.
- Para compartir un pack con trazabilidad completa, lo ideal es acompañarlo con un inventario por archivo.

---

## Normalizar wallpapers (imágenes nuevas)

Cuando añadas imágenes nuevas a la carpeta del slideshow, ejecutá el normalizador para unificar tamaño, formato y calidad. El slideshow rinde mejor con JPG homogéneos.

### Requisitos de las imágenes

- **Se descarta** la imagen si el **ancho es menor que 1920** o el **alto es menor que 1080** (valores por defecto; cambian con `--width` y `--height` en la línea de comandos). Hace falta cumplir **los dos** mínimos a la vez.
- **Si ancho ≥ 1920 y alto ≥ 1080:** se genera un JPG 1920×1080 (calidad 90 por defecto) y el original va a `NASA_Desktop\Archive\backup`.
- Si el archivo ya es un `.jpg` de `1920×1080` y usás la calidad por defecto (`90`), el script lo omite para evitar recomprimirlo sin necesidad.
- Si pedís otra calidad con `--quality`, el script sí vuelve a procesar esos `.jpg` para respetar esa intención.

Las dimensiones se evalúan **después de aplicar la orientación EXIF** (fotos de móvil), igual que en el procesamiento final.

En la **raíz** de trabajo pueden convivir varios formatos de entrada; la salida
homogénea son JPG en esa misma raíz. Backups y descartes siempre quedan fuera
del slideshow. Para una ruta personalizada se usa una carpeta hermana
`<nombre>-archive`.

### Cómo ejecutarlo

#### 1. Desde el repositorio (Python 3.10+, con Pillow instalado)

`pip install -e .` requiere el `pyproject.toml` en la raíz del clon (incluido en el repositorio).

```powershell
cd ruta\al\repo\w11-nasa-theme
pip install -e .
python scripts/normalize-wallpapers.py --dry-run   # simular sin tocar archivos
python scripts/normalize-wallpapers.py             # carpeta instalada del tema NASA
python scripts/normalize-wallpapers.py --path "D:\MisWallpapers"
python scripts/normalize-wallpapers.py --force-unlock  # sólo para un lock obsoleto
```

#### 2. Ejecutable opcional (sin Python en la máquina de destino)

El repositorio publica el ejecutable junto a
`NASA-Normalize-Wallpapers.exe.sha256`. Para regenerarlos:

```powershell
.\scripts\build-normalize-exe.ps1
# Actualizar primero las versiones bloqueadas:
.\scripts\build-normalize-exe.ps1 -RefreshLock
```

El build usa `scripts/requirements-build.lock`, fija las variables de
reproducibilidad y comprueba el hash. Dos builds consecutivos con las mismas
fuentes y entorno deben producir el mismo SHA-256.

En equipos con Windows Application Control, un ejecutable local sin firma puede
ser bloqueado por política. En ese caso usá directamente el script Python; el
checksum verifica integridad, pero no sustituye una firma de código.

**Códigos de salida (Python):** `0` éxito (incluye «no había imágenes que procesar»); `1` si hubo errores al procesar; `130` si cancelaste con Ctrl+C. No conviene lanzar dos instancias a la vez sobre la misma carpeta.
