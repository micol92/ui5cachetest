# SK ON E-HR 흰 화면 이슈 — 원인 분석 및 실 BTP 환경 재현 기록

## 1. 배경

SK ON E-HR 시스템에서 "메뉴 클릭 후 흰 화면, 일정 시간 후 또는 브라우저 캐시 전체 삭제 후 정상화"되는 현상이 불특정 사용자에게 간헐적으로 발생. 1년 전 유사 이슈(브라우저 재시작 후 인증 실패)는 `xs-app.json`의 welcome file(`index.html`)에 `cacheControl` 설정을 추가해 해결한 바 있음.

## 2. 가설 수립 과정

### 2.1 최초 분석 (고객 문의 기반)

고객 요청 8개 항목(원인/원인별 확인방법, 원인 범위 구분, Cache Buster 적정성, 배포 전후 절차, Edge/VDI 권고설정, 재발방지 방안, 관련 SAP 문서, 필요 로그)에 대해 아래 4개 가설을 도출:

1. **세션/토큰 타임아웃 계층 불일치** (AppRouter 30m / XSUAA refresh 1h / IAS refresh 12h)
2. **HTML5 앱 정적 리소스의 xs-app.json 캐시 정책 커버리지 불균일** (welcome file만 처리, 나머지 리소스는 미처리) — 1순위 가설
3. **Work Zone 사이트 타일의 sap-ui-version 고정** (SAP KBA 3703606 참고)
4. **Destination(OAuth2UserTokenExchange) 토큰 캐시 TTL 불일치**

### 2.2 SAP 공식 자료 조사 결과

- **Cache Behavior for Application Resources** (help.sap.com): SAPUI5 앱 리소스는 기본적으로 브라우저에 최대 1년 캐시됨
- **Cache Buster for SAPUI5 Application Resources**: ABAP NetWeaver 전용 메커니즘(`/UI5/APP_INDEX_CALCULATE`), 현재 BTP CF 아키텍처엔 미적용
- **KBA 3703606** (Blank screen in Work Zone, Cloud Foundry): Work Zone 타일의 outdated `sap-ui-version` 고정으로 인한 blank screen — `net::ERR_BLOCKED_BY_ORB`
- **KBA 3554398** (Blank Screen in SAP Build Work Zone): CSP/보안헤더 이슈, 캐시 삭제로 해결 안 되는 케이스, MS Edge 명시
- **Browser and Platform Support** (help.sap.com): SAPUI5는 Edge(Chromium)를 Chrome과 동일하게 취급하나, **Edge 고유의 추적 방지(Tracking Prevention) 기능이 엄격하면 `*.hana.ondemand.com` 요청이 차단**될 수 있음

### 2.3 실제 고객 콘솔 로그 분석 (E-HR 재현 스크린샷)

`www.nets-jsso.com` (SK 그룹 사내 SSO)에서 `DNS_PROBE_FINISHED_NXDOMAIN` 확인 → **캐싱과는 별개의, 사내 SSO/DNS 인프라 이슈**로 판단. SAP BTP 범위 밖.

## 3. 로컬 Toy Demo 재현 (1차)

Node.js 정적 서버로 welcome file(항상 fresh) + 메뉴 리소스(캐시 정책 유무 전환 가능)를 흉내낸 축소 모형 제작 (`repro/` 폴더). 결과:

- **캐시 정책 없음** → 배포 후 흰 화면 재현 성공 (구버전 JS가 신버전 셸 데이터 형상을 못 읽어 `TypeError`)
- **`cacheControl` 적용** → 흰 화면 재발 없음, 정상 반영 확인
- **추가 발견**: 이미 캐시가 오염된 사용자는 서버 설정만 바꿔도 소급 적용 안 됨 (헤더 정책 변경은 향후 요청에만 영향, 과거 캐시 엔트리는 그대로 유지됨)

## 4. 실제 BTP CF 환경 재현 (2차, 본 기록의 핵심)

