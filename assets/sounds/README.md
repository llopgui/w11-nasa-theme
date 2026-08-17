# Sonidos

Colocá aquí archivos **`.wav`** para personalizar los sonidos del sistema. Son **opcionales**: si la carpeta está vacía, el instalador sigue sin error y **no toca** el esquema de sonidos actual de Windows.

## Instalación

Al ejecutar **`install.ps1`** (desde la raíz del repo o `scripts/install.ps1`), los `.wav` de esta carpeta se copian a la carpeta del tema en Windows:

`%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop\Sounds`

Si cambiás, añadís o eliminás sonidos en el repo, ejecutá `-Action Repair`. La
carpeta instalada se reconstruye desde la fuente actual, por lo que un WAV
eliminado no reaparece desde instalaciones anteriores.

## Formato

- **Formato:** WAV (PCM, 16-bit recomendado, 44.1 kHz o 48 kHz)

## Nombres de archivo

| Archivo | Evento |
| ------- | ------ |
| `systemstart.wav` | Inicio de Windows |
| `systemexit.wav` | Cierre de Windows |
| `systemexclamation.wav` | Advertencia general |
| `systemhand.wav` | Error crítico |
| `systemquestion.wav` | Pregunta / confirmación |
| `systemasterisk.wav` | Mensaje informativo |
| `menucommand.wav` | Al seleccionar ítem de menú |
| `menupopup.wav` | Al abrir menú desplegable |
| `open.wav` | Al abrir ventana |
| `close.wav` | Al cerrar ventana |
| `minimize.wav` | Al minimizar ventana |
| `maximize.wav` | Al maximizar ventana |
| `restoredown.wav` | Al restaurar ventana |
| `restoreup.wav` | Al restaurar ventana |
| `emptyrecyclebin.wav` | Al vaciar la papelera |

El instalador solo asocia en el `.theme` los eventos cuyos `.wav` realmente existen en esta carpeta. Si faltan algunos nombres, esos eventos **no se sobrescriben** y Windows conserva su configuración actual o por defecto.
