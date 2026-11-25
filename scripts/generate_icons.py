"""Generates all Android, iOS, Flutter in-app, iOS OTA, and Alert Bot icons from root icon.png."""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC_ICON = ROOT / "icon.png"

ANDROID_RES = ROOT / "mobile_app" / "android" / "app" / "src" / "main" / "res"
IOS_APPICON = ROOT / "mobile_app" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_LAUNCH = ROOT / "mobile_app" / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
FLUTTER_ASSETS = ROOT / "mobile_app" / "assets" / "images"
IOS_OTA_DIR = ROOT / "ios_ota"
ALERT_BOT_STATIC = ROOT / "alert_bot" / "static"


def _tight_rgba_crop(im: Image.Image, alpha_threshold: int = 16) -> Image.Image:
    rgba = im.convert("RGBA")
    alpha = rgba.getchannel("A")
    mask = alpha.point(lambda a: 255 if a >= alpha_threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return rgba
    return rgba.crop(bbox)


def _center_on_square(im: Image.Image, canvas_size: int, fill_ratio: float = 0.94) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    target = max(1, int(round(canvas_size * fill_ratio)))
    copy = im.copy()
    copy.thumbnail((target, target), Image.Resampling.LANCZOS)
    x = (canvas_size - copy.width) // 2
    y = (canvas_size - copy.height) // 2
    canvas.alpha_composite(copy, (x, y))
    return canvas


def _make_vertical_blue_gradient(size: int, top_rgb: tuple[int, int, int], bottom_rgb: tuple[int, int, int]) -> Image.Image:
    bg = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / max(1, size - 1)
        r = int(round(top_rgb[0] + (bottom_rgb[0] - top_rgb[0]) * t))
        g = int(round(top_rgb[1] + (bottom_rgb[1] - top_rgb[1]) * t))
        b = int(round(top_rgb[2] + (bottom_rgb[2] - top_rgb[2]) * t))
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    return bg


def _sample_edge_blue(cropped: Image.Image) -> tuple[tuple[int, int, int], tuple[int, int, int]]:
    w, h = cropped.size
    # Sample top-center and bottom-center opaque blue rim colors
    top_rgb = (0, 140, 255)
    bot_rgb = (0, 56, 235)
    for y in range(int(h * 0.03), int(h * 0.15)):
        px = cropped.getpixel((w // 2, y))
        if px[3] > 230:
            top_rgb = (px[0], px[1], px[2])
            break
    for y in range(int(h * 0.96), int(h * 0.85), -1):
        px = cropped.getpixel((w // 2, y))
        if px[3] > 230:
            bot_rgb = (px[0], px[1], px[2])
            break
    return top_rgb, bot_rgb


def _make_ios_opaque_master(cropped: Image.Image, size: int = 1024) -> Image.Image:
    """Builds an opaque (no-alpha) 1024x1024 iOS App Store master icon with matching blue gradient backdrop."""
    top_rgb, bot_rgb = _sample_edge_blue(cropped)
    bg = _make_vertical_blue_gradient(size, top_rgb, bot_rgb).convert("RGBA")
    # Fill 100% edge-to-edge so iOS squircle mask has zero white/blank corner gaps
    fg = _center_on_square(cropped, size, fill_ratio=1.0)
    bg.alpha_composite(fg)
    return bg.convert("RGB")


def _save_png(im: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = im.resize((size, size), Image.Resampling.LANCZOS) if im.size != (size, size) else im
    resized.save(path, format="PNG", optimize=True)


def main() -> None:
    if not SRC_ICON.exists():
        raise FileNotFoundError(f"Source icon not found: {SRC_ICON}")

    raw = Image.open(SRC_ICON)
    cropped = _tight_rgba_crop(raw)

    # Master images
    transparent_master = _center_on_square(cropped, 1024, fill_ratio=0.96)
    adaptive_fg_master = _center_on_square(cropped, 1024, fill_ratio=0.72)
    ios_master = _make_ios_opaque_master(cropped, 1024)

    # 1. Android Legacy + Adaptive Foreground + Launch Splash icons
    android_launcher_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    android_adaptive_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    android_launch_sizes = {
        "mipmap-mdpi": 128,
        "mipmap-hdpi": 192,
        "mipmap-xhdpi": 256,
        "mipmap-xxhdpi": 384,
        "mipmap-xxxhdpi": 512,
    }

    for folder, px in android_launcher_sizes.items():
        _save_png(transparent_master, ANDROID_RES / folder / "ic_launcher.png", px)
        _save_png(transparent_master, ANDROID_RES / folder / "ic_launcher_round.png", px)
    for folder, px in android_adaptive_sizes.items():
        _save_png(adaptive_fg_master, ANDROID_RES / folder / "ic_launcher_foreground.png", px)
    for folder, px in android_launch_sizes.items():
        _save_png(transparent_master, ANDROID_RES / folder / "launch_image.png", px)

    # 2. iOS AppIcon.appiconset (ALL 15 required opaque RGB PNGs)
    ios_icon_specs = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, px in ios_icon_specs.items():
        _save_png(ios_master, IOS_APPICON / filename, px)

    # 3. iOS LaunchImage.imageset (centered splash logo)
    _save_png(transparent_master, IOS_LAUNCH / "LaunchImage.png", 160)
    _save_png(transparent_master, IOS_LAUNCH / "LaunchImage@2x.png", 320)
    _save_png(transparent_master, IOS_LAUNCH / "LaunchImage@3x.png", 480)

    # 4. Flutter in-app brand asset
    _save_png(transparent_master, FLUTTER_ASSETS / "app_icon.png", 512)

    # 5. iOS OTA manifest icons
    _save_png(ios_master, IOS_OTA_DIR / "icon-57.png", 57)
    _save_png(ios_master, IOS_OTA_DIR / "icon-512.png", 512)

    # 6. Alert Bot web dashboard favicon & logo
    _save_png(transparent_master, ALERT_BOT_STATIC / "favicon.png", 64)
    _save_png(transparent_master, ALERT_BOT_STATIC / "app-icon-192.png", 192)
    ALERT_BOT_STATIC.mkdir(parents=True, exist_ok=True)
    transparent_master.resize((64, 64), Image.Resampling.LANCZOS).save(
        ALERT_BOT_STATIC / "favicon.ico", format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64)]
    )

    print("Generated all icons successfully!")


if __name__ == "__main__":
    main()