사용자 요청에 따라 로컬 축소 모형이 아닌 **실제 참조 소스(`demo01`, SK ON 아키텍처와 동일한 CAP+Fiori+AppRouter+XSUAA+html5-apps-repo 구성)를 실제 BTP dev subaccount(org `BTP KR_pockr`, space `dev`)에 배포**하여 재현.

### 4.1 배포 과정에서 만난 이슈 (캐싱과 무관, 별도 처리)

| 이슈 | 원인 | 해결 |
|---|---|---|
| `jwincidentapp02-db-deployer` 빌드 실패 | `engines.node: "^18 \|\| ^20"` 인데 buildpack엔 Node 22/24만 존재 | mtar 내부 `package.json`을 직접 패치하여 엔진 범위 확장 |
| `jwincidentapp02-approuter`, `frontendui02-approuter` 빌드 실패 | `@sap/approuter` 14.4.2로 고정, 구버전이라 Node 22/24 미지원 | 최신 버전(`^23`)으로 업그레이드 (사용자 지적대로 "npm 패키지만 맞추면" 해결되는 문제였음) |
| db-deployer HDI 배포 시 TLS 에러 (`unable to get local issuer certificate`) | Node 22/24의 강화된 인증서 검증과 HANA Cloud 인증서 체인 불일치로 추정 (미해결, 별도 과제) | 스키마 변경 없어 db-deployer는 배포에서 제외(`-m` 옵션으로 srv/approuter만 배포) |

### 4.2 실제 배포된 아키텍처에서 발견한 코드 레벨 근거

`frontendui02/xs-app.json` 분석 결과:
```json
{ "source": "^/index.html", ..., "cacheControl": "no-store, no-cache, must-revalidate" },  // 작년 수정분
{ "source": "^/service/(.*)$", ... },        // cacheControl 없음
{ "source": "^/resources/(.*)$", ... },       // cacheControl 없음
{ "source": "^(.*)$", "service": "html5-apps-repo-rt", ... }  // ⚠️ 앱의 실제 JS/manifest 등 전부 여기로 빠짐, cacheControl 없었음
```
추가로 `ui5-deploy.yaml`이 `generateCachebusterInfo` 태스크를 실행해 캐시버스터 메타데이터를 생성하지만, `webapp/index.html`의 부트스트랩에 이를 활성화하는 `data-sap-ui-app-cache-buster` 속성이 없어 **생성된 메타데이터가 런타임에서 전혀 사용되지 않음**을 확인.

### 4.3 텍스트 기반 1차 검증 (i18n.properties)

`appTitle`을 실제로 변경 → 재빌드 → `cf deploy` → 브라우저 정상 새로고침/하드리프레시에도 반영 안 됨 → **Network 탭에서 `Component-preload.js`가 `(disk cache)`로 응답**되는 것을 직접 확인. `fetch(url, {cache:'no-store'})`로 서버는 이미 최신 콘텐츠를 갖고 있음을 별도 확인 → 순수 브라우저 캐시 문제로 확정.

### 4.4 자유형(Freestyle) 크래시 테스트 페이지 추가

Fiori Elements(List Report/Object Page)는 OData 메타데이터 기반으로 동적 렌더링되고 방어적으로 설계되어 있어, 단순 텍스트 변경으로는 "완전한 흰 화면(크래시)"까지 재현하기 어려움 (일부 위젯만 부분적으로 깨짐 — 예: `incidentsID`라는 스키마에 없는 필드를 참조하는 기존 annotation 버그로 인해 헤더 타이틀 영역만 깨지는 현상 별도 확인, 이는 캐싱과 무관한 **기존 결함**).

