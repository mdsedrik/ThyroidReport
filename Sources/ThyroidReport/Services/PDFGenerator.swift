import UIKit
import PDFKit

class PDFGenerator {

    // MARK: - Sabitler
    private static let pageW: CGFloat = 595.2   // A4
    private static let pageH: CGFloat = 841.8   // A4
    private static let margin: CGFloat = 55
    private static var contentW: CGFloat { pageW - 2 * margin }

    // Renkler
    private static let titleColor      = UIColor(red: 0.08, green: 0.25, blue: 0.45, alpha: 1)
    private static let sectionColor    = UIColor(red: 0.13, green: 0.40, blue: 0.65, alpha: 1)
    private static let labelColor      = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
    private static let valueColor      = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
    private static let dividerColor    = UIColor(red: 0.13, green: 0.40, blue: 0.65, alpha: 0.4)
    private static let tiradsColor     = UIColor(red: 0.60, green: 0.10, blue: 0.10, alpha: 1)
    private static let bgHeaderColor   = UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1)

    // MARK: - Üretim

    static func generate(from report: ThyroidReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Tiroid Rapor",
            kCGPDFContextTitle  as String: "Tiroid Ultrason Raporu - \(report.patientFullName)"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
            format: format
        )

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // ─── Başlık Kutusu ───────────────────────────────────────────
            let headerRect = CGRect(x: margin - 10, y: y, width: contentW + 20, height: 56)
            let path = UIBezierPath(roundedRect: headerRect, cornerRadius: 8)
            bgHeaderColor.setFill(); path.fill()

            y = drawCenteredText("TİROİD ULTRASON RAPORU",
                                  at: y + 10, font: .boldSystemFont(ofSize: 17), color: titleColor)
            y += 28

            // ─── Hasta & Tarih ────────────────────────────────────────────
            drawThinDivider(at: y); y += 14

            let df = DateFormatter()
            df.locale = Locale(identifier: "tr-TR")
            df.dateFormat = "dd MMMM yyyy HH:mm"

            y = drawRow(label: "Hasta", value: report.patientFullName, y: y)
            y += 4
            y = drawRow(label: "Tarih", value: df.string(from: report.date), y: y)
            y += 14

            // ─── Tiroid Ölçüleri ──────────────────────────────────────────
            drawThinDivider(at: y); y += 12
            y = drawSectionHeader("TİROİD BEZİ ÖLÇÜLERİ", y: y); y += 10

            if let r = report.rightLobe {
                y = drawRow(label: "Sağ lob", value: r.displayString, y: y); y += 4
            }
            if let l = report.leftLobe {
                y = drawRow(label: "Sol lob", value: l.displayString, y: y); y += 4
            }
            if let i = report.isthmusThickness {
                let s = i.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(i)) mm" : String(format: "%.1f mm", i)
                y = drawRow(label: "İstmus kalınlığı", value: s, y: y); y += 4
            }

            // ─── Nodüller ─────────────────────────────────────────────────
            if !report.nodules.isEmpty {
                y += 10
                y = checkPageBreak(ctx: ctx, y: y, neededSpace: 60)
                drawThinDivider(at: y); y += 12
                y = drawSectionHeader("NODÜLLER", y: y); y += 10

                for (i, nodule) in report.nodules.enumerated() {
                    (ctx, y) = checkPageBreak(ctx: ctx, y: y, neededSpace: 80)

                    // Nodül başlık bandı
                    let bandH: CGFloat = 22
                    let bandRect = CGRect(x: margin - 6, y: y, width: contentW + 12, height: bandH)
                    UIColor(red: 0.85, green: 0.92, blue: 1, alpha: 1).setFill()
                    UIBezierPath(roundedRect: bandRect, cornerRadius: 4).fill()

                    y = drawText("Nodül \(i + 1)",
                                  x: margin, y: y + 3, width: contentW,
                                  font: .boldSystemFont(ofSize: 11), color: sectionColor)
                    y += 8

                    // Açıklama
                    y = drawText(nodule.description,
                                  x: margin + 12, y: y + 2, width: contentW - 12,
                                  font: .systemFont(ofSize: 10.5), color: valueColor)
                    y += 4

                    // TI-RADS
                    if let tr = nodule.tiradsScore, !tr.isEmpty {
                        y = drawRow(label: "TI-RADS", value: tr, y: y,
                                    labelFont: .boldSystemFont(ofSize: 10),
                                    valueFont: .boldSystemFont(ofSize: 10),
                                    valueColor: tiradsColor,
                                    indent: 12)
                    }
                    y += 10
                }
            }

            // ─── Lenf Nodları ─────────────────────────────────────────────
            if !report.lymphNodes.isEmpty {
                y += 6
                y = checkPageBreak(ctx: ctx, y: y, neededSpace: 60)
                drawThinDivider(at: y); y += 12
                y = drawSectionHeader("SERVİKAL LENF NODLARI", y: y); y += 10

                for (i, node) in report.lymphNodes.enumerated() {
                   y = checkPageBreak(ctx: ctx, y: y, neededSpace: 60)

                    let bandRect = CGRect(x: margin - 6, y: y, width: contentW + 12, height: 22)
                    UIColor(red: 0.92, green: 0.96, blue: 0.92, alpha: 1).setFill()
                    UIBezierPath(roundedRect: bandRect, cornerRadius: 4).fill()

                    y = drawText("Lenf Nodu \(i + 1) — \(node.location)",
                                  x: margin, y: y + 3, width: contentW,
                                  font: .boldSystemFont(ofSize: 11),
                                  color: UIColor(red: 0.10, green: 0.40, blue: 0.15, alpha: 1))
                    y += 8

                    y = drawText(node.description,
                                  x: margin + 12, y: y + 2, width: contentW - 12,
                                  font: .systemFont(ofSize: 10.5), color: valueColor)
                    y += 12
                }
            }

            // ─── Alt Çizgi ────────────────────────────────────────────────
            drawThinDivider(at: pageH - 35)
            drawCenteredText("Tiroid Rapor Uygulaması",
                              at: pageH - 28,
                              font: .systemFont(ofSize: 8),
                              color: .lightGray)
        }
    }

    // MARK: - Yardımcı Çizim Fonksiyonları

    @discardableResult
    private static func drawText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat,
                                   font: UIFont, color: UIColor) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style
        ]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: bounds.height), withAttributes: attrs)
        return y + bounds.height
    }

    @discardableResult
    private static func drawCenteredText(_ text: String, at y: CGFloat,
                                          font: UIFont, color: UIColor) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: contentW, height: 200),
            options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: contentW, height: bounds.height), withAttributes: attrs)
        return y + bounds.height
    }

    @discardableResult
    private static func drawSectionHeader(_ text: String, y: CGFloat) -> CGFloat {
        return drawText(text, x: margin, y: y, width: contentW,
                         font: .boldSystemFont(ofSize: 12.5), color: sectionColor)
    }

    @discardableResult
    private static func drawRow(label: String, value: String, y: CGFloat,
                                 labelFont: UIFont = .boldSystemFont(ofSize: 10.5),
                                 valueFont: UIFont = .systemFont(ofSize: 10.5),
                                 valueColor vc: UIColor = valueColor,
                                 indent: CGFloat = 0) -> CGFloat {
        let labelW: CGFloat = 170
        let valueX = margin + indent + labelW + 8

        // Label
        let lAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]
        (label + ":").draw(in: CGRect(x: margin + indent, y: y, width: labelW, height: 20), withAttributes: lAttrs)

        // Value
        let vW = contentW - labelW - 8 - indent
        let vAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: vc]
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let vAttrsFull: [NSAttributedString.Key: Any] = vAttrs.merging([.paragraphStyle: style]) { $1 }
        let bounds = (value as NSString).boundingRect(
            with: CGSize(width: vW, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: vAttrsFull, context: nil)
        (value as NSString).draw(in: CGRect(x: valueX, y: y, width: vW, height: bounds.height),
                                  withAttributes: vAttrsFull)
        return y + max(18, bounds.height)
    }

    private static func drawThinDivider(at y: CGFloat) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.setStrokeColor(dividerColor.cgColor)
        ctx.setLineWidth(0.6)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private static func checkPageBreak(ctx: UIGraphicsPDFRendererContext,
                                    y: CGFloat, neededSpace: CGFloat) -> CGFloat {
    if y + neededSpace > pageH - margin - 40 {
        ctx.beginPage()
        return margin
    }
    return y
}
}
