#!/usr/bin/env python3
"""
Script para normalizar wallpapers: calidad, tamaño y formato.

Ejecutar contra la carpeta donde están instalados los wallpapers del tema NASA
(%LOCALAPPDATA%\\Microsoft\\Windows\\Themes\\NASA_Desktop). Para cuando el usuario
añade imágenes nuevas al slideshow.

Solo procesa imágenes >= 1920x1080. Las menores se mueven a descartadas/.
Las originales aptas se mueven a backup/ antes de generar el JPG normalizado.
Las carpetas backup/ y descartadas/ no las usa el slideshow.

Uso:
    python scripts/normalize-wallpapers.py
    python scripts/normalize-wallpapers.py --path "C:\\ruta\\personalizada"
    python scripts/normalize-wallpapers.py --dry-run
"""

import argparse
import os
import shutil
from pathlib import Path

try:
    from PIL import Image  # type: ignore[import-untyped]
    from PIL.Image import DecompressionBombError  # type: ignore[import-untyped]
except ImportError:
    print("Error: Se requiere Pillow. Ejecuta: pip install Pillow")
    exit(1)

# Configuración por defecto
DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080
DEFAULT_QUALITY = 90
DEFAULT_OUTPUT_FORMAT = "JPEG"
SUPPORTED_INPUT_FORMATS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"}

# Carpetas internas de wallpapers (no se procesan ni usa el slideshow)
BACKUP_SUBDIR = "backup"
DISCARDED_SUBDIR = "descartadas"


def get_installed_wallpapers_path() -> Path:
    """
    Obtiene la ruta donde el tema NASA instala los wallpapers.

    Coincide con la carpeta que usa install.ps1:
    %LOCALAPPDATA%\\Microsoft\\Windows\\Themes\\NASA_Desktop

    Returns:
        Path: Ruta absoluta a la carpeta de wallpapers instalados.
    """
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if not local_app_data:
        raise RuntimeError(
            "LOCALAPPDATA no está definido. Usa --path para especificar la carpeta."
        )
    return Path(local_app_data) / "Microsoft" / "Windows" / "Themes" / "NASA_Desktop"


def center_crop_resize(image: Image.Image, target_width: int, target_height: int) -> Image.Image:
    """
    Recorta y redimensiona la imagen manteniendo la relación de aspecto.

    Usa recorte central (center crop) para que el resultado llene todo el
    espacio sin deformar la imagen. Ideal para wallpapers.

    Args:
        image: Imagen PIL a procesar.
        target_width: Ancho objetivo en píxeles.
        target_height: Alto objetivo en píxeles.

    Returns:
        Imagen recortada y redimensionada.
    """
    orig_width, orig_height = image.size
    target_ratio = target_width / target_height
    orig_ratio = orig_width / orig_height

    if orig_ratio > target_ratio:
        # Imagen más ancha: recortar los lados
        new_height = orig_height
        new_width = int(orig_height * target_ratio)
    else:
        # Imagen más alta: recortar arriba/abajo
        new_width = orig_width
        new_height = int(orig_width / target_ratio)

    left = (orig_width - new_width) // 2
    top = (orig_height - new_height) // 2
    right = left + new_width
    bottom = top + new_height

    cropped = image.crop((left, top, right, bottom))
    return cropped.resize((target_width, target_height), Image.Resampling.LANCZOS)


def normalize_image(
    input_path: Path,
    output_path: Path,
    width: int,
    height: int,
    quality: int,
    output_format: str,
) -> bool:
    """
    Normaliza una imagen individual.

    Args:
        input_path: Ruta del archivo de entrada.
        output_path: Ruta del archivo de salida.
        width: Ancho objetivo.
        height: Alto objetivo.
        quality: Calidad JPEG (1-100).
        output_format: Formato de salida (ej: "JPEG").

    Returns:
        True si se procesó correctamente, False en caso contrario.
    """
    try:
        with Image.open(input_path) as opened_img:
            # Convertir a RGB para estandarizar salida JPG y evitar problemas de alpha.
            if opened_img.mode != "RGB":
                img_rgb = opened_img.convert("RGB")
            else:
                img_rgb = opened_img.copy()

            normalized = center_crop_resize(img_rgb, width, height)

            if output_format == "JPEG":
                normalized.save(
                    output_path,
                    format=output_format,
                    quality=quality,
                    optimize=True,
                )
            else:
                normalized.save(
                    output_path,
                    format=output_format,
                    quality=quality,
                )
            return True

    except (OSError, ValueError, MemoryError, DecompressionBombError) as e:
        print(f"  [ERROR] {input_path.name}: {e}")
        return False


def get_image_dimensions(image_path: Path) -> tuple[int, int] | None:
    """
    Obtiene las dimensiones de una imagen sin cargarla completamente.

    Args:
        image_path: Ruta al archivo de imagen.

    Returns:
        (ancho, alto) en píxeles, o None si no se puede leer.
    """
    try:
        with Image.open(image_path) as img:
            return img.size
    except (OSError, ValueError, MemoryError, DecompressionBombError):
        return None


def is_eligible_for_slideshow(width: int, height: int, min_width: int, min_height: int) -> bool:
    """
    Comprueba si las dimensiones son aptas para el slideshow (>= mínimo).

    Args:
        width: Ancho de la imagen.
        height: Alto de la imagen.
        min_width: Ancho mínimo requerido.
        min_height: Alto mínimo requerido.

    Returns:
        True si la imagen cumple o supera los mínimos.
    """
    return width >= min_width and height >= min_height


