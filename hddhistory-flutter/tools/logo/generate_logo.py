#!/usr/bin/env python3
"""Sinh logo trống đồng Đông Sơn dạng SVG cho app.

Chạy:  python3 tools/logo/generate_logo.py

Sinh ra 2 tệp trong assets/svg/common/:
  - logo_trong_dong.svg         : chỉ mặt trống (vuông, dùng cho icon/chỗ hẹp)
  - logo_trong_dong_banner.svg  : mặt trống + chữ (thay cho logo_banner.png)

Vì sao sinh bằng script thay vì gõ tay toạ độ: mặt trống đồng là hình học lặp
theo góc (ngôi sao 14 cánh, vành chim Lạc xoay đều, vành răng cưa). Tính bằng
lượng giác cho ra hình cân đối tuyệt đối và sửa thông số rất nhanh; gõ tay
hàng trăm toạ độ vừa dễ lệch vừa không sửa được.

Bố cục theo mặt trống Ngọc Lũ, đã giản lược cho cỡ logo:
  - Tâm: ngôi sao 14 cánh (số cánh của trống Ngọc Lũ)
  - Vành răng cưa bao quanh tâm
  - Vành chim Lạc bay ngược chiều kim đồng hồ (giản lược còn 6 con thay vì 18)
  - Hai vòng viền ngoài
"""
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = ROOT / "assets" / "svg" / "common"

# Bảng màu hổ phách, khớp AppCustomColor trong lib/config/themes/colors.dart
AMBER = "#B8860B"       # brandPrimary
AMBER_DARK = "#7A5807"  # brandPrimary700
AMBER_DEEP = "#3D2C04"  # brandPrimary900

SIZE = 512
CX = CY = SIZE / 2


def polar(cx, cy, r, deg):
    """Toạ độ Descartes từ toạ độ cực (góc tính bằng độ, 0° hướng sang phải)."""
    rad = math.radians(deg)
    return cx + r * math.cos(rad), cy + r * math.sin(rad)


def fmt(x):
    return f"{x:.2f}".rstrip("0").rstrip(".")


def star(cx, cy, points, r_outer, r_inner, start_deg=-90):
    """Ngôi sao `points` cánh — cánh nhọn xen kẽ đỉnh ngoài/đỉnh trong."""
    step = 360 / (points * 2)
    coords = []
    for i in range(points * 2):
        r = r_outer if i % 2 == 0 else r_inner
        x, y = polar(cx, cy, r, start_deg + i * step)
        coords.append(f"{fmt(x)},{fmt(y)}")
    return f'<polygon points="{" ".join(coords)}" fill="{AMBER}"/>'


def ray_triangles(cx, cy, points, r_from, r_to, half_width_deg, start_deg=-90):
    """Hoạ tiết lông công hình tam giác xen giữa các cánh sao."""
    out = []
    step = 360 / points
    for i in range(points):
        mid = start_deg + step / 2 + i * step
        apex = polar(cx, cy, r_to, mid)
        left = polar(cx, cy, r_from, mid - half_width_deg)
        right = polar(cx, cy, r_from, mid + half_width_deg)
        pts = " ".join(f"{fmt(x)},{fmt(y)}" for x, y in (apex, left, right))
        out.append(f'<polygon points="{pts}" fill="{AMBER}" opacity="0.55"/>')
    return out


def sawtooth_ring(cx, cy, teeth, r_base, r_tip):
    """Vành răng cưa — mô-típ lặp đặc trưng trên mặt trống."""
    out = []
    step = 360 / teeth
    for i in range(teeth):
        a = -90 + i * step
        tip = polar(cx, cy, r_tip, a)
        left = polar(cx, cy, r_base, a - step * 0.38)
        right = polar(cx, cy, r_base, a + step * 0.38)
        pts = " ".join(f"{fmt(x)},{fmt(y)}" for x, y in (tip, left, right))
        out.append(f'<polygon points="{pts}" fill="{AMBER}"/>')
    return out


def dot_ring(cx, cy, count, r, dot_r, color=AMBER, opacity=1.0):
    out = []
    step = 360 / count
    for i in range(count):
        x, y = polar(cx, cy, r, -90 + i * step)
        out.append(f'<circle cx="{fmt(x)}" cy="{fmt(y)}" r="{fmt(dot_r)}" '
                   f'fill="{color}" opacity="{opacity}"/>')
    return out


# Chim Lạc cách điệu, hệ toạ độ riêng: mỏ hướng +x, dài ~200, cao ~80.
# Bám đúng dáng chim trên trống Đông Sơn: MỎ RẤT DÀI (gần bằng thân), thân
# tròn đầy, cánh vuốt ngược ôm thân (không phải gai dựng đứng), đuôi xoè dài,
# chân mảnh kéo về sau. Bản trước vẽ cánh nhọn dựng lên nên nhìn ra con muỗi.
# Tỉ lệ tổng thể ~160×70 (2.3:1). Bản trước dài 280×80 nên nhìn ra cá bay:
# ở cỡ logo, thân phải TRÒN ĐẦY và mỏ phải NGẮN HƠN thân thì mới ra dáng chim.
# Thân và đầu dùng ellipse/đường tròn thay vì bezier tự do cho chắc dáng.
BIRD_BODY_ELLIPSE = (0, 0, 46, 23, -8)      # cx, cy, rx, ry, xoay (độ)
BIRD_HEAD_CIRCLE = (54, -20, 16)            # cx, cy, r
BIRD_EYE = (59, -22, 3.6)
BIRD_BEAK = "M 68 -25 L 120 -17 L 68 -11 Z"
BIRD_CREST = "M 50 -33 C 44 -44, 34 -49, 24 -50 C 34 -43, 40 -38, 43 -31 Z"
BIRD_NECK = "M 30 -14 C 34 -22, 42 -26, 52 -26 C 52 -18, 46 -10, 34 -6 Z"
# Đuôi xoè đặc, có khía — khối duy nhất ở phía sau
BIRD_TAIL = ["M -40 -10 L -98 -26 L -86 -8 L -98 10 L -38 10 Z"]
BIRD_WING = "M -20 -9 C -4 -23, 20 -21, 30 -11 C 14 -3, -6 1, -20 -9 Z"
BIRD_LEGS = [
    "M -6 20 C -12 29, -20 33, -30 35",
    "M 8 18 C 2 28, -6 33, -16 36",
]


