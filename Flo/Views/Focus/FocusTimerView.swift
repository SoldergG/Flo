import SwiftUI
import SwiftData

// MARK: - Focus Timer View

struct FocusTimerView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = FocusViewModel()
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.createdAt)
    private var activeTasks: [TaskItem]

    // FIX #59: read defaultFocusDuration from AppStorage
    @AppStorage("defaultFocusDuration") private var defaultFocusDuration = 25

    var body: some View {
        // FIX #60: remove inner NavigationStack (FocusHubView already has one)
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    if vm.isRunning {
                        activeTimerView
                    } else {
                        setupView
                    }
                    todayStatsReal
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Focus")
        .onAppear {
            vm.loadTodaySessions(context: context)
            // FIX #61: apply defaultFocusDuration from settings
            if vm.workMinutes == 25 {
                vm.workMinutes = defaultFocusDuration
            }
        }
        .sheet(isPresented: $vm.showCompleted) {
            FocusCompletedSheet(vm: vm, context: context)
        }
        .sheet(isPresented: $vm.showBreakCompleted) {
            BreakCompletedSheet()
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 40) {
            // Two dials: Work + Break
            HStack(spacing: 24) {
                TimerDialControl(
                    minutes: $vm.workMinutes,
                    maxMinutes: 120,
                    label: "Focus",
                    color: FloColors.Hex.accent,
                    size: 160
                )
                TimerDialControl(
                    minutes: $vm.breakMinutes,
                    maxMinutes: 60,
                    label: "Break",
                    color: FloColors.Hex.success,
                    size: 120
                )
            }

            // Optional task link
            if !activeTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link to task")
                        .font(FloTypography.footnote)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "None", isSelected: vm.selectedTask == nil) {
                                vm.selectedTask = nil
                            }
                            ForEach(activeTasks.prefix(8)) { task in
                                FilterChip(
                                    label: task.title,
                                    isSelected: vm.selectedTask?.persistentModelID == task.persistentModelID,
                                    color: task.priority.color
                                ) { vm.selectedTask = task }
                            }
                        }
                    }
                }
            }

            FloButton("Start Focus", icon: "play.fill") {
                withAnimation(FloAnimations.springDefault) { vm.startSession() }
            }
        }
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
        VStack(spacing: 32) {
            // Phase label
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.phase == .breakTime ? FloColors.Hex.success : FloColors.Hex.accent)
                    .frame(width: 8, height: 8)
                Text(vm.phase == .breakTime ? "Break" : "Focus")
                    .font(FloTypography.footnote)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            // Active progress ring
            ActiveTimerRing(vm: vm)

            // Task label
            if let task = vm.selectedTask, vm.phase == .work {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text(task.title)
                        .font(FloTypography.footnote)
                        .lineLimit(1)
                }
                .foregroundStyle(FloColors.Hex.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(FloColors.Hex.surface)
                .clipShape(Capsule())
            }

            // Controls
            HStack(spacing: 20) {
                // Stop
                Button {
                    withAnimation(FloAnimations.springDefault) {
                        vm.stopSession(context: context)
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(FloColors.Hex.textSecondary)
                        .frame(width: 52, height: 52)
                        .background(FloColors.Hex.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Play / Pause
                Button {
                    withAnimation(FloAnimations.springSnappy) {
                        vm.isPaused ? vm.resumeSession() : vm.pauseSession()
                    }
                } label: {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(vm.phase == .breakTime ? FloColors.Hex.success : FloColors.Hex.accent)
                        .clipShape(Circle())
                        .shadow(color: (vm.phase == .breakTime ? FloColors.Hex.success : FloColors.Hex.accent).opacity(0.25), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .bounceOnTap()

                // Skip (for break, skip back to work)
                if vm.phase == .breakTime {
                    Button {
                        withAnimation(FloAnimations.springDefault) {
                            vm.resetSession()
                        }
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(FloColors.Hex.textSecondary)
                            .frame(width: 52, height: 52)
                            .background(FloColors.Hex.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    // Placeholder for symmetry
                    Color.clear.frame(width: 52, height: 52)
                }
            }
        }
    }

    // FIX #62: use real session data for stats
    @Query private var allSessions: [FocusSession]

    private var todayStatsReal: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let todaySessions = allSessions.filter { $0.startedAt >= today }
        let totalMinutes = Int(todaySessions.reduce(0) { $0 + ($1.actualDuration ?? $1.duration) } / 60)
        let completed = todaySessions.filter(\.wasCompleted).count

        return FloCard {
            HStack(spacing: 0) {
                statCell(title: "Sessions", value: "\(todaySessions.count)", icon: "flame.fill", color: FloColors.Hex.accent)
                Divider().frame(height: 36)
                statCell(title: "Focus time", value: "\(totalMinutes)m", icon: "clock.fill", color: FloColors.Hex.success)
                Divider().frame(height: 36)
                statCell(title: "Completed", value: "\(completed)", icon: "checkmark.circle.fill", color: FloColors.Hex.textSecondary)
            }
        }
    }

    private func statCell(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(FloTypography.headline)
                .foregroundStyle(FloColors.Hex.textPrimary)
            Text(title)
                .font(FloTypography.caption2)
                .foregroundStyle(FloColors.Hex.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Draggable Timer Dial

struct TimerDialControl: View {
    @Binding var minutes: Int
    let maxMinutes: Int
    let label: String
    let color: Color
    let size: CGFloat

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var fieldFocused: Bool

    private var angle: Double {
        // 0 min = -90° (top), maxMinutes = 270° (full circle)
        let fraction = Double(minutes) / Double(maxMinutes)
        return fraction * 360.0 - 90.0
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Track
                Circle()
                    .stroke(FloColors.Hex.border.opacity(0.25), lineWidth: 10)
                    .frame(width: size, height: size)

                // Progress arc
                Circle()
                    .trim(from: 0, to: Double(minutes) / Double(maxMinutes))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(FloAnimations.springSnappy, value: minutes)

                // Center content
                if isEditing {
                    TextField("", text: $editText)
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(FloColors.Hex.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($fieldFocused)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .frame(width: size * 0.5)
                        .onSubmit { commitEdit() }
                        .onChange(of: editText) { _, v in
                            if v.count > 3 { editText = String(v.prefix(3)) }
                        }
                } else {
                    VStack(spacing: 2) {
                        Text("\(minutes)")
                            .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                            .foregroundStyle(FloColors.Hex.textPrimary)
                            .contentTransition(.numericText())
                        Text("min")
                            .font(.system(size: size * 0.11))
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                    .onTapGesture { startEditing() }
                }

                // Drag handle dot
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                    .shadow(color: color.opacity(0.4), radius: 4)
                    .offset(y: -(size / 2))
                    .rotationEffect(.degrees(angle + 90))
                    .animation(FloAnimations.springSnappy, value: minutes)
            }
            .frame(width: size, height: size)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in handleDrag(value, size: size) }
                    .onEnded { _ in HapticManager.trigger(.selection) }
            )
            .onTapGesture { if !isEditing { startEditing() } }

            Text(label)
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textSecondary)
        }
        .onChange(of: fieldFocused) { _, focused in
            if !focused { commitEdit() }
        }
    }

    private func startEditing() {
        editText = "\(minutes)"
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            fieldFocused = true
        }
        HapticManager.trigger(.light)
    }

    private func commitEdit() {
        if let v = Int(editText), v > 0 {
            minutes = min(v, maxMinutes)
        }
        isEditing = false
        fieldFocused = false
        HapticManager.trigger(.light)
    }

    private func handleDrag(_ value: DragGesture.Value, size: CGFloat) {
        let center = CGSize(width: size / 2, height: size / 2)
        let dx = value.location.x - center.width
        let dy = value.location.y - center.height
        var angle = atan2(dy, dx) * (180 / .pi) + 90
        if angle < 0 { angle += 360 }
        let fraction = angle / 360.0
        let newMinutes = max(1, Int(fraction * Double(maxMinutes)))
        if newMinutes != minutes {
            minutes = newMinutes
            HapticManager.trigger(.selection)
        }
    }
}

// MARK: - Active Timer Ring

private struct ActiveTimerRing: View {
    let vm: FocusViewModel
    private let size: CGFloat = 240

    var body: some View {
        ZStack {
            Circle()
                .stroke(FloColors.Hex.border.opacity(0.15), lineWidth: 12)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(
                    vm.phase == .breakTime ? FloColors.Hex.success : FloColors.Hex.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.progress)

            VStack(spacing: 4) {
                Text(vm.formattedTime)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(FloColors.Hex.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if vm.isPaused {
                    Text("Paused")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Focus Completed Sheet

struct FocusCompletedSheet: View {
    @Environment(\.dismiss) private var dismiss
    let vm: FocusViewModel
    let context: ModelContext
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FloColors.Hex.success.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(FloColors.Hex.success)
                    .symbolEffect(.bounce, value: showConfetti)
            }
            .confetti(isActive: $showConfetti)

            VStack(spacing: 6) {
                Text("Well done!")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                Text("You focused for \(vm.workMinutes) minutes.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            Text("Session #\(vm.sessionsToday) today")
                .font(FloTypography.footnote)
                .foregroundStyle(FloColors.Hex.textTertiary)

            Spacer()

            VStack(spacing: 12) {
                FloButton("Take a \(vm.breakMinutes)m Break", icon: "cup.and.saucer.fill", style: .secondary) {
                    vm.startBreak()
                    dismiss()
                }
                FloButton("Done", style: .primary) {
                    vm.stopSession(context: context)
                    dismiss()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(FloColors.Hex.background.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showConfetti = true }
        }
    }
}

// MARK: - Break Completed Sheet

struct BreakCompletedSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 52))
                .foregroundStyle(FloColors.Hex.warning)
            VStack(spacing: 6) {
                Text("Break done!")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)
                Text("Ready to get back in the zone?")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
            Spacer()
            FloButton("Let's go", icon: "play.fill", style: .primary) { dismiss() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(FloColors.Hex.background.ignoresSafeArea())
    }
}