def get_unique_path(base_path: Path) -> Path:
    """
    Devuelve una ruta de archivo libre, añadiendo sufijo incremental si existe.

    Args:
        base_path: Ruta candidata original.

    Returns:
        Ruta disponible sin sobrescribir un archivo existente.
    """
    if not base_path.exists():
        return base_path

    n = 1
    while True:
        candidate = base_path.with_name(f"{base_path.stem} ({n}){base_path.suffix}")
        if not candidate.exists():
            return candidate
        n += 1


def main() -> None:
    """Punto de entrada principal del script."""
    parser = argparse.ArgumentParser(
        description="Normaliza wallpapers: solo >= 1920x1080. Menores van a descartadas/."
    )
    parser.add_argument(
        "--width",
        type=int,
        default=DEFAULT_WIDTH,
        help=f"Ancho mínimo y objetivo en píxeles (default: {DEFAULT_WIDTH})",
    )
    parser.add_argument(
        "--height",
        type=int,
        default=DEFAULT_HEIGHT,
        help=f"Alto mínimo y objetivo en píxeles (default: {DEFAULT_HEIGHT})",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=DEFAULT_QUALITY,
        help=f"Calidad JPEG 1-100 (default: {DEFAULT_QUALITY})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Mostrar qué se haría sin modificar archivos",
    )
    parser.add_argument(
        "--path",
        "-p",
        type=str,
        default=None,
        help="Carpeta de wallpapers (default: carpeta instalada del tema NASA)",
    )

    args = parser.parse_args()

    if args.width <= 0 or args.height <= 0:
        print("Error: --width y --height deben ser mayores que 0.")
        exit(1)
    if args.quality < 1 or args.quality > 100:
        print("Error: --quality debe estar entre 1 y 100.")
        exit(1)

    try:
        wallpapers_dir = (
            Path(args.path).resolve()
            if args.path
            else get_installed_wallpapers_path()
        )
    except RuntimeError as e:
        print(f"Error: {e}")
        exit(1)
    backup_dir = wallpapers_dir / BACKUP_SUBDIR
    discarded_dir = wallpapers_dir / DISCARDED_SUBDIR

    if not wallpapers_dir.exists():
        print(f"Error: No existe {wallpapers_dir}")
        if not args.path:
            print("  Ejecuta primero install.ps1 o usa --path para otra carpeta.")
        exit(1)

    # Solo archivos en la raíz de wallpapers (no en subcarpetas)
    image_files = [
        f for f in wallpapers_dir.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_INPUT_FORMATS
    ]

    if not image_files:
        print(f"No se encontraron imágenes en {wallpapers_dir}")
        exit(0)

    print("=" * 55)
    print("  Normalizador de Wallpapers - NASA Theme")
    print("=" * 55)
    print(f"  Carpeta: {wallpapers_dir}")
    print(f"  Mínimo requerido: {args.width}x{args.height}")
    print(f"  Salida: JPG {args.width}x{args.height} calidad {args.quality}%")
    print(f"  Imágenes encontradas: {len(image_files)}")
    print("=" * 55)

    if args.dry_run:
        print("\n[DRY RUN] No se modificará ningún archivo.\n")
        for f in image_files:
            dims = get_image_dimensions(f)
            if dims is None:
                status = "? (error al leer)"
            elif is_eligible_for_slideshow(dims[0], dims[1], args.width, args.height):
                status = f"OK {dims[0]}x{dims[1]} -> procesar"
            else:
                status = f"DESCARTAR {dims[0]}x{dims[1]} -> {DISCARDED_SUBDIR}/"
            print(f"  - {f.name}: {status}")
        exit(0)

    # Crear carpetas backup y descartadas
    backup_dir.mkdir(parents=True, exist_ok=True)
    discarded_dir.mkdir(parents=True, exist_ok=True)

    processed_count = 0
    discarded_count = 0
    error_count = 0

    for img_path in image_files:
        try:
            dims = get_image_dimensions(img_path)
            if dims is None:
                print(f"  [ERROR] {img_path.name}: no se pudo leer")
                error_count += 1
                continue

            width, height = dims

            if not is_eligible_for_slideshow(width, height, args.width, args.height):
                dest = get_unique_path(discarded_dir / img_path.name)
                shutil.move(str(img_path), str(dest))
                print(f"  [DESCARTADA] {img_path.name} ({width}x{height}) -> {DISCARDED_SUBDIR}/")
                discarded_count += 1
                continue

            backup_path = get_unique_path(backup_dir / img_path.name)
            shutil.move(str(img_path), str(backup_path))
            output_path = get_unique_path(wallpapers_dir / (img_path.stem + ".jpg"))

            if normalize_image(
                backup_path,
                output_path,
                args.width,
                args.height,
                args.quality,
                DEFAULT_OUTPUT_FORMAT,
            ):
                processed_count += 1
                print(f"  [OK] {img_path.name} ({width}x{height}) -> {output_path.name}")
            else:
                shutil.move(str(backup_path), str(img_path))
                error_count += 1
                print(f"  [ERROR] {img_path.name}: fallo al procesar, restaurado")
        except (OSError, FileNotFoundError) as e:
            print(f"  [ERROR] {img_path.name}: {e}")
            error_count += 1
    print("\n" + "=" * 55)
    print(f"  Procesadas: {processed_count} | Descartadas: {discarded_count} | Errores: {error_count}")
    print("=" * 55)


if __name__ == "__main__":
    main()
