# Coding Conventions

**Analysis Date:** 2026-04-04

## Overview

This project spans two major platforms with distinct conventions:

- **Swift/SwiftUI**: iOS/macOS/visionOS app (ConstructionOS native)
- **TypeScript/React + Next.js**: Web platform

Each has its own naming, style, and structural patterns that must be followed consistently.

---

## Swift Conventions

### File Organization & MARK Comments

**Files use explicit `// MARK:` sections** to organize code logically. Every major file includes a header:

```swift
// MARK: - ========== FileName.swift ==========
```

Sub-sections separate concerns:

```swift
// MARK: - Auth Gate View (Procore-style with 2FA)
// MARK: - Sub-views
// MARK: - Keychain Tests
// MARK: - API Key Setup
// MARK: - Claude API with MCP Tool Use
// MARK: - Persistence
```

**Apply to all files:** Use section separators generously. When writing new Swift code, add a top-level MARK comment with the filename and purpose.

### Naming Patterns

**Views:**
- Use suffix `View` for all SwiftUI views: `ProjectsView`, `AuthGateView`, `MoneyLensView`, `AngelicAIView`
- Extracted sub-views are typically private var-computed properties within parent (e.g., `projectsHeader`, `statsRow`) or separate Views with descriptive names

**Models & Structs:**
- PascalCase for all model names: `SupabaseProject`, `WealthOpportunity`, `DecisionJournalEntry`, `PsychologySession`
- Enum cases: camelCase: `case login, signup, twoFactor, forgotPassword`
- Computed properties: camelCase with semantic meaning: `avgScore`, `wealthSignal`, `signalColor`

**Functions & Properties:**
- camelCase for all function and property names
- Private properties: prefix with `private let`, `@State private var`
- Derived properties: computed vars using `var` with getter
- Plurals for collections: `projects`, `mockProjects`, `displayProjects`

**AppStorage & UserDefaults Keys:**
- Hierarchical dot notation: `ConstructOS.Wealth.PsychologyScore`, `ConstructOS.AngelicAI.SessionID`, `ConstructOS.Integrations.Backend.BaseURL`
- Pattern: `{appName}.{feature}.{property}`
- Apply to all persistent state in UserDefaults

### Code Style & Structure

**View Hierarchy:**
- Prefer computed properties for sub-views over inline closures
- Use `var body: some View` at top, then private sub-views below
- LazyVStack/VStack with consistent spacing (usually 12–16)

**State Management:**
- `@State private var` for local UI state
- `@AppStorage` for persisted simple values (strings, ints, booleans)
- `@StateObject` for complex observable objects
- `@ObservedObject` when passing in shared instances (e.g., `@ObservedObject var profileStore = UserProfileStore.shared`)
- `@EnvironmentObject` for app-wide services (e.g., `SupabaseService`)

**Closures & Callbacks:**
- Use `@escaping` for async callbacks
- Prefer `Task { await func() }` over GCD for async work
- Use `.task { await loadData() }` modifier on views for onAppear-like behavior

**Styling:**
- Use `Theme` struct colors globally: `Theme.bg`, `Theme.surface`, `Theme.accent`, `Theme.gold`, `Theme.text`, `Theme.muted`
- Apply `.premiumGlow(cornerRadius: 16, color: Theme.accent)` for elevated cards (View extension in Theme)
- Fonts: `.system(size:, weight:)` with explicit weights (.heavy, .semibold, .medium)
- Letter spacing: `.tracking(2)` or `.tracking(4)` for titles

**Error Handling:**
- Use `AppError` enum from `AppError.swift` with cases: `.network()`, `.supabaseNotConfigured`, `.supabaseHTTP()`, `.decoding()`, `.authFailed()`, `.validationFailed()`, `.permissionDenied()`, `.unknown()`
- All errors conform to `LocalizedError & Identifiable`
- Check `error.isRetryable` before auto-retry logic
- Use `error.severity` to determine alert style (`.info`, `.warning`, `.error`)

