# Testing Patterns

**Analysis Date:** 2026-04-04

## Overview

The project has two separate testing approaches:

- **Swift Tests**: Using Swift Testing framework (native, modern macro-based)
- **TypeScript Tests**: Using Vitest with Node environment

Both are integration-style tests (testing behavior, not isolated units). Full end-to-end testing is minimal; UI tests exist but are template stubs.

---

## Swift Testing (iOS/macOS/visionOS)

### Test Framework

**Runner:**
- Swift Testing (native framework, macOS 15.6+, iOS 18.0+)
- Config: Built into Xcode, no config file needed
- Macros: `@Test`, `#expect()` for assertions

**Test Targets:**
- `ready player 8Tests` — unit and integration tests
- `ready player 8UITests` — UI automation tests (launch tests only)

**Run Commands:**
```bash
# In Xcode: Cmd+U or Product > Test
# Via CLI:
xcodebuild test -scheme "ready player 8" -configuration Debug
```

### Test File Organization

**Location:**
- `ready player 8Tests/ready_player_8Tests.swift` — Main test suite
- `ready player 8UITests/ready_player_8UITests.swift` — UI tests
- `ready player 8UITests/ready_player_8UITestsLaunchTests.swift` — Launch tests (template)

**Structure:**
- Single main test struct: `struct ConstructionOSTests { }`
- All tests as methods with `@Test` macro
- Organized into sections with `// MARK: - [Category] Tests`

**Test File Example:**
```swift
import Testing
@testable import ready_player_8

struct ConstructionOSTests {

    // MARK: - Keychain Tests

    @Test func keychainSaveAndRead() {
        let key = "test.keychain.\(UUID().uuidString)"
        KeychainHelper.save(key: key, data: "test-secret-value")
        let result = KeychainHelper.read(key: key)
        #expect(result == "test-secret-value")
        KeychainHelper.delete(key: key)
        #expect(KeychainHelper.read(key: key) == nil)
    }
}
```

### Test Structure & Assertions

**Test Lifecycle:**
- No setup/teardown; each test is independent
- Use UUID for unique test keys to avoid state pollution: `"test.keychain.\(UUID().uuidString)"`
- Clean up after (delete UserDefaults keys, Keychain entries)

**Assertions:**
- Use `#expect()` macro instead of `XCTAssert*`
- Syntax: `#expect(condition == expected)` or `#expect(condition)`
- Message support: `#expect(value == expected, "Human readable message")`

**Pattern - JSON Persistence:**
```swift
@Test func saveAndLoadJSON() {
    let key = "test.json.\(UUID().uuidString)"
    let data = ["hello", "world"]
    saveJSON(key, value: data)
    let loaded: [String] = loadJSON(key, default: [])
    #expect(loaded == data)
    UserDefaults.standard.removeObject(forKey: key)
}
```

**Pattern - Codable Round-Trip:**
```swift
@Test func changeOrderCodable() {
    let co = ChangeOrderItem(number: "CO-001", title: "Test", amount: "$1,000", ...)
    let data = try? JSONEncoder().encode(co)
    #expect(data != nil)
    let decoded = try? JSONDecoder().decode(ChangeOrderItem.self, from: data!)
    #expect(decoded?.title == "Test")
    #expect(decoded?.status == .pending)
}
```

**Pattern - Enum/State Tests:**
```swift
@Test func rolePresetRawValues() {
    #expect(OpsRolePreset(rawValue: "SUPER") == .superintendent)
    #expect(OpsRolePreset(rawValue: "PM") == .projectManager)
    #expect(OpsRolePreset(rawValue: "INVALID") == nil)
}
```

### Mocking

**Approach:**
- Minimal mocking — tests use real objects with live implementations
- Mock data provided as global `let` arrays: `mockProjects`, `mockContracts`, `mockMarketData` in `ContentView.swift`
- Supabase tests check local state without network calls

**Pattern - Supabase Service Tests:**
```swift
@Test @MainActor func supabaseSignOutClearsState() {
    let svc = SupabaseService()
    svc.accessToken = "test-token"
    svc.currentUserEmail = "test@test.com"
    svc.signOut()
    #expect(svc.accessToken == nil)
    #expect(svc.currentUserEmail == nil)
    #expect(svc.isAuthenticated == false)
}
```

**Pattern - MCP Tool Tests (integration):**
```swift
@Test @MainActor func mcpGetProjects() {
    let server = MCPToolServer.shared
    let result = server.executeTool(name: "get_projects", input: [:])
    #expect(result.contains("Metro Tower"))
    #expect(result.contains("Budget:"))
}
```

