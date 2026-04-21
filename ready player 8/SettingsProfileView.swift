import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - ========== Settings & Profile Tab ==========

struct SettingsProfileView: View {
    @ObservedObject private var supabase = SupabaseService.shared
    @ObservedObject private var bioManager = BiometricAuthManager.shared
    @ObservedObject private var subManager = SubscriptionManager.shared
    @AppStorage("ConstructOS.RolePreset") private var rolePresetRaw: String = "SUPER"
    @AppStorage("ConstructOS.OnboardingComplete") private var onboardingComplete = false
    @State private var showPaywall = false
    @State private var showBackupAlert = false
    @State private var backupStatus: String?
    @State private var showResetConfirm = false

    private var role: OpsRolePreset { OpsRolePreset(rawValue: rolePresetRaw) ?? .superintendent }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Profile header
                HStack(spacing: 14) {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .overlay(Text(String((supabase.currentUserEmail ?? "U").prefix(1)).uppercased())
                            .font(.system(size: 22, weight: .heavy)).foregroundColor(.black))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(supabase.currentUserEmail ?? "Local User")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                        Text(role.display)
                            .font(.system(size: 11)).foregroundColor(Theme.muted)
                        HStack(spacing: 6) {
                            Text(subManager.subscriptionStatus.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(subManager.subscriptionStatus.color).cornerRadius(3)
                            if supabase.isConfigured {
                                Text("SUPABASE LINKED").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.green)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(16).background(Theme.surface).cornerRadius(14)
                .premiumGlow(cornerRadius: 14, color: Theme.accent)

                // Role preset
                VStack(alignment: .leading, spacing: 8) {
                    Text("ROLE PRESET").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
                    Text("Changes how dashboards, reports, and risk scores are presented")
                        .font(.system(size: 9)).foregroundColor(Theme.muted)
                    HStack(spacing: 6) {
                        ForEach(OpsRolePreset.allCases, id: \.rawValue) { preset in
                            Button { rolePresetRaw = preset.rawValue } label: {
                                VStack(spacing: 4) {
                                    Text(preset.icon).font(.system(size: 18))
                                    Text(preset.display).font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(role == preset ? .black : Theme.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(role == preset ? Theme.cyan : Theme.surface)
                                .cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Security
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECURITY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
                    Toggle(isOn: $bioManager.biometricEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: bioManager.biometricType == .faceID ? "faceid" : "touchid")
                                .font(.system(size: 16)).foregroundColor(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Require \(bioManager.biometricName)").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
                                Text("Lock app with biometric authentication").font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                        }
                    }
                    .tint(Theme.accent)

                    if supabase.isAuthenticated && supabase.currentUserEmail != "local" {
                        Button {
                            supabase.signOutEverywhere()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.red)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.red.opacity(0.1)).cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Subscription
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUBSCRIPTION").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Plan: \(subManager.subscriptionStatus.rawValue)")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
                            Text("\(subManager.subscriptionStatus.features.count) features included")
                                .font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Button { showPaywall = true } label: {
                            Text("UPGRADE").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Theme.gold).cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Data & Backup
                VStack(alignment: .leading, spacing: 8) {
                    Text("DATA & BACKUP").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)

                    Button {
                        exportBackup()
                    } label: {
                        Label("Export Data Backup", systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    }.buttonStyle(.plain)

                    if let status = backupStatus {
                        Text(status).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.green)
                    }

                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.red)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    }.buttonStyle(.plain)

                    Button {
                        onboardingComplete = false
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    }.buttonStyle(.plain)
                }
                .padding(14).background(Theme.surface).cornerRadius(12)

                // Sync status
                if supabase.isConfigured {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SYNC STATUS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
                        HStack(spacing: 8) {
                            Circle().fill(Theme.green).frame(width: 8, height: 8)
                            Text("Supabase connected").font(.system(size: 11)).foregroundColor(Theme.green)
                            Spacer()
                            if let lastSync = supabase.lastSyncAt {
                                Text("Last sync: \(lastSync, style: .relative) ago")
                                    .font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                        }
                        if !supabase.pendingWrites.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(Theme.gold)
                                Text("\(supabase.pendingWrites.count) pending writes queued")
                                    .font(.system(size: 10)).foregroundColor(Theme.gold)
                                Spacer()
                                Button("Flush") { Task { await supabase.flushPendingWrites() } }
                                    .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                            }
                        }
                    }
                    .padding(14).background(Theme.surface).cornerRadius(12)
                }

                // App info
                VStack(alignment: .leading, spacing: 6) {
                    Text("ABOUT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
                    HStack { Text("App").font(.system(size: 10)).foregroundColor(Theme.muted); Spacer(); Text("ConstructionOS v2.0").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text) }
                    HStack { Text("Tabs").font(.system(size: 10)).foregroundColor(Theme.muted); Spacer(); Text("22").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text) }
                    HStack { Text("Build").font(.system(size: 10)).foregroundColor(Theme.muted); Spacer(); Text("22,000+ lines").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text) }
                    HStack { Text("AI").font(.system(size: 10)).foregroundColor(Theme.muted); Spacer(); Text("Angelic (Claude) + 18 MCP Tools").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text) }
                    HStack { Text("Rental Items").font(.system(size: 10)).foregroundColor(Theme.muted); Spacer(); Text("97 across 6 providers").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text) }
                }
                .padding(14).background(Theme.surface).cornerRadius(12)
            }
            .padding(16)
        }
        .background(Theme.bg)
        .sheet(isPresented: $showPaywall) { SubscriptionPaywallView() }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAllData() }
        } message: {
            Text("This will delete all local data including expenses, leads, favorites, and history. This cannot be undone.")
        }
    }

    private func exportBackup() {
        let keys = [
            "ConstructOS.Ops.Alerts", "ConstructOS.Ops.ActionQueue", "ConstructOS.Ops.ChangeOrders",
            "ConstructOS.Ops.SafetyIncidents", "ConstructOS.Ops.MaterialDeliveries", "ConstructOS.Ops.PunchList",
            "ConstructOS.Ops.Subcontractors", "ConstructOS.Ops.DailyCosts", "ConstructOS.Ops.Submittals",
            "ConstructOS.Ops.ProjectAccounts", "ConstructOS.Ops.ContractAccounts", "ConstructOS.Ops.PortfolioMetrics",
            "ConstructOS.Ops.RFIs", "ConstructOS.Tax.Expenses", "ConstructOS.Electrical.Leads",
            "ConstructOS.Rentals.Favorites", "ConstructOS.Rentals.History", "ConstructOS.Rentals.PriceAlerts",
            "ConstructOS.Field.DailyLogs", "ConstructOS.Field.Permits"
        ]
        var backup: [String: String] = [:]
        for key in keys {
            if let val = UserDefaults.standard.string(forKey: key) {
                backup[key] = val
            }
        }
        if let data = try? JSONEncoder().encode(backup) {
            let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            backupStatus = "Backup ready: \(backup.count) keys, \(size)"
            copyTextToClipboard(String(data: data, encoding: .utf8) ?? "")
        }
    }

    private func resetAllData() {
        let keys = [
            "ConstructOS.Ops.Alerts", "ConstructOS.Ops.ActionQueue", "ConstructOS.Ops.ChangeOrders",
            "ConstructOS.Ops.SafetyIncidents", "ConstructOS.Ops.MaterialDeliveries", "ConstructOS.Ops.PunchList",
            "ConstructOS.Ops.Subcontractors", "ConstructOS.Ops.DailyCosts", "ConstructOS.Ops.Submittals",
            "ConstructOS.Ops.ProjectAccounts", "ConstructOS.Ops.ContractAccounts", "ConstructOS.Ops.PortfolioMetrics",
            "ConstructOS.Ops.RFIs", "ConstructOS.Tax.Expenses", "ConstructOS.Tax.SubPayments",
            "ConstructOS.Electrical.Leads", "ConstructOS.Rentals.Favorites", "ConstructOS.Rentals.History",
            "ConstructOS.Rentals.PriceAlerts", "ConstructOS.Rentals.Bundles", "ConstructOS.Rentals.ConditionReports",
            "ConstructOS.Rentals.Reviews", "ConstructOS.Field.DailyLogs", "ConstructOS.Field.Permits",
        ]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
    }
}