**Validation:**
- Use `InputValidator` static methods: `.email()`, `.required()`, `.numeric()`, `.password()`, `.minLength()`
- Each validator returns `{ isValid: Bool, message: String }`

### Import Order

1. System frameworks: `import SwiftUI`, `import Foundation`, `import Combine`
2. Third-party: `import Anthropic` (if using Claude SDK)
3. No relative imports (single module)

### Comments

**When to comment:**
- Explain `why`, not `what`: "Filter to active projects only" not "if status != Delayed"
- Document non-obvious logic: rate limiting, retry strategies, complex calculations
- Mark sections with `// MARK: -` for navigation

**JSDoc/documentation:**
- Not commonly used in this codebase; prefer clear code
- Comments above complex computed properties: `// Average score excluding failed projects`

---

## TypeScript / Next.js Conventions

### File Organization

**Project Structure:**

```
web/
├── src/
│   ├── app/
│   │   ├── api/           # Route handlers
│   │   ├── [page]/page.tsx    # Pages
│   │   ├── [page]/layout.tsx   # Layouts
│   │   ├── [page]/error.tsx    # Error boundaries
│   │   └── components/    # App-specific components
│   ├── lib/
│   │   ├── supabase/      # Supabase client, fetch, types
│   │   ├── hooks/         # Custom hooks (useFetch, etc)
│   │   ├── subscription/  # Feature access, tier logic
│   │   ├── links/         # Link validation, external references
│   │   ├── seo.ts         # Metadata registry
│   │   ├── nav.ts         # Navigation structure
│   │   └── *.ts           # Utilities
│   └── __tests__/         # Test files
├── eslint.config.mjs      # ESLint rules (flat config)
├── tsconfig.json          # TypeScript config
└── vitest.config.ts       # Test runner config
```

### Naming Patterns

**Files:**
- kebab-case for routes: `web/src/app/projects/page.tsx`, `web/src/app/api/chat/route.ts`
- camelCase for utilities and libraries: `web/src/lib/useFetch.ts`, `web/src/lib/seo.ts`
- PascalCase for React components (rarely extracted from pages): `AngelicFlowStrip.tsx`

**Functions & Variables:**
- camelCase for all function and variable names
- `async` functions: `fetchTable()`, `getAuthenticatedClient()`, `insertRow()`
- Hook functions: prefix `use`: `useFetch()`, `useSubscriptionTier()`
- Constant arrays/objects: SCREAMING_SNAKE_CASE if config, camelCase if data: `RATE_LIMIT`, `WINDOW_MS`, `pageMetadata`, `navGroups`

**Type Names:**
- PascalCase: `type Project = { ... }`, `type RentalLead = { ... }`
- Suffixes: `_ledger`, `_messages`, `_ai_messages` for table names (snake_case in DB)
- Use `type` not `interface` for consistency

### Code Style

**TypeScript:**
- Strict mode enabled (`"strict": true` in tsconfig)
- Target ES2017, ESNext modules
- No implicit any; all return types annotated

**Imports:**
- Use path aliases: `@/lib`, `@/app/components`
- Organized in groups:
  1. Next.js framework imports
  2. React imports
  3. Third-party libraries
  4. Local imports (path aliases)

**Async Patterns:**
- Server functions: `async function fetchTable<T>(...)`
- Route handlers: `export async function POST(req: Request) { ... }`
- Client hooks: `useEffect(() => { fetch(...) })` with cleanup
- Always check `res.ok` before parsing JSON: `if (!res.ok) throw new Error(...)`

**Error Handling:**
- Try-catch in async functions: wrap JSON parsing, API calls
- Return `NextResponse.json({ error: "message" }, { status: 400 })`
- Log to console: `console.error("[context] message:", err)`
- Fallback to safe defaults on error (empty arrays, null data)

