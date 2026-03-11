import Foundation

// MARK: - Ana Rapor Modeli

struct ThyroidReport: Identifiable, Codable {
    var id: UUID = UUID()
    var patientFirstName: String = ""
    var patientLastName: String = ""
    var date: Date = Date()
    var rightLobe: LobeSize? = nil
    var leftLobe: LobeSize? = nil
    var isthmusThickness: Double? = nil
    var nodules: [Nodule] = []
    var lymphNodes: [LymphNode] = []

    var patientFullName: String {
        let full = "\(patientFirstName) \(patientLastName)"
            .trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "Hasta Adı Girilmedi" : full
    }

    var fileName: String {
        let safe = patientFullName
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr-TR"))
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted)
            .joined()
        let df = DateFormatter()
        df.dateFormat = "ddMMyyyy"
        return "\(safe)_\(df.string(from: date)).pdf"
    }
}

// MARK: - Lob Ölçüleri

struct LobeSize: Codable {
    var d1: Double  // mm
    var d2: Double  // mm
    var d3: Double  // mm

    var volume: Double {
        d1 * d2 * d3 * 0.479
    }

    var displayString: String {
        let v = String(format: "%.1f", volume)
        return "\(formatMM(d1)) x \(formatMM(d2)) x \(formatMM(d3)) mm (Volüm: \(v) mL)"
    }

    private func formatMM(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Nodül

struct Nodule: Identifiable, Codable {
    var id: UUID = UUID()
    var location: String = ""
    var description: String = ""
    var tiradsScore: String? = nil
}

// MARK: - Lenf Nodu

struct LymphNode: Identifiable, Codable {
    var id: UUID = UUID()
    var location: String = ""
    var description: String = ""
}