// MARK: - ========== Offline Mode Indicator ==========

struct OfflineIndicatorBar: View {
    @ObservedObject var supabase = SupabaseService.shared
    let pendingCount: Int

    var body: some View {
        if pendingCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash").font(.system(size: 10)).foregroundColor(Theme.gold)
                Text("\(pendingCount) pending sync \u{2022} Changes saved locally")
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.gold)
                Spacer()
                Button("Retry") { Task { await supabase.flushPendingWrites() } }
                    .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(Theme.gold.opacity(0.08))
            .border(width: 1, edges: [.bottom], color: Theme.gold.opacity(0.2))
        }
    }
}

// MARK: - What's New Changelog

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let releases: [(version: String, date: String, features: [String])] = [
        ("2.0", "Mar 2026", [
            "25 navigation tabs across 6 groups",
            "97 rental items from 6 providers (United Rentals, DOZR, Toolsy, Rent My Equipment, Sunbelt, Herc)",
            "Angelic AI with 18 MCP tools for live data access",
            "Face ID / Touch ID biometric lock",
            "StoreKit 2 subscriptions (Free/Pro/Enterprise)",
            "Video call system with mute/camera controls",
            "Construction Rental Search Engine with AI recommender",
            "Electrician & Fiber contractor directory with lead generation",
            "Tax center with expense tracking, deduction finder, 1099 management",
            "Field Ops: daily logs, timecards, equipment GPS, permits",
            "Finance Hub: AIA invoicing, lien waivers, cash flow forecast",
            "Compliance: toolbox talks, certified payroll, environmental",
            "Client Portal: owner dashboard, selections, warranty, meetings",
            "Analytics: bid win/loss, labor productivity, AI risk scoring",
            "Schedule Hub: Gantt chart, crew calendar, cost codes, takeoff calculator",
            "QR scanner, blueprint viewer, time-lapse camera, photo markup",
            "Training & certification tracker with expiry alerts",
            "Supabase backend with auth, offline sync, token refresh",
            "Keychain-secured API keys",
            "Global search, onboarding, push notifications, calendar sync",
            "PDF export, document attachments, data backup/restore",
            "Spotlight search indexing, deep linking, haptic feedback",
            "41 focused Swift files, 23,900+ lines of code",
        ]),
        ("1.0", "Mar 2026", [
            "Initial release",
            "Basic project and contract management",
            "Supabase integration",
        ]),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(releases, id: \.version) { release in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("v\(release.version)")
                                        .font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.accent)
                                    Text(release.date)
                                        .font(.system(size: 11)).foregroundColor(Theme.muted)
                                    Spacer()
                                }
                                ForEach(release.features, id: \.self) { feature in
                                    HStack(alignment: .top, spacing: 6) {
                                        Circle().fill(Theme.accent).frame(width: 4, height: 4).padding(.top, 5)
                                        Text(feature).font(.system(size: 11)).foregroundColor(Theme.text)
                                    }
                                }
                            }
                            .padding(14).background(Theme.surface).cornerRadius(12)
                        }
                    }
                    .padding(16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(Theme.accent)
                }
            }
            .navigationTitle("What's New")
        }
        .preferredColorScheme(.dark)
    }
}
