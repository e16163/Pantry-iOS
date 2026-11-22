#!/usr/bin/env python3
"""Generate the dish photo library on this Mac with Z-Image Turbo (free, runs locally through mflux).

Usage (run with mflux's own Python, installed by `uv tool install mflux`):
  ~/.local/share/uv/tools/mflux/bin/python tools/generate-dish-photos.py [--only dish-a,dish-b] [--redo]

Reads tools/dishes.json, writes each missing photo as a 960x640 JPEG imageset in
iOS App/Assets.xcassets/Photos, then writes iOS App/Resources/dish_photos.json (photo name, match words and description
for every dish that has a photo), which the app uses to pick a photo for any recipe title.
The same style line and a seed from the photo name keep every photo consistent and reproducible.
"""
import json, pathlib, subprocess, sys, tempfile, time, zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "iOS App/Assets.xcassets/Photos"
MANIFEST = ROOT / "iOS App/Resources/dish_photos.json"
WIDTH, HEIGHT, QUALITY = 960, 640, 80


def write_imageset(png, name):
    folder = PHOTOS / f"{name}.imageset"
    folder.mkdir(exist_ok=True)
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(QUALITY), str(png),
                    "--out", str(folder / f"{name}.jpg")], check=True, capture_output=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.jpg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def write_manifest(dishes):
    have = [{"photo": n, "words": w, "look": look} for n, w, look in dishes if (PHOTOS / f"{n}.imageset").exists()]
    MANIFEST.write_text(json.dumps(have, indent=1) + "\n")
    print(f"{len(have)} of {len(dishes)} dishes have a photo")


def main(argv):
    spec = json.loads((ROOT / "tools/dishes.json").read_text())
    dishes, style = spec["dishes"], spec["style"]
    only = set(argv[argv.index("--only") + 1].split(",")) if "--only" in argv else None
    todo = [d for d in dishes if (only is None or d[0] in only)
            and ("--redo" in argv or not (PHOTOS / f"{d[0]}.imageset").exists())]
    if todo:
        from mflux.models.z_image.cli.z_image_turbo_generate import ZImageTurboCommand, build_parser
        # mflux's parser only reads sys.argv.
        sys.argv = ["mflux", "--prompt", "x", "--quantize", "8", "--width", str(WIDTH), "--height", str(HEIGHT)]
        args = build_parser().parse_args()
        model = ZImageTurboCommand.load(args)
        with tempfile.TemporaryDirectory() as tmp:
            for i, (name, _, look) in enumerate(todo, 1):
                start = time.time()
                image = ZImageTurboCommand.generate(model, args, seed=zlib.crc32(name.encode()),
                                                    prompt=f"{look} {style}")
                png = pathlib.Path(tmp) / f"{name}.png"
                image.save(path=str(png))
                write_imageset(png, name)
                print(f"[{i}/{len(todo)}] {name} {time.time() - start:.0f}s", flush=True)
    write_manifest(dishes)


if __name__ == "__main__":
    main(sys.argv[1:])
