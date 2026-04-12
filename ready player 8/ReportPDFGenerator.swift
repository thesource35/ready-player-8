import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ========== ReportPDFGenerator.swift ==========
// Phase 19: iOS PDF generation using UIGraphicsPDFRenderer (D-28).
// D-30: Charts rendered as UIImage via ImageRenderer.
// D-32: Header/footer on each page. D-33: Light theme.
// D-34b: Auto-detect paper size. D-34c: Auto-detect orientation.
// D-34d: Table of contents. D-34f: Confidentiality + DRAFT watermark.
// D-34g: Executive summary. D-34i: QR code via CIQRCodeGenerator.
// D-34j: Smart page breaks. D-34k: Tagged PDF accessibility.
// D-31: Filename pattern "{ProjectName}-Report-{date}.pdf".

// MARK: - PDF Options

struct PDFOptions {
    var projectName: String = "Project Report"
    var companyName: String?
    var companyLogo: UIImage?
    var landscape: Bool = false
    var paperSize: CGSize = PDFOptions.detectedPaperSize()
    var confidential: Bool = false
    var executiveSummary: String?
    var isDraft: Bool = false
    var password: String?
    var webReportURL: String?

    // D-34b: Auto-detect paper size using Locale.current.region
    static func detectedPaperSize() -> CGSize {
        let usLetterCountries: Set<String> = ["US", "CA", "MX", "PH", "CL", "CO", "VE", "GT", "DO"]
        let regionCode = Locale.current.region?.identifier ?? "US"
        if usLetterCountries.contains(regionCode) {
            // US Letter: 8.5 x 11 inches = 612 x 792 points
            return CGSize(width: 612, height: 792)
        } else {
            // A4: 210 x 297 mm = 595.28 x 841.89 points
            return CGSize(width: 595, height: 842)
        }
    }

    // D-34c: Portrait for project, landscape for rollup
    var effectivePageSize: CGSize {
        if landscape {
            return CGSize(width: paperSize.height, height: paperSize.width)
        }
        return paperSize
    }

    // D-31: Filename pattern
    var filename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let safeName = projectName
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        return "\(safeName)-Report-\(dateString).pdf"
    }
}

// MARK: - PDF Section Tracking

private struct PDFSection {
    let title: String
    let pageNumber: Int
}

// MARK: - ReportPDFGenerator

final class ReportPDFGenerator {

    // MARK: - Constants

    private let margin: CGFloat = 54 // 0.75 inches
    private let headerHeight: CGFloat = 60
    private let footerHeight: CGFloat = 40
    private let sectionSpacing: CGFloat = 20
    private let lineSpacing: CGFloat = 4

    // Light theme colors (D-33)
    private let textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    private let mutedColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    private let accentColor = UIColor(red: 0.95, green: 0.62, blue: 0.24, alpha: 1.0)
    private let borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
    private let backgroundColor = UIColor.white

    // Typography
    private let titleFont = UIFont.systemFont(ofSize: 24, weight: .heavy)
    private let headingFont = UIFont.systemFont(ofSize: 18, weight: .bold)
    private let sectionFont = UIFont.systemFont(ofSize: 14, weight: .bold)
    private let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    private let labelFont = UIFont.systemFont(ofSize: 8, weight: .bold)
    private let footerFont = UIFont.systemFont(ofSize: 8, weight: .regular)

    // MARK: - State

    private var currentPageNumber = 0
    private var tocSections: [PDFSection] = []

    // MARK: - Generate PDF (D-28: UIGraphicsPDFRenderer)