사용자 제안에 따라 **`webapp/crashtest.html` + `crashtest.js`** 자유형 테스트 페이지를 신규 추가:
- `crashtest.html` = 셸 역할, xs-app.json에 `index.html`과 동일한 always-fresh 라우트 추가
- `crashtest.js` = catch-all 라우트를 따름 (캐시 정책 전환 대상)
- v1: `window.CRASH_CTX = { empNo: 'E12345', name: '홍길동' }`, JS가 `ctx.empNo.toUpperCase()` 읽음
- v2("배포 후"): 셸이 `{ employeeNumber: ... }`로 필드명 변경, JS도 `ctx.employeeNumber` 읽도록 동시 변경 — **실제로는 구버전 JS가 캐시에 남아있고 셸만 새로 받는 상황을 재현**

### 4.5 재현 중 겪은 시행착오 (중요한 부수적 발견들)

1. **`cacheControl` 완전 미지정 시 재현 불안정** → 브라우저의 휴리스틱 캐싱(Last-Modified 기반 추정)은 경과 시간에 따라 들쑥날쑥해서, 짧은 테스트 주기 안에서는 캐시가 안 걸리기도 함. **`max-age=31536000`을 명시**해서 결정론적으로 재현하도록 변경.
2. **`<script src="...">` 태그 로딩이 `fetch()`와 다르게 캐시 재검증을 안 타는 현상 관찰** → `fetch()` + `eval()` 방식으로 로딩 방식 변경.
3. **시크릿/InPrivate 창을 "새로" 열어도 기존에 열려있는 시크릿 창이 하나라도 남아있으면 같은 캐시(세션)를 공유** → 완전히 새로 테스트하려면 시크릿 창을 전부 닫거나, "인터넷 사용 기록 삭제"(Delete Browsing Data)로 캐시를 명시적으로 지워야 함.

### 4.6 최종 검증 결과

| 시나리오 | 절차 | 결과 |
|---|---|---|
| 취약 모드 (catch-all `max-age=31536000`) | v1 로드(캐시 워밍) → v2 배포 → 동일 창에서 새로고침 | **흰 화면 + 콘솔에 `TypeError: Cannot read properties of undefined (reading 'toUpperCase')`** — 재현 성공 |
| 수정 모드 (catch-all `no-store, no-cache, must-revalidate`) | 캐시 완전 삭제 → v1 로드 → v2 배포 → **동일 창, 캐시 안 지우고 새로고침만** | **정상적으로 v2 반영, 크래시 없음** — 수정 효과 검증 성공 |

## 5. 최종 결론

- **근본 원인**: `xs-app.json`의 catch-all 라우트(앱의 대부분 정적 리소스가 여기로 매칭됨)에 `cacheControl` 미설정 → 브라우저 기본/휴리스틱 장기 캐싱 → 배포 후 셸(항상 최신)과 캐시된 리소스(구버전)의 형상 불일치 → JS 런타임 에러 → 렌더링 중단(흰 화면)
- **수정**: catch-all 라우트에 `"cacheControl": "no-store, no-cache, must-revalidate"` 추가
- **실제 BTP CF 환경(AppRouter+XSUAA+IAS+html5-apps-repo)에서 원인 재현부터 수정 효과 검증까지 완전히 실증됨**

## 6. 캐시 개념 Q&A (진행 중 나온 질문 정리)

**Q. no-store / no-cache / must-revalidate 차이는?**
- `no-store`: 캐시에 저장 자체를 하지 마라
- `no-cache`: 저장은 하되, 쓰기 전에 매번 서버에 확인(재검증)해라
- `must-revalidate`: 유효기간(max-age)이 지난 뒤에만 강제로 재확인해라 (지나기 전엔 그냥 씀, 네트워크 장애 시 "그냥 옛날 거 쓰기"라는 예외를 금지)

**Q. no-store와 no-cache를 같이 쓸 수 있나?**
- 네, 문법적으로 모순 없음. `no-store`가 저장 자체를 막아서 `no-cache`(저장된 걸 재검증)가 적용될 상황 자체가 생기지 않음 — 사실상 중복이지만, 브라우저/프록시 구현 편차에 대비한 이중 안전장치로 실무에서 흔히 같이 씀.

