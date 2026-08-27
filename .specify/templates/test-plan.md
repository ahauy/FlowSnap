# Test Plan: <Feature Title>

**Feature slug**: `<feature-slug>`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (trước implement)
**Traces to**: `.specify/features/<slug>/spec/user-stories.md`

> **Mục đích**: Document này mô tả test cases ở dạng Gherkin trước khi viết code.
> Sau khi implement xong, actual test files được viết dựa trên document này.

---

## Unit Tests

### `<Module/Service name>`

#### TC-001: <Tên test case>

```gherkin
Given <điều kiện ban đầu>
When  <hành động>
Then  <kết quả mong đợi>
```

**File**: `apps/api/src/<module>/<service>.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-<SLUG>-001` Scenario 1

---

#### TC-002: <Edge case>

```gherkin
Given <điều kiện biên>
When  <hành động>
Then  <graceful handling>
```

**File**: `apps/api/src/<module>/<service>.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-<SLUG>-001` Scenario 2

---

## Integration Tests

### `<API Endpoint>`

#### TC-010: <Tên test case>

```gherkin
Given user is authenticated as <role>
  And <precondition>
When  <HTTP method> /api/v1/<endpoint> is called with <payload>
Then  response status is <status code>
  And response body matches <expected shape>
```

**File**: `apps/api/src/<module>/<controller>.spec.ts`
**Priority**: Must-Have
**Traces to**: `REQ-<SLUG>-001`

---

## E2E Tests (Playwright)

### Flow: <Tên user flow>

#### TC-020: Happy path

```gherkin
Given user navigates to <route>
  And user is logged in as <persona>
When  user performs <action sequence>
Then  user sees <expected UI state>
  And database reflects <expected data change>
```

**File**: `apps/web/e2e/<feature>.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-<SLUG>-001` Scenario 1

---

#### TC-021: Error / edge case

```gherkin
Given user navigates to <route>
  And <error condition>
When  user performs <action>
Then  user sees error message "<message>"
  And no data is persisted
```

**File**: `apps/web/e2e/<feature>.spec.ts`
**Priority**: Must-Have
**Traces to**: `US-<SLUG>-001` Scenario 2

---

## Test Coverage Checklist

- [ ] Tất cả `US-<SLUG>-###` Scenario 1 (happy path) có TC tương ứng
- [ ] Tất cả `US-<SLUG>-###` Scenario 2+ (edge cases) có TC tương ứng
- [ ] Business rules có anti-abuse đã có TC kiểm tra
- [ ] Error states (400, 401, 403, 404, 422, 500) có TC
- [ ] Idempotency / double-submit scenarios có TC
- [ ] Race condition / concurrency scenarios có TC (nếu applicable)
