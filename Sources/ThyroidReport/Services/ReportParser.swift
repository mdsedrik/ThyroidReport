import Foundation

class ReportParser: ObservableObject {
    @Published var report = ThyroidReport()
    @Published var feedbackMessages: [FeedbackMessage] = []
    @Published var parserState: ParserState = .waitingPatientName

    private var undoStack: [ThyroidReport] = []

    // MARK: - İç Tipler

    enum ParserState {
        case waitingPatientName
        case waitingMeasurements
        case inNodule
        case inLymphNode
    }

    struct FeedbackMessage: Identifiable {
        var id = UUID()
        var text: String
        var isSuccess: Bool
        var timestamp = Date()
    }

    // MARK: - Ana Giriş Noktası

    func process(segment rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let lower = text.lowercased()

        // 1) Düzeltme komutu
        if isDüzeltKomut(lower) {
            performUndo()
            return
        }

        switch parserState {
        case .waitingPatientName:
            handlePatientName(raw: text, lower: lower)

        case .waitingMeasurements, .inNodule, .inLymphNode:
            // Öncelik sırası: lenf nodu → nodül başlangıcı → ölçüm → devam
            if isLenfNoduBaslangici(lower) {
                handleLymphNode(raw: text, lower: lower)
            } else if isNodülBaslangici(lower) {
                handleNodule(raw: text, lower: lower)
            } else if isSağLobÖlçümü(lower) {
                handleRightLobe(raw: text, lower: lower)
            } else if isSolLobÖlçümü(lower) {
                handleLeftLobe(raw: text, lower: lower)
            } else if isİstmusÖlçümü(lower) {
                handleIsthmus(raw: text, lower: lower)
            } else if parserState == .inNodule {
                appendToLastNodule(raw: text, lower: lower)
            } else if parserState == .inLymphNode {
                appendToLastLymphNode(raw: text)
            } else {
                addFeedback("⚠️ Tanımlanamadı: \"\(text)\"", isSuccess: false)
            }
        }
    }

    // MARK: - Tespit Fonksiyonları

    private func isDüzeltKomut(_ lower: String) -> Bool {
        ["düzelt", "geri al", "iptal", "sil bunu", "yanlış", "olmadı"].contains { lower.contains($0) }
    }

    private func isLenfNoduBaslangici(_ lower: String) -> Bool {
        lower.contains("sağ seviye") || lower.contains("sol seviye") ||
        lower.contains("sag seviye") || lower.contains("sol sevıye")
    }

    private func isNodülBaslangici(_ lower: String) -> Bool {
        let locationWords = [
            "sağ lob", "sol lob", "sag lob", "sol lob",
            "anteriorda", "posteriorda", "lateralde", "medialde",
            "alt pol", "üst pol", "orta kesim", "alt polde", "üst polde",
            "istmusta", "istmus'ta"
        ]
        let hasLocation = locationWords.contains { lower.contains($0) }
        let hasNoduleHint = lower.contains("nodül") || lower.contains("kitle") ||
                            lower.contains("lezyon") || ölçümVarMı(lower)
        return hasLocation && hasNoduleHint
    }

    private func isSağLobÖlçümü(_ lower: String) -> Bool {
        lower.contains("sağ lob") && ölçümVarMı(lower) && !nodülAçıklamasıMı(lower)
    }

    private func isSolLobÖlçümü(_ lower: String) -> Bool {
        lower.contains("sol lob") && ölçümVarMı(lower) && !nodülAçıklamasıMı(lower)
    }

    private func isİstmusÖlçümü(_ lower: String) -> Bool {
        lower.contains("istmus") && (ölçümVarMı(lower) || tekilÖlçümVarMı(lower))
    }

    private func ölçümVarMı(_ text: String) -> Bool {
        let pattern = #"\d+\s*[x×*]\s*\d+"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private func tekilÖlçümVarMı(_ text: String) -> Bool {
        let pattern = #"\d+\s*mm"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private func nodülAçıklamasıMı(_ lower: String) -> Bool {
        let keywords = ["nodül", "anteriorda", "posteriorda", "polde",
                        "hipoekoik", "hiperekoik", "izoekoik", "kitle", "lezyon"]
        return keywords.contains { lower.contains($0) }
    }

    // MARK: - İşleyiciler

    private func handlePatientName(raw: String, lower: String) {
        saveToUndoStack()
        var name = raw

        // "hasta adı ..." gibi ön ekleri temizle
        let prefixes = ["hasta adı", "hasta soyadı", "hasta:", "ad:", "isim:"]
        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                name = String(raw.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            report.patientFirstName = parts[0]
            report.patientLastName = parts.dropFirst().joined(separator: " ")
        } else if let single = parts.first {
            report.patientFirstName = single
        }

        parserState = .waitingMeasurements
        addFeedback("✅ Hasta: \(report.patientFullName)", isSuccess: true)
    }

    private func handleRightLobe(raw: String, lower: String) {
        if let size = çiftÖlçümÇıkar(from: lower) {
            saveToUndoStack()
            report.rightLobe = size
            addFeedback("✅ Sağ lob: \(size.displayString)", isSuccess: true)
        } else {
            addFeedback("⚠️ Sağ lob ölçüleri anlaşılamadı.", isSuccess: false)
        }
    }

    private func handleLeftLobe(raw: String, lower: String) {
        if let size = çiftÖlçümÇıkar(from: lower) {
            saveToUndoStack()
            report.leftLobe = size
            addFeedback("✅ Sol lob: \(size.displayString)", isSuccess: true)
        } else {
            addFeedback("⚠️ Sol lob ölçüleri anlaşılamadı.", isSuccess: false)
        }
    }

