"""Génère l'icône de l'application à partir d'un seul dessin (brand kit, sections 4 et 5).

Symbole : carnet ouvert ivoire + bulle de dialogue corail, sur fond vert profond, sans texte.
Usage, depuis la racine du projet :  python tool/generate_app_icons.py
Prérequis : Pillow (pip install pillow).
"""
from pathlib import Path

from PIL import Image, ImageDraw

GREEN = (0x17, 0x4D, 0x43, 255)
IVORY = (0xF7, 0xF4, 0xEA, 255)
CORAL = (0xF2, 0xA3, 0x8A, 255)
SOFT_GREEN = (0x7C, 0x98, 0x8E, 255)  # lignes d'écriture : vert à 55 % sur ivoire

CANVAS = 108  # unités du canevas d'icône adaptative Android ; le symbole tient dans la zone sûre
SUPERSAMPLING = 4
# Une icône adaptative n'affiche que les 72 unités centrales : même cadrage pour les icônes pleines.
FULL_ICON_ZOOM = CANVAS / 72

ROOT = Path(__file__).resolve().parent.parent
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def curve(start, control, end, steps=24):
    """Points d'une courbe de Bézier quadratique."""
    return [
        (
            (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0],
            (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1],
        )
        for t in (step / steps for step in range(steps + 1))
    ]


def draw_symbol(size, background=None, zoom=1.0):
    """Dessine le symbole, centré, sur un carré de `size` pixels."""
    pixels = size * SUPERSAMPLING
    image = Image.new("RGBA", (pixels, pixels), background or (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    scale = pixels / CANVAS * zoom
    offset = pixels / 2 - CANVAS / 2 * scale

    def at(x, y):
        return (x * scale + offset, y * scale + offset)

    notebook = (
        curve((32, 50), (43, 46), (54, 52))
        + curve((54, 52), (65, 46), (76, 50))
        + curve((76, 74), (65, 70), (54, 76))
        + curve((54, 76), (43, 70), (32, 74))
    )
    draw.polygon([at(*point) for point in notebook], fill=IVORY)

    stroke = max(1, round(1.6 * scale))
    draw.line([at(54, 52), at(54, 76)], fill=GREEN, width=stroke)
    for start, end in (
        ((37, 58), (49, 59.5)),
        ((37, 64), (49, 65.5)),
        ((59, 59.5), (71, 58)),
        ((59, 65.5), (71, 64)),
    ):
        draw.line([at(*start), at(*end)], fill=SOFT_GREEN, width=stroke)

    draw.rounded_rectangle([at(55, 30), at(78, 46)], radius=5 * scale, fill=CORAL)
    draw.polygon([at(60, 45), at(58, 53), at(67, 45)], fill=CORAL)
    for center_x in (61, 66.5, 72):
        draw.ellipse([at(center_x - 1.6, 36.4), at(center_x + 1.6, 39.6)], fill=GREEN)

    return image.resize((size, size), Image.LANCZOS)


def rounded(image, radius_ratio=0.22):
    """Arrondit les coins d'une icône pleine (anciennes versions d'Android)."""
    size = image.width * SUPERSAMPLING
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=size * radius_ratio, fill=255)
    image.putalpha(mask.resize(image.size, Image.LANCZOS))
    return image


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(f"{path.relative_to(ROOT)}  {image.width}x{image.height}")


def main():
    for density, factor in DENSITIES.items():
        folder = ANDROID_RES / f"mipmap-{density}"
        # Android 8 et plus : calque de premier plan de l'icône adaptative.
        save(draw_symbol(round(108 * factor)), folder / "ic_launcher_foreground.png")
        # Android 7 : icône pleine.
        legacy = draw_symbol(round(48 * factor), background=GREEN, zoom=FULL_ICON_ZOOM)
        save(rounded(legacy), folder / "ic_launcher.png")

    full_icon = {"background": GREEN, "zoom": FULL_ICON_ZOOM}
    # Logo affiché dans l'application.
    save(draw_symbol(256, **full_icon), ROOT / "assets" / "brand" / "logo.png")
    # Original pour les fiches des stores et l'icône iOS (non embarqué dans l'app).
    save(draw_symbol(1024, **full_icon), ROOT / "design" / "app_icon_1024.png")


if __name__ == "__main__":
    main()
