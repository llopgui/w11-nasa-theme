# Wallpapers

Coloca aquí tus wallpapers (jpg, png, bmp, tif) para la instalación inicial.

El tema cambiará de fondo automáticamente cada **10 minutos** en orden aleatorio.

Tras instalar el tema, se crea un acceso directo **"NASA Wallpapers"** en el escritorio que apunta a la carpeta donde Windows usa los wallpapers del slideshow. **Añade ahí las imágenes nuevas** que quieras incluir.

---

## Normalizar wallpapers (imágenes nuevas)

Cuando añadas imágenes nuevas a la carpeta NASA Wallpapers, ejecuta el normalizador para que todas queden homogéneas (tamaño, formato, calidad). El slideshow funciona mejor con imágenes uniformes.

### Requisitos de las imágenes

- **Menor de 1920×1080:** se mueve a `descartadas/`. No se usa en el slideshow.
- **Igual o mayor de 1920×1080:** se procesa a JPG 1920×1080 calidad 90. El original se mueve a `backup/`.

Las carpetas `backup/` y `descartadas/` están dentro de la carpeta de wallpapers y **no las usa el slideshow**; solo se procesan los JPG en la raíz.

### Cómo ejecutarlo

```text
assets/wallpapers/NASA-Normalize-Wallpapers.exe
```

Doble clic o desde la terminal. Por defecto actúa sobre la carpeta instalada del tema.
