import SwiftUI
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ========== ReportExportView.swift ==========
// Phase 19: Export sheet with PDF preview and options.
// D-29: Sheet presentation with PDF preview and download.
// D-34e: Company branding settings.
// D-34f: Confidentiality toggle.
// D-34g: Executive summary text editor.
// D-34h: Password protection toggle + password field.
// D-34m: Batch export button.
// D-47: Additional export options (CSV, JSON).

// MARK: - ReportExportView

struct ReportExportView: View {
    let report: ProjectReportData
    let projectName: String

    @Environment(\.dismiss) private var dismiss

    // PDF options state
    @State private var executiveSummary: String = ""
    @State private var isConfidential: Bool = false
    @State private var isDraft: Bool = false
    @State private var passwordProtected: Bool = false
    @State private var password: String = ""
    @State private var landscape: Bool = false

    // Company branding (D-34e)
    @State private var companyName: String = ""
    @State private var companyLogoData: Data?
    @State private var showLogoPicker: Bool = false

    // Generation state
    @State private var isGenerating: Bool = false
    @State private var generatedPDFData: Data?
    @State private var pdfDocument: PDFDocument?
    @State private var showShareSheet: Bool = false
    @State private var errorMessage: String?

    private let generator = ReportPDFGenerator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // PDF Preview section (D-29)
                    pdfPreviewSection

                    // Export options
                    exportOptionsSection

                    // D-34g: Executive summary editor
                    executiveSummarySection

                    // D-34e: Company branding
                    brandingSection

                    // D-34f & D-34h: Security options
                    securitySection

