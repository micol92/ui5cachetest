#!/usr/bin/env bash
# xs-app.json의 catch-all 라우트를 "취약 모드"로 설정
# (cacheControl 없음 상태를 데모에서 결정론적으로 재현하기 위해 명시적 장기 캐시로 강제)
set -euo pipefail
cd "$(dirname "$0")"
python3 _lib.py "max-age=31536000"
