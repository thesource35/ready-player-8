---
phase: 13-document-management-foundation
verified: 2026-04-19T15:50:00Z
status: partial
score: 5/5 must-haves verified (code); UAT pending for DOC-01/04/05
re_verification: false
human_verification:
  - test: "Upload a PDF and a JPEG to a project entity from the web (/projects/[id]) using the AttachmentList UploadButton"
    expected: "Both files appear in the attachment list with filename, size, MIME type; clicking the row opens DocumentPreview inline (iframe for PDF, img for JPEG)"
    why_human: "Full upload → preview chain requires a live Supabase Storage bucket, signed URL generation, and browser rendering — cannot be verified without a running dev server, authenticated session, and visual inspection"
  - test: "Upload a HEIC photo from iPhone simulator (or real device) via DocumentAttachmentsView on a project, RFI, submittal, and change order"
    expected: "HEIC is converted to JPEG via HEICConverter before upload; the resulting attachment is visible on all 4 entity detail surfaces with correct MIME type image/jpeg; preview opens via PDFKit/AsyncImage"
    why_human: "HEIC conversion path requires a real iOS photo library, and the 4-entity integration requires tapping through ProjectsView, OperationsCommercial (RFITrackerPanel, SubmittalLogPanel), and OperationsCore (ChangeOrderTrackerPanel) — each sheet is presented via .sheet(item:) and needs visual confirmation"
  - test: "Upload a new version of an existing document via /documents/[chainId]/versions on web"
    expected: "Version list shows the prior version with is_current=false and the new version with is_current=true; prior content is still downloadable via signed URL; version_chain_id links both rows"
    why_human: "Version flip is driven by the create_document_version RPC atomically; confirming the visual order, current-version highlight, and prior-version download requires a browser walk-through"
  - test: "Oversized upload (>50MB) and unsupported MIME (e.g. .exe) rejection flow"
    expected: "Web returns 413/415 with a user-readable error toast; iOS surfaces AppError.fileTooLarge / AppError.unsupportedFileType via the Retry affordance"
    why_human: "Error UX correctness (toast color, retry button placement) cannot be verified programmatically"
---

# Phase 13: Document Management Foundation Verification Report

**Phase Goal (ROADMAP.md line 61-63):** Users can upload, attach, preview, and version files across all entity types.

**Verified:** 2026-04-19T15:50:00Z
**Status:** partial
**Re-verification:** No — initial verification (created by Phase 28 retroactive sweep)
**Score:** 5/5 must-haves verified (code); UAT pending for DOC-01/04/05

## Goal Achievement

### Observable Truths

