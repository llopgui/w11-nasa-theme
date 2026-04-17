#!/usr/bin/env python3
"""
Script para normalizar wallpapers: calidad, tamaño y formato.

Ejecutar contra la carpeta donde están instalados los wallpapers del tema NASA
(%LOCALAPPDATA%\\Microsoft\\Windows\\Themes\\NASA_Desktop). Para cuando el usuario
añade imágenes nuevas al slideshow.

Solo procesa imágenes cuyo ancho y alto son ambos >= 1920 y 1080 (por defecto).
Las menores se mueven a descartadas/. Las originales aptas se mueven a backup/
antes de generar el JPG normalizado. Las carpetas backup/ y descartadas/ suelen
quedar fuera del patrón del slideshow del .theme (solo se listan JPG en la raíz).

Uso:
    python scripts/normalize-wallpapers.py
    python scripts/normalize-wallpapers.py --path "C:\\ruta\\personalizada"
    python scripts/normalize-wallpapers.py --dry-run
"""

import argparse
import os
import shutil
import sys
import uuid
from collections import defaultdict
from contextlib import contextmanager
from pathlib import Path

try:
    from PIL import Image, ImageOps  # type: ignore[import-untyped]
    from PIL.Image import DecompressionBombError  # type: ignore[import-untyped]
except ImportError:
    print("Error: Se requiere Pillow. Ejecuta: pip install Pillow", file=sys.stderr)
    sys.exit(1)

# Límite de descompresión: mitiga imágenes corruptas o hostiles; suficiente para panorámicas 4K/8K habituales.
Image.MAX_IMAGE_PIXELS = 100_000_000

# Configuración por defecto
DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080
DEFAULT_QUALITY = 90
DEFAULT_OUTPUT_FORMAT = "JPEG"
SUPPORTED_INPUT_FORMATS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"}

# Carpetas internas de wallpapers (no se procesan ni usa el slideshow)
BACKUP_SUBDIR = "backup"
DISCARDED_SUBDIR = "descartadas"
LOCK_FILENAME = ".normalize-wallpapers.lock"


def _eprint(message: str) -> None:
    """Escribe un mensaje en stderr (errores y advertencias operativas)."""
    print(message, file=sys.stderr)


def _image_has_transparency(img: Image.Image) -> bool:
    """
    Indica si la imagen puede tener zonas transparentes (alpha o paleta con transparencia).

    Args:
        img: Imagen ya abierta con Pillow.

    Returns:
        True si conviene advertir al convertir a JPEG.
    """
    if img.mode in ("RGBA", "LA"):
        return True
    if img.mode == "P" and "transparency" in img.info:
        return True
    return False


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
        raise RuntimeError("LOCALAPPDATA no está definido. Usa --path para especificar la carpeta.")
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
    tmp_path = output_path.with_name(f"{output_path.stem}.{uuid.uuid4().hex}.tmp.jpg")
    try:
        with Image.open(input_path) as opened_img:
            # Mantener el valor en una variable nueva evita conflicto de tipado (ImageFile -> Image).
            oriented_img = ImageOps.exif_transpose(opened_img)

            n_frames = getattr(oriented_img, "n_frames", 1)
            if n_frames > 1:
                _eprint(f"  [AVISO] {input_path.name}: imagen multipágina ({n_frames}); solo se usa la primera página.")

            if _image_has_transparency(oriented_img):
                _eprint(f"  [AVISO] {input_path.name}: canal alpha / transparencia; al pasar a JPEG el fondo transparente se rellenará (típicamente negro).")

            # Convertir a RGB para estandarizar salida JPG y evitar problemas de alpha.
            if oriented_img.mode != "RGB":
                img_rgb = oriented_img.convert("RGB")
            else:
                img_rgb = oriented_img.copy()

            normalized = center_crop_resize(img_rgb, width, height)

            if output_format != "JPEG":
                raise ValueError(f"Formato de salida no soportado: {output_format}")

            normalized.save(
                tmp_path,
                format="JPEG",
                quality=quality,
                optimize=True,
            )
            tmp_path.replace(output_path)
            return True

    except (OSError, ValueError, MemoryError, DecompressionBombError) as e:
        _eprint(f"  [ERROR] {input_path.name}: {e}")
        return False
    except (RuntimeError, TypeError, AttributeError, KeyError) as e:
        # Red de seguridad acotada para errores no operativos de Pillow o metadatos EXIF.
        _eprint(f"  [ERROR] {input_path.name}: {e}")
        return False
    finally:
        if tmp_path.exists():
            try:
                tmp_path.unlink()
            except OSError:
                pass


