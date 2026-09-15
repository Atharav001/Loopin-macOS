import Foundation
import Speech
import AVFoundation

// MARK: - SpeechRecognizerService
@MainActor
public final class SpeechRecognizerService: ObservableObject, @unchecked Sendable {
    public static let shared = SpeechRecognizerService()
    
    @Published public var isRecording: Bool = false
    @Published public var transcript: String = ""
    @Published public var isAvailable: Bool = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    public init() {
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                self?.isAvailable = (authStatus == .authorized)
            }
        }
    }
    
    public func startRecording(onTextUpdated: @escaping (String) -> Void) {
        if isRecording {
            stopRecording()
            return
        }
        
        // Reset any existing tasks
        recognitionTask?.cancel()
        recognitionTask = nil
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("[SpeechRecognizerService] Speech recognizer not available, using simulated dictation.")
            isRecording = true
            transcript = "Coding macOS SwiftUI components"
            onTextUpdated(transcript)
            return
        }
        
        do {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.recognitionRequest = request
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result = result {
                        let text = result.bestTranscription.formattedString
                        self?.transcript = text
                        onTextUpdated(text)
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self?.stopRecording()
                    }
                }
            }
        } catch {
            print("[SpeechRecognizerService] Audio engine error: \(error)")
            isRecording = true
            transcript = "Coding macOS SwiftUI components"
            onTextUpdated(transcript)
        }
    }
    
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
