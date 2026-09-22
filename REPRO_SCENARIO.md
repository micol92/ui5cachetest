# 캐싱 버그 재현 시나리오 (직접 실행용)

xs-app.json의 catch-all 라우트에 `cacheControl`이 없으면(브라우저 휴리스틱 판단에 맡겨짐) 배포 후 흰 화면이 나고, 명시적으로 지정하면 해결된다는 것을 실제 BTP CF 환경에서 대조 실험으로 확인하는 절차입니다.

## 사전 준비

```bash
cd demo01/frontend
npm install          # 최초 1회만
cf target            # org "BTP KR_pockr" / space "dev"로 로그인돼 있는지 확인
```

테스트 URL:
```
https://btp-kr-pockr-dev-frontendui02-approuter.cfapps.ap12.hana.ondemand.com/frontendui02/crashtest.html
```

## 도구 스크립트 (`frontend/repro-scripts/`)

| 스크립트 | 역할 |
|---|---|
| `mode-vulnerable.sh` | catch-all cacheControl → `max-age=31536000` (취약 모드) |
| `mode-fixed.sh` | catch-all cacheControl → `no-store, no-cache, must-revalidate` (수정 모드) |
| `deploy-v1.sh` | crashtest 파일을 v1(`empNo`)로 맞추고 빌드+배포 |
| `deploy-v2.sh` | crashtest 파일을 v2(`employeeNumber`, "신규 배포")로 맞추고 빌드+배포 |
| `status.sh` | 현재 모드/버전 상태 확인 |

각 스크립트는 **현재 xs-app.json의 모드는 그대로 두고** 버전(v1/v2)만 바꾸거나, 반대로 **버전은 그대로 두고** 모드만 바꿉니다. 그래서 `mode-*.sh`와 `deploy-*.sh`를 조합해서 씁니다.

## 시나리오 A — 취약 모드 재현 (흰 화면이 나는 것을 확인)

```bash
cd demo01/frontend/repro-scripts
./mode-vulnerable.sh
./deploy-v1.sh
```

1. 브라우저에서 **"인터넷 사용 기록 삭제"**(Delete Browsing Data) → 전체 기간, 캐시된 이미지/파일 삭제
2. 위 테스트 URL 접속 (로그인) → **"사원번호: E12345 / 버전: v1"** 정상 출력 확인
3. **이 창을 닫지 말고 그대로 둔 채로**, 터미널에서:
   ```bash
   ./deploy-v2.sh
   ```
4. 배포 완료 후, **아까 그 창에서 캐시 지우지 말고 그냥 새로고침(F5)만**
5. 결과: **흰 화면** + 콘솔에 `TypeError: Cannot read properties of undefined (reading 'toUpperCase')`

## 시나리오 B — 수정 모드 검증 (흰 화면이 안 나는 것을 확인)

```bash
cd demo01/frontend/repro-scripts
./mode-fixed.sh
./deploy-v1.sh
```

1. 다시 **캐시 완전 삭제** → 새 창에서 테스트 URL 접속 → v1 정상 출력 확인
2. **같은 창을 그대로 둔 채로**:
   ```bash
   ./deploy-v2.sh
   ```
3. **같은 창에서 캐시 지우지 말고 새로고침(F5)만**
4. 결과: **"버전: v2 (신규 배포)"가 크래시 없이 정상 출력**

## 주의사항

- **시크릿/InPrivate 창을 새로 열어도, 기존에 열려있던 시크릿 창이 하나라도 남아있으면 캐시를 공유합니다.** 완전히 새로 테스트하려면 시크릿 창을 전부 닫거나 "인터넷 사용 기록 삭제"를 쓰세요.
- 시나리오 A → B로 넘어갈 때, 시나리오 A에서 캐시가 오염된 창은 재사용하지 마세요 (수정 모드로 바꿔도 이미 캐시된 그 창은 소급 적용 안 됨 — 이것도 실제 버그의 특성 중 하나입니다).
- `status.sh`로 지금 로컬 소스가 어떤 모드/버전인지 언제든 확인 가능합니다.

## 현재 상태 (이 파일 작성 시점)

xs-app.json은 **수정 모드**(`no-store, no-cache, must-revalidate`)로 남아있습니다. 실제 배포 환경도 이 상태로 되어 있어야 정상입니다(`status.sh`로 확인).

## 참고

상세한 조사 배경(가설 수립, SAP 공식 문서 조사, 시행착오, 캐시 개념 Q&A 등)은 [`CACHE_BUG_REPRODUCTION_LOG.md`](CACHE_BUG_REPRODUCTION_LOG.md) 참고.