def get_image_dimensions(image_path: Path) -> tuple[int, int] | None:
    """
    Obtiene (ancho, alto) tras aplicar la orientación EXIF, igual que en la normalización.

    Así el umbral 1920×1080 y el dry-run coinciden con la geometría que verá `normalize_image`.

    Args:
        image_path: Ruta al archivo de imagen.

    Returns:
        (ancho, alto) en píxeles, o None si no se puede leer.
    """
    try:
        with Image.open(image_path) as img:
            oriented = ImageOps.exif_transpose(img)
            return oriented.size
    except (OSError, ValueError, MemoryError, DecompressionBombError):
        return None
    except (RuntimeError, TypeError, AttributeError, KeyError) as e:
        _eprint(f"  [AVISO] {image_path.name}: no se pudieron leer dimensiones ({e})")
        return None


def is_eligible_for_slideshow(width: int, height: int, min_width: int, min_height: int) -> bool:
    """
    Comprueba si la imagen alcanza el mínimo en ambos ejes (ancho y alto).

    No basta con que un solo lado sea grande: deben cumplirse los dos umbrales.

    Args:
        width: Ancho de la imagen.
        height: Alto de la imagen.
        min_width: Ancho mínimo requerido.
        min_height: Alto mínimo requerido.

    Returns:
        True si ancho >= min_width y alto >= min_height.
    """
    return width >= min_width and height >= min_height


def is_already_normalized_jpg(
    image_path: Path,
    width: int,
    height: int,
    target_width: int,
    target_height: int,
) -> bool:
    """
    Detecta JPG ya normalizados al tamaño objetivo para mantener idempotencia.

    Solo se omiten archivos con extensión .jpg exacta: los .jpeg siguen el flujo
    normal para conservar la salida estándar del script en .jpg.
    """
    return image_path.suffix.lower() == ".jpg" and width == target_width and height == target_height


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


@contextmanager
def folder_execution_lock(base_dir: Path):
    """
    Aplica un lock exclusivo por carpeta para evitar dos ejecuciones simultáneas.

    Raises:
        RuntimeError: Si ya hay otra instancia en ejecución o no se puede crear el lock.
    """
    lock_path = base_dir / LOCK_FILENAME
    lock_fd: int | None = None
    lock_created = False

    try:
        lock_fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        lock_created = True
        os.write(lock_fd, f"pid={os.getpid()}\n".encode("utf-8"))
    except FileExistsError as e:
        raise RuntimeError(
            f"Ya hay otra instancia ejecutándose en {base_dir}. "
            f"Si no hay ningún proceso activo, borra {lock_path.name} y reintenta."
        ) from e
    except OSError as e:
        raise RuntimeError(f"No se pudo crear el lock en {base_dir}: {e}") from e

    try:
        yield
    finally:
        if lock_fd is not None:
            try:
                os.close(lock_fd)
            except OSError:
                pass
        if lock_created:
            try:
                lock_path.unlink()
            except FileNotFoundError:
                pass
            except OSError as e:
                _eprint(f"  [AVISO] No se pudo eliminar el lock {lock_path.name}: {e}")


