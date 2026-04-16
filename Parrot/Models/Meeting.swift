import Foundation
import SwiftData

enum MeetingStatus: String, Codable {
    case recording
    case processing
    case done
    case failed
}

@Model
final class Meeting {
    var id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var systemAudioPath: String
    var micAudioPath: String?
    var status: MeetingStatus
    var errorMessage: String?

    @Relationship(deleteRule: .cascade, inverse: \TranscriptSegment.meeting)
    var segments: [TranscriptSegment]

    init(
        title: String? = nil,
        date: Date = .now,
        systemAudioPath: String = "",
        micAudioPath: String? = nil
    ) {
        self.id = UUID()
        self.title = title ?? Self.defaultTitle(for: date)
        self.date = date
        self.duration = 0
        self.systemAudioPath = systemAudioPath
        self.micAudioPath = micAudioPath
        self.status = .recording
        self.errorMessage = nil
        self.segments = []
    }

    static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return "Meeting \(formatter.string(from: date))"
    }

    var sortedSegments: [TranscriptSegment] {
        segments.sorted { $0.startTime < $1.startTime }
    }

    var speakerCount: Int {
        Set(segments.compactMap(\.speakerLabel)).count
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
