#!/usr/bin/env python3
"""
Caelestia / Material Design 3 Palette & Variant Engine.
Extracts 8 Material You variants (Tonal Spot, Vibrant, Expressive, Fidelity,
Fruit Salad, Rainbow, Neutral, Monochrome) with Default and Hard flavours.
Outputs shell environment variables and generates variants.json for live QML switching.
Fully self-contained: works with Caelestia, materialyoucolor, or standalone pure-Python fallback.
"""

import sys
import os
import json
import colorsys
from pathlib import Path
from PIL import Image

VARIANTS = [
    "tonalspot",
    "vibrant",
    "expressive",
    "fidelity",
    "fruitsalad",
    "rainbow",
    "neutral",
    "monochrome",
]

FLAVOURS = ["default", "hard"]

def hex_fmt(r, g, b):
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"

def try_caelestia_engine(image_path):
    try:
        from caelestia.utils.material import get_colours_for_image
        from caelestia.utils.scheme import Scheme

        result = {}
        for v in VARIANTS:
            result[v] = {}
            for f in FLAVOURS:
                s = Scheme({'name': 'dynamic', 'flavour': f, 'mode': 'dark', 'variant': v, 'colours': {}})
                cols = get_colours_for_image(str(image_path), scheme=s)
                pri = '#' + cols.get('primary', '89b4fa')
                surf = '#' + cols.get('surface', '111317')
                outl = '#' + cols.get('outline', '72757e')
                result[v][f] = {
                    'primary': pri,
                    'surface': surf,
                    'outline': outl,
                    'glow': '#60' + cols.get('primary', '89b4fa')
                }
        return result
    except Exception:
        return None

def standalone_engine(image_path):
    """
    Pure-Python HSL Material 3 mathematical generator.
    Works on ANY machine with zero external dependencies (standard library + PIL).
    """
    im = Image.open(image_path).convert('RGB')
    im.thumbnail((160, 160), Image.Resampling.LANCZOS)
    quant = im.quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert('RGB')
    colors = quant.getcolors(maxcolors=256)

    best_seed = (0.6, 0.45, 0.85) # fallback hue, sat, val
    max_score = -1.0

    if colors:
        for count, (r, g, b) in colors:
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if s < 0.16 or v < 0.18 or v > 0.96:
                continue
            score = count * (s ** 1.35) * (1.0 - abs(v - 0.65) * 0.75)
            if score > max_score:
                max_score = score
                best_seed = (h, s, v)

    seed_h, seed_s, seed_v = best_seed

    # Generate each variant based on Material 3 tonal specifications
    specs = {
        "vibrant":    (seed_h,          0.85, 0.64),
        "tonalspot":  (seed_h,          0.38, 0.66),
        "expressive": ((seed_h + 0.22) % 1.0, 0.75, 0.65),
        "fidelity":   (seed_h,          seed_s, 0.63),
        "fruitsalad": ((seed_h + 0.52) % 1.0, 0.78, 0.66),
        "rainbow":    ((seed_h + 0.35) % 1.0, 0.82, 0.66),
        "neutral":    (seed_h,          0.08, 0.72),
        "monochrome": (0.0,             0.00, 0.96),
    }

    result = {}
    for v_name, (vh, vs, vl) in specs.items():
        result[v_name] = {}
        for f_name in FLAVOURS:
            # Primary accent
            pr, pg, pb = [int(c * 255) for c in colorsys.hls_to_rgb(vh, vl, vs)]
            pri_hex = hex_fmt(pr, pg, pb)

            # Surface background tint
            if f_name == "hard":
                # OLED deep dark
                surf_l = 0.02
                surf_s = min(0.20, vs * 0.25)
            else:
                # Soft subtle dark
                surf_l = 0.06
                surf_s = min(0.30, vs * 0.40)

            sr, sg, sb = [int(c * 255) for c in colorsys.hls_to_rgb(vh, surf_l, surf_s)]
            surf_hex = hex_fmt(sr, sg, sb)

            # Outline
            out_l = 0.45 if v_name != "monochrome" else 0.55
            out_s = min(0.35, vs * 0.5)
            or_, og, ob = [int(c * 255) for c in colorsys.hls_to_rgb(vh, out_l, out_s)]
            out_hex = hex_fmt(or_, og, ob)

            result[v_name][f_name] = {
                "primary": pri_hex,
                "surface": surf_hex,
                "outline": out_hex,
                "glow": f"#60{pri_hex.lstrip('#')}"
            }

    return result

def main():
    if len(sys.argv) < 2:
        print("Usage: extract-palette.py <image_path>", file=sys.stderr)
        sys.exit(1)

    image_path = Path(sys.argv[1]).resolve()
    if not image_path.exists():
        print(f"Error: image not found: {image_path}", file=sys.stderr)
        sys.exit(1)

    # 1. Try Caelestia engine first, fall back to standalone
    variants_data = try_caelestia_engine(image_path)
    if not variants_data:
        variants_data = standalone_engine(image_path)

    # 2. Write variants.json and variants.js alongside image / in repo root
    output_dir = image_path.parent
    variants_file = output_dir / "variants.json"
    with open(variants_file, "w") as f:
        json.dump(variants_data, f, indent=2)

    variants_js_file = output_dir / "variants.js"
    with open(variants_js_file, "w") as f:
        f.write(".pragma library\n\nvar variants = " + json.dumps(variants_data, indent=2) + ";\n")

    # 3. Default active scheme: vibrant / default
    active = variants_data.get("vibrant", {}).get("default", {})
    if not active:
        active = {
            "primary": "#89b4fa",
            "surface": "#111317",
            "outline": "#72757e",
            "glow": "#6089b4fa"
        }

    accent = active["primary"]
    card_tint = active["surface"]
    border = active["outline"]
    glow = active["glow"]

    print(f"ACCENT_COLOR={accent}")
    print(f"CARD_TINT={card_tint}")
    print(f"BORDER_COLOR={border}")
    print(f"HIGHLIGHT_GLOW={glow}")

if __name__ == "__main__":
    main()
