#!/usr/bin/env python3
"""catch-all 라우트(^(.*)$)의 cacheControl 값만 안전하게 치환하는 공용 스크립트."""
import re
import sys
from pathlib import Path

XS_APP_JSON = Path(__file__).resolve().parent.parent / "frontendui02" / "xs-app.json"


def set_catchall_cache_control(value: str) -> None:
    content = XS_APP_JSON.read_text(encoding="utf-8")
    pattern = re.compile(
        r'("source": "\^\(\.\*\)\$"[\s\S]*?"cacheControl": ")[^"]*(")'
    )
    new_content, count = pattern.subn(rf'\g<1>{value}\g<2>', content)
    if count != 1:
        sys.exit(f"[ERROR] catch-all cacheControl 치환 실패 (매칭 {count}건, 1건이어야 함) — xs-app.json 구조를 확인하세요.")
    XS_APP_JSON.write_text(new_content, encoding="utf-8")
    print(f"[mode] catch-all cacheControl -> {value}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: _lib.py <cacheControl value>")
    set_catchall_cache_control(sys.argv[1])
