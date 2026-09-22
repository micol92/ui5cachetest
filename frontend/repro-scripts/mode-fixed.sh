#!/usr/bin/env bash
# xs-app.json의 catch-all 라우트를 "수정 모드"로 설정
set -euo pipefail
cd "$(dirname "$0")"
python3 _lib.py "no-store, no-cache, must-revalidate"
