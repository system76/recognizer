# BigCommerce 계정 동기화 개선

## 개요

이 문서는 BigCommerce와 자사 계정 간 동기화 문제를 해결하기 위한 개선사항을 설명합니다.

## 구현된 개선사항

### 1. 로그인 시 자동 재동기화

**파일**: `lib/recognizer_web/authentication.ex`

**기능**:
- 사용자가 로그인할 때 BigCommerce 계정이 동기화되지 않은 경우 자동으로 백그라운드에서 동기화 시도
- 동기화 실패 시에도 로그인은 정상적으로 진행 (사용자 경험에 영향 없음)
- 상세한 로그를 통해 동기화 성공/실패 추적 가능

**로그 예시**:
```
[info] Attempting BigCommerce sync for user 123 (user@example.com) during login
[info] Successfully synced BigCommerce customer for user 123 during login
```

**작동 방식**:
```elixir
def log_in_user(conn, user, params \\ %{}) do
  case Recognizer.Accounts.user_prompts(user) do
    {:ok, user} ->
      # 로그인 성공 시 백그라운드에서 BigCommerce 동기화 시도
      ensure_bigcommerce_user_async(user)
      # ... 나머지 로그인 처리
  end
end
```

### 2. Two-Factor 세션 설정 공통 함수

**파일**: `lib/recognizer_web/authentication.ex`

**함수**: `put_two_factor_session/2`

**변경 내용**:
- `UserSessionController`와 `UserOAuthController`에 중복되어 있던 코드를 공통 함수로 추출
- 코드 중복 제거로 유지보수성 향상

**Before (중복 코드)**:
```elixir
# UserSessionController
conn
|> put_session(:two_factor_user_id, user.id)
|> put_session(:two_factor_sent, false)
|> put_session(:two_factor_issue_time, System.system_time(:second))

# UserOAuthController
conn
|> put_session(:two_factor_user_id, user.id)
|> put_session(:two_factor_sent, false)
```

**After (공통 함수)**:
```elixir
# 두 컨트롤러 모두
conn |> Authentication.put_two_factor_session(user)
```

### 3. BigCommerce 동기화 헬퍼 함수

**파일**: `lib/recognizer_web/authentication.ex`

**함수**: `ensure_bigcommerce_user_async/1`

**기능**:
- 비동기로 BigCommerce 동기화 수행 (로그인 속도에 영향 없음)
- 이미 동기화된 사용자는 자동으로 스킵
- 상세한 로깅으로 디버깅 용이

## 문제 해결

### apatura.inc@protonmail.com 케이스

**해결 방법**: 사용자가 다시 로그인하면 자동으로 동기화됩니다.

1. 사용자에게 로그인 요청
2. 로그인 시 자동으로 백그라운드에서 BigCommerce 동기화 시도
3. 성공 시 이후 주문 가능

### 긴급 상황: 콘솔 접근

클라우드 환경에서 긴급하게 수동 동기화가 필요한 경우:

```bash
# Kubernetes pod 접속
kubectl exec -it <recognizer-pod-name> -- iex -S mix

# IEx 콘솔에서 실행
iex> user = Recognizer.Accounts.get_user_by_email("apatura.inc@protonmail.com")
iex> Recognizer.BigCommerce.get_or_create_customer(user)
```

또는 Docker Compose:
```bash
docker-compose exec recognizer iex -S mix
```

## 영향 받는 파일

### 수정된 파일
- `lib/recognizer_web/authentication.ex` - 로그인 로직 및 공통 함수 추가
- `lib/recognizer_web/controllers/accounts/user_session_controller.ex` - 중복 코드 제거
- `lib/recognizer_web/controllers/accounts/user_oauth_controller.ex` - 중복 코드 제거

## 로그인 시 자동 동기화가 충분한 이유

### ✅ 대부분의 케이스를 자동 해결
- **계정 생성 시 실패**: 다음 로그인에서 자동 재시도
- **일시적 API 오류**: 다음 로그인에서 자동 재시도
- **네트워크 문제**: 다음 로그인에서 자동 재시도

### ✅ 보안 이점
- **API 엔드포인트 없음**: 악용 가능성 제로
- **Rate limiting 불필요**: 사용자가 자연스럽게 제한됨
- **감사 로그 불필요**: 로그인 로그로 추적 가능
- **권한 관리 불필요**: 사용자 본인만 동기화됨

### ✅ 사용자 경험
- **투명함**: 사용자는 아무것도 할 필요 없음
- **빠름**: 백그라운드 처리로 로그인 속도 영향 없음
- **신뢰성**: 실패해도 로그인은 성공

### ⚠️ 제한 사항
**로그인하지 않는 사용자는 동기화 안 됨**
- 하지만 BigCommerce 동기화는 주문 시 필요
- 주문하려면 로그인 필수
- 따라서 실제로는 문제 없음

### 🚨 긴급 상황 대응
로그인 전에 동기화가 꼭 필요한 경우 (매우 드묾):
- kubectl/docker exec로 콘솔 접속
- IEx에서 수동 동기화
- 완전한 접근 제어 및 감사 추적

## 향후 개선 가능 사항

1. **동기화 재시도 큐**: 실패한 동기화를 주기적으로 재시도하는 백그라운드 작업
2. **동기화 상태 필드**: `users` 테이블에 `bc_sync_status` 필드 추가
3. **모니터링 및 알림**: 동기화 실패율 추적 및 알림 시스템
4. **이벤트 소싱**: 동기화 이벤트를 별도 테이블에 저장하여 추적성 향상

## 테스트

컴파일 확인:
```bash
mix compile
```

## 참고사항

- ✅ 로그인 시 자동 동기화는 백그라운드에서 수행되므로 로그인 속도에 영향 없음
- ✅ 동기화 실패 시에도 사용자는 정상적으로 로그인 가능
- ✅ 모든 동기화 시도는 로그에 기록되어 추적 가능
- ✅ API 엔드포인트가 없어 보안 위험 최소화
- ✅ 사용자가 로그인할 때마다 자동으로 재시도되어 결국 해결됨

