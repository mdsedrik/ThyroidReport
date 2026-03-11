import SwiftUI

struct PreviewView: View {
    @ObservedObject var parser: ReportParser
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var pdfData: Data? = nil
    @State private var showSuccess = false
    @State private var savedURL: URL? = nil

    var body: some View {
        Form {
            // ── Hasta Bilgileri ───────────────────────────────────────────
            Section("Hasta Bilgileri") {
                LabeledTextField("Ad", text: $parser.report.patientFirstName)
                LabeledTextField("Soyad", text: $parser.report.patientLastName)
            }

            // ── Tiroid Ölçüleri ───────────────────────────────────────────
            Section("Tiroid Bezi Ölçüleri") {
                LobeEditor(title: "Sağ Lob", lobe: $parser.report.rightLobe)
                LobeEditor(title: "Sol Lob", lobe: $parser.report.leftLobe)
                IsthmusEditor(mm: $parser.report.isthmusThickness)
            }

            // ── Nodüller ──────────────────────────────────────────────────
            if !parser.report.nodules.isEmpty {
                Section("Nodüller") {
                    ForEach($parser.report.nodules) { $nodule in
                        NoduleEditor(nodule: $nodule)
                    }
                    .onDelete { parser.report.nodules.remove(atOffsets: $0) }
                }
            }

            // ── Lenf Nodları ──────────────────────────────────────────────
            if !parser.report.lymphNodes.isEmpty {
                Section("Servikal Lenf Nodları") {
                    ForEach($parser.report.lymphNodes) { $node in
                        LymphNodeEditor(node: $node)
                    }
                    .onDelete { parser.report.lymphNodes.remove(atOffsets: $0) }
                }
            }

            // ── PDF Oluştur ───────────────────────────────────────────────
            Section {
                Button {
                    generateAndShare()
                } label: {
                    HStack {
                        Spacer()
                        Label("PDF Oluştur ve Kaydet", systemImage: "arrow.down.doc.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.accentColor)
            }
        }
        .navigationTitle("Raporu İncele")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                PDFShareSheet(data: data, fileName: parser.report.fileName)
            }
        }
        .alert("PDF Kaydedildi", isPresented: $showSuccess) {
            Button("Tamam") { dismiss() }
        } message: {
            Text("Rapor Dosyalar uygulamasına kaydedildi:\n\(parser.report.fileName)")
        }
    }

    private func generateAndShare() {
        let data = PDFGenerator.generate(from: parser.report)
        pdfData = data
        showShareSheet = true
    }
}

// MARK: - Alt Bileşenler

struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            TextField(label, text: $text)
        }
    }
}

struct LobeEditor: View {
    let title: String
    @Binding var lobe: LobeSize?

    @State private var d1: String = ""
    @State private var d2: String = ""
    @State private var d3: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                mmField("D1", value: $d1)
                Text("×").foregroundColor(.secondary)
                mmField("D2", value: $d2)
                Text("×").foregroundColor(.secondary)
                mmField("D3", value: $d3)
                Text("mm").font(.caption).foregroundColor(.secondary)
            }

            if let l = lobe {
                Text("Volüm: \(String(format: "%.1f", l.volume)) mL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if let l = lobe {
                d1 = formatMM(l.d1); d2 = formatMM(l.d2); d3 = formatMM(l.d3)
            }
        }
        .onChange(of: d1) { _ in updateLobe() }
        .onChange(of: d2) { _ in updateLobe() }
        .onChange(of: d3) { _ in updateLobe() }
    }

    private func mmField(_ placeholder: String, value: Binding<String>) -> some View {
        TextField(placeholder, text: value)
            .keyboardType(.decimalPad)
            .frame(width: 52)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
    }

    private func updateLobe() {
        guard let v1 = Double(d1.replacingOccurrences(of: ",", with: ".")),
              let v2 = Double(d2.replacingOccurrences(of: ",", with: ".")),
              let v3 = Double(d3.replacingOccurrences(of: ",", with: ".")) else {
            if d1.isEmpty && d2.isEmpty && d3.isEmpty { lobe = nil }
            return
        }
        lobe = LobeSize(d1: v1, d2: v2, d3: v3)
    }

    private func formatMM(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

struct IsthmusEditor: View {
    @Binding var mm: Double?
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text("İstmus")
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            TextField("Kalınlık", text: $text)
                .keyboardType(.decimalPad)
            Text("mm").font(.caption).foregroundColor(.secondary)
        }
        .onAppear {
            if let v = mm {
                text = v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
            }
        }
        .onChange(of: text) { newVal in
            mm = Double(newVal.replacingOccurrences(of: ",", with: "."))
        }
    }
}

struct NoduleEditor: View {
    @Binding var nodule: Nodule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                Text("Nodül")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            TextField("Lokasyon", text: $nodule.location)
                .font(.caption)

            TextEditor(text: $nodule.description)
                .font(.system(size: 13))
                .frame(minHeight: 70)

            HStack {
                Text("TI-RADS:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Örn: TR4", text: Binding(
                    get: { nodule.tiradsScore ?? "" },
                    set: { nodule.tiradsScore = $0.isEmpty ? nil : $0 }
                ))
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LymphNodeEditor: View {
    @Binding var node: LymphNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Lenf Nodu")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            TextField("Lokasyon (örn: Sağ seviye 3)", text: $node.location)
                .font(.caption)

            TextEditor(text: $node.description)
                .font(.system(size: 13))
                .frame(minHeight: 60)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PDF Paylaşım Sayfası

struct PDFShareSheet: UIViewControllerRepresentable {
    let data: Data
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Geçici dosyaya yaz
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)

        let vc = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
