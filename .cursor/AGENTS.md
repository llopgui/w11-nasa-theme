# w11-nasa-theme - Contexto para agentes

## Resumen

Tema visual para Windows 11 inspirado en NASA Web Design System. Incluye wallpapers, cursores, sonidos y archivos `.theme` para personalización del escritorio.

## Stack

- **Python 3.10+**: `scripts/normalize-wallpapers.py` (Pillow)
- **PowerShell**: `scripts/install.ps1`, `scripts/build-normalize-exe.ps1`
- **PyInstaller**: genera `NASA-Normalize-Wallpapers.exe`

## Estructura clave

```
assets/wallpapers/   → Imágenes fuente (copiadas a NASA_Desktop)
assets/cursors/      → Cursores dark/light
assets/sounds/       → Sonidos del sistema
themes/              → NASA_Tema_Oscuro.theme, NASA_Tema_Claro.theme
scripts/             → install.ps1, normalize-wallpapers.py, build-normalize-exe.ps1
docs/                → research.md, plan.md (flujo RPI)
```

## Destino de instalación

`%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop\`

## Convenciones

- Comentarios y mensajes: español
- Código: inglés
- Ver reglas en `.cursor/rules/`
