#!/usr/bin/env bash
# 현재 로컬 소스 상태(모드/버전)를 한눈에 확인
set -euo pipefail
cd "$(dirname "$0")"
echo "=== catch-all cacheControl (현재 모드) ==="
grep -A4 -F '"^(.*)$"' ../frontendui02/xs-app.json | grep cacheControl
echo
echo "=== crashtest.html의 CRASH_CTX (현재 버전) ==="
grep CRASH_CTX ../frontendui02/webapp/crashtest.html
echo
echo "=== crashtest.js가 읽는 필드 ==="
grep "ctx\." ../frontendui02/webapp/crashtest.js
