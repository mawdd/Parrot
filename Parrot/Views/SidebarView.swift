import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var showDashboard: Bool
    @Binding var searchText: String

    @Environment(RecordingManager.self) private var recordingManager
    @Query(sort: \Meeting.date, order: .reverse) private var meetings: [Meeting]

    var body: some View {
        List {
            // Dashboard button
            Button {
                showDashboard = true
                selectedMeeting = nil
            } label: {
                Label("Dashboard", systemImage: "house")
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .foregroundStyle(showDashboard ? Color.accentColor : .primary)

            Divider()

            // Meeting list grouped by date
            ForEach(groupedMeetings.keys.sorted().reversed(), id: \.self) { key in
                Section(key) {
                    ForEach(filteredMeetings(in: groupedMeetings[key] ?? [])) { meeting in
                        Button {
                            selectedMeeting = meeting
                            showDashboard = false
                        } label: {
                            MeetingSidebarRow(meeting: meeting)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                        .background(
                            selectedMeeting?.id == meeting.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Parrot")
    }

    private var groupedMeetings: [String: [Meeting]] {
        Dictionary(grouping: meetings) { meeting in
            dateGroupLabel(for: meeting.date)
        }
    }

    private func filteredMeetings(in meetings: [Meeting]) -> [Meeting] {
        guard !searchText.isEmpty else { return meetings }
        return meetings.filter { meeting in
            meeting.title.localizedCaseInsensitiveContains(searchText) ||
            meeting.segments.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func dateGroupLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now),
           date > weekAgo { return "This Week" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct MeetingSidebarRow: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if meeting.status == .processing {
                    ProgressView()
                        .controlSize(.mini)
                } else if meeting.status == .recording {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }
            }

            HStack(spacing: 8) {
                Text(meeting.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(meeting.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if meeting.speakerCount > 0 {
                    Label("\(meeting.speakerCount)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
