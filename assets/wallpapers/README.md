# Wallpapers

Coloca aquí tus wallpapers (jpg, png, bmp, tif) para la instalación inicial.

El tema cambiará de fondo automáticamente cada **10 minutos** en orden aleatorio.

Tras instalar el tema, se crea un acceso directo **"NASA Wallpapers"** en el escritorio que apunta a la carpeta donde Windows usa los wallpapers del slideshow. **Añade ahí las imágenes nuevas** que quieras incluir.

---

## Normalizar wallpapers (imágenes nuevas)

Cuando añadas imágenes nuevas a la carpeta NASA Wallpapers, ejecuta el normalizador para que todas queden homogéneas (tamaño, formato, calidad). El slideshow funciona mejor con imágenes uniformes.

### Requisitos de las imágenes

| Resolución | ¿Qué pasa? |
|------------|------------|
| **Menor de 1920×1080** | Se mueve a `descartadas/`. No se usa en el slideshow. |
| **Igual o mayor de 1920×1080** | Se procesa a JPG 1920×1080 calidad 90. El original se mueve a `backup/`. |

Las carpetas `backup/` y `descartadas/` están dentro de la carpeta de wallpapers y **no las usa el slideshow**; solo se procesan los JPG en la raíz.

### Cómo ejecutarlo

**Opción 1 – Ejecutable (recomendado, no requiere Python):**

```
assets/wallpapers/NASA-Normalize-Wallpapers.exe
```

Doble clic o desde la terminal. Por defecto actúa sobre la carpeta instalada del tema.

**Opción 2 – Script Python:**

```powershell
pip install -r requirements.txt
python scripts/normalize-wallpapers.py
```

### Opciones

| Opción | Descripción |
|--------|-------------|
| `--dry-run` | Muestra qué haría sin modificar archivos |
| `--path "C:\ruta"` | Usa otra carpeta en lugar de la instalada |
| `--width`, `--height` | Cambiar resolución (default: 1920×1080) |
| `--quality` | Calidad JPEG 1–100 (default: 90) |

### Generar el ejecutable

Si modificas el script y quieres crear de nuevo el .exe:

```powershell
.\scripts\build-normalize-exe.ps1
```

El ejecutable se genera en `dist/NASA-Normalize-Wallpapers.exe`. Cópialo a `assets/wallpapers/` si quieres distribuirlo con el proyecto.
