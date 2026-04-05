---
phase: 01-secrets-infrastructure-cleanup
plan: 03
subsystem: infra
tags: [gitignore, xcode, deployment-target, swc, cleanup]

# Dependency graph
requires: []
provides:
  - Comprehensive .gitignore covering secrets, build artifacts, IDE files
  - Clean web/package.json without platform-specific SWC dependency
  - Valid iOS deployment target (18.2) across all build configurations
affects: [all-phases, ios-builds, web-builds, ci-cd]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ".gitignore covers .env*, .DS_Store, xcuserdata/, DerivedData/, *.pem, node_modules/, .next/"

key-files:
  created:
    - .gitignore
  modified:
    - web/package.json
    - web/package-lock.json
    - "ready player 8.xcodeproj/project.pbxproj"

key-decisions:
  - "6 occurrences of IPHONEOS_DEPLOYMENT_TARGET found (plan expected 3) -- all replaced to 18.2"

patterns-established:
  - "Comprehensive .gitignore as baseline for all future commits"

requirements-completed: [SEC-09, SEC-10, SEC-11, INFRA-01]

# Metrics
duration: 51min
completed: 2026-04-05
---

# Phase 1 Plan 3: Repo Cleanup and Infrastructure Fixes Summary

**Comprehensive .gitignore, removed platform-specific SWC dep, fixed iOS deployment target from invalid 26.2 to 18.2**

## Performance

- **Duration:** 51 min
- **Started:** 2026-04-05T04:03:58Z
- **Completed:** 2026-04-05T04:54:00Z
- **Tasks:** 2 of 3 completed (1 awaiting human action)
- **Files modified:** 4

## Accomplishments
- Replaced single-line .gitignore with comprehensive rules covering secrets, build artifacts, IDE files, certs, and OS debris
- Removed @next/swc-darwin-arm64 from web/package.json (platform-specific dep that breaks Linux CI)
- Removed orphaned directories: "untitled folder/" and "web/src/.next/"
- Fixed all 6 occurrences of IPHONEOS_DEPLOYMENT_TARGET from invalid 26.2 to valid 18.2

## Task Commits

Each task was committed atomically:

1. **Task 1: Rotate Supabase secret key** - PENDING (checkpoint:human-action -- requires manual key rotation in Supabase dashboard)
2. **Task 2: Fix .gitignore, remove SWC dep, clean orphaned folders** - `6a1e65c` (chore)
3. **Task 3: Fix iOS deployment target** - `8d247f2` (fix)

## Files Created/Modified
- `.gitignore` - Comprehensive ignore rules for secrets, build artifacts, IDE files, certificates
- `web/package.json` - Removed @next/swc-darwin-arm64 platform-specific dependency
- `web/package-lock.json` - Regenerated after dependency removal
- `ready player 8.xcodeproj/project.pbxproj` - iOS deployment target changed from 26.2 to 18.2 (6 occurrences)

## Decisions Made
- Plan documented 3 occurrences of IPHONEOS_DEPLOYMENT_TARGET = 26.2 but 6 were found (Debug, Release, and Test configs for both app and test targets); all 6 replaced to 18.2

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Additional deployment target occurrences**
- **Found during:** Task 3
- **Issue:** Plan expected 3 occurrences of IPHONEOS_DEPLOYMENT_TARGET = 26.2 but 6 existed
- **Fix:** Replaced all 6 occurrences with 18.2 using replace_all
- **Files modified:** ready player 8.xcodeproj/project.pbxproj
- **Verification:** grep confirms 6 occurrences of 18.2, 0 of 26.2, macOS target unchanged
- **Committed in:** 8d247f2

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Minor -- more occurrences than documented, all correctly fixed.

## Issues Encountered
None.

## User Setup Required

**Supabase secret key rotation required (SEC-08).** The service_role key was committed in .env.local and is exposed in git history.

Steps for the user:
1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to Project Settings -> API
4. Under "service_role" (secret), regenerate/rotate the key
5. Copy the NEW service_role key
6. Update `web/.env.local` with: `SUPABASE_SERVICE_ROLE_KEY=your_new_key_here`
7. If deployed on Vercel, update the env var in Vercel Dashboard -> Project -> Settings -> Environment Variables

## Known Stubs
None -- no stubs introduced.

## Next Phase Readiness
- .gitignore and repo cleanliness ready for all future work
- iOS project buildable with valid deployment target
- Web dependencies clean for CI/CD
- **Blocker:** SEC-08 (Supabase key rotation) still requires human action before the compromised key is invalidated

---
*Phase: 01-secrets-infrastructure-cleanup*
*Completed: 2026-04-05 (Tasks 2-3; Task 1 pending human action)*

## Self-Check: PASSED

All files exist, all commits verified.
