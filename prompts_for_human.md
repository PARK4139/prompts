# Prompts
### 프로젝트 작업규칙 기억요청

#### 개발 환경 규칙
- **파이썬 환경**: `uv` + `pyproject.toml` + `uv.lock` 기반 가상환경 사용
- **서비스 환경**: Linux/Docker + docker-compose 기반 환경 구성
- **서비스 구조**: `services/` 내 디렉토리들이 MSA 서비스별 루트 디렉토리
- **CLI 래퍼**: `pk_ensure` 접두사로 시작하는 파일들은  CLI 모드 실행 시 래퍼 파일


#### 자동 실행 규칙
- **터미널 도구**: `시스템 터미널` 안되면 `커서 내장 터미널` 이나 다른터미널 사용, 안되면 반대순서로도 시도
- **커서 내장 터미널**: 명령어응답이 안오면 `bash -c`, `zsh -c 방식` 으로도 시도, 안되면 반대순서로도 시도
그래도 안되면, Cursor 터미널 재실행


#### 파일 및 디렉토리 관리 규칙
- **문서 관리**: `services/`의 docs는 `docs/README_{MSA_service_name}.md` 형태로 분리 관리
- **레거시 파일**: `deprecatd`된 기존 버전 파이썬 파일에는 `# ` 접두사를 붙여서 rename

#### 코드 작성 규칙
- **다국어 지원**: 모든 프로그램은 다국어 지원 가능하도록 작성 (PkMessage2025 객체 적극 활용)
- **이모지 제외**: 코드 작성 시 이모지 사용 금지
- **함수명 규칙**: 함수명은 `ensure_` 접두사로 시작
- **파일명 규칙**: `.py`, `.sh`, `.cmd`, `.bat`, `.ps1` 확장자 파일들은 `ensure_` 접두사로 시작

#### 테스트 코드 규칙
- **테스트 파일**: `test_` 접두사를 붙여 명시적으로 작성
- **테스트 위치**: `tests` 폴더에서 작성

#### 경로 처리 규칙
- **Path 객체 활용**: 파이썬에서 파일 및 디렉토리 경로 처리 시 Path 객체 사용
- **레거시 변환**: str path 사용 시 Path 객체로 변환 (예: `D_PKG_WINDOWS` → `Path(D_PKG_WINDOWS)`)
- **경로 유틸리티**: `pkg_py/system_object/files.py`, `pkg_py/system_object/directories.py` 활용

#### 코드 구조 규칙
- **클래스 작성**: `pkg_py/system_object`에 작성
- **함수 작성**: `pkg_py/function_split`에 작성
- **래퍼 패턴**: pkg_py에 래퍼 작성 시 주변 래퍼의 패턴을 비교하여 재생성

#### 보안 규칙
- **민감정보 경고**: 비밀번호, API 키 등 민감한 개인정보가 포함된 컨텐츠에 대해 경고 요청

