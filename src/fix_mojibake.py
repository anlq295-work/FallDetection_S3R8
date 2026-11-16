import pathlib
import re

input_path = pathlib.Path("D:\\FallDetection_S3R8\\src\\ble_provision.cpp")
output_path = pathlib.Path("D:\\FallDetection_S3R8\\src\\ble_provision.cpp")

text = input_path.read_text(encoding="utf-8", errors="replace")

# Khớp toàn bộ dải ký tự Latin-1 (kể cả ký tự điều khiển C1 từ \x80-\x9f và \xa0) + các ký tự đặc biệt của Windows-1252
MOJIBAKE_CHUNK = re.compile(
    r'[\u0080-\u00ff\u0152\u0153\u0160\u0161\u0178\u017d\u017e\u0192\u02c6\u02dc\u2013-\u2022\u2026\u2030\u2039\u203a\u20ac\u2122]+'
)

def try_decode(chunk: str) -> str:
    for enc in ("latin1", "cp1252"):
        try:
            decoded = chunk.encode(enc).decode("utf-8")
            if decoded != chunk:
                return decoded
        except (UnicodeEncodeError, UnicodeDecodeError):
            pass
    return chunk

def fix_all_mojibake(s: str) -> str:
    # KHÔNG thay thế \u00a0 trước khi giải mã vì \u00a0 chính là byte 0xA0 của các chữ 'à', 'À', 'Đ'...
    for _ in range(6):
        new_s = MOJIBAKE_CHUNK.sub(lambda m: try_decode(m.group(0)), s)
        if new_s == s:
            break
        s = new_s
    # Chỉ dọn dẹp \u00a0 dư thừa SAU KHI đã giải mã xong hết các lớp UTF-8
    return s.replace("\u00a0", " ")

fixed_text = fix_all_mojibake(text)
output_path.write_text(fixed_text, encoding="utf-8")

# Kiểm tra tự động xem còn sót chuỗi mojibake nào không
remaining = re.findall(r'.{0,15}(?:Ãƒ|Ã‚|Ã¡|Ã†|Ã„).{0,15}', fixed_text)
print(f"Hoàn tất! Tổng số dòng: {len(fixed_text.splitlines())}")
print(f"Số cụm nghi ngờ còn sót: {len(remaining)}")
for r in remaining[:10]:
    print(" ->", repr(r))