**Q. disk cache와 memory cache 차이는?**
- memory cache: 현재 세션 동안 메모리에 들고 있는 것 (탭 닫으면 사라짐)
- disk cache: 디스크에 저장, 브라우저 재시작해도 남음
- 공통점: 둘 다 서버에 재확인 없이 그대로 재사용함 (Network 탭에 `(disk cache)`/`(memory cache)`로 표시, 실제 다운로드 크기가 아님)

**Q. cacheControl을 아예 안 쓰면 어떻게 되나?**
- 브라우저의 자체 휴리스틱(주로 Last-Modified 기준 경과시간 비율)으로 캐시 여부/기간을 추정 — **시점에 따라 들쑥날쑥**해서 예측 불가능. 실제 고객사의 "간헐적" 증상 패턴과 일치. 데모에서 확정적으로 재현하려면 `max-age`를 명시해야 함.

**Q. 이 휴리스틱이 브라우저마다 다른가?**
- 네. HTTP 표준은 "휴리스틱을 써도 된다"고만 하고 정확한 공식은 강제하지 않아서 Chrome/Edge(Chromium), Firefox, Safari가 각자 다르게 구현함. 브라우저 버전, 디스크 캐시 정책(그룹정책 등)도 영향을 줌. 이게 "왜 하필 Edge에서" 문제가 두드러지는지의 또 다른 배경이 될 수 있음. cacheControl을 명시하면 이 편차 자체가 무의미해짐(서버가 못박으므로).

## 7. 단계별 슬로우 워크스루 기록 (사용자 요청으로 처음부터 재현)

사용자가 "천천히, 모든 과정을 확인"하고 싶다고 요청하여, 취약 모드 재현을 처음부터 단계별로 다시 수행. 아래는 그 실제 기록.

### 7.1 1차 테스트 — 취약 모드 재현 (완료)

| 단계 | 수행 내용 | 결과 |
|---|---|---|
| 0 | 구조 설명: `crashtest.html`=셸(항상 fresh), `crashtest.js`=앱 로직(catch-all, 캐시 대상) | — |
| 1 | 현재 xs-app.json 확인 | catch-all이 이미 수정본(`no-store...`) 상태였음 |
| 2 | catch-all을 취약 상태로 되돌림 | `cacheControl` → `"max-age=31536000"` |
| 3 | 현재 소스가 v1인지 확인 | v2 상태였음, v1으로 리셋 |
| 4 | v1 + 취약 설정으로 빌드/배포 | 성공 |
| 5 | 사용자: 브라우저 캐시 완전 삭제(Delete Browsing Data) 후 새 창에서 접속 | **"사원번호: E12345 / 버전: v1"** 정상 출력 확인 |
| 6 | 이 창을 유지한 채 서버에 v2 배포 (셸: `employeeNumber`, JS: `ctx.employeeNumber` 동시 변경) | 배포 성공 — 서버 입장에선 셸/JS 서로 정합적인 정상 배포 |
| 7 | 사용자: **같은 창에서 캐시 안 지우고 일반 새로고침(F5)만** | **"하얀화면"** — 재현 성공 |
| 8 | 원인 확인 (콘솔) | `crashtest v1] render failed: TypeError: Cannot read properties of undefined (reading 'toUpperCase')` 예상대로 확인 |

**핵심 확인 사항 (사용자 질의응답)**:
- "html은 서버(html5-apps-repo-rt)에서 호출, JS는 disk-cache에서 호출(max-age 때문)" — **정확히 맞음**으로 확인됨
- 원인 3단계 정리: ① 즉각 원인(`ctx.empNo`가 `undefined`라 `.toUpperCase()`에서 크래시) → ② 중간 원인(셸은 새로 받고 JS는 캐시된 구버전 재사용) → ③ 근본 원인(catch-all 라우트에 `cacheControl` 미설정/`max-age` 설정으로 브라우저가 JS를 장기 캐시)

