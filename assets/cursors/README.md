# Cursores

Este tema incluye el pack **W11 Tail Cursor Concept Free** de [Jepri Creations](https://www.deviantart.com/jepricreations).

## Estructura esperada

```text
w11-tail-cursor-concept-free/
  cursor/
    dark/    ← usado con NASA_Tema_Oscuro.theme
    light/   ← usado con NASA_Tema_Claro.theme
```

En cada carpeta **`dark`** y **`light`** deben estar los archivos **`.cur`** y **`.ani`** que usa el tema. Si solo hay metadatos (por ejemplo `Install.inf`) sin cursores binarios, el instalador mostrará una advertencia y Windows puede mostrar cursores genéricos aunque el `.theme` siga apuntando a rutas concretas.

**No modifiques la estructura** del pack salvo que sepas actualizar también las rutas en los archivos `.theme`.

## Instalación

**`install.ps1`** copia los cursores del tema elegido (`-Theme dark` o `light`) a:

`%LOCALAPPDATA%\Microsoft\Windows\Themes\NASA_Desktop\Cursors`

La atribución al autor es obligatoria por licencia; el script la muestra al instalar cursores correctamente.

Ver [CREDITS.md](../../CREDITS.md) para la licencia completa del pack.
