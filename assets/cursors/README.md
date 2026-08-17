# Cursores

Este tema incluye el pack **W11 Tail Cursor Concept Free** de [Jepri Creations](https://www.deviantart.com/jepricreations).

## Estructura esperada

```text
w11-tail-cursor-concept-free/
  cursor/
    dark/    ← usado con NASA_Tema_Oscuro.theme
    light/   ← usado con NASA_Tema_Claro.theme
```

En cada carpeta **`dark`** y **`light`** deben estar todos los `.cur` y `.ani`
referenciados por los `Install.inf`. Si falta uno, el instalador aborta y hace
rollback para evitar un esquema parcialmente aplicado.

**No modifiques la estructura** del pack salvo que sepas actualizar también las rutas en los archivos `.theme`.

## Instalación

`install.ps1` copia ambas variantes a:

`%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop\Cursors\dark|light`

También registra **NASA Space Dark** y **NASA Space Light**, activa la variante
elegida y refresca cursores mediante la API de Windows. Los slots especiales
usan `Person=person.cur` y `Pin=pin.cur`, de acuerdo con los `Install.inf`.

La atribución al autor es obligatoria por licencia; el script la muestra al instalar cursores correctamente.

Ver [CREDITS.md](../../CREDITS.md) para la licencia completa del pack.
