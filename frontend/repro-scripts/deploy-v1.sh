#!/usr/bin/env bash
# crashtest.html/js를 v1(empNo)로 맞추고, 현재 xs-app.json 상태 그대로 빌드+배포
set -euo pipefail
cd "$(dirname "$0")"
cp ../repro-versions/crashtest-v1.html ../frontendui02/webapp/crashtest.html
cp ../repro-versions/crashtest-v1.js ../frontendui02/webapp/crashtest.js
cd ..
npm run build
cf deploy mta_archives/archive.mtar --retries 1 -m frontendui02_ui_deployer
echo "[deploy] v1 (empNo) 배포 완료"