#### 세부 요청 유형
- **코드 리뷰 및 개선**: 기존 코드의 품질 향상 및 최적화
- **버그 해결**: 발생한 문제점의 원인 분석 및 해결 방안
- **아이디어 브레인스토밍**: 새로운 기능이나 개선 방안에 대한 아이디어 논의
- **콘텐츠 작성 보조**: 문서나 설명서 작성에 대한 도움
- **창작 방향 설정**: 프로젝트의 방향성이나 구조에 대한 가이드
- **개념 설명 요청**: 특정 기술이나 개념에 대한 이해 도움
- **자료 정리 및 요약**: 복잡한 정보의 정리 및 핵심 요약
- **연구 방향 설정**: 기술 조사나 연구 주제 설정에 대한 가이드
---
___________________________________________________________
### 프로젝트 설계기획 기억요청
1. 설계달성목표 : SEO 성능 우수, 멀티플랫폼(PC/스마트폰/웹) 지원, 유지보수용의, 뛰어난 UX 
1. 적용 디자인패턴 및 적용 아키텍쳐 : DDD 아키텍처 적용, MSA 적용, Docker-container 는 MSA 단위로 구성
1. 환경구성요소 : 서버운영환경(AWS EC2), 도커환경(docker-compose, docker-compose.dev, docker-compose.prod), 파이썬가상환경(python1.13 이상, uv.lock, pyproject.toml) 
1. 서버구조 : vercel/page 서버(Next.js + TypeScript + Tailwind CSS + Zustand + NextAuth.js / React Native OAuth), AWS EC2/api서버(fastapi), AWS EC2/DB서버(postrege, Database 테이블 개수는 최소화하여 운영)
1. 트리구조 :
prompts/ : AI 기반 코드생성 명령용 프롬프트 모음. 
services/{MSA service name} : MSA 레벨의 서비스하위 요소 집합.
services/{MSA service name}/page_server : frontend 관련 요소(web 소스코드) 의 집합 
services/{MSA service name}/api_server : api server 관련 요소(api 라우터 소스코드, api 컨테이너, 등)의 집합
services/{MSA service name}/db_server : db server 관련 요소(db 컨테이너, 등)의 집합
scripts/ : 서비스 자동화용 스크립트, 파일명에 `ensure_` prefix 패턴적용 
tests/ : 테스트용 스크립트, 파일명에 `test_` prefix 패턴적용 
logs/ : 프로그램 실행의 결과를 저장, 서비스 운영에서 발생된 로그 저장. 
monitors/ : 서비스 모니터링용 스크립트, 파일명에 `ensure_` prefix 와 `state_monitored` suffix 패턴적용 
1. urls 패턴(page 서버, api 서버 url 라우터에 적용) 
heal_base_hospital_worker/v1/api/ensure/login/                     # 로그인 api
heal_base_hospital_worker/v1/page/ensure/login/                     # 로그인 (메인화면)
heal_base_hospital_worker/v1/page/ensure/login-guide/               # 로그인 (가이드)
heal_base_hospital_worker/v1/page/ensure/login-via-google            # 로그인 (구글)
heal_base_hospital_worker/v1/page/ensure/signup/                    # 회원가입
heal_base_hospital_worker/v1/page/ensure/signup-form-submit/        # 회원가입 폼 작성 및 제출
heal_base_hospital_worker/v1/page/ensure/signup-complete/           # 회원가입 완료 페이지
heal_base_hospital_worker/v1/page/ensure/logined/and/hospital-location-guided/{실}         # 실별위치가이드 + 광고
___________________________________________________________
### 프로젝트 설계기획 반영요청
___________________________________________________________
### 프로젝트 구조 생성요청
1. AI에 의한 트리구조 생성결과
business_with_ai/
├── prompts/                                    # AI 기반 코드생성 명령용 프롬프트 모음
├── services/hospital_workers/                  # MSA 레벨의 서비스하위 요소 집합
│   ├── page_server/                           # frontend 관련 요소 (web 소스코드) 의 집합
│   │   ├── app/                              # Next.js App Router
│   │   ├── components/                       # React 컴포넌트
│   │   ├── lib/                              # 유틸리티 함수
│   │   ├── store/                            # Zustand 상태 관리
│   │   ├── auth/                             # NextAuth.js 설정
│   │   └── public/                           # 정적 파일
│   ├── api_server/                           # api server 관련 요소 (api 라우터 소스코드, api 컨테이너, 등)의 집합
│   │   ├── src/                              # FastAPI 소스코드
│   │   ├── tests/                            # API 테스트
│   │   ├── pyproject.toml                    # Python 의존성
│   │   ├── uv.lock                           # uv 잠금 파일
│   │   └── Dockerfile                        # API 컨테이너
│   ├── db_server/                            # db server 관련 요소 (db 컨테이너, 등)의 집합
│   │   ├── migrations/                       # 데이터베이스 마이그레이션
│   │   ├── seeds/                            # 초기 데이터
│   │   └── docker-compose.yml                # DB 컨테이너
│   └── shared/                               # 공통 모듈
├── scripts/                                   # 서비스 자동화용 스크립트 (ensure_ prefix 패턴적용)
├── tests/                                     # 테스트용 스크립트 (test_ prefix 패턴적용)
├── logs/                                      # 프로그램 실행의 결과를 저장, 서비스 운영에서 발생된 로그 저장
└── business_documents/                        # 
___________________________________________________________
### 프로젝트 구조 재기억요청
1. 프로젝트 내부의 `docs 관련 문서`들을 1차 분석 
1. 프로젝트 내부를 순회하며 2차 분석
1. 1, 2차 분석결과에 대한 모호한 부분을 사용자 질의하여 검토요청
___________________________________________________________
### 도커빌드최적화 요청
1. docker-compose.dev/docker-compose.prod 구분
1. `docker-compose.dev` 에는 개발속도가 빠르도록  볼륨 마운트로 코드 변경사항 즉시 반영, 멀티스테이지 빌드로 이미지 크기 최소화
___________________________________________________________
### 백엔드 작업요청
1. page server 빌드/실행 진행요청
1. page server 빌드/실행/기능테스트 진행요청
___________________________________________________________
### 프론트엔드 작업요청
1. page server 빌드/실행 진행요청
1. page server 빌드/실행/기능테스트 진행요청
1. 프론트엔드 컨테이너는 개발모드/운영모드 구분, 개발모드에서는 hot reload 방식으로 동작하도록 개발요청
___________________________________________________________
### 서비스 작업요청
1. hospital_workers 의 page/api/db 서버를 컨테이너로 빌드~실행까지 모두 테스트하자 scripts/ 에 따라서 
___________________________________________________________
### 문제코드수정 또는 문재해결용 자동화코드 생성 및 테스트 요청
1. 문제 : target api-service: failed to solve: process "/bin/sh -c uv sync" did not complete successfully: exit code: 1
1. 코드 수정 및 테스트 재진행
___________________________________________________________
### 코드검토 및 리펙토링 및 테스트 진행요청
1. 문제 : target api-service: failed to solve: process "/bin/sh -c uv sync" did not complete successfully: exit code: 1
1. 코드 수정 및 테스트 재진행
___________________________________________________________
### 코드 수정요청 (저빈도 요청)
1. nginx   page_server/ 로 이동하는게 어떄?
___________________________________________________________
### 서비스 코드베이스 빌드 및 실행 자동화 요청 
1. 도커컨테이너 빌드 자동화스크립트 scripts/ 에 작성요청
1. 도커컨테이너 실행 자동화스크립트 scripts/ 에 작성요청
1. 도커컨테이너 실행 자동화스크립트 scripts/ 에 작성요청
1. scripts/ 의 서비스 빌드 관련 테스트 실행요청
1. 테스트 수행전 모든 도커컨테이너 kill 요청
1. ./scripts/ensure_service_tested.sh 작성 및 실행 요청 # 실행시 서비스별 컨테이너가 동작상태 콘솔출력
1. ./scripts/ensure_service_operated_as_dev.sh 작성 및 실행 요청 # 실행시 서비스별 컨테이너가 동작상태 콘솔출력
1. ./scripts/ensure_service_operated.sh 작성 및 실행 요청 # 서비스 operation 용 스크립트, 실행시 서비스별 컨테이너가 동작상태 콘솔출력
___________________________________________________________
### API 테스트 수행요청
1. 서비스의 모든 api 테스트 수행요청 `scripts/all_api_test.py` 생성 후 실행.
1. 수행결과 형태는 api 호출결과를 `logs/all_api_test.log`에 저장 후
1. 결과를 확인할 수 있도록 log 파일을 open 
___________________________________________________________
### docs 업데이트 요청
1. `README.md` 에 오늘 작업한 내용에 대해서 내용 추가작성
1. 오늘 지금까지 나눈 대화에 대해서 `prompts/chatting_room_with_ai.md` 에 추가작성요청
___________________________________________________________
### 커밋 요청 
1. 지난 commit 이후의 지금까지의 작업에 대한 상세한 한글 커밋멘트 2개 제안
1. 후보 중 사용자가 선택한 메시지로 git push 요청
1. 앞으로의 작업에 대해서도 사용자의 검토결과 만족스럽다는 표현이 나오면, git push 실행을 제안
___________________________________________________________
### 배포 자동화 방법제안요청
___________________________________________________________
### 자동화배포 요청