### 7.2 2차 테스트 — 수정 모드 검증 (완료)

| 단계 | 수행 내용 | 결과 |
|---|---|---|
| 9 | catch-all의 `cacheControl`을 `max-age=31536000` → `no-store, no-cache, must-revalidate`로 복원 | — |
| 10 | v1으로 리셋 후 이 수정본으로 빌드/배포 | 성공 |
| 11 | 사용자: 캐시 완전 삭제 후 새 창에서 접속 | **"사원번호: E12345 / 버전: v1"** 정상 출력 |
| 12 | 이 창을 유지한 채 서버에 v2 배포 (1차 테스트와 완전히 동일한 변경: 셸/JS 둘 다 `empNo`→`employeeNumber`) | 배포 성공 |
| 13 | 사용자: **같은 창에서 캐시 안 지우고 일반 새로고침(F5)만** | **"crashtest.js 버전: v2 (신규 배포)"가 크래시 없이 정상 출력** — 수정 효과 검증 성공 |

**결론**: 동일한 배포 변경(필드명 rename)에 대해, `cacheControl` 설정 하나만 다르게 했을 때 결과가 완전히 갈림 — 취약 설정은 100% 크래시, 수정 설정은 100% 정상 반영. **catch-all 라우트의 cacheControl이 근본 원인이자 해결책임을 실제 BTP CF 환경에서 대조 실험으로 확정.**

## 8. 실제 `welfare` 앱 xs-app.json 확인 (결정적 증거)

사용자가 SK ON 실제 `welfare` 앱의 xs-app.json을 공유함. 확인 결과:

```json
{
  "welcomeFile": "/welfare",
  "sessionTimeout": 3600,
  "routes": [
    ... (objectstore, mail, ecp, sfsf, sfsf1, odata, adobeapi 등 백엔드 destination 라우트들) ...
    { "source": "^/resources/(.*)$", "destination": "ui5", ... },
    { "source": "^/test-resources/(.*)$", "destination": "ui5", ... },
    {
      "source": "^/welfare/index.html$",
      "target": "/welfare/index.html",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa",
      "cacheControl": "no-store, no-cache, must-revalidate"   // ✅ 작년에 이미 처리됨
    },
    {
      "source": "^(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"                             // ⚠️ cacheControl 없음 — 실제로 확인됨
    }
  ]
}
```

**저희가 가설·재현했던 것과 정확히 동일한 구조적 갭이 실제 프로덕션 xs-app.json에 그대로 존재함을 확인.** welcome file(`/welfare/index.html`)만 처리돼 있고, 나머지 모든 앱 리소스(Component-preload.js, View.xml, Controller.js, manifest.json 등)가 걸리는 catch-all에는 `cacheControl`이 없음.

(참고: catch-all 블록의 `"authenticationType": "xsuaa"` 부분에 둥근따옴표(smart quote)가 섞여 보이는 부분 발견 — 복사 과정의 artifact인지 실제 파일 문제인지 원본 파일 재확인 필요)

**권장 수정**:
```json
{
  "source": "^(.*)$",
  "target": "$1",
  "service": "html5-apps-repo-rt",
  "authenticationType": "xsuaa",
  "cacheControl": "no-store, no-cache, must-revalidate"
}
```

## 9. 실제 인시던트 사례 및 해시 라우팅 정밀 재현

### 9.1 실제 프로덕션 인시던트 정보

