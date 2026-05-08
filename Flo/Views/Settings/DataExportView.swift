import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Data Export View (FIX #28: real CSV/JSON export with share sheet)

struct DataExportView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @Query private var habits: [Habit]
    @Query private var focusSessions: [FocusSession]
    @Query private var journalEntries: [JournalEntry]
    @Query private var moodEntries: [MoodEntry]

    @State private var isExporting = false
    @State private var exportedFile: ExportFile?
    @State private var showShareSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var exportFormat: ExportFormat = .json

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(FloColors.Hex.accent)

                        Text("Export Your Data")
                            .font(FloTypography.title3)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        Text("Download everything as JSON or CSV.")
                            .font(FloTypography.body)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Format picker
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Stats
                    VStack(spacing: 10) {
                        exportRow(icon: "checkmark.circle", title: "Tasks", count: tasks.count, color: FloColors.Hex.accent)
                        exportRow(icon: "flame", title: "Habits", count: habits.count, color: FloColors.Hex.warning)
                        exportRow(icon: "timer", title: "Focus Sessions", count: focusSessions.count, color: FloColors.Hex.success)
                        exportRow(icon: "book", title: "Journal Entries", count: journalEntries.count, color: Color(hex: "8B5CF6"))
                        exportRow(icon: "face.smiling", title: "Mood Entries", count: moodEntries.count, color: FloColors.Hex.accentSecondary)
                    }
                    .padding(.horizontal, 20)

                    // Export button
                    FloButton(isExporting ? "Exporting…" : "Export All", icon: isExporting ? "" : "arrow.down.doc.fill") {
                        exportData()
                    }
                    .disabled(isExporting)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Data Export")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let file = exportedFile {
                ShareSheet(items: [file.url])
            }
        }
        #endif
        .alert("Export", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Row

    private func exportRow(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(FloTypography.subheadline.weight(.semibold))
                .foregroundStyle(FloColors.Hex.textPrimary)

            Spacer()

            Text("\(count) items")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FloColors.Hex.border.opacity(0.4))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Export Logic (FIX #29: real export)

    private func exportData() {
        isExporting = true

        Task {
            do {
                let data: Data
                let ext: String

                if exportFormat == .json {
                    data = try buildJSON()
                    ext = "json"
                } else {
                    data = try buildCSV()
                    ext = "csv"
                }

                let dateStr = DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
                    .replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "")
                let filename = "flo_export_\(dateStr).\(ext)"
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: url)

                await MainActor.run {
                    exportedFile = ExportFile(url: url)
                    isExporting = false
                    #if os(iOS)
                    showShareSheet = true
                    #else
                    // macOS: save to downloads
                    let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                    let dest = downloads.appendingPathComponent(filename)
                    try? FileManager.default.copyItem(at: url, to: dest)
                    alertMessage = "Saved to Downloads: \(filename)"
                    showAlert = true
                    #endif
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    alertMessage = "Export failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func buildJSON() throws -> Data {
        let payload: [String: Any] = [
            "exported_at": ISO8601DateFormatter().string(from: .now),
            "tasks": tasks.map { t in [
                "id": t.persistentModelID.hashValue,
                "title": t.title,
                "notes": t.notes,
                "is_completed": t.isCompleted,
                "priority": t.priority.label,
                "due_date": t.dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull(),
                "created_at": ISO8601DateFormatter().string(from: t.createdAt)
            ]},
            "habits": habits.map { h in [
                "id": h.persistentModelID.hashValue,
                "name": h.name,
                "icon": h.icon,
                "frequency": h.frequency.label,
                "current_streak": h.currentStreak,
                "best_streak": h.bestStreak,
                "total_completions": h.totalCompletions
            ]},
            "focus_sessions": focusSessions.map { s in [
                "started_at": ISO8601DateFormatter().string(from: s.startedAt),
                "duration_minutes": s.durationMinutes,
                "actual_minutes": s.actualMinutes,
                "was_completed": s.wasCompleted
            ]},
            "journal_entries": journalEntries.map { e in [
                "title": e.title,
                "content": e.content,
                "mood": e.mood.map { $0 as Any } ?? "null" as Any,
                "tags": e.tags,
                "created_at": ISO8601DateFormatter().string(from: e.createdAt)
            ]},
            "mood_entries": moodEntries.map { m in [
                "mood": m.mood,
                "energy": m.energy,
                "note": m.note,
                "entry_type": m.entryType,
                "created_at": ISO8601DateFormatter().string(from: m.createdAt)
            ]}
        ]
        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    private func buildCSV() throws -> Data {
        var csv = "# Flo Export \(Date.now.formatted(.dateTime))\n\n"

        csv += "## TASKS\ntitle,priority,completed,due_date,created_at\n"
        for t in tasks {
            let due = t.dueDate.map { $0.formatted(.dateTime) } ?? ""
            csv += "\"\(t.title)\",\(t.priority.label),\(t.isCompleted),\"\(due)\",\(t.createdAt.formatted(.dateTime))\n"
        }

        csv += "\n## HABITS\nname,frequency,streak,best_streak,completions\n"
        for h in habits {
            csv += "\"\(h.name)\",\(h.frequency.label),\(h.currentStreak),\(h.bestStreak),\(h.totalCompletions)\n"
        }

        csv += "\n## FOCUS SESSIONS\nstarted_at,duration_min,actual_min,completed\n"
        for s in focusSessions {
            csv += "\(s.startedAt.formatted(.dateTime)),\(s.durationMinutes),\(s.actualMinutes),\(s.wasCompleted)\n"
        }

        csv += "\n## JOURNAL\ntitle,content_preview,mood,created_at\n"
        for e in journalEntries {
            let preview = String(e.content.prefix(80)).replacingOccurrences(of: "\"", with: "'")
            csv += "\"\(e.title)\",\"\(preview)\",\(e.mood ?? 0),\(e.createdAt.formatted(.dateTime))\n"
        }

        return Data(csv.utf8)
    }
}

// MARK: - Export File (for ShareSheet)

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - ShareSheet (iOS)

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