def main() -> None:
    """Punto de entrada principal del script."""
    parser = argparse.ArgumentParser(
        description=("Normaliza wallpapers: exige ancho y alto >= valores dados (default 1920x1080). Menores van a descartadas/."),
        epilog=(
            "Códigos de salida: 0 éxito (incluye carpeta sin imágenes elegibles); "
            "1 hubo errores al procesar; 130 cancelado con Ctrl+C. "
            "No ejecutar dos instancias a la vez sobre la misma carpeta."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
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
        _eprint("Error: --width y --height deben ser mayores que 0.")
        sys.exit(1)
    if args.quality < 1 or args.quality > 100:
        _eprint("Error: --quality debe estar entre 1 y 100.")
        sys.exit(1)

    if args.path is not None:
        stripped_path = args.path.strip()
        if not stripped_path:
            _eprint("Error: --path no puede estar vacío ni ser solo espacios.")
            sys.exit(1)
        path_arg: Path | None = Path(stripped_path)
    else:
        path_arg = None

    try:
        wallpapers_dir = path_arg.resolve() if path_arg else get_installed_wallpapers_path()
    except RuntimeError as e:
        _eprint(f"Error: {e}")
        sys.exit(1)
    except OSError as e:
        if path_arg is not None:
            _eprint(f"Error: no se pudo resolver la ruta indicada ({path_arg}): {e}")
        else:
            _eprint(f"Error: no se pudo acceder a la ruta de wallpapers: {e}")
        sys.exit(1)
    backup_dir = wallpapers_dir / BACKUP_SUBDIR
    discarded_dir = wallpapers_dir / DISCARDED_SUBDIR

    try:
        wallpapers_exists = wallpapers_dir.exists()
        wallpapers_is_dir = wallpapers_dir.is_dir()
    except OSError as e:
        _eprint(f"Error: no se pudo acceder a {wallpapers_dir}: {e}")
        sys.exit(1)

    if not wallpapers_exists:
        _eprint(f"Error: No existe {wallpapers_dir}")
        if args.path is None:
            _eprint("  Ejecuta primero install.ps1 o usa --path para otra carpeta.")
        sys.exit(1)

    if not wallpapers_is_dir:
        _eprint(f"Error: La ruta no es un directorio: {wallpapers_dir}")
        sys.exit(1)

    # Solo archivos en la raíz (no subcarpetas); se ignoran enlaces simbólicos por seguridad.
    # Orden estable por nombre para resultados reproducibles si hay colisiones de nombre base.
    try:
        image_files = sorted(
            (f for f in wallpapers_dir.iterdir() if f.is_file() and not f.is_symlink() and f.suffix.lower() in SUPPORTED_INPUT_FORMATS),
            key=lambda p: p.name.casefold(),
        )
    except OSError as e:
        _eprint(f"Error: no se pudo listar el contenido de {wallpapers_dir}: {e}")
        sys.exit(1)

    if not image_files:
        _eprint(f"No se encontraron imágenes en {wallpapers_dir} (salida 0: nada que hacer).")
        sys.exit(0)

    # Aviso si varios archivos comparten el mismo nombre base (p. ej. foo.png y foo.jpg): la salida sería un solo foo.jpg.
    by_stem: defaultdict[str, list[Path]] = defaultdict(list)
    for f in image_files:
        by_stem[f.stem.casefold()].append(f)
    for stem_key, files in sorted(by_stem.items(), key=lambda x: x[0]):
        if len(files) > 1:
            names = ", ".join(sorted(p.name for p in files))
            _eprint(f"  [AVISO] Mismo nombre base ({stem_key!r}) en varios archivos: {names}. Renombrá o dejá solo uno para evitar colisiones al generar .jpg.")

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
        sys.exit(0)

    processed_count = 0
    discarded_count = 0
    error_count = 0

    try:
        with folder_execution_lock(wallpapers_dir):
            # Crear carpetas backup y descartadas dentro del lock para evitar carreras.
            try:
                backup_dir.mkdir(parents=True, exist_ok=True)
                discarded_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                _eprint(f"Error: no se pudieron crear carpetas internas en {wallpapers_dir}: {e}")
                sys.exit(1)

            for img_path in image_files:
                try:
                    dims = get_image_dimensions(img_path)
                    if dims is None:
                        _eprint(f"  [ERROR] {img_path.name}: no se pudo leer")
                        error_count += 1
                        continue

                    width, height = dims

                    if not is_eligible_for_slideshow(width, height, args.width, args.height):
                        dest = get_unique_path(discarded_dir / img_path.name)
                        shutil.move(str(img_path), str(dest))
                        print(f"  [DESCARTADA] {img_path.name} ({width}x{height}) -> {DISCARDED_SUBDIR}/")
                        discarded_count += 1
                        continue

                    if is_already_normalized_jpg(img_path, width, height, args.width, args.height):
                        print(f"  [OMITIDA] {img_path.name} ({width}x{height}) ya está normalizada")
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
                        if output_path.exists():
                            try:
                                output_path.unlink()
                            except OSError:
                                pass
                        try:
                            shutil.move(str(backup_path), str(img_path))
                            error_count += 1
                            _eprint(f"  [ERROR] {img_path.name}: fallo al procesar, restaurado")
                        except OSError as move_err:
                            error_count += 1
                            _eprint(f"  [ERROR] {img_path.name}: fallo al procesar; original en {BACKUP_SUBDIR}/{backup_path.name} ({move_err})")
                except OSError as e:
                    _eprint(f"  [ERROR] {img_path.name}: {e}")
                    error_count += 1
    except RuntimeError as e:
        _eprint(f"Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        _eprint("\nInterrupción por el usuario (Ctrl+C). Revisa backup/ por archivos ya movidos.")
        sys.exit(130)

    print("\n" + "=" * 55)
    print(f"  Procesadas: {processed_count} | Descartadas: {discarded_count} | Errores: {error_count}")
    print("=" * 55)

    if error_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