                    // Action buttons
                    actionButtonsSection
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
            .alert("Export Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let err = errorMessage {
                    Text(err)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = generatedPDFData {
                    ShareSheet(activityItems: [data], filename: buildOptions().filename)
                }
            }
        }
    }

    // MARK: - PDF Preview (D-29)

    private var pdfPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.system(size: 8, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
                .textCase(.uppercase)

            if let pdfDoc = pdfDocument {
                ReportPDFPreviewView(document: pdfDoc)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.surface)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.muted)
                            Text("Tap 'Generate Preview' to see PDF")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.muted)
                        }
                    )
            }

            Button {
                generatePreview()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(Theme.bg)
                    } else {
                        Image(systemName: "eye")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Preview")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.surface)
                .foregroundColor(Theme.text)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isGenerating)
        }
    }

    // MARK: - Export Options

    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FORMAT")
                .font(.system(size: 8, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
                .textCase(.uppercase)

            Toggle(isOn: $landscape) {
                HStack {
                    Image(systemName: landscape ? "rectangle" : "rectangle.portrait")
                    Text(landscape ? "Landscape" : "Portrait")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.text)
            }
            .tint(Theme.accent)
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - D-34g: Executive Summary

    private var executiveSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXECUTIVE SUMMARY")
                .font(.system(size: 8, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
                .textCase(.uppercase)

            Text("Optional notes that appear at the start of the PDF")
                .font(.system(size: 10))
                .foregroundColor(Theme.muted)

            TextEditor(text: $executiveSummary)
                .font(.system(size: 12))
                .foregroundColor(Theme.text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(8)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("Executive summary text")
        }
    }

    // MARK: - D-34e: Company Branding

    private var brandingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BRANDING")
                .font(.system(size: 8, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
                .textCase(.uppercase)

            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(Theme.muted)
                TextField("Company Name", text: $companyName)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text)
            }
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Logo picker placeholder
            Button {
                showLogoPicker = true
            } label: {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(Theme.muted)
                    Text(companyLogoData != nil ? "Logo Selected" : "Add Company Logo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.muted)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Select company logo")
        }
    }

    // MARK: - D-34f & D-34h: Security Options

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SECURITY")
                .font(.system(size: 8, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)
                .textCase(.uppercase)

            // D-34f: Confidentiality toggle
            Toggle(isOn: $isConfidential) {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Confidential Footer")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.text)
            }
            .tint(Theme.accent)
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // DRAFT watermark toggle
            Toggle(isOn: $isDraft) {
                HStack {
                    Image(systemName: "doc.badge.ellipsis")
                    Text("DRAFT Watermark")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.text)
            }
            .tint(Theme.accent)
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // D-34h: Password protection
            Toggle(isOn: $passwordProtected) {
                HStack {
                    Image(systemName: "key")
                    Text("Password Protection")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.text)
            }
            .tint(Theme.accent)
            .padding(12)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if passwordProtected {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(Theme.muted)
                    SecureField("PDF Password", text: $password)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.text)
                }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: passwordProtected)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Export PDF button
            Button {
                exportPDF()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(Theme.bg)
                    } else {
                        Image(systemName: "arrow.down.doc")
                    }
                    Text(isGenerating ? "Generating..." : "Export PDF")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent)
                .foregroundColor(Theme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isGenerating)
            .accessibilityLabel("Export report as PDF")

            // D-47: Additional export options
            HStack(spacing: 12) {
                Button {
                    exportCSV()
                } label: {
                    HStack {
                        Image(systemName: "tablecells")
                        Text("CSV")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .foregroundColor(Theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Export as CSV")

                Button {
                    exportJSON()
                } label: {
                    HStack {
                        Image(systemName: "curlybraces")
                        Text("JSON")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .foregroundColor(Theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border.opacity(0.3), lineWidth: 1)
                    )
                }
                .accessibilityLabel("Export as JSON")
            }

            // D-34m: Batch export
            Button {
                // Batch export triggers generation for all projects
                // For now, export current report
                exportPDF()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Export All Reports")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundColor(Theme.muted)
            }
            .accessibilityLabel("Export all project reports as batch")
        }
    }

    // MARK: - PDF Generation

    private func buildOptions() -> PDFOptions {
        var options = PDFOptions()
        options.projectName = projectName
        options.companyName = companyName.isEmpty ? nil : companyName
        options.landscape = landscape
        options.confidential = isConfidential
        options.executiveSummary = executiveSummary.isEmpty ? nil : executiveSummary
        options.isDraft = isDraft
        options.password = passwordProtected ? (password.isEmpty ? nil : password) : nil
        if let logoData = companyLogoData {
            options.companyLogo = UIImage(data: logoData)
        }
        return options
    }

    private func generatePreview() {
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                var opts = buildOptions()
                opts.isDraft = true // Preview always shows draft
                let data = generator.generatePDF(report: report, options: opts)
                await MainActor.run {
                    generatedPDFData = data
                    pdfDocument = PDFDocument(data: data)
                    isGenerating = false
                }
            }
        }
    }

    private func exportPDF() {
        isGenerating = true
        errorMessage = nil
        Task {
            let options = buildOptions()
            let data = generator.generatePDF(report: report, options: options)
            await MainActor.run {
                generatedPDFData = data
                isGenerating = false
                showShareSheet = true
            }
        }
    }

    // D-47: CSV export
    private func exportCSV() {
        var csv = "Section,Metric,Value\n"
        if let budget = report.budget {
            csv += "Budget,Contract Value,\(budget.contractValue ?? 0)\n"
            csv += "Budget,Total Billed,\(budget.totalBilled ?? 0)\n"
            csv += "Budget,Percent Complete,\(budget.percentComplete ?? 0)\n"
            csv += "Budget,Change Order Net,\(budget.changeOrderNet ?? 0)\n"
            csv += "Budget,Retainage,\(budget.retainage ?? 0)\n"
        }
        if let schedule = report.schedule {
            csv += "Schedule,Percent On Track,\(schedule.percentOnTrack ?? 0)\n"
            for m in schedule.milestones ?? [] {
                csv += "Schedule,\(m.name),\(m.percentComplete)\n"
            }
        }
        if let safety = report.safety {
            csv += "Safety,Total Incidents,\(safety.totalIncidents ?? 0)\n"
            csv += "Safety,Minor,\(safety.minor ?? 0)\n"
            csv += "Safety,Moderate,\(safety.moderate ?? 0)\n"
            csv += "Safety,Serious,\(safety.serious ?? 0)\n"
        }
        if let team = report.team {
            csv += "Team,Member Count,\(team.memberCount ?? 0)\n"
        }

        let data = Data(csv.utf8)
        shareData(data, filename: "\(projectName)-Report.csv", type: "text/csv")
    }

    // D-47: JSON export
    private func exportJSON() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)
            shareData(data, filename: "\(projectName)-Report.json", type: "application/json")
        } catch {
            errorMessage = "Failed to encode report: \(error.localizedDescription)"
        }
    }

    private func shareData(_ data: Data, filename: String, type: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            errorMessage = "Failed to save file: \(error.localizedDescription)"
        }
    }
}

// MARK: - PDFKit View Wrapper

struct ReportPDFPreviewView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(Theme.surface)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

// MARK: - Share Sheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var filename: String?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items = activityItems

        // If we have PDF data and a filename, write to temp file for better sharing
        if let data = activityItems.first as? Data, let name = filename {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? data.write(to: tempURL)
            items = [tempURL]
        }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
