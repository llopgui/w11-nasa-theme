# NASA Space Theme for Windows 11

Tema profesional para Windows 11 con temática espacial inspirado en el **NASA Web Design System**. Incluye variantes oscuro y claro, paleta de colores oficial NASA, cursores personalizados y soporte para sonidos y wallpapers.

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

```powershell
# Clonar o descargar el repositorio
git clone https://github.com/llopgui/w11-nasa-theme.git
cd w11-nasa-theme

# Instalar tema oscuro
.\install.ps1 -Theme dark

# O tema claro
.\install.ps1 -Theme light

# Sin reiniciar Explorer
.\install.ps1 -Theme dark -NoRestart
```

## Estructura del proyecto

```
w11-nasa-theme/
├── install.ps1              # Launcher (ejecutar desde raíz)
├── scripts/
│   └── install.ps1          # Script de instalación
├── themes/
│   ├── NASA_Tema_Oscuro.theme
│   └── NASA_Tema_Claro.theme
├── assets/
│   ├── wallpapers/          # Coloca aquí tus imágenes
│   │   └── README.md
│   ├── cursors/             # Pack W11 Tail Cursor incluido
│   │   ├── README.md
│   │   └── w11-tail-cursor-concept-free/
│   └── sounds/              # Sonidos personalizados (.wav)
│       └── README.md
├── CREDITS.md               # Atribuciones y licencias
├── LICENSE
└── README.md
```

## Requisitos

- Windows 11
- PowerShell 5.1 o superior (incluido en Windows)

## Personalización

| Carpeta | Contenido |
|---------|-----------|
| `assets/wallpapers/` | Imágenes jpg, png, bmp (slideshow cada 10 min) |
| `assets/sounds/` | Archivos .wav (ver README para nombres) |
| `assets/cursors/` | Pack W11 Tail Cursor ya incluido |

## Créditos

- **Cursores:** [W11 Tail Cursor Concept Free](https://www.deviantart.com/jepricreations) por Jepri Creations
- **Paleta:** [NASA Web Design System](https://nasa.github.io/nasawds-site/components/colors/)

Ver [CREDITS.md](CREDITS.md) para detalles completos.

## Licencia

[WTFPL](LICENSE) - Haz lo que quieras con este proyecto.

**Nota:** Los cursores tienen su propia licencia (ver `assets/cursors/w11-tail-cursor-concept-free/Agreement.txt`). Se requiere atribución al autor.
