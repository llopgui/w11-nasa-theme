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

#### Ejecutable
El repositorio publica el ejecutable junto a
`NASA-Normalize-Wallpapers.exe.sha256`.

En equipos con Windows Application Control, un ejecutable local sin firma puede
ser bloqueado por política.