**Validation:**
- Inline in route handlers: check `typeof`, `.trim()`, required fields before DB insert
- Return 400 with descriptive error message if validation fails

**Rate Limiting:**
- Implement per-IP in-memory map for single-instance deployments
- Key pattern: `rateLimit.get(ip)`, check count and resetAt
- Prune stale entries when map exceeds 10,000 entries

### Component Patterns

**Server Components (default):**
- Fetch data directly in component
- Use `async` component if needed
- No hooks, no event handlers

**Client Components:**
- Add `"use client"` directive at top of file
- Use `useState`, `useEffect`, `useFetch` hook
- `useState` for form inputs and local UI state

**Metadata:**
- Import from `@/lib/seo`: `const metadata = getPageMetadata("projects")`
- Export `metadata` const in `page.tsx` (server component)
- Type: `Metadata` from `next`

### Styling

**CSS:**
- Inline `style={}` objects (no external CSS files in most pages)
- Custom properties: `var(--surface)`, `var(--accent)`, `var(--muted)`, `var(--green)`, `var(--purple)`, `var(--cyan)`, `var(--gold)`, `var(--red)`
- Design tokens: `padding: 20`, `borderRadius: 14`, `fontSize: 12`, `fontWeight: 800`

**Tailwind:**
- Not heavily used (mostly inline styles)
- When used, prefer semantic utilities

### Comments

**When to comment:**
- Rate limiting logic, buffer management, memory cleanup
- Non-obvious state transitions
- TODO/FIXME for known gaps

**Example:**
```typescript
// Prevent unbounded memory growth — prune stale entries when map exceeds limit
if (rateLimit.size > 10_000) {
  for (const [key, val] of rateLimit) {
    if (now > val.resetAt) rateLimit.delete(key);
  }
}
```

---

## Cross-Platform Patterns

### Model Consistency

Both platforms use the same conceptual models, represented in:

**Swift:**
- `SupabaseProject`, `SupabaseContract`, `SupabaseWealthOpportunity` in `SupabaseService.swift`
- Wealth models in `WealthShared.swift`

**TypeScript:**
- `type Project`, `type Contract`, `type RentalLead` in `web/src/lib/supabase/types.ts`

**Mapping:** Both use Supabase as source of truth. Field names aligned: `full_name` (DB) → `fullName` (Swift/TS objects)

### AppStorage & UserDefaults Keys

Consistent hierarchy used on both platforms:

```
ConstructOS.{Feature}.{Property}
ConstructOS.Wealth.PsychologyScore
ConstructOS.AngelicAI.SessionID
ConstructOS.Integrations.Backend.BaseURL
```

### Error Recovery

**Patterns across both:**
- Log errors with context: file, function, what operation failed
- Provide user-friendly messages (no stack traces)
- Distinguish retryable from non-retryable errors
- Offer fallback UI: demo data (mobile), error boundary (web)

---

## Linting & Formatting

**TypeScript (web):**
- Tool: ESLint 9 (flat config)
- Config: `web/eslint.config.mjs`
- Rules: Next.js core web vitals + TypeScript
- Run: `npm run lint` (no --fix used automatically)

**Swift:**
- No linter enforced (SwiftUI formatting conventions followed by convention)
- Code structure enforced via Xcode build phases

---

## Summary

| Aspect | Swift | TypeScript |
|--------|-------|-----------|
| **File Org** | MARK comments, views + models | app/ routes, lib/ utilities |
| **Naming** | PascalCase types, camelCase props | kebab-case routes, camelCase utils |
| **State** | @State, @AppStorage, @ObservedObject | useState, hooks |
| **Async** | Task, async/await | async/await, useEffect |
| **Errors** | AppError enum | NextResponse.json with status |
| **Styling** | Theme struct colors | CSS custom properties |
| **Comments** | MARK sections, explain why | Rate limit, state logic |

---

*Convention analysis: 2026-04-04*