    func generatePDF(report: ProjectReportData, options: PDFOptions) -> Data {
        let pageSize = options.effectivePageSize
        let format = UIGraphicsPDFRendererFormat()

        // D-34k: Tagged PDF accessibility (basic metadata)
        let metadata: [String: Any] = [
            kCGPDFContextTitle as String: options.projectName,
            kCGPDFContextAuthor as String: options.companyName ?? "ConstructionOS",
            kCGPDFContextCreator as String: "ConstructionOS Report Generator",
            kCGPDFContextSubject as String: "Project Report for \(options.projectName)"
        ]
        format.documentInfo = metadata

        let renderer = UIGraphicsPDFRendererContext.self
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        currentPageNumber = 0
        tocSections = []

        let data = pdfRenderer.pdfData { context in
            let contentRect = CGRect(
                x: margin,
                y: margin + headerHeight,
                width: pageSize.width - margin * 2,
                height: pageSize.height - margin * 2 - headerHeight - footerHeight
            )

            // --- Page 1: Title + TOC ---
            beginNewPage(context: context, pageSize: pageSize, options: options)
            var yPos = contentRect.minY

            // Title
            yPos = drawTitle(options.projectName, at: yPos, width: contentRect.width, xOffset: contentRect.minX)
            yPos += 8

            // D-34i: QR code on first page
            if let urlString = options.webReportURL {
                drawQRCode(urlString: urlString, at: CGPoint(x: pageSize.width - margin - 60, y: margin + 10), size: 50)
            }

            // Generation date
            let dateStr = report.generatedAt ?? formattedDate()
            yPos = drawText("Generated: \(dateStr)", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: mutedColor)
            yPos += sectionSpacing

            // D-34d: Table of contents placeholder (will be filled after rendering)
            let tocStartY = yPos
            yPos = drawText("TABLE OF CONTENTS", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: sectionFont, color: accentColor)
            yPos += 8
            // Reserve space for TOC entries (we know the sections we'll render)
            let tocEntries = buildTOCEntries(report: report, options: options)
            for entry in tocEntries {
                yPos = drawText("  \(entry)", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                yPos += lineSpacing
            }
            yPos += sectionSpacing

            // D-34g: Executive summary
            if let summary = options.executiveSummary, !summary.isEmpty {
                yPos = checkPageBreak(yPos: yPos, needed: 80, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                yPos = drawSectionHeading("EXECUTIVE SUMMARY", at: yPos, width: contentRect.width, xOffset: contentRect.minX)
                yPos = drawWrappedText(summary, at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                yPos += sectionSpacing
            }

            // --- Budget Section ---
            if let budget = report.budget {
                yPos = checkPageBreak(yPos: yPos, needed: 120, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                tocSections.append(PDFSection(title: "Budget & Financials", pageNumber: currentPageNumber))
                yPos = drawSectionHeading("BUDGET & FINANCIALS", at: yPos, width: contentRect.width, xOffset: contentRect.minX)

                let budgetLines = [
                    "Contract Value: \(formatCurrency(budget.contractValue ?? 0))",
                    "Total Billed: \(formatCurrency(budget.totalBilled ?? 0))",
                    "Percent Complete: \(formatPercent(budget.percentComplete ?? 0))",
                    "Change Order Net: \(formatCurrency(budget.changeOrderNet ?? 0))",
                    "Retainage: \(formatCurrency(budget.retainage ?? 0))"
                ]
                for line in budgetLines {
                    yPos = drawText(line, at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                    yPos += lineSpacing
                }
                yPos += 8

                // D-30: Render budget chart as image
                let chartImage = renderBudgetChart(spent: budget.totalBilled ?? 0, remaining: (budget.contractValue ?? 0) - (budget.totalBilled ?? 0))
                if let img = chartImage {
                    yPos = checkPageBreak(yPos: yPos, needed: 160, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                    let chartRect = CGRect(x: contentRect.minX + 40, y: yPos, width: min(contentRect.width - 80, 200), height: 150)
                    img.draw(in: chartRect)
                    yPos += 160
                }
                yPos += sectionSpacing
            }

            // --- Schedule Section ---
            if let schedule = report.schedule {
                yPos = checkPageBreak(yPos: yPos, needed: 100, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                tocSections.append(PDFSection(title: "Schedule & Milestones", pageNumber: currentPageNumber))
                yPos = drawSectionHeading("SCHEDULE & MILESTONES", at: yPos, width: contentRect.width, xOffset: contentRect.minX)

                if let onTrack = schedule.percentOnTrack {
                    yPos = drawText("On Track: \(formatPercent(onTrack))", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                    yPos += lineSpacing
                }

                if let milestones = schedule.milestones {
                    for milestone in milestones.prefix(8) {
                        yPos = checkPageBreak(yPos: yPos, needed: 20, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                        let bar = progressBar(percent: milestone.percentComplete, width: 100)
                        yPos = drawText("\(milestone.name): \(formatPercent(milestone.percentComplete)) \(bar)", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                        yPos += lineSpacing
                    }
                }

                // D-30: Render schedule chart
                if let milestones = schedule.milestones, !milestones.isEmpty {
                    let chartImage = renderScheduleChart(milestones: milestones)
                    if let img = chartImage {
                        yPos = checkPageBreak(yPos: yPos, needed: 160, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                        let chartRect = CGRect(x: contentRect.minX, y: yPos, width: min(contentRect.width, 400), height: 150)
                        img.draw(in: chartRect)
                        yPos += 160
                    }
                }
                yPos += sectionSpacing
            }

            // --- Safety Section ---
            if let safety = report.safety {
                yPos = checkPageBreak(yPos: yPos, needed: 100, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                tocSections.append(PDFSection(title: "Safety", pageNumber: currentPageNumber))
                yPos = drawSectionHeading("SAFETY", at: yPos, width: contentRect.width, xOffset: contentRect.minX)

                let safetyLines = [
                    "Total Incidents: \(safety.totalIncidents ?? 0)",
                    "Minor: \(safety.minor ?? 0)  |  Moderate: \(safety.moderate ?? 0)  |  Serious: \(safety.serious ?? 0)",
                    "Days Since Last Incident: \(safety.daysSinceLastIncident ?? 0)"
                ]
                for line in safetyLines {
                    yPos = drawText(line, at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                    yPos += lineSpacing
                }

                // D-30: Render safety chart
                if let monthlyData = safety.monthlyData, !monthlyData.isEmpty {
                    let chartImage = renderSafetyChart(data: monthlyData)
                    if let img = chartImage {
                        yPos = checkPageBreak(yPos: yPos, needed: 160, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                        let chartRect = CGRect(x: contentRect.minX, y: yPos, width: min(contentRect.width, 400), height: 150)
                        img.draw(in: chartRect)
                        yPos += 160
                    }
                }
                yPos += sectionSpacing
            }

            // --- Team Section ---
            if let team = report.team {
                yPos = checkPageBreak(yPos: yPos, needed: 80, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                tocSections.append(PDFSection(title: "Team & Activity", pageNumber: currentPageNumber))
                yPos = drawSectionHeading("TEAM & ACTIVITY", at: yPos, width: contentRect.width, xOffset: contentRect.minX)

                yPos = drawText("Team Members: \(team.memberCount ?? 0)", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                yPos += lineSpacing

                if let activity = team.recentActivity {
                    yPos = drawText("Recent Activity:", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: sectionFont, color: textColor)
                    yPos += lineSpacing
                    for entry in activity.prefix(5) {
                        yPos = checkPageBreak(yPos: yPos, needed: 16, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                        yPos = drawText("  \(entry.user) - \(entry.action) (\(entry.timestamp))", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                        yPos += lineSpacing
                    }
                }
                yPos += sectionSpacing
            }

            // --- AI Insights Section ---
            if let insights = report.insights, !insights.isEmpty {
                yPos = checkPageBreak(yPos: yPos, needed: 60, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                tocSections.append(PDFSection(title: "AI Insights", pageNumber: currentPageNumber))
                yPos = drawSectionHeading("AI INSIGHTS", at: yPos, width: contentRect.width, xOffset: contentRect.minX)

                for insight in insights {
                    yPos = checkPageBreak(yPos: yPos, needed: 20, context: context, pageSize: pageSize, options: options, contentRect: contentRect)
                    yPos = drawText("  \(insight)", at: yPos, width: contentRect.width, xOffset: contentRect.minX, font: bodyFont, color: textColor)
                    yPos += lineSpacing
                }
            }

            // D-34f: DRAFT watermark on preview PDFs
            if options.isDraft {
                drawDraftWatermark(pageSize: pageSize)
            }
        }

        // D-34h: Password protection
        if let password = options.password, !password.isEmpty {
            return applyPasswordProtection(to: data, password: password) ?? data
        }

        return data
    }

    // MARK: - Page Management

    private func beginNewPage(context: UIGraphicsPDFRendererContext, pageSize: CGSize, options: PDFOptions) {
        context.beginPage()
        currentPageNumber += 1
        drawHeader(pageSize: pageSize, options: options)
        drawFooter(pageSize: pageSize, options: options)
    }

    // D-34j: Smart page breaks -- track Y position, add new page before section if would overflow
    private func checkPageBreak(yPos: CGFloat, needed: CGFloat, context: UIGraphicsPDFRendererContext, pageSize: CGSize, options: PDFOptions, contentRect: CGRect) -> CGFloat {
        let maxY = pageSize.height - margin - footerHeight
        if yPos + needed > maxY {
            beginNewPage(context: context, pageSize: pageSize, options: options)
            return contentRect.minY
        }
        return yPos
    }

    // MARK: - Header & Footer (D-32)

    private func drawHeader(pageSize: CGSize, options: PDFOptions) {
        // Company logo left
        if let logo = options.companyLogo {
            let logoRect = CGRect(x: margin, y: margin, width: min(120, logo.size.width), height: min(40, logo.size.height))
            logo.draw(in: logoRect)
        }

        // Project name center
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: headingFont,
            .foregroundColor: textColor
        ]
        let nameSize = (options.projectName as NSString).size(withAttributes: nameAttrs)
        let nameX = (pageSize.width - nameSize.width) / 2
        (options.projectName as NSString).draw(at: CGPoint(x: nameX, y: margin + 10), withAttributes: nameAttrs)

        // Date right
        let dateStr = formattedDate()
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: mutedColor
        ]
        let dateSize = (dateStr as NSString).size(withAttributes: dateAttrs)
        (dateStr as NSString).draw(at: CGPoint(x: pageSize.width - margin - dateSize.width, y: margin + 14), withAttributes: dateAttrs)

        // Header line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: margin + headerHeight - 4))
        linePath.addLine(to: CGPoint(x: pageSize.width - margin, y: margin + headerHeight - 4))
        borderColor.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
    }

    private func drawFooter(pageSize: CGSize, options: PDFOptions) {
        let footerY = pageSize.height - margin - footerHeight + 12

        // "Generated by ConstructionOS" left
        let genAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: mutedColor
        ]
        ("Generated by ConstructionOS" as NSString).draw(at: CGPoint(x: margin, y: footerY), withAttributes: genAttrs)

        // Page number center
        let pageStr = "Page \(currentPageNumber)"
        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: mutedColor
        ]
        let pageSize2 = (pageStr as NSString).size(withAttributes: pageAttrs)
        (pageStr as NSString).draw(at: CGPoint(x: (pageSize.width - pageSize2.width) / 2, y: footerY), withAttributes: pageAttrs)

        // D-34f: Confidentiality footer
        if options.confidential {
            let confStr = "Confidential \u{2014} \(options.companyName ?? "ConstructionOS")"
            let confAttrs: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: mutedColor
            ]
            let confSize = (confStr as NSString).size(withAttributes: confAttrs)
            (confStr as NSString).draw(at: CGPoint(x: pageSize.width - margin - confSize.width, y: footerY), withAttributes: confAttrs)
        }

        // Footer line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: footerY - 4))
        linePath.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 4))
        borderColor.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
    }

    // MARK: - Drawing Helpers

    @discardableResult
    private func drawTitle(_ text: String, at y: CGFloat, width: CGFloat, xOffset: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: textColor
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: xOffset, y: y), withAttributes: attrs)
        return y + size.height
    }

    @discardableResult
    private func drawSectionHeading(_ text: String, at y: CGFloat, width: CGFloat, xOffset: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: accentColor
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: xOffset, y: y), withAttributes: attrs)

        // Underline
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: xOffset, y: y + size.height + 2))
        linePath.addLine(to: CGPoint(x: xOffset + width, y: y + size.height + 2))
        accentColor.withAlphaComponent(0.3).setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()

        return y + size.height + 8
    }

    @discardableResult
    private func drawText(_ text: String, at y: CGFloat, width: CGFloat, xOffset: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let rect = CGRect(x: xOffset, y: y, width: width, height: 1000)
        let boundingRect = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return y + boundingRect.height
    }

    @discardableResult
    private func drawWrappedText(_ text: String, at y: CGFloat, width: CGFloat, xOffset: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        let drawRect = CGRect(x: xOffset, y: y, width: width, height: boundingRect.height)
        (text as NSString).draw(in: drawRect, withAttributes: attrs)
        return y + boundingRect.height
    }

    // MARK: - D-34i: QR Code via CIQRCodeGenerator

    private func drawQRCode(urlString: String, at point: CGPoint, size: CGFloat) {
        guard let qrImage = generateQRCode(from: urlString, size: size) else { return }
        qrImage.draw(in: CGRect(origin: point, size: CGSize(width: size, height: size)))
    }

    private func generateQRCode(from string: String, size: CGFloat) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - D-34f: DRAFT Watermark

    private func drawDraftWatermark(pageSize: CGSize) {
        let text = "DRAFT"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 72, weight: .heavy),
            .foregroundColor: UIColor.gray.withAlphaComponent(0.08)
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)

        // Save graphics state
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()

        // Rotate 45 degrees and draw centered
        let centerX = pageSize.width / 2
        let centerY = pageSize.height / 2
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: -.pi / 4)
        (text as NSString).draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)

        ctx.restoreGState()
    }

    // MARK: - D-30: Chart Rendering via ImageRenderer

    private func renderBudgetChart(spent: Double, remaining: Double) -> UIImage? {
        let chartView = BudgetPieChartView(spent: spent, remaining: remaining)
            .frame(width: 200, height: 150)
            .background(Color.white)
        return renderSwiftUIView(chartView, size: CGSize(width: 200, height: 150))
    }

    private func renderScheduleChart(milestones: [ReportMilestone]) -> UIImage? {
        let tuples = milestones.map { (name: $0.name, percent: $0.percentComplete) }
        let chartView = ScheduleBarChartView(milestones: tuples)
            .frame(width: 400, height: 150)
            .background(Color.white)
        return renderSwiftUIView(chartView, size: CGSize(width: 400, height: 150))
    }

    private func renderSafetyChart(data: [SafetyMonthData]) -> UIImage? {
        let tuples = data.map { (month: $0.month, count: $0.count) }
        let chartView = SafetyLineChartView(monthlyData: tuples)
            .frame(width: 400, height: 150)
            .background(Color.white)
        return renderSwiftUIView(chartView, size: CGSize(width: 400, height: 150))
    }

    @MainActor
    private func renderSwiftUIViewOnMain<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: size.width, height: size.height)
        renderer.scale = 2.0 // 2x for print clarity
        return renderer.uiImage
    }