| # | Truth (from ROADMAP.md success criteria lines 65-69) | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can upload a PDF or image to Supabase Storage from iOS and web (DOC-01) | VERIFIED (code) / Partial (UAT) | Web: `POST /api/documents/upload` exists at `web/src/app/api/documents/upload/route.ts` with `validateDocumentUpload` gate on MIME/size (50 MB, ALLOWED_MIME = pdf/png/jpeg/heic/webp) — 13-02-SUMMARY.md lines 38-43. iOS: `DocumentSyncManager.uploadDocument(fileURL:entityType:entityId:orgId:uploadedBy:)` at `ready player 8/DocumentSyncManager.swift`, backed by `SupabaseService.uploadFile(bucket:path:data:mimeType:)` extension — 13-03-SUMMARY.md lines 40-48. HEIC converted via `HEICConverter.heicToJpeg` before upload (13-03-SUMMARY.md). UAT walk-through deferred to Plan 28-02. |
| 2 | User can download any attached file (DOC-02) | VERIFIED | Web: `GET /api/documents/[id]/sign` returns 1-hour signed URL at `web/src/app/api/documents/[id]/sign/route.ts` — 13-02-SUMMARY.md lines 54-57. iOS: `SupabaseService.createSignedURL(bucket:path:expiresIn:)` + `downloadFile(signedURL:)` — 13-03-SUMMARY.md. Activity-event emission on download path is closed via Phase 24 — cite `.planning/phases/24-document-activity-event-emission/24-01-SUMMARY.md` (trigger function) + `24-02-SUMMARY.md` (activity feed rendering) → INT-02 CLOSED. |
| 3 | User can attach files to a project, RFI, submittal, or change order (DOC-03) | VERIFIED | `POST /api/documents/attach` at `web/src/app/api/documents/attach/route.ts` writes to `cs_document_attachments` with entity_type whitelist (project/rfi/submittal/change_order and Phase 16 additions) — 13-02-SUMMARY.md. RLS predicate on `cs_document_attachments` originally referenced non-existent tables (INT-01) — **CLOSED by Phase 26**: stub tables created + RLS rebuilt for all 7 entity types → cite `.planning/phases/26-documents-rls-table-reconciliation/26-05-VERIFICATION.md` Query 3/4 (15 policies across 5 stub tables, all RLS-enabled). iOS: `DocumentAttachmentsView` integrated into `ProjectsView.ProjectDetailSheet`, `OperationsCommercial.RFITrackerPanel`, `OperationsCommercial.SubmittalLogPanel`, `OperationsCore.ChangeOrderTrackerPanel` — 13-05-SUMMARY.md lines 60-69. |
| 4 | User can preview PDFs and images in-app without downloading (DOC-04) | VERIFIED (code) / Partial (UAT) | Web: `DocumentPreview.tsx` at `web/src/components/documents/DocumentPreview.tsx` renders `<iframe>` for `application/pdf` and `<img>` for image MIMEs — 13-04-SUMMARY.md lines 52-55. iOS: `DocumentPreviewView.swift` uses PDFKit for PDFs and AsyncImage for images — 13-05-SUMMARY.md line 50. RLS predicate previously silently skipped three entity types → **CLOSED by Phase 26** (same citation as DOC-03). Browser + simulator UAT walk-through deferred. |
| 5 | User can view a list of prior versions of a revised document (DOC-05) | VERIFIED (code) / Partial (UAT) | Web: `GET /api/documents/[id]/versions` + `/documents/[chainId]/versions` page + `VersionHistory.tsx` component at `web/src/components/documents/VersionHistory.tsx` — 13-04-SUMMARY.md lines 51-53. iOS: `DocumentSyncManager.listVersions(chainId:)` + `DocumentVersionsView.swift` — 13-03/13-05-SUMMARYs. Backing SQL: `create_document_version` RPC atomically flips `is_current` on the version chain; partial unique index enforces one-current-per-chain (13-01-SUMMARY.md). UAT walk-through deferred. |

