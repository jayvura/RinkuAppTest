import Foundation
import AVFoundation
import Combine

/// Service for text-to-speech audio reminders
final class AudioService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioService()
    
    @Published var isSpeaking = false
    @Published var isEnabled = true
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private let enabledKey = "audio_reminders_enabled"
    
    private override init() {
        super.init()
        
        // Load saved preference
        if UserDefaults.standard.object(forKey: enabledKey) != nil {
            isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }
        
        // Set up delegate
        synthesizer.delegate = self
        
        // Configure audio session for playback
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggle audio reminders on/off
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        
        if !enabled {
            stop()
        }
    }
    
    /// Speak a recognition reminder for a loved one
    func speakRecognitionReminder(for lovedOne: LovedOne) {
        guard isEnabled else { return }
        
        // Build the reminder message
        var message = "This is \(lovedOne.displayName), your \(lovedOne.relationship)."
        
        if let memoryPrompt = lovedOne.memoryPrompt, !memoryPrompt.isEmpty {
            message += " \(memoryPrompt)"
        }
        
        speak(message)
    }
    
    /// Speak custom text
    func speak(_ text: String) {
        guard isEnabled else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Activate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure voice settings for clarity
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Use a high-quality voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        // Add slight pauses for better comprehension
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.2
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        synthesizer.speak(utterance)
    }
    
    /// Stop speaking
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
