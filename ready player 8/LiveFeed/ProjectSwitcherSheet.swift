// Phase 29 LIVE-04 — Project switcher sheet (iOS).
// D-06: persists selection to ConstructOS.LiveFeed.LastSelectedProjectId (binding from parent).
// Case-insensitive prefix filter per UI-SPEC §Interaction Contracts LIVE-04 line 303.

import SwiftUI

struct ProjectSwitcherSheet: View {
    let projects: [ProjectSummary]
    @Binding var selectedProjectId: String
    @Binding var isPresented: Bool
    @State private var filter: String = ""

    // Case-insensitive prefix match (UI-SPEC line 303). Empty filter returns full list.
    private var filtered: [ProjectSummary] {
        if filter.isEmpty { return projects }
        let lower = filter.lowercased()
        return projects.filter { $0.name.lowercased().hasPrefix(lower) }
    }

    var body: some View {
        NavigationView {
            List(filtered) { project in
                Button(action: {
                    selectedProjectId = project.id
                    isPresented = false
                }) {
                    HStack {
                        Text(project.name)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.text)
                        Spacer()
                        if project.id == selectedProjectId {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
                .accessibilityLabel(
                    project.id == selectedProjectId
                        ? "\(project.name), selected"
                        : project.name
                )
            }
            .searchable(text: $filter, prompt: "Switch project…")
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}
