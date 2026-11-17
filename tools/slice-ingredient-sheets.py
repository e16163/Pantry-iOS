#!/usr/bin/env python3
"""Cut ChatGPT ingredient grid sheets into one asset per ingredient.

Usage: python3 tools/slice-ingredient-sheets.py <folder with ingredient-sheet-NN.png files>

Reads the cell order from tools/ingredient-sheets.json (4 columns, rows as needed), crops each cell
with a small inset to drop the gutters, and writes 400px JPEG imagesets to
iOS App/Assets.xcassets/Ingredients/ingredient-<slug>.imageset. Uses macOS `sips`, no other deps.
"""
import json, math, pathlib, re, subprocess, sys, tempfile, unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "iOS App/Assets.xcassets/Ingredients"
COLUMNS, INSET, SIZE = 4, 0.04, 400


def slug(name):
    """Must match FoodPhoto.slug in RecipeArt.swift."""
    folded = unicodedata.normalize("NFKD", name.lower()).encode("ascii", "ignore").decode()
    return "-".join(re.findall(r"[a-z0-9]+", folded))


def size(path):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                         capture_output=True, text=True, check=True).stdout
    return [int(v) for v in re.findall(r"pixel(?:Width|Height): (\d+)", out)]


def main(folder):
    manifest = json.loads((ROOT / "tools/ingredient-sheets.json").read_text())
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
    done = 0
    for sheet, names in manifest.items():
        files = [p for p in pathlib.Path(folder).glob(sheet + ".*") if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp")]
        if not files:
            print(f"skip {sheet}: no file")
            continue
        width, height = size(files[0])
        rows = math.ceil(len(names) / COLUMNS)
        cell_w, cell_h = width / COLUMNS, height / rows
        for i, name in enumerate(names):
            row, col = divmod(i, COLUMNS)
            x, y = int(col * cell_w + cell_w * INSET), int(row * cell_h + cell_h * INSET)
            w, h = int(cell_w * (1 - 2 * INSET)), int(cell_h * (1 - 2 * INSET))
            key = "ingredient-" + slug(name)
            out_dir = ASSETS / f"{key}.imageset"
            out_dir.mkdir(exist_ok=True)
            with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
                # sips ignores --cropOffset unless it comes before -c.
                subprocess.run(["sips", "--cropOffset", str(y), str(x), "-c", str(h), str(w),
                                str(files[0]), "--out", tmp.name], capture_output=True, check=True)
                subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82", "-Z", str(SIZE),
                                tmp.name, "--out", str(out_dir / f"{key}.jpg")], capture_output=True, check=True)
            (out_dir / "Contents.json").write_text(json.dumps(
                {"images": [{"filename": f"{key}.jpg", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}},
                indent=2))
            done += 1
        print(f"{sheet}: {len(names)} ingredients")
    print(f"done: {done} ingredient photos in {ASSETS.relative_to(ROOT)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
