import Speech
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var liveText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var micAuthorizationStatus: AVAudioSession.RecordPermission = .undetermined

    var onSegmentFinalized: ((String) -> Void)?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var lastTranscription = ""
    private var isRestarting = false
    private let sessionQueue = DispatchQueue(label: "com.tiroidrapor.sessionQueue")

    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
        speechRecognizer?.delegate = self
        requestAuthorizations()
    }

    func requestAuthorizations() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.micAuthorizationStatus = granted ? .granted : .denied
            }
        }
    }

    var canRecord: Bool {
        authorizationStatus == .authorized && micAuthorizationStatus == .granted
    }

    func startRecording() {
        guard canRecord else { return }
        guard !audioEngine.isRunning else { return }
        guard !isRestarting else { return }

        do {
            try startRecognitionSession()
        } catch {
            print("Kayıt başlatılamadı: \(error)")
        }
    }

    func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        isRestarting = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        DispatchQueue.main.async {
            self.isRecording = false
            if !self.lastTranscription.isEmpty {
                let text = self.lastTranscription
                self.lastTranscription = ""
                self.liveText = ""
                self.onSegmentFinalized?(text)
            }
        }
    }

    private func startRecognitionSession() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        recognitionRequest.contextualStrings = medicalHints()

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.liveText = text
                    self.lastTranscription = text
                }
                self.resetSilenceTimer()

                if result.isFinal {
                    DispatchQueue.main.async {
                        self.finalizeCurrentSegment()
                        if self.isRecording {
                            self.restartSession()
                        }
                    }
                }
            }

            if let error = error as NSError? {
                if error.code == 1110 || error.code == 203 {
                    DispatchQueue.main.async {
                        if self.isRecording && !self.isRestarting {
                            self.restartSession()
                        }
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    private func finalizeCurrentSegment() {
        guard !lastTranscription.isEmpty else { return }
        let text = lastTranscription
        lastTranscription = ""
        liveText = ""
        onSegmentFinalized?(text)
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self, !self.lastTranscription.isEmpty else { return }
            DispatchQueue.main.async {
                self.finalizeCurrentSegment()
                if self.isRecording {
                    self.restartSession()
                }
            }
        }
    }

    private func restartSession() {
        guard isRecording, !isRestarting else { return }
        isRestarting = true

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            guard self.isRecording else {
                self.isRestarting = false
                return
            }
            self.isRestarting = false
            try? self.startRecognitionSession()
        }
    }

    private func medicalHints() -> [String] {
        return [
            "hipoekoik", "hiperekoik", "izoekoik",
            "mikrokalsifikasyon", "makrokalsifikasyon",
            "vaskülarite", "heterojen", "homojen",
            "lobüle", "irregüler", "düzensiz",
            "TI-RADS", "tirads", "nodül",
            "anteriorda", "posteriorda", "lateralde",
            "medialde", "istmus", "parankima",
            "hipovolemi", "ekojenik", "anekoik",
            "sağ seviye", "sol seviye",
            "düzelt", "geri al"
        ]
    }
}

extension SpeechManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available && isRecording {
            stopRecording()
        }
    }
}
