#!/usr/bin/env python3
"""Sinh bộ icon ứng dụng iOS VÀ ảnh logo màn splash từ logo trống đồng.

Vì sao không dùng flutter_launcher_icons: dự án chọn bộ icon theo biến
`ASSET_PREFIX` trong xcconfig (`ASSETCATALOG_COMPILER_APPICON_NAME =
"$(ASSET_PREFIX)AppIcon"`), tức bản dev đọc `devAppIcon.appiconset`. Còn
flutter_launcher_icons lại sinh ra `AppIcon-dev.appiconset` — một thư mục
Xcode không hề đọc. Chạy nó sẽ "thành công" mà icon trên máy không đổi.

Yêu cầu: Pillow (python3 hệ thống) và @resvg/resvg-js (trong bao-cao/node_modules).

Chạy:  python3 tools/logo/generate_app_icon.py
"""
import json
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
SVG = ROOT / "assets/svg/common/logo_trong_dong.svg"
ICONSET = ROOT / "ios/Runner/Assets.xcassets/devAppIcon.appiconset"
RESVG = ROOT.parent / "bao-cao/node_modules/@resvg/resvg-js"

# Nền tối, hoa văn vàng sáng: nét trống đồng rất mảnh (4–11px trên khung 512),
# đặt trên nền kem thì ở cỡ 40px trên màn hình chính gần như biến mất.
BACKGROUND = (61, 44, 4)        # brandPrimary900 #3D2C04
MARK_COLOR = "#DCB84A"          # brandPrimary300
SOURCE_COLOR = "#B8860B"        # màu gốc trong file SVG
# iOS bo góc icon, nên hoa văn phải thụt vào kẻo bị cắt mất vành ngoài.
MARK_RATIO = 0.86
MASTER = 2048

# Ảnh logo giữa màn splash (Flutter vẽ, không phải launch screen của iOS —
# devLaunchImage.imageset chỉ là ảnh 1x1 rỗng). Là một ô bo góc trên nền trong
# suốt để đặt được lên nền trang, đúng như thiết kế "Splash mới" mô tả.
SPLASH = ROOT / "assets/images/common/main_icon_splash.png"
SPLASH_SIZE = 1024
SPLASH_CORNER_RATIO = 0.225   # đúng tỉ lệ bo góc icon của iOS

# Ảnh icon dùng trong app (hộp thoại "Về ứng dụng") — cùng ô bo góc với splash.
APP_IMAGE = ROOT / "assets/images/common/main_icon.png"

# Logo chữ, thay cho wordmark "HDDhistory?" cũ ở màn đăng ký.
BANNER = ROOT / "assets/images/common/logo_banner.png"
BANNER_HEIGHT = 313           # giữ đúng chiều cao logo cũ
BANNER_FONT_SIZE = 130
BANNER_GAP = 36               # khoảng cách mặt trống <-> chữ
BANNER_PAD = 24               # chừa mép phải
BANNER_FONT = ROOT / "assets/fonts/Poppins/Poppins-Bold.ttf"
INK_DARK = (61, 44, 4)        # brandPrimary900
INK_GOLD = (184, 134, 11)     # brandPrimary

# Dấu thương hiệu dạng SVG dùng trong onboarding, trước là dấu "?" của HDDhistory.
BRAND_MARK_SVG = ROOT / "assets/svg/app/ob_brand_mark.svg"


def render_svg(size: int) -> Image.Image:
    """Đổi màu nét rồi rasterise SVG ra PNG có nền trong suốt."""
    svg = SVG.read_text(encoding="utf-8").replace(SOURCE_COLOR, MARK_COLOR)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as tmp_svg:
        tmp_svg.write(svg)
        svg_path = tmp_svg.name
    png_path = svg_path.replace(".svg", ".png")

    script = f"""
      const {{ Resvg }} = require({json.dumps(str(RESVG))});
      const fs = require('fs');
      const r = new Resvg(fs.readFileSync({json.dumps(svg_path)}, 'utf-8'),
                          {{ fitTo: {{ mode: 'width', value: {size} }} }});
      fs.writeFileSync({json.dumps(png_path)}, r.render().asPng());
    """
    subprocess.run(["node", "-e", script], check=True)
    return Image.open(png_path).convert("RGBA")


