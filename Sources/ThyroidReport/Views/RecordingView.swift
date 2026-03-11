import SwiftUI

struct RecordingView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var parser: ReportParser
    @Binding var showPreview: Bool

    @State private var showPermissionAlert = false
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Üst: Durum Özeti ──────────────────────────────────────
                statusSummaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // ── Orta: Geri Bildirim Listesi ───────────────────────────
                feedbackList
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Spacer()

                // ── Canlı Transkript ──────────────────────────────────────
                if !speechManager.liveText.isEmpty {
                    liveTranscriptBubble
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // ── Alt: Kayıt Butonu + Eylemler ─────────────────────────
                bottomBar
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("Tiroid Rapor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sıfırla") { showResetAlert = true }
                    .foregroundColor(.red)
            }
        }
        .alert("İzin Gerekli", isPresented: $showPermissionAlert) {
            Button("Ayarları Aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Uygulamanın çalışması için Mikrofon ve Konuşma Tanıma izinleri gereklidir. Lütfen Ayarlar'dan izin verin.")
        }
        .alert("Raporu Sıfırla", isPresented: $showResetAlert) {
            Button("Sıfırla", role: .destructive) {
                if speechManager.isRecording { speechManager.stopRecording() }
                parser.resetReport()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Tüm girilen bilgiler silinecek. Emin misiniz?")
        }
    }

    // MARK: - Alt Bileşenler

    private var statusSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.accentColor)
                Text(parser.report.patientFirstName.isEmpty
                     ? "Hasta adı bekleniyor..."
                     : parser.report.patientFullName)
                    .font(.headline)
                    .foregroundColor(parser.report.patientFirstName.isEmpty ? .secondary : .primary)
                Spacer()
                Text(stateLabel)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stateColor.opacity(0.15))
                    .foregroundColor(stateColor)
                    .cornerRadius(8)
            }

            HStack(spacing: 16) {
                statBadge(icon: "circle.lefthalf.filled", value: lobeSummary)
                statBadge(icon: "dot.radiowaves.left.and.right", value: "\(parser.report.nodules.count) nodül")
                statBadge(icon: "circle.grid.3x3", value: "\(parser.report.lymphNodes.count) lenf")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func statBadge(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var feedbackList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(parser.feedbackMessages) { msg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(msg.text)
                                .font(.system(size: 13))
                                .foregroundColor(msg.isSuccess ? .primary : .orange)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            msg.isSuccess
                                ? Color(.tertiarySystemGroupedBackground)
                                : Color.orange.opacity(0.08)
                        )
                        .cornerRadius(8)
                        .id(msg.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 260)
            .onChange(of: parser.feedbackMessages.count) { _ in
                if let last = parser.feedbackMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var liveTranscriptBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform")
                .foregroundColor(.accentColor)
                .symbolEffect(.variableColor.iterative)
            Text(speechManager.liveText)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(12)
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            // Büyük kayıt butonu
            Button {
                toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(speechManager.isRecording ? Color.red : Color.accentColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: (speechManager.isRecording ? Color.red : Color.accentColor).opacity(0.4),
                                radius: speechManager.isRecording ? 16 : 8)
                        .scaleEffect(speechManager.isRecording ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: speechManager.isRecording)

                    Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }

            Text(speechManager.isRecording ? "Kaydı Durdur" : "Kayda Başla")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Önizle butonu
            if !parser.report.patientFirstName.isEmpty {
                Button {
                    if speechManager.isRecording { speechManager.stopRecording() }
                    showPreview = true
                } label: {
                    Label("Önizle ve PDF Oluştur", systemImage: "doc.text.magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Yardımcı

    private var stateLabel: String {
        switch parser.parserState {
        case .waitingPatientName:   return "Hasta adı"
        case .waitingMeasurements:  return "Ölçüm"
        case .inNodule:             return "Nodül modu"
        case .inLymphNode:          return "Lenf nodu"
        }
    }

    private var stateColor: Color {
        switch parser.parserState {
        case .waitingPatientName:   return .orange
        case .waitingMeasurements:  return .blue
        case .inNodule:             return .purple
        case .inLymphNode:          return .green
        }
    }

    private var lobeSummary: String {
        let r = parser.report.rightLobe != nil ? "S" : "-"
        let l = parser.report.leftLobe  != nil ? "S" : "-"
        return "Sağ:\(r) Sol:\(l)"
    }

    private func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            guard speechManager.canRecord else {
                showPermissionAlert = true
                return
            }
            speechManager.startRecording()
        }
    }
}
