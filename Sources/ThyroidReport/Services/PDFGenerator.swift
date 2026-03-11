import UIKit
import PDFKit

class PDFGenerator {

    // MARK: - Sabitler
    private static let pageW: CGFloat = 595.2
    private static let pageH: CGFloat = 841.8
    private static let margin: CGFloat = 55
    private static var contentW: CGFloat { pageW - 2 * margin }

    private static let titleColor   = UIColor(red: 0.08, green: 0.25, blue: 0.45, alpha: 1)
    private static let sectionColor = UIColor(red: 0.13, green: 0.40, blue: 0.65, alpha: 1)
    private static let labelColor   = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
    private static let valueColor   = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
    private static let dividerColor = UIColor(red: 0.13, green: 0.40, blue: 0.65, alpha: 0.4)
    private static let tiradsColor  = UIColor(red: 0.60, green: 0.10, blue: 0.10, alpha: 1)
    private static let bgHeader     = UIColor(red: 0.90, green: 0.95, blue: 1.00, alpha: 1)

    // MARK: - Üretim

    static func generate(from report: ThyroidReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Tiroid Ultrason Raporu - \(report.patientFullName)"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
            format: format
        )

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // Başlık kutusu
            let headerRect = CGRect(x: margin - 10, y: y, width: contentW + 20, height: 56)
            bgHeader.setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 8).fill()
            y = drawCentered("TİROİD ULTRASON RAPORU", at: y + 10,
                             font: .boldSystemFont(ofSize: 17), color: titleColor)
            y += 30

            // Hasta & Tarih
            drawDivider(at: y); y += 14
            let df = DateFormatter()
            df.locale = Locale(identifier: "tr-TR")
            df.dateFormat = "dd MMMM yyyy HH:mm"
            y = drawRow(label: "Hasta", value: report.patientFullName, y: y); y += 4
            y = drawRow(label: "Tarih", value: df.string(from: report.date), y: y); y += 14

            // Lob ölçüleri
            drawDivider(at: y); y += 12
            y = drawSection("TİROİD BEZİ ÖLÇÜLERİ", y: y); y += 10
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

            // Nodüller
            if !report.nodules.isEmpty {
                y += 10
                y = pageBreakIfNeeded(ctx: ctx, y: y, need: 60)
                drawDivider(at: y); y += 12
                y = drawSection("NODÜLLER", y: y); y += 10

                for (i, nodule) in report.nodules.enumerated() {
                    y = pageBreakIfNeeded(ctx: ctx, y: y, need: 80)

                    let bandRect = CGRect(x: margin - 6, y: y, width: contentW + 12, height: 22)
                    UIColor(red: 0.85, green: 0.92, blue: 1, alpha: 1).setFill()
                    UIBezierPath(roundedRect: bandRect, cornerRadius: 4).fill()
                    y = drawText("Nodül \(i + 1)", x: margin, y: y + 3, w: contentW,
                                 font: .boldSystemFont(ofSize: 11), color: sectionColor)
                    y += 8
                    y = drawText(nodule.description, x: margin + 12, y: y + 2,
                                 w: contentW - 12, font: .systemFont(ofSize: 10.5), color: valueColor)
                    y += 4
                    if let tr = nodule.tiradsScore, !tr.isEmpty {
                        y = drawRow(label: "TI-RADS", value: tr, y: y,
                                    labelFont: .boldSystemFont(ofSize: 10),
                                    valueFont: .boldSystemFont(ofSize: 10),
                                    vc: tiradsColor, indent: 12)
                    }
                    y += 10
                }
            }

            // Lenf nodları
            if !report.lymphNodes.isEmpty {
                y += 6
                y = pageBreakIfNeeded(ctx: ctx, y: y, need: 60)
                drawDivider(at: y); y += 12
                y = drawSection("SERVİKAL LENF NODLARI", y: y); y += 10

                for (i, node) in report.lymphNodes.enumerated() {
                    y = pageBreakIfNeeded(ctx: ctx, y: y, need: 60)

                    let bandRect = CGRect(x: margin - 6, y: y, width: contentW + 12, height: 22)
                    UIColor(red: 0.92, green: 0.96, blue: 0.92, alpha: 1).setFill()
                    UIBezierPath(roundedRect: bandRect, cornerRadius: 4).fill()
                    y = drawText("Lenf Nodu \(i + 1) — \(node.location)",
                                 x: margin, y: y + 3, w: contentW,
                                 font: .boldSystemFont(ofSize: 11),
                                 color: UIColor(red: 0.10, green: 0.40, blue: 0.15, alpha: 1))
                    y += 8
                    y = drawText(node.description, x: margin + 12, y: y + 2,
                                 w: contentW - 12, font: .systemFont(ofSize: 10.5), color: valueColor)
                    y += 12
                }
            }

            // Alt çizgi
            drawDivider(at: pageH - 35)
            drawCentered("Tiroid Rapor Uygulaması", at: pageH - 28,
                         font: .systemFont(ofSize: 8), color: .lightGray)
        }
    }

    // MARK: - Sayfa geçişi

    @discardableResult
    private static func pageBreakIfNeeded(ctx: UIGraphicsPDFRendererContext,
                                           y: CGFloat, need: CGFloat) -> CGFloat {
        if y + need > pageH - margin - 40 {
            ctx.beginPage()
            return margin
        }
        return y
    }

    // MARK: - Çizim yardımcıları

    @discardableResult
    private static func drawText(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat,
                                  font: UIFont, color: UIColor) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style
        ]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: w, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil)
        (text as NSString).draw(in: CGRect(x: x, y: y, width: w, height: bounds.height),
                                withAttributes: attrs)
        return y + bounds.height
    }

    @discardableResult
    private static func drawCentered(_ text: String, at y: CGFloat,
                                      font: UIFont, color: UIColor) -> CGFloat {
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: style
        ]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: contentW, height: 200),
            options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        (text as NSString).draw(
            in: CGRect(x: margin, y: y, width: contentW, height: bounds.height),
            withAttributes: attrs)
        return y + bounds.height
    }

    @discardableResult
    private static func drawSection(_ text: String, y: CGFloat) -> CGFloat {
        return drawText(text, x: margin, y: y, w: contentW,
                        font: .boldSystemFont(ofSize: 12.5), color: sectionColor)
    }

    @discardableResult
    private static func drawRow(label: String, value: String, y: CGFloat,
                                 labelFont: UIFont = .boldSystemFont(ofSize: 10.5),
                                 valueFont: UIFont = .systemFont(ofSize: 10.5),
                                 vc: UIColor = valueColor,
                                 indent: CGFloat = 0) -> CGFloat {
        let labelW: CGFloat = 170
        let valueX = margin + indent + labelW + 8
        let lAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]
        (label + ":").draw(in: CGRect(x: margin + indent, y: y, width: labelW, height: 20),
                           withAttributes: lAttrs)
        let vW = contentW - labelW - 8 - indent
        let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping
        let vAttrs: [NSAttributedString.Key: Any] = [
            .font: valueFont, .foregroundColor: vc, .paragraphStyle: style
        ]
        let bounds = (value as NSString).boundingRect(
            with: CGSize(width: vW, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: vAttrs, context: nil)
        (value as NSString).draw(
            in: CGRect(x: valueX, y: y, width: vW, height: bounds.height),
            withAttributes: vAttrs)
        return y + max(18, bounds.height)
    }

    private static func drawDivider(at y: CGFloat) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.setStrokeColor(dividerColor.cgColor)
        ctx.setLineWidth(0.6)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }
}
