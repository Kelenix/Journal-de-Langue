"""Génère les visuels des fiches Google Play et App Store aux couleurs du brand kit.

- Icône Google Play 512 × 512, depuis design/app_icon_1024.png.
- Image de présentation Google Play 1024 × 500, en français et en anglais.
- Captures commentées, depuis les captures brutes de l'émulateur rangées dans
  docs/store/captures/<langue>/<numéro>-<écran>.png : téléphone Android 1080 × 1920 et
  iPhone 6,9" 1320 × 2868.

Usage, depuis la racine du projet :  python tool/generate_store_visuals.py
Prérequis : Pillow (pip install pillow).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

GREEN = (0x17, 0x4D, 0x43)
IVORY = (0xF7, 0xF4, 0xEA)
CORAL = (0xF2, 0xA3, 0x8A)

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "design" / "app_icon_1024.png"
TITLE_FONT = ROOT / "assets" / "fonts" / "DMSans-Variable.ttf"
BODY_FONT = ROOT / "assets" / "fonts" / "Inter-Variable.ttf"
CAPTURES = ROOT / "docs" / "store" / "captures"
OUTPUT = ROOT / "docs" / "store" / "assets"

TAGLINES = {
    "fr": "Écris chaque jour.\nComprends tes fautes.",
    "en": "Write every day.\nUnderstand your mistakes.",
}

# Légende de chaque capture, par écran (nom du fichier après le numéro).
CAPTIONS = {
    "fr": {
        "journal": "Écris quelques phrases\npar jour",
        "correction": "Comprends\nchaque faute",
        "review": "Révise tes mots\net entraîne-toi",
        "progress": "Suis tes progrès",
        "exam": "Prépare\ntes examens",
    },
    "en": {
        "journal": "Write a few sentences\na day",
        "correction": "Understand\nevery mistake",
        "review": "Review your words\nand practise",
        "progress": "Track your progress",
        "exam": "Prepare\nfor your exams",
    },
}

# Formats demandés par les stores : (nom, largeur, hauteur).
SCREEN_FORMATS = (("android", 1080, 1920), ("iphone69", 1320, 2868))

# Barres du système à retirer des captures brutes de l'émulateur (1080 × 2400).
STATUS_BAR = 120
NAVIGATION_BAR = 126


def font(path, size, weight):
    """Police variable au poids demandé."""
    loaded = ImageFont.truetype(str(path), size)
    axes = loaded.get_variation_axes()
    loaded.set_variation_by_axes(
        [weight if axis["name"] == b"Weight" else axis["default"] for axis in axes]
    )
    return loaded


def fitted_font(path, text, weight, max_size, max_width):
    """Plus grande taille, jusqu'à max_size, dont chaque ligne tient dans max_width."""
    size = max_size
    while size > 10:
        candidate = font(path, size, weight)
        if all(candidate.getlength(line) <= max_width for line in text.split("\n")):
            return candidate
        size -= 2
    return font(path, size, weight)


def rounded(image, radius):
    """Copie de l'image aux coins arrondis (transparents)."""
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *image.size), radius, fill=255)
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def play_icon():
    Image.open(ICON).convert("RGBA").resize((512, 512), Image.LANCZOS).save(
        OUTPUT / "play_icon_512.png"
    )


def feature_graphic(language):
    canvas = Image.new("RGB", (1024, 500), GREEN)
    icon = rounded(Image.open(ICON).resize((300, 300), Image.LANCZOS), 66)
    canvas.paste(icon, (80, 100), icon)

    draw = ImageDraw.Draw(canvas)
    left, width = 440, 1024 - 440 - 56
    title = fitted_font(TITLE_FONT, "Journal de Langue", 700, 64, width)
    draw.text((left, 120), "Journal de Langue", font=title, fill=IVORY)
    draw.rounded_rectangle((left, 210, left + 110, 218), 4, fill=CORAL)
    tagline = TAGLINES[language]
    body = fitted_font(BODY_FONT, tagline, 500, 34, width)
    draw.multiline_text((left, 250), tagline, font=body, fill=IVORY, spacing=12)
    canvas.save(OUTPUT / language / "feature_graphic_1024x500.png")


def screenshot(capture, caption, size):
    width, height = size
    canvas = Image.new("RGB", size, GREEN)
    draw = ImageDraw.Draw(canvas)
    margin = round(width * 0.08)

    title = fitted_font(TITLE_FONT, caption, 700, round(width * 0.075), width - 2 * margin)
    top = round(height * 0.05)
    draw.multiline_text(
        (width // 2, top), caption, font=title, fill=IVORY, anchor="ma", align="center",
        spacing=round(title.size * 0.25),
    )
    caption_bottom = draw.multiline_textbbox(
        (width // 2, top), caption, font=title, anchor="ma", align="center",
        spacing=round(title.size * 0.25),
    )[3]

    raw = Image.open(capture).convert("RGB")
    raw = raw.crop((0, STATUS_BAR, raw.width, raw.height - NAVIGATION_BAR))
    available = height - caption_bottom - round(height * 0.04) - margin
    scale = min((width - 2 * margin) / raw.width, available / raw.height)
    phone = raw.resize((round(raw.width * scale), round(raw.height * scale)), Image.LANCZOS)
    phone = rounded(phone, round(phone.width * 0.06))
    x = (width - phone.width) // 2
    y = caption_bottom + round(height * 0.04)

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, y + 12, x + phone.width, y + phone.height + 12), round(phone.width * 0.06),
        fill=(0, 0, 0, 90),
    )
    canvas.paste(shadow.filter(ImageFilter.GaussianBlur(18)), (0, 0), shadow.filter(
        ImageFilter.GaussianBlur(18)))
    canvas.paste(phone, (x, y), phone)
    return canvas


def screenshots(language):
    for capture in sorted((CAPTURES / language).glob("*.png")):
        screen = capture.stem.split("-", 1)[1]
        for name, width, height in SCREEN_FORMATS:
            image = screenshot(capture, CAPTIONS[language][screen], (width, height))
            image.save(OUTPUT / language / f"{name}_{capture.stem}.png")


def main():
    play_icon()
    for language in ("fr", "en"):
        (OUTPUT / language).mkdir(parents=True, exist_ok=True)
        feature_graphic(language)
        screenshots(language)


if __name__ == "__main__":
    main()