**What to Mock:**
- Network calls (don't hit Supabase unless intentional)
- Time-based operations (Date.now) — use fixed dates in test data

**What NOT to Mock:**
- JSON serialization (test real Codable implementations)
- UserDefaults (test persistence fully)
- UI state (@State, @AppStorage)
- Model logic (computed properties, filtering)

### Test Coverage

**Requirements:** No enforced target.

**Current Coverage:**
- Keychain operations (6 tests)
- JSON persistence (3 tests)
- Input validation (6 tests)
- MCP tool execution (8 tests)
- Model Codable round-trips (8 tests)
- Supabase service state (3 tests)
- Deep link routing (6 tests)
- Theme and colors (1 test)
- Analytics engine (3 tests)
- Crash reporter (1 test)
- Feature flags (1 test)
- Rental operations (3 tests)
- Navigation tabs (3 tests)
- Total: **70+ tests**

**Gaps:**
- No UI component tests (views not unit tested separately)
- No performance/stress tests
- No async data loading tests (Supabase fetch operations)
- No race condition tests
- AngelicAI API integration not tested

### Test Data & Fixtures

**Location:**
- `ContentView.swift` contains global mock arrays: `mockProjects`, `mockContracts`, `mockMarketData`, `feedbackInsights`
- `WealthShared.swift` contains static data: `moneyLensPrinciples`, `wealthArchetypes`, `leverageCategories`
- Inline in tests: unique test keys using UUID

**Pattern:**
```swift
let projects = [
    SupabaseProject(name: "Riverside Lofts", client: "Acme", type: "Commercial", ...),
    SupabaseProject(name: "Harbor Crossing", client: "Dev Corp", type: "Residential", ...)
]
```

**Creating Test Data:**
- Use struct initializers directly: `ChangeOrderItem(number: "CO-001", title: "Test", ...)`
- Inline JSON test data not used (prefer struct init)

### Running Tests

**Individual test:**
```bash
xcodebuild test -scheme "ready player 8" -only ConstructionOSTests/keychainSaveAndRead
```

**All tests:**
```bash
xcodebuild test -scheme "ready player 8"
```

**In Xcode:**
- Open Test Navigator (Cmd+6)
- Click diamond to run individual tests or all
- View results in Issue Navigator

---

## TypeScript Testing (Next.js Web)

### Test Framework

**Runner:**
- Vitest 3.2.4
- Config: `web/vitest.config.ts`
- Environment: Node (not jsdom, no browser APIs)

**Assertion Library:**
- Node assert (Node built-in) — `expect()` from Vitest

**Run Commands:**
```bash
npm run test              # Run once
npm run test -- --watch  # Watch mode
npm run test -- --coverage # Code coverage
```

### Test File Organization

**Location:**
- `web/src/__tests__/api.test.ts` — Main test file
- Pattern: `src/**/*.test.ts` or `src/**/*.test.tsx`

**Naming:**
- Describe blocks by feature: `describe("Rate Limiter", ...)`
- Test names as readable sentences: `it("allows requests under limit", ...)`

**Structure:**
```typescript
import { describe, it, expect } from "vitest";
import { checkRateLimit } from "@/lib/rate-limit";

describe("Rate Limiter", () => {
  it("allows requests under limit", () => {
    const ip = "test-" + Date.now();
    expect(checkRateLimit(ip, 5)).toBe(true);
    expect(checkRateLimit(ip, 5)).toBe(true);
    expect(checkRateLimit(ip, 5)).toBe(true);
  });

  it("blocks requests over limit", () => {
    const ip = "blocked-" + Date.now();
    for (let i = 0; i < 5; i++) checkRateLimit(ip, 5);
    expect(checkRateLimit(ip, 5)).toBe(false);
  });
});
```

### Test Structure & Patterns

**Setup Pattern:**
- No beforeEach/afterEach; use unique IDs (timestamps, random strings) to avoid state collision
- Each test is fully isolated

**Assertion Pattern:**
```typescript
expect(value).toBe(expected)           // Strict equality
expect(value).toContain("substring")   // String/array contains
expect(value).toBeDefined()            // Not undefined
expect(value).toBeGreaterThanOrEqual() // Numeric comparison
expect(array).toHaveLength(n)          // Array length
```

**Async Testing:**
```typescript
it("fetches data", async () => {
  const data = await fetchTable("projects");
  expect(data).toBeDefined();
  expect(data.length).toBeGreaterThan(0);
});
```

**Error Testing:**
```typescript
it("returns error for invalid JSON", () => {
  const body = '{ invalid json }';
  expect(() => JSON.parse(body)).toThrow();
});
```

### Mocking

**Current Approach:**
- No mocking framework in use
- Tests import real implementations
- Mock data embedded in test functions: `const ip = "test-" + Date.now()`
- Supabase operations not tested (would require network)

**If Mocking Needed:**
- Install: `npm install -D vitest --allow-scripts` (already have vitest)
- Use `vi.mock()` to mock imports
- Mock example:
```typescript
vi.mock("@/lib/rate-limit", () => ({
  checkRateLimit: vi.fn(() => true)
}));
```

**What to Mock (if extending):**
- External API calls (Supabase, Anthropic)
- File system operations
- Date/time (use `vi.useFakeTimers()`)

**What NOT to Mock:**
- Utility functions being tested
- Data transformation logic
- SEO metadata generation

### Test Coverage

**Requirements:** No enforced target.

**Current Coverage:**
- Rate limiter (2 tests)
- SEO metadata (3 tests)
- Navigation structure (3 tests)
- Total: **8 tests** (minimal)

**Gaps:**
- No API route tests (POST handlers like `/api/leads`)
- No Supabase integration tests
- No form validation tests
- No component rendering tests (would need jsdom)
- No end-to-end tests

### Running Tests

**All tests:**
```bash
npm run test
```

**Watch mode (development):**
```bash
npm run test -- --watch
```

**Single file:**
```bash
npm run test -- src/__tests__/api.test.ts
```

**Matching pattern:**
```bash
npm run test -- --grep "Rate Limiter"
```

**Coverage:**
```bash
npm run test -- --coverage
```

---

## Test Strategy & Philosophy

### What IS Tested

**Swift:**
- Data persistence (UserDefaults, Keychain, JSON encoding)
- Model validation (Codable round-trips)
- Business logic (filtering, averaging, state transitions)
- Integrations (Supabase service, MCP tools, deep links)

**TypeScript:**
- Utility functions (rate limiting, SEO metadata)
- Data validation (input checks in route handlers)
- Navigation structure (no broken links)

### What is NOT Tested

**Swift:**
- UI rendering (SwiftUI views not unit tested)
- Async data loading (network operations)
- Performance/stress

**TypeScript:**
- API route handlers (POST/GET logic)
- Supabase queries
- Component rendering
- Client-side hooks

### Why This Approach

- **Integration-focused**: Tests real behavior, not mocked internals
- **Minimal maintenance**: Fewer mocks = fewer test breaks when code changes
- **Build confidence**: Tests cover critical paths (persistence, validation, tool execution)
- **Quick iteration**: No complex test infrastructure to slow down development

### Adding New Tests

**For Swift feature:**
1. Add `@Test func feature_name() { ... }` in `ConstructionOSTests`
2. Use UUID for unique keys: `"test.\(UUID().uuidString)"`
3. Clean up state (delete UserDefaults, Keychain keys)
4. Assert on side effects, not just return values

**For TypeScript utility:**
1. Add describe/it blocks in `web/src/__tests__/api.test.ts`
2. Use unique identifiers (timestamps): `"test-" + Date.now()`
3. Import the function and test its output
4. Don't mock unless necessary

---

## CI/CD & Automation

**Local Verification:**
```bash
# Swift (in Xcode or via CLI)
xcodebuild test -scheme "ready player 8"

# TypeScript
npm run test
npm run lint
npm run typecheck
```

**Pre-commit:**
- No hooks enforced currently
- Manual run: `npm run verify` (lint + typecheck + build)

**Test Execution Order:**
- Fast: Utility tests (TypeScript) — ~1 second
- Medium: Persistence tests (Swift) — ~5 seconds
- Slow: MCP tool tests (Swift) — ~3 seconds

---

## Common Issues & Fixes

**Swift:**

| Issue | Cause | Fix |
|-------|-------|-----|
| "Test state polluted" | Reusing UserDefaults keys | Use UUID in key name |
| "#expect failed" | Async operation not awaited | Add `@MainActor` to test |
| "MCP tool returns empty" | Tool not registered | Check MCPToolServer.shared.toolDefinitions |

**TypeScript:**

| Issue | Cause | Fix |
|-------|-------|-----|
| Import fails | Path alias not resolved | Check vitest.config.ts `resolve.alias` |
| Async hangs | Promise not awaited | Use `await` or return Promise |
| "Cannot find module" | Dependencies not installed | Run `npm install` |

---

## Future Improvements

**High Priority:**
- Add API route handler tests (POST, GET in web/src/app/api/)
- Add async data loading tests (Supabase fetch operations)
- Add E2E test smoke checks (link health, basic navigation)

**Medium Priority:**
- Add UI component snapshot tests (Swift)
- Add form validation tests (TypeScript)
- Add performance benchmarks (MCP tools, Supabase queries)

**Low Priority:**
- Full accessibility testing (WCAG)
- Browser compatibility testing (web)
- Security/fuzzing tests

---

*Testing analysis: 2026-04-04*
