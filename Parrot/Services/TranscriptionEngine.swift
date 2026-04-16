import AVFoundation
import WhisperKit
import Combine
import os

/// Wraps WhisperKit for real-time streaming transcription.
@Observable
final class TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private var audioBuffer: [Float] = []
    private let bufferLock = OSAllocatedUnfairLock()
    private var transcriptionTask: Task<Void, Never>?

    private(set) var isReady = false
    private(set) var isTranscribing = false
    private(set) var currentText = ""
    private(set) var modelState: ModelState = .notLoaded

    /// Called when a finalized transcript segment is ready
    var onSegment: ((TranscriptionResult) -> Void)?

    enum ModelState {
        case notLoaded
        case downloading(progress: Double)
        case loading
        case ready
        case error(String)
    }

    struct TranscriptionResult {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
        let confidence: Float?
    }

    // MARK: - Model Management

    /// Load WhisperKit with the specified model
    func loadModel(_ modelName: String = "base") async {
        modelState = .loading
        do {
            let config = WhisperKitConfig(
                model: modelName,
                verbose: false,
                logLevel: .none,
                prewarm: true,
                load: true
            )
            whisperKit = try await WhisperKit(config)
            modelState = .ready
            isReady = true
        } catch {
            modelState = .error(error.localizedDescription)
            isReady = false
        }
    }

    // MARK: - Audio Input

    /// Feed audio buffer from AudioCaptureManager
    func appendAudio(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        bufferLock.withLock {
            audioBuffer.append(contentsOf: samples)
        }
    }

    // MARK: - Transcription Loop

    /// Start the continuous transcription loop
    func startTranscribing(meetingStartTime: Date) {
        guard isReady else { return }
        isTranscribing = true

        transcriptionTask = Task { [weak self] in
            guard let self else { return }

            // Process audio in chunks (~2 seconds at 16kHz)
            let chunkSize = 32000 // 2 seconds at 16kHz
            var processedSamples = 0

            while !Task.isCancelled && self.isTranscribing {
                try? await Task.sleep(for: .milliseconds(500))

                let availableSamples = self.bufferLock.withLock { self.audioBuffer.count }

                guard availableSamples - processedSamples >= chunkSize else { continue }

                let chunk: [Float] = self.bufferLock.withLock {
                    Array(self.audioBuffer[processedSamples..<availableSamples])
                }

                let startTime = Double(processedSamples) / 16000.0
                processedSamples = availableSamples

                do {
                    guard let whisperKit = self.whisperKit else { continue }
                    let result = try await whisperKit.transcribe(audioArray: chunk)

                    for transcription in result {
                        let text = transcription.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { continue }

                        let endTime = Double(processedSamples) / 16000.0
                        let avgLogProb = transcription.segments.map(\.avgLogprob).reduce(0, +)
                            / Float(max(transcription.segments.count, 1))

                        await MainActor.run {
                            self.currentText = text
                            self.onSegment?(TranscriptionResult(
                                text: text,
                                startTime: startTime,
                                endTime: endTime,
                                confidence: avgLogProb
                            ))
                        }
                    }
                } catch {
                    print("Transcription error: \(error)")
                }
            }
        }
    }

    /// Stop transcription
    func stopTranscribing() {
        isTranscribing = false
        transcriptionTask?.cancel()
        transcriptionTask = nil

        bufferLock.withLock {
            audioBuffer.removeAll()
        }

        currentText = ""
    }
}