def bird(cx, cy, r, angle_deg, scale):
    """Một con chim Lạc đặt trên vành tròn, thân tiếp tuyến với vành."""
    x, y = polar(cx, cy, r, angle_deg)
    # +90° để chim bay theo chiều tiếp tuyến (ngược chiều kim đồng hồ)
    rot = angle_deg + 90
    ex, ey, er = BIRD_EYE
    bx, by, brx, bry, brot = BIRD_BODY_ELLIPSE
    hx, hy, hr = BIRD_HEAD_CIRCLE
    parts = [f'<path d="{d}" fill="{AMBER}"/>' for d in BIRD_TAIL]
    parts += [
        f'<path d="{d}" stroke="{AMBER}" stroke-width="4" '
        f'stroke-linecap="round" fill="none"/>' for d in BIRD_LEGS
    ]
    parts += [
        f'<path d="{BIRD_CREST}" fill="{AMBER}"/>',
        f'<ellipse cx="{bx}" cy="{by}" rx="{brx}" ry="{bry}" fill="{AMBER}" '
        f'transform="rotate({brot} {bx} {by})"/>',
        f'<path d="{BIRD_NECK}" fill="{AMBER}"/>',
        f'<circle cx="{hx}" cy="{hy}" r="{hr}" fill="{AMBER}"/>',
        f'<path d="{BIRD_BEAK}" fill="{AMBER}"/>',
        f'<path d="{BIRD_WING}" fill="{AMBER_DARK}"/>',
        f'<circle cx="{ex}" cy="{ey}" r="{er}" fill="#FFFFFF"/>',
    ]
    inner = "".join(parts)
    return (f'<g transform="translate({fmt(x)},{fmt(y)}) rotate({fmt(rot)}) '
            f'scale({fmt(scale)})">{inner}</g>')


def drum_mark():
    """Mặt trống đồng hoàn chỉnh, trong viewBox 512×512."""
    el = []
    # Vòng viền ngoài
    el.append(f'<circle cx="{CX}" cy="{CY}" r="246" fill="none" '
              f'stroke="{AMBER}" stroke-width="11"/>')
    el.append(f'<circle cx="{CX}" cy="{CY}" r="226" fill="none" '
              f'stroke="{AMBER}" stroke-width="4"/>')
    # Vành chấm tròn giữa hai viền
    el += dot_ring(CX, CY, 36, 236, 2.6, opacity=0.75)
    # Vành chim Lạc — 6 con, đủ lớn để nhận ra dáng chim ở cỡ nhỏ
    for i in range(6):
        el.append(bird(CX, CY, 180, -90 + i * 60, 0.95))
    # Viền trong bao quanh tâm
    el.append(f'<circle cx="{CX}" cy="{CY}" r="140" fill="none" '
              f'stroke="{AMBER}" stroke-width="4"/>')
    el += sawtooth_ring(CX, CY, 28, 140, 124)
    el.append(f'<circle cx="{CX}" cy="{CY}" r="120" fill="none" '
              f'stroke="{AMBER}" stroke-width="3"/>')
    # Hoạ tiết lông công xen giữa các cánh sao
    el += ray_triangles(CX, CY, 14, 40, 100, 6.5)
    # Ngôi sao 14 cánh ở tâm
    el.append(star(CX, CY, 14, 100, 34))
    el.append(f'<circle cx="{CX}" cy="{CY}" r="15" fill="{AMBER_DEEP}"/>')
    return el


def write_mark():
    body = "\n  ".join(drum_mark())
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}" '
           f'width="{SIZE}" height="{SIZE}" role="img" '
           f'aria-label="Logo trống đồng Đông Sơn">\n  {body}\n</svg>\n')
    path = OUT_DIR / "logo_trong_dong.svg"
    path.write_text(svg, encoding="utf-8")
    return path


def write_banner(wordmark="HDDhistory", tagline="Học sử theo dòng thời gian"):
    """Bản ngang: mặt trống bên trái + chữ bên phải, thay cho logo_banner.png.

    Muốn đổi tên hiển thị: sửa tham số `wordmark` (và `tagline`) rồi chạy lại
    script — không cần sửa tay trong tệp SVG.
    """
    w, h = 1120, 360
    scale = 300 / SIZE
    mark = "\n    ".join(drum_mark())
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-label="{wordmark} — logo trống đồng Đông Sơn">
  <g transform="translate(30,30) scale({fmt(scale)})">
    {mark}
  </g>
  <text x="380" y="196" font-family="Georgia, 'Times New Roman', serif" font-size="108" font-weight="700" fill="{AMBER_DEEP}" letter-spacing="-1">{wordmark}</text>
  <text x="384" y="248" font-family="Helvetica, Arial, sans-serif" font-size="34" fill="{AMBER_DARK}" letter-spacing="1.5">{tagline}</text>
</svg>
'''
    path = OUT_DIR / "logo_trong_dong_banner.svg"
    path.write_text(svg, encoding="utf-8")
    return path


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for p in (write_mark(), write_banner()):
        print(f"Đã ghi {p.relative_to(ROOT)} ({p.stat().st_size} byte)")