- **현상**: 일부 메뉴 클릭 시 무반응/흰 화면, 메뉴 간 이동 시 URL만 바뀌고 화면 변화 없음, 행복연금 신청서 이미지가 다른 메뉴로 가도 겹쳐 남음
- **대상**: 김동환 (so22309), IP 10.86.126.55
- **영향 메뉴**: 단신부임신청, 경조금(전체), 행복나눔신청, 산후조리원비 신청, 의료비 신청, 특수교육비 신청, 급여계좌등록변경, 소득세율변경, 생년월일 입력, 퇴직금/행복연금 가입신청("이미 가입됨" 오류 + 페이지 이동 불가)
- **실제 스크린샷 확인**: `https://skon-prod.cfapps.jp10.hana.ondemand.com/welfare/index.html#/CarRegistration`(정상) vs `#/ShortLivedApply`(회색 화면 + "조회 중입니다" 팝업 멈춤, 또는 완전 백지)
- **구조적 확인**: URL 패턴(`/welfare/index.html#/<라우트>`)으로 볼 때, 각 메뉴는 별도 앱이 아니라 **`welfare`라는 하나의 UI5 앱 내 해시 라우팅으로 구분되는 View들**임 → 하나의 Component-preload.js(번들)를 여러 메뉴가 공유 → 캐싱 버그 하나가 여러 메뉴에 동시다발적으로 영향 줄 수 있는 구조

### 9.2 해시 라우팅 정밀 재현 데모 (`webapp/hashdemo/`)

"XML과 JS를 직접 비교해야 하는가"라는 질문에서 출발, 실제 `welfare` 앱과 동일한 방식(해시 라우팅 + 진짜 `.view.xml` + 진짜 `.controller.js`, `sap.ui.core.mvc.XMLView.create()`)으로 데모 구축:

- `hashdemo/index.html` — 셸 (xs-app.json에 `^/hashdemo/index.html$` always-fresh 라우트 추가, 실제 `^/welfare/index.html$`와 동일 패턴), `window.HASH_CTX` 제공
- `hashdemo/app.js` — `hashchange` 리스너로 `XMLView.create({viewName: "hashdemo.view." + route})` 호출 (실제 UI5 해시 라우팅 매커니즘)
- `view/CarRegistration.view.xml` + `controller/CarRegistration.controller.js` — `HASH_CTX`를 참조하지 않음 (실제 스크린샷에서 이 메뉴가 정상이었던 것과 동일하게 항상 정상 동작하도록 설계)
- `view/ShortLivedApply.view.xml` + `controller/ShortLivedApply.controller.js` — busy 인디케이터 표시 → 비동기 조회 시뮬레이션(`setTimeout`) → `HASH_CTX.empNo`(v1) 또는 `.employeeNumber`(v2) 읽어서 표시. 예외 발생 시 busy를 못 풀어 **"조회 중" 상태로 영구 정지** (실제 스크린샷의 "조회 중입니다" 멈춤과 동일한 메커니즘)

#### 재현 결과

| 단계 | 결과 |
|---|---|
| 취약 모드: v1 로드 → v2 배포 → 같은 창 새로고침 | "차량등록증 등록"은 정상, **"단신부임신청"은 조회 중 상태로 영구 정지** — 실제 프로덕션 스크린샷과 동일한 패턴 재현 |
| 콘솔 에러 | `[hashdemo] ShortLivedApply render failed: TypeError: Cannot read properties of undefined (reading 'toUpperCase')` |
| 수정 모드: 동일 절차 반복 | "단신부임신청"도 캐시 지우지 않고 새로고침만으로 **정상적으로 v2 내용 반영, 정지 없음** |

**결론**: 실제 `welfare` 앱과 동일한 아키텍처(해시 라우팅, XML View, JS Controller, Component 번들링)로 재현했을 때도 동일한 메커니즘과 동일한 수정 효과가 확인됨. 특히 "일부 메뉴만 문제, 나머지는 정상"이라는 실제 증상 패턴까지 정확히 재현되어, 가설의 신뢰도가 크게 높아짐.

## 10. 성능 고려사항 및 대안 비교

수정안(catch-all에 `no-store, no-cache, must-revalidate`)을 실제 반영하기 전, 성능 트레이드오프에 대한 논의.

### 10.1 `no-store` 적용 시 성능 영향