    private func handleIsthmus(raw: String, lower: String) {
        if let mm = tekilÖlçümÇıkar(from: lower) {
            saveToUndoStack()
            report.isthmusThickness = mm
            let str = mm.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(mm)) : String(format: "%.1f", mm)
            addFeedback("✅ İstmus: \(str) mm", isSuccess: true)
        } else {
            addFeedback("⚠️ İstmus kalınlığı anlaşılamadı.", isSuccess: false)
        }
    }

    private func handleNodule(raw: String, lower: String) {
        saveToUndoStack()
        var nodule = Nodule()
        nodule.location = lokasyonÇıkar(from: raw)
        nodule.description = raw

        if let tr = tiradsÇıkar(from: lower) {
            nodule.tiradsScore = tr
        }

        report.nodules.append(nodule)
        parserState = .inNodule
        addFeedback("✅ Nodül \(report.nodules.count): \(nodule.location)", isSuccess: true)
    }

    private func appendToLastNodule(raw: String, lower: String) {
        guard !report.nodules.isEmpty else { return }
        saveToUndoStack()

        let idx = report.nodules.count - 1

        // TI-RADS skoru mu?
        if let tr = tiradsÇıkar(from: lower) {
            report.nodules[idx].tiradsScore = tr
            addFeedback("✅ Nodül \(idx + 1) TI-RADS: \(tr)", isSuccess: true)
            return
        }

        // Açıklamaya ekle
        report.nodules[idx].description += " \(raw)"
        addFeedback("✅ Nodül \(idx + 1) açıklaması güncellendi.", isSuccess: true)
    }

    private func handleLymphNode(raw: String, lower: String) {
        saveToUndoStack()
        var node = LymphNode()
        node.location = lenfNoduLokasyonuÇıkar(from: raw)
        node.description = raw

        report.lymphNodes.append(node)
        parserState = .inLymphNode
        addFeedback("✅ Lenf nodu: \(node.location)", isSuccess: true)
    }

    private func appendToLastLymphNode(raw: String) {
        guard !report.lymphNodes.isEmpty else { return }
        saveToUndoStack()
        let idx = report.lymphNodes.count - 1
        report.lymphNodes[idx].description += " \(raw)"
        addFeedback("✅ Lenf nodu açıklaması güncellendi.", isSuccess: true)
    }

    // MARK: - Ayıklama Fonksiyonları

    private func çiftÖlçümÇıkar(from text: String) -> LobeSize? {
        // Hem 3'lü hem de 2'li ölçümleri destekle
        let p3 = #"(\d+(?:[.,]\d+)?)\s*[x×*]\s*(\d+(?:[.,]\d+)?)\s*[x×*]\s*(\d+(?:[.,]\d+)?)"#
        if let regex = try? NSRegularExpression(pattern: p3),
           let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let d = (1...3).compactMap { i -> Double? in
                guard let r = Range(m.range(at: i), in: text) else { return nil }
                return Double(text[r].replacingOccurrences(of: ",", with: "."))
            }
            if d.count == 3 { return LobeSize(d1: d[0], d2: d[1], d3: d[2]) }
        }
        return nil
    }

    private func tekilÖlçümÇıkar(from text: String) -> Double? {
        let pattern = #"(\d+(?:[.,]\d+)?)\s*(?:mm|milimetre)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return Double(text[r].replacingOccurrences(of: ",", with: "."))
    }

    private func tiradsÇıkar(from text: String) -> String? {
        let pattern = #"ti[-\s]?rads\s*[:\s]?\s*(tr\s*)?([1-5]\s*[a-e]?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 2), in: text) else { return nil }
        let score = text[r].trimmingCharacters(in: .whitespaces)
        return "TR\(score.uppercased())"
    }

    private func lokasyonÇıkar(from text: String) -> String {
        // Ölçüm başlamadan önceki kısmı al
        let pattern = #"\d+\s*[x×*]\s*\d+"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            let location = String(text[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !location.isEmpty { return location }
        }
        // Ölçüm yoksa ilk 6 kelime
        return text.split(separator: " ").prefix(6).joined(separator: " ")
    }

    private func lenfNoduLokasyonuÇıkar(from text: String) -> String {
        let pattern = #"(sağ|sol|sag)\s+seviye\s*\d*[a-zA-Z]?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 0), in: text) else {
            return text.split(separator: " ").prefix(4).joined(separator: " ")
        }
        return String(text[r])
    }

    // MARK: - Undo & Feedback

    private func saveToUndoStack() {
        undoStack.append(report)
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func performUndo() {
        if undoStack.isEmpty {
            addFeedback("⚠️ Geri alınacak işlem yok.", isSuccess: false)
        } else {
            report = undoStack.removeLast()
            // State'i güncelle
            if !report.lymphNodes.isEmpty { parserState = .inLymphNode }
            else if !report.nodules.isEmpty { parserState = .inNodule }
            else if report.patientFirstName.isEmpty { parserState = .waitingPatientName }
            else { parserState = .waitingMeasurements }
            addFeedback("↩️ Son işlem geri alındı.", isSuccess: true)
        }
    }

    func addFeedback(_ message: String, isSuccess: Bool) {
        DispatchQueue.main.async {
            self.feedbackMessages.append(
                FeedbackMessage(text: message, isSuccess: isSuccess)
            )
            if self.feedbackMessages.count > 12 {
                self.feedbackMessages.removeFirst()
            }
        }
    }

    func resetReport() {
        report = ThyroidReport()
        feedbackMessages = []
        parserState = .waitingPatientName
        undoStack = []
    }
}
