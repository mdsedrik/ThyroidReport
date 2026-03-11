import SwiftUI

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var parser = ReportParser()
    @State private var showPreview = false

    var body: some View {
        NavigationStack {
            RecordingView(
                speechManager: speechManager,
                parser: parser,
                showPreview: $showPreview
            )
            .navigationDestination(isPresented: $showPreview) {
                PreviewView(parser: parser)
            }
        }
        .onAppear {
            setupSpeech()
        }
    }

    private func setupSpeech() {
        speechManager.onSegmentFinalized = { segment in
            parser.process(segment: segment)
        }
    }
}