catch-all에 걸리는 모든 리소스(Component-preload.js, 모든 View.xml/Controller.js, manifest.json, 이미지 등)가 **캐시 혜택을 전혀 못 받음** — 매 페이지 로드마다 안 바뀐 파일도 전부 재다운로드. 서버 요청 수 증가, 체감 로딩 속도 저하 가능성 있음. 다만 사내 E-HR처럼 트래픽이 크지 않은 환경에서는 실제 영향은 제한적일 가능성이 높고, "매번 흰 화면"의 비용이 "매번 조금 더 로딩"의 비용보다 훨씬 큼.

### 10.2 검토했으나 기각한 대안 — "문제되는 XML/메뉴만 선택적으로 no-cache"

아이디어는 합리적이나 다음 이유로 권장하지 않음:

1. **다음에 "문제될 파일"을 미리 알 수 없음** — 이번엔 `ShortLivedApply`였지만 다음 배포에선 다른 메뉴가 걸릴 수 있음. 매번 화이트리스트를 사후 관리해야 하는 두더지 잡기(whack-a-mole) 방식이 됨
2. **번들링된 경우 애초에 선택 불가** — 여러 메뉴의 View/Controller가 `Component-preload.js` 하나로 뭉쳐있으면 "일부만" 캐시 정책을 다르게 줄 방법이 없음
3. **관리 부담 증가** — 메뉴가 추가/변경될 때마다 xs-app.json 라우트 목록도 같이 유지보수해야 함

### 10.3 더 나은 절충안 — `no-cache` + ETag (조건부 재검증)

`no-store` 대신 `no-cache`만 쓰고 서버가 ETag를 응답하면: 파일이 안 바뀌었으면 서버가 `304 Not Modified`로 응답해 캐시된 걸 그대로 재사용(빠름), 바뀌었을 때만 새로 다운로드 — "안 바뀐 파일은 빠르게, 바뀐 파일만 갱신"되는 이상적 절충안.

**⚠️ 실제 테스트에서 발견한 함정**: 4.5절에서 이미 기록했듯, `<script src="...">` 태그로 로드되는 리소스는 `no-cache`만으로는 **재검증 자체를 안 타는 현상을 실측으로 확인**했음 (그래서 최종적으로 `no-store`로 확실하게 처리함). UI5 모듈 로더의 실제 리소스 로딩 방식에 따라 이 절충안이 안 먹힐 수 있어, **적용 전 반드시 실측 테스트 필요**.

### 10.4 중장기 이상적 해법 — content-hash 파일명 전략

배포마다 리소스 URL 자체가 바뀌게(`Component-preload-a1b2c3.js`) 하면 `max-age`를 길게 걸어도 전혀 위험하지 않음 — 성능과 정합성을 동시에 확보하는 가장 근본적인 해법. 다만 xs-app.json 수정만으로 끝나지 않고 빌드/배포 파이프라인 구조 변경이 필요해 중장기 과제.

### 10.5 권장 순서

1. **단기(즉시)**: `no-store`로 반영 — 확실하지만 성능 비용 있음
2. **중기**: `no-cache`+ETag 절충안을 실측 테스트 후 가능하면 전환
3. **장기**: content-hash 파일명 전략 검토

## 11. 남은 과제 (이번 재현 범위 밖)

1. `jwincidentapp02-db-deployer`의 TLS 인증서 이슈 — Node 22/24 buildpack과 HANA Cloud 인증서 체인 검증 문제로 추정, 별도 조사 필요
2. `backend/app/annotations.cds`의 `incidentsID` — 스키마(`schema.cds`)에 존재하지 않는 필드를 참조하는 기존 결함, 캐싱과 무관, 별도 수정 필요
3. 세션/토큰 타임아웃 불일치, Work Zone 타일 sap-ui-version 고정, Destination TTL 가설은 이번 재현에서 다루지 않음 (실제 XSUAA/IAS/Work Zone 설정 확인 필요)