def main() -> int:
    contents = json.loads((ICONSET / "Contents.json").read_text())

    mark = render_svg(int(MASTER * MARK_RATIO))
    master = Image.new("RGBA", (MASTER, MASTER), BACKGROUND + (255,))
    master.alpha_composite(
        mark,
        ((MASTER - mark.width) // 2, (MASTER - mark.height) // 2),
    )
    # Bỏ kênh alpha: App Store từ chối icon có alpha, và Xcode cảnh báo.
    master = master.convert("RGB")

    written = 0
    for image in contents["images"]:
        base = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        pixels = int(round(base * scale))
        out = ICONSET / image["filename"]
        master.resize((pixels, pixels), Image.LANCZOS).save(out, "PNG")
        written += 1

    print(f"Đã ghi {written} tệp icon vào {ICONSET.relative_to(ROOT)}")

    # Ô bo góc cho màn splash, dùng lại đúng bản master ở trên.
    tile = master.resize((SPLASH_SIZE, SPLASH_SIZE), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", tile.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, SPLASH_SIZE - 1, SPLASH_SIZE - 1],
        radius=int(SPLASH_SIZE * SPLASH_CORNER_RATIO),
        fill=255,
    )
    splash = Image.new("RGBA", tile.size, (0, 0, 0, 0))
    splash.paste(tile, (0, 0), mask)
    splash.save(SPLASH, "PNG")
    print(f"Đã ghi {SPLASH.relative_to(ROOT)}")

    # Cùng ô đó dùng luôn cho ảnh icon trong app.
    splash.save(APP_IMAGE, "PNG")
    print(f"Đã ghi {APP_IMAGE.relative_to(ROOT)}")

    write_banner(splash)
    print(f"Đã ghi {BANNER.relative_to(ROOT)}")

    # Dấu thương hiệu: dùng thẳng file SVG gốc, không rasterise — nó chỉ gồm
    # circle/ellipse/path/polygon nên flutter_svg vẽ được.
    BRAND_MARK_SVG.write_text(SVG.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"Đã ghi {BRAND_MARK_SVG.relative_to(ROOT)}")
    return 0


def write_banner(tile: Image.Image) -> None:
    """Logo chữ: mặt trống bên trái, chữ "HDDhistory" bên phải.

    Bề rộng khung tính theo bề rộng chữ thật chứ không đặt cứng: đặt cứng 900px
    thì "HDDhistory" bị cắt mất đuôi, mà độ rộng chữ còn đổi theo phông và cỡ.

    Nền trong suốt vì màn đăng ký tự đặt nền kem của nó. Chữ hai tông để phần
    "history" — thứ phân biệt sản phẩm này với HDDhistory — nổi lên bằng màu thương hiệu.
    """
    h = BANNER_HEIGHT
    font = ImageFont.truetype(str(BANNER_FONT), BANNER_FONT_SIZE)

    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    parts = (("HDD", INK_DARK), ("history", INK_GOLD))
    text_w = sum(probe.textlength(t, font=font) for t, _ in parts)

    w = int(h + BANNER_GAP + text_w + BANNER_PAD)
    banner = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    banner.alpha_composite(tile.resize((h, h), Image.LANCZOS), (0, 0))

    draw = ImageDraw.Draw(banner)
    box = draw.textbbox((0, 0), "HDDhistory", font=font)
    y = (h - (box[3] - box[1])) // 2 - box[1]
    x = float(h + BANNER_GAP)
    for part, ink in parts:
        draw.text((x, y), part, font=font, fill=ink + (255,))
        x += draw.textlength(part, font=font)

    banner.save(BANNER, "PNG")


if __name__ == "__main__":
    sys.exit(main())
