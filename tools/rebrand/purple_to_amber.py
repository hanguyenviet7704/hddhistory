#!/usr/bin/env python3
"""Đổi toàn bộ màu tím còn cứng trong mã nguồn và SVG sang tông vàng hổ phách.

Dự án đổi màu chủ đạo từ tím sang vàng. Các token trong `colors.dart` đã đổi
bằng tay, nhưng còn hàng trăm mã màu viết cứng rải khắp widget — chúng không
đi qua token nên không đổi theo, để lại những mảng tím lạc lõng (đầu Trang chủ,
paywall, warm-up, coach...).

Cách đổi: XOAY TÔNG MÀU (hue) sang 43° — đúng tông của #B8860B — và giữ nguyên
độ bão hoà. Giữ hue-rotation thay vì thay bằng một màu cố định vì thang màu cũ
có cả trăm sắc độ từ nền rất nhạt tới chữ rất đậm; thay tất cả bằng một màu sẽ
phá sạch tương phản chữ/nền.

Độ sáng chỉ hạ ở khoảng giữa (0.45–0.80): tím thương hiệu #554FF0 sáng hơn vàng
thương hiệu #B8860B khá nhiều, nếu giữ nguyên độ sáng thì nút bấm sẽ ra màu cam
pastel chứ không ra vàng đồng. Ngoài khoảng đó KHÔNG hạ: nền rất nhạt phải ở
nguyên độ sáng kẻo chữ trên nó mất tương phản, và chữ rất đậm vốn đã đủ đậm.

Chạy:  python3 tools/rebrand/purple_to_amber.py [--apply]
Không có --apply thì chỉ in bảng ánh xạ và danh sách tệp, không ghi gì.
"""
from __future__ import annotations

import colorsys
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

TARGET_HUE = 43.0 / 360.0     # tông của #B8860B
PURPLE_MIN, PURPLE_MAX = 235.0, 305.0
MIN_SAT = 0.15
DARKEN_LO, DARKEN_HI = 0.45, 0.80
DARKEN_AMOUNT = 0.24          # chỉnh sao cho #554FF0 rơi đúng vào #B8860B

SKIP_SUFFIXES = ('.g.dart', '.freezed.dart', '.config.dart', '.gen.dart')


def shift(hex6: str) -> str | None:
    """Trả về mã màu vàng tương ứng, hoặc None nếu màu này không phải tím."""
    r, g, b = (int(hex6[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    hue = h * 360
    if not (PURPLE_MIN <= hue <= PURPLE_MAX and s > MIN_SAT and 0.02 < l < 0.99):
        return None

    new_l = l
    if DARKEN_LO <= l <= DARKEN_HI:
        t = (l - DARKEN_LO) / (DARKEN_HI - DARKEN_LO)
        new_l = l - DARKEN_AMOUNT * math.sin(math.pi * t)

    nr, ng, nb = colorsys.hls_to_rgb(TARGET_HUE, new_l, s)
    return ''.join(f'{round(c * 255):02X}' for c in (nr, ng, nb))


def targets():
    for f in (ROOT / 'lib').rglob('*.dart'):
        if not f.name.endswith(SKIP_SUFFIXES):
            yield f, re.compile(r'0x(?:FF|[0-9A-Fa-f]{2})([0-9A-Fa-f]{6})'), '0x'
    for f in (ROOT / 'assets/svg').rglob('*.svg'):
        yield f, re.compile(r'#([0-9A-Fa-f]{6})\b'), '#'


def main() -> int:
    apply = '--apply' in sys.argv
    mapping = {}
    seen = {}   # gồm cả màu không phải tím, để khỏi tính lại
    touched = {}

    for path, pattern, _prefix in targets():
        text = path.read_text(encoding='utf-8', errors='ignore')
        count = 0

        def repl(m: re.Match) -> str:
            nonlocal count
            hex6 = m.group(1).upper()
            if hex6 not in seen:
                seen[hex6] = shift(hex6)
            new = seen[hex6]
            if new is None:
                return m.group(0)
            mapping[hex6] = new
            count += 1
            # Giữ nguyên phần alpha/tiền tố, chỉ thay 6 ký tự màu.
            return m.group(0)[: m.start(1) - m.start(0)] + new

        new_text = pattern.sub(repl, text)
        if count:
            touched[str(path.relative_to(ROOT))] = count
            if apply:
                path.write_text(new_text, encoding='utf-8')

    print(f'{len(mapping)} màu khác nhau, {sum(touched.values())} lần xuất hiện, '
          f'{len(touched)} tệp\n')
    for old in sorted(mapping):
        print(f'  #{old}  ->  #{mapping[old]}')
    print()
    for f in sorted(touched):
        print(f'  {touched[f]:>3}  {f}')
    print('\n' + ('ĐÃ GHI' if apply else 'CHƯA GHI (thêm --apply để ghi)'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
