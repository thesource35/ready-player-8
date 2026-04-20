// Phase 29 LIVE-03 / LIVE-04 — Live Feed tab shell.
// Per-project default (D-06); Fleet toggle (D-07) persisted via ConstructOS.LiveFeed.LastFleetSelection.
// Project switcher (D-06) persisted via ConstructOS.LiveFeed.LastSelectedProjectId.
// Downstream plans fill LiveFeedPerProjectView content:
//   29-06: video player + scrubber + upload + library
//   29-07: suggestion cards + traffic + budget badge + analyze now

import SwiftUI

// Minimal project summary used by the switcher + Fleet grid. Full cs_projects shape lives
// in SupabaseService's SupabaseProject DTO; this view-layer struct keeps the UI decoupled
// from network-layer typing for the Wave 3 scaffold.
struct ProjectSummary: Identifiable, Equatable {
    let id: String
    let name: String
    let client: String?
}

struct LiveFeedView: View {
    @AppStorage(LiveFeedStorageKey.lastSelectedProjectId) private var selectedProjectId: String = ""
    @AppStorage(LiveFeedStorageKey.lastFleetSelection)   private var fleetMode: Bool = false
    @State private var showProjectSwitcher = false

    // Projects list. Wave 3 scaffold leaves this empty; downstream consumption plans
    // (29-06 / 29-07) wire to SupabaseService.shared authenticated client — NEVER
    // service-role — and RLS enforces org_id scope (T-29-RLS-CLIENT mitigation).
    @State private var accessibleProjects: [ProjectSummary] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if fleetMode {
                LiveFeedFleetView(projects: accessibleProjects)
            } else {
                LiveFeedPerProjectView(projectId: effectiveProjectId)
            }
        }
        .padding(16)
        .background(Theme.bg)
        .task { await loadProjects() }
        .sheet(isPresented: $showProjectSwitcher) {
            ProjectSwitcherSheet(
                projects: accessibleProjects,
                selectedProjectId: $selectedProjectId,
                isPresented: $showProjectSwitcher
            )
        }
    }

    // D-06: if the persisted id is in the user's current list, honour it; else fall back
    // to the first accessible project. Guards against stale ids after removal from org.
    private var effectiveProjectId: String {
        if !selectedProjectId.isEmpty,
           accessibleProjects.contains(where: { $0.id == selectedProjectId }) {
            return selectedProjectId
        }
        return accessibleProjects.first?.id ?? ""
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("LIVE FEED")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
            Spacer()
            if !fleetMode {
                Button(action: { showProjectSwitcher = true }) {
                    HStack(spacing: 6) {
                        Text(currentProjectName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Theme.text)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Project switcher, \(currentProjectName), button")
            }
            Toggle(isOn: $fleetMode) {
                Text(fleetMode ? "FLEET VIEW" : "PER-PROJECT")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(fleetMode ? Theme.accent : Theme.muted)
            }
            .toggleStyle(.switch)
            .tint(Theme.accent)
            .fixedSize()
        }
    }

    private var currentProjectName: String {
        accessibleProjects.first(where: { $0.id == effectiveProjectId })?.name ?? "Switch project…"
    }

    // Wave 3 scaffold: real fetch lands in downstream consumption plans where the UI
    // actually needs project data. The shell exists so 29-06 / 29-07 have a stable
    // parent view to mount into without further ContentView edits.
    private func loadProjects() async {
        let svc = SupabaseService.shared
        if svc.isConfigured {
            // Downstream plans wire SupabaseService.shared.fetch("cs_projects") here with
            // the authenticated session. RLS scopes by org_id automatically.
            accessibleProjects = []
        } else {
            accessibleProjects = []
        }
    }
}
