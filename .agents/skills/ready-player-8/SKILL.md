```markdown
# ready-player-8 Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill teaches you how to effectively contribute to the `ready-player-8` Swift codebase. You'll learn the project's coding conventions, file organization strategies, and the most common development workflows—ranging from adding new navigation tabs, syncing Supabase schemas, implementing features with tests and docs, preparing releases, expanding AI tool access, and refactoring large files. Each workflow is documented with step-by-step instructions and associated commands for streamlined collaboration.

## Coding Conventions

- **File Naming:**  
  Use PascalCase for all Swift files.  
  _Example:_  
  ```
  FieldOpsView.swift
  FinanceHubView.swift
  SupabaseService.swift
  ```

- **Import Style:**  
  Use relative imports between modules/files.  
  _Example:_  
  ```swift
  import Foundation
  import SwiftUI
  ```

- **Export Style:**  
  Use named exports for classes, structs, and functions.  
  _Example:_  
  ```swift
  public struct FinanceHubView: View {
      // ...
  }
  ```

- **Directory Structure:**  
  - Main app code in `ready player 8/`
  - Tests in `ready player 8Tests/`
  - Documentation and SQL schemas in `docs/`

- **Commit Messages:**  
  Freeform, usually descriptive, average 62 characters.

## Workflows

### Add or Expand Navigation Tab
**Trigger:** When introducing a new major feature area or expanding the app's navigation with a new tab.  
**Command:** `/add-tab`

1. Edit or expand `ready player 8/ContentView.swift` to add the new tab and navigation logic.
2. Create a new View file for the tab (e.g., `ready player 8/FieldOpsView.swift`).
3. Implement sub-tabs or features within the new View file.
4. Update related models or helpers if needed.

_Example snippet:_
```swift
TabView {
    FieldOpsView()
        .tabItem {
            Label("Field Ops", systemImage: "map")
        }
    // ...other tabs
}
```

---

### Supabase Schema and Backend Sync
**Trigger:** When adding/updating database tables or expanding Supabase integration.  
**Command:** `/new-table`

1. Edit `docs/supabase-schema.sql` to add or update tables.
2. Update or create corresponding DTOs and backend sync logic in `ready player 8/SupabaseService.swift` or related files.
3. Enable RLS and set up policies as needed.
4. Wire up new tables to app panels or sync managers.

_Example snippet (SQL):_
```sql
CREATE TABLE missions (
    id uuid PRIMARY KEY,
    name text,
    status text
);
```
_Example snippet (Swift):_
```swift
struct Mission: Codable {
    let id: UUID
    let name: String
    let status: String
}
```

---

### Feature Development, Implementation, Tests & Docs
**Trigger:** When delivering a complete feature with code, tests, and documentation.  
**Command:** `/feature`

1. Implement feature logic in one or more `ready player 8/*.swift` files.
2. Add or update tests in `ready player 8Tests/ready_player_8Tests.swift`.
3. Update or create documentation in `docs/` (e.g., `docs/IAP-Setup-Guide.md`).

_Example snippet (test):_
```swift
func testMissionCreation() {
    let mission = Mission(id: UUID(), name: "Test", status: "active")
    XCTAssertEqual(mission.status, "active")
}
```

---

### App Store Build and Release Prep
**Trigger:** When preparing a new build for App Store or TestFlight.  
**Command:** `/release`

1. Update `ready player 8.xcodeproj/project.pbxproj` for version/build bump.
2. Edit `ready player 8/Info.plist` and `ready player 8/ready_player_8.entitlements` as needed.
3. Update or add `docs/AppStore-Metadata.md` or related metadata files.
4. Optionally update app icon assets.

---

### AI Tool MCP Server Expansion
**Trigger:** When adding new AI-accessible tools to the MCPServer for Angelic AI.  
**Command:** `/add-mcp-tool`

1. Edit or expand `ready player 8/MCPServer.swift` to add new tool definitions and logic.
2. Update related view files or models if new data/features are exposed.
3. Document new tools in commit messages or docs.

_Example snippet:_
```swift
func registerTool(name: String, handler: @escaping (ToolInput) -> ToolOutput) {
    // Tool registration logic
}
```

---

### Refactor or Split Monolithic File
**Trigger:** When a file (usually `ContentView.swift`) becomes too large and needs modularization.  
**Command:** `/refactor-split`

1. Identify logical components or feature areas within the monolithic file.
2. Extract each area into a new `ready player 8/*.swift` file.
3. Reduce `ContentView.swift` to navigation and glue logic.
4. Verify build and update imports/usages.

_Example:_
- Move mission-related views from `ContentView.swift` to `MissionView.swift`.

---

## Testing Patterns

- **Framework:** Unknown (likely XCTest or Swift's built-in testing)
- **Test Files:** Located in `ready player 8Tests/`, matching pattern `*.test.*`
- **Example Test:**
  ```swift
  import XCTest
  @testable import ready_player_8

  class ready_player_8Tests: XCTestCase {
      func testExample() {
          // Test logic here
      }
  }
  ```

## Commands

| Command         | Purpose                                                        |
|-----------------|----------------------------------------------------------------|
| /add-tab        | Add or expand a navigation tab with associated views           |
| /new-table      | Add/update Supabase tables and sync backend models             |
| /feature        | Implement a new feature with tests and documentation           |
| /release        | Prepare and document a new App Store/TestFlight release        |
| /add-mcp-tool   | Add a new AI-accessible tool to the MCPServer                  |
| /refactor-split | Refactor or modularize a large file for maintainability        |
```