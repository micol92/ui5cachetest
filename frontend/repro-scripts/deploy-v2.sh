#!/usr/bin/env bash
# crashtest.html/js를 v2(employeeNumber)로 맞추고, 현재 xs-app.json 상태 그대로 빌드+배포
# ("정기 배포" 시뮬레이션 — 셸/JS 필드명을 empNo -> employeeNumber로 동시 변경)
set -euo pipefail
cd "$(dirname "$0")"
cp ../repro-versions/crashtest-v2.html ../frontendui02/webapp/crashtest.html
cp ../repro-versions/crashtest-v2.js ../frontendui02/webapp/crashtest.js
cd ..
npm run build
cf deploy mta_archives/archive.mtar --retries 1 -m frontendui02_ui_deployer
echo "[deploy] v2 (employeeNumber, 신규 배포) 배포 완료"