    private func renderSwiftUIView<V: View>(_ view: V, size: CGSize) -> UIImage? {
        // ImageRenderer must be used on main actor
        var result: UIImage?
        if Thread.isMainThread {
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: size.width, height: size.height)
            renderer.scale = 2.0
            result = renderer.uiImage
        } else {
            DispatchQueue.main.sync {
                let renderer = ImageRenderer(content: view)
                renderer.proposedSize = .init(width: size.width, height: size.height)
                renderer.scale = 2.0
                result = renderer.uiImage
            }
        }
        return result
    }

    // MARK: - D-34h: Password Protection

    private func applyPasswordProtection(to data: Data, password: String) -> Data? {
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let pdfDocument = CGPDFDocument(dataProvider) else { return nil }

        let outputData = NSMutableData()
        guard let consumer = CGDataConsumer(data: outputData),
              let context = CGContext(consumer: consumer, mediaBox: nil, [
                  kCGPDFContextOwnerPassword as String: password,
                  kCGPDFContextUserPassword as String: password
              ] as CFDictionary) else { return nil }

        let pageCount = pdfDocument.numberOfPages
        for i in 1...pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let mediaBox = page.getBoxRect(.mediaBox)
            var box = mediaBox
            context.beginPage(mediaBox: &box)
            context.drawPDFPage(page)
            context.endPage()
        }
        context.closePDF()

        return outputData as Data
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formatPercent(_ value: Double) -> String {
        return "\(Int(value))%"
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    private func progressBar(percent: Double, width: Int) -> String {
        let filled = Int(percent / 100.0 * Double(width / 5))
        let empty = (width / 5) - filled
        return "[\(String(repeating: "#", count: max(0, filled)))\(String(repeating: "-", count: max(0, empty)))]"
    }

    private func buildTOCEntries(report: ProjectReportData, options: PDFOptions) -> [String] {
        var entries: [String] = []
        if options.executiveSummary != nil { entries.append("Executive Summary") }
        if report.budget != nil { entries.append("Budget & Financials") }
        if report.schedule != nil { entries.append("Schedule & Milestones") }
        if report.safety != nil { entries.append("Safety") }
        if report.team != nil { entries.append("Team & Activity") }
        if report.insights != nil { entries.append("AI Insights") }
        return entries
    }
}