**Score:** 5/5 truths verified at the code layer. Partial status is driven by UAT gating for DOC-01/04/05, not by missing code.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20260406_documents.sql` | Schema: cs_documents + cs_document_attachments + version RPC | VERIFIED | File present; DDL migrated to live Supabase (confirmed via Phase 16-01 SUMMARY "Idempotent rerun" narrative); HEIC MIME in CHECK constraint (13-01 Rule 2 deviation) |
| `supabase/migrations/20260406001_documents_rls.sql` | 6 policies on cs_documents + cs_document_attachments + storage.objects | VERIFIED | File present; 7 `cs_documents` references (grep -c = 7); rebuilt in Phase 26 to cover all 7 entity types — see `.planning/phases/26-documents-rls-table-reconciliation/26-05-VERIFICATION.md` Query 5 |
| `web/src/lib/documents/validation.ts` | ALLOWED_MIME + MAX_BYTES + validateDocumentUpload | VERIFIED | 13-02 commit `a7dc337`; tests in `validation.test.ts` green |
| `web/src/app/api/documents/upload/route.ts` | POST multipart handler | VERIFIED | Exists; 13-02 commit `928ea91`; 29 vitest cases pass |
| `web/src/app/api/documents/[id]/sign/route.ts` | GET signed-URL handler | VERIFIED | Exists; 13-02-SUMMARY.md |
| `web/src/app/api/documents/[id]/versions/route.ts` | GET + POST version handlers | VERIFIED | Exists; 13-02-SUMMARY.md |
| `web/src/app/api/documents/attach/route.ts` | POST attach handler with entity_type whitelist | VERIFIED | Exists; 1 cs_document_attachments reference; Phase 26 preflight extended to 7 entity types |
| `web/src/app/api/documents/list/route.ts` | GET RLS-aware list endpoint | VERIFIED | Exists (13-04-SUMMARY.md) |
| `web/src/components/documents/AttachmentList.tsx` | Client list component | VERIFIED | Exists |
| `web/src/components/documents/UploadButton.tsx` | XHR upload with progress + retry | VERIFIED | Exists; 13-04 decisions note XHR chosen over fetch for upload progress |
| `web/src/components/documents/DocumentPreview.tsx` | iframe/img preview | VERIFIED | Exists |
| `web/src/components/documents/VersionHistory.tsx` | Version list + inline upload | VERIFIED | Exists |
| `web/src/app/documents/[chainId]/versions/page.tsx` | Version history route | VERIFIED | Exists (13-04-SUMMARY.md) |
| `ready player 8/DocumentModels.swift` | SupabaseDocument + DocumentEntityType + validators | VERIFIED | Exists; Phase 16 extended with GPS fields |
| `ready player 8/DocumentSyncManager.swift` | @MainActor sync singleton | VERIFIED | Exists (13-03-SUMMARY.md) |
| `ready player 8/HEICConverter.swift` | HEIC → JPEG helper | VERIFIED | Exists; 6 XCTest cases in `HEICConversionTests.swift` |
| `ready player 8/DocumentPickerHelper.swift` | UIDocumentPickerViewController bridge | VERIFIED | Exists (13-05-SUMMARY.md) |
| `ready player 8/DocumentPreviewView.swift` | PDFKit + AsyncImage preview | VERIFIED | Exists |
| `ready player 8/DocumentAttachmentsView.swift` | Integrated into 4 entity surfaces | VERIFIED | Exists; integrated per 13-05-SUMMARY.md table |
| `ready player 8/DocumentVersionsView.swift` | iOS version history UI | VERIFIED | Exists |
| `ready player 8Tests/HEICConversionTests.swift` | HEIC conversion tests | VERIFIED | Exists; commits `5a98083`, `eebf99e`, `ef0b230` on main |
| `ready player 8Tests/SupabaseServiceUploadTests.swift` | Upload REST tests | VERIFIED | Exists |
| `ready player 8Tests/DocumentVersioningTests.swift` | Version RPC tests | VERIFIED | Exists |

### Key Link Verification

All grep assertions executed in repo root on 2026-04-19T15:50:00Z at commit `fe96de7`.

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `grep -c 'cs_documents' supabase/migrations/20260406001_documents_rls.sql` | ≥ 1 | **7** | PASS |
| `grep -c 'cs_document_attachments' web/src/app/api/documents/attach/route.ts` | ≥ 1 | **1** | PASS |
| `grep -rl 'DocumentSyncManager' 'ready player 8/' \| wc -l` | ≥ 1 | **5** (DocumentSyncManager.swift declaration + 4 callers: DocumentAttachmentsView, DocumentVersionsView, HEICConverter, FieldPhotoUpload) | PASS |
| `grep -c 'cs_documents' 'ready player 8/SupabaseService.swift'` | ≥ 1 | **3** (allowedTables entry + insertDocumentRow routing) | PASS |
| `grep -l 'emit_document_activity_event' supabase/migrations/` | ≥ 1 | **2 files** (20260417001_phase24_document_activity_triggers.sql, 20260418004_phase26_extend_document_activity_trigger.sql) | PASS (cites Phase 24 for INT-02 closure, Phase 26 for whitelist extension) |
| `ls 'ready player 8/'Document*.swift \| wc -l` | 6 (Models, Picker, Preview, Sync, Attachments, Versions) | **6** | PASS |
| `ls web/src/components/documents/ \| grep -v .test. \| wc -l` | 4 UI components | **4** (AttachmentList, DocumentPreview, UploadButton, VersionHistory) | PASS |

### Behavioral Spot-Checks

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Shared build + lint evidence | Cite `.planning/phases/28-retroactive-verification-sweep/28-01-EVIDENCE.md` @ commit `fe96de7` timestamp `2026-04-19T15:46:17Z` | iOS BUILD SUCCEEDED; web lint exit 0; web build exit 0 | PASS |
| Phase 13 vitest subset | `cd web && npx vitest run src/lib/documents/ src/app/api/documents/` | **6 files / 62 tests passed (0 fail)** @ 309ms | PASS |
| iOS compile of document surface | Cite 28-01-EVIDENCE.md (DocumentModels, DocumentSyncManager, HEICConverter, DocumentAttachmentsView, DocumentVersionsView, DocumentPreviewView, DocumentPickerHelper all compile) | BUILD SUCCEEDED | PASS |

## Integration Gap Closure

The v2.0 milestone audit (`v2.0-MILESTONE-AUDIT.md`) flagged two Phase-13 integration blockers — both closed in the v2.1 follow-up work:

| Gap ID | Description | Status | Closed By |
|--------|-------------|--------|-----------|
| INT-01 | RLS references non-existent cs_rfis/cs_submittals/cs_change_orders (silent skip) | CLOSED | Phase 26 Plans 01/02 — 5 stub tables created + RLS rebuilt for all 7 entity types. Cite `.planning/phases/26-documents-rls-table-reconciliation/26-05-VERIFICATION.md` (Query 1: 5 stub tables present; Query 2: RLS enabled on all; Query 3: 15 policies across stubs; Query 4: 7 entity types now covered by document RLS). |
| INT-02 | Document routes do not emit cs_activity_events (breaks NOTIF-02 downstream) | CLOSED | Phase 24 Plans 01/02 — `emit_document_activity_event()` trigger function attached to cs_documents and cs_document_attachments; activity feed page extended with ENTITY_LABELS + DETAIL_LABELS. Cite `.planning/phases/24-document-activity-event-emission/24-01-SUMMARY.md` (trigger + backfill) and `24-02-SUMMARY.md` (rendering + 7 contract tests green). |

Per D-03 (hybrid closure credit), Phase 28 does **not** re-run pg_catalog queries or re-execute the Phase 24/26 test suites — both closure-phase VERIFICATIONs/SUMMARYs are cited as authoritative.

## Dependent Requirements Status

| Requirement | Before | After | Evidence |
|-------------|--------|-------|----------|
| **DOC-01** — Upload PDF/image to Storage from iOS + web | Pending (Phase 28) | Partial | Code green (upload route + DocumentSyncManager); UAT walk-through deferred to Plan 28-02 |
| **DOC-02** — Download any attached file | Pending (Phase 28) | Satisfied | Signed-URL route + iOS download; activity emission closed by Phase 24 |
| **DOC-03** — Attach files to project/RFI/submittal/change order | Pending (Phase 28) | Satisfied | Attach API + RLS across all 7 entity types via Phase 26 closure |
| **DOC-04** — Preview PDFs and images in-app | Pending (Phase 28) | Partial | DocumentPreview.tsx (iframe/img) + DocumentPreviewView.swift (PDFKit/AsyncImage); UAT deferred |
| **DOC-05** — View prior versions of revised documents | Pending (Phase 28) | Partial | Versions API + VersionHistory.tsx + DocumentVersionsView.swift; UAT deferred |

The Partial vs Satisfied split above aligns with the three-state `[x]`/`[~]`/`[ ]` convention Plan 28-02 introduces (D-09).

## Nyquist Note

`13-VALIDATION.md` is in **draft** status (`nyquist_compliant: false`, `wave_0_complete: false` per `.planning/phases/13-document-management-foundation/13-VALIDATION.md` frontmatter). Flip via `/gsd-validate-phase 13`. Out of scope for Phase 28 per D-12.

## Deviations from Plan

### D-03 Hybrid closure credit applied

DOC-03 and DOC-04 verification relies on Phase 26's RLS reconciliation — this VERIFICATION.md cites `26-05-VERIFICATION.md` rather than re-running the pg_catalog queries. Similarly, DOC-02's activity-event emission relies on Phase 24 — cited via `24-01-SUMMARY.md` and `24-02-SUMMARY.md` rather than re-executing the 13-element document-trigger test matrix.

### Partial status honors UAT gating

DOC-01, DOC-04, and DOC-05 ship as **Partial** — their implementation code is fully present and the targeted vitest suite (62/62 green) exercises every API boundary — but the ROADMAP success criteria include end-to-end user interactions (upload flow, in-app preview, version list UX) that require a browser walk-through with a live Supabase bucket and/or an iOS simulator run. Those UAT items are enumerated in the `human_verification` frontmatter block and will be walked in Plan 28-02.

### Grep divergence note

`grep -c 'DocumentSyncManager' 'ready player 8/SupabaseService.swift'` returned 0 (plan expected ≥ 1). This is not a regression: `DocumentSyncManager` lives in its own file (`ready player 8/DocumentSyncManager.swift`) and is referenced from 4 other iOS files. The recursive grep (`grep -rl ... 'ready player 8/'`) confirms 5 total references. Plan text had an incorrect expected location; the observable truth is satisfied via the recursive search.

---

_Verified: 2026-04-19T15:50:00Z_
_Verifier: Claude (gsd-executor running plan 28-01)_
_Evidence anchors: 28-01-EVIDENCE.md @ commit `fe96de7`, 26-05-VERIFICATION.md (INT-01), 24-01-SUMMARY.md + 24-02-SUMMARY.md (INT-02)_
