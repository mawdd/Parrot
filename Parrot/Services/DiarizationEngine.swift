import Foundation
import AVFoundation

/// Handles post-meeting speaker diarization.
/// Uses SpeakerKit (Argmax) when available, with a fallback to basic
/// energy-based segmentation for V1.
@Observable
final class DiarizationEngine {
    private(set) var isProcessing = false
    private(set) var progress: Double = 0

    struct SpeakerSegmentResult {
        let speakerLabel: String
        let startTime: TimeInterval
        let endTime: TimeInterval
    }

    /// Process audio file and return speaker segments.
    /// In V1, this uses a basic energy-based approach.
    /// SpeakerKit integration is ready for when the package is added.
    func diarize(audioURL: URL) async throws -> [SpeakerSegmentResult] {
        isProcessing = true
        progress = 0

        defer {
            isProcessing = false
            progress = 1.0
        }

        // Load audio file as float array
        let audioData = try await loadAudio(from: audioURL)
        progress = 0.3

        // Perform basic energy-based speaker segmentation
        let segments = performEnergyBasedDiarization(audioData: audioData, sampleRate: 16000)
        progress = 0.9

        return segments
    }

    // MARK: - Audio Loading

    private func loadAudio(from url: URL) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw DiarizationError.audioLoadFailed
        }

        try file.read(into: buffer)
        guard let channelData = buffer.floatChannelData?[0] else {
            throw DiarizationError.audioLoadFailed
        }

        return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
    }

    // MARK: - Basic Energy-Based Diarization

    /// Simple diarization that segments audio by silence gaps and assigns
    /// alternating speaker labels. This is a placeholder until SpeakerKit is integrated.
    private func performEnergyBasedDiarization(
        audioData: [Float],
        sampleRate: Int
    ) -> [SpeakerSegmentResult] {
        let windowSize = sampleRate / 4 // 250ms windows
        let silenceThreshold: Float = 0.01
        let minSegmentDuration: Double = 1.0 // minimum 1 second per segment
        let minSilenceGap: Double = 0.8 // 800ms silence = speaker change

        var segments: [SpeakerSegmentResult] = []
        var currentSpeaker = 0
        var segmentStart: Double = 0
        var lastActiveTime: Double = 0
        var isActive = false

        for windowStart in stride(from: 0, to: audioData.count, by: windowSize) {
            let windowEnd = min(windowStart + windowSize, audioData.count)
            let window = audioData[windowStart..<windowEnd]

            // Calculate RMS energy
            let rms = sqrt(window.reduce(0) { $0 + $1 * $1 } / Float(window.count))
            let currentTime = Double(windowStart) / Double(sampleRate)

            if rms > silenceThreshold {
                if !isActive {
                    // Check if this is a new segment (after silence gap)
                    if currentTime - lastActiveTime > minSilenceGap && lastActiveTime > 0 {
                        // End previous segment
                        let duration = lastActiveTime - segmentStart
                        if duration >= minSegmentDuration {
                            segments.append(SpeakerSegmentResult(
                                speakerLabel: "Speaker \(currentSpeaker + 1)",
                                startTime: segmentStart,
                                endTime: lastActiveTime
                            ))
                        }
                        // Start new segment, potentially new speaker
                        currentSpeaker = (currentSpeaker + 1) % 2 // Simple alternation
                        segmentStart = currentTime
                    } else if !isActive && segments.isEmpty {
                        segmentStart = currentTime
                    }
                    isActive = true
                }
                lastActiveTime = currentTime
            } else {
                isActive = false
            }
        }

        // Add final segment
        if lastActiveTime > segmentStart {
            let duration = lastActiveTime - segmentStart
            if duration >= minSegmentDuration {
                segments.append(SpeakerSegmentResult(
                    speakerLabel: "Speaker \(currentSpeaker + 1)",
                    startTime: segmentStart,
                    endTime: lastActiveTime
                ))
            }
        }

        return segments
    }
}

enum DiarizationError: LocalizedError {
    case audioLoadFailed
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .audioLoadFailed: "Failed to load audio file for diarization"
        case .modelNotAvailable: "Diarization model is not available"
        }
    }
}

// MARK: - SpeakerKit Integration (ready for Phase 4 upgrade)
//
// To upgrade to SpeakerKit:
// 1. Add to Package.swift: .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", from: "x.x.x")
// 2. Import SpeakerKit
// 3. Replace performEnergyBasedDiarization with:
//
//    let config = SpeakerKitConfig(load: true)
//    let speakerKit = try await SpeakerKit(config: config)
//    let result = try await speakerKit.diarize(audioArray: audioData, options: nil, progressCallback: { p in
//        self.progress = Double(p.fractionCompleted)
//    })
//    return result.segments.map { segment in
//        SpeakerSegmentResult(
//            speakerLabel: "Speaker \(segment.speaker.speakerId + 1)",
//            startTime: Double(segment.startFrame) / Double(result.frameRate),
//            endTime: Double(segment.endFrame) / Double(result.frameRate)
//        )
//    }
