import SwiftUI
import SwiftData

struct FocusTimerView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = FocusViewModel()
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted }, sort: \TaskItem.createdAt)
    private var activeTasks: [TaskItem]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        if vm.isRunning {
                            activeTimerView
                        } else {
                            setupView
                        }

                        todayStats
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Focus")
            .onAppear {
                vm.loadTodaySessions(context: context)
            }
            .sheet(isPresented: $vm.showCompleted) {
                FocusCompletedSheet(duration: vm.selectedDuration, sessionsToday: vm.sessionsToday)
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 28) {
            // Duration picker
            VStack(spacing: 12) {
                Text("Duration")
                    .font(FloTypography.footnote)
                    .foregroundStyle(FloColors.Hex.textSecondary)

                HStack(spacing: 10) {
                    ForEach(FocusDuration.allCases) { duration in
                        Button {
                            withAnimation(FloAnimations.springSnappy) {
                                vm.selectedDuration = duration
                            }
                        } label: {
                            Text(duration.label)
                                .font(FloTypography.headline)
                                .foregroundStyle(
                                    vm.selectedDuration == duration ? .white : FloColors.Hex.textSecondary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    vm.selectedDuration == duration
                                        ? FloColors.Hex.accent
                                        : FloColors.Hex.surface
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            vm.selectedDuration == duration
                                                ? FloColors.Hex.accent
                                                : FloColors.Hex.border,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Preview ring
            ZStack {
                Circle()
                    .stroke(FloColors.Hex.border.opacity(0.2), lineWidth: 8)
                    .frame(width: 220, height: 220)

                VStack(spacing: 4) {
                    Text("\(vm.selectedDuration.rawValue)")
                        .font(FloTypography.statNumber)
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Text("minutes")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }

            // Task picker (optional)
            if !activeTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link to task (optional)")
                        .font(FloTypography.footnote)
                        .foregroundStyle(FloColors.Hex.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "None", isSelected: vm.selectedTask == nil) {
                                vm.selectedTask = nil
                            }
                            ForEach(activeTasks.prefix(10)) { task in
                                FilterChip(
                                    label: task.title,
                                    isSelected: vm.selectedTask?.persistentModelID == task.persistentModelID,
                                    color: task.priority.color
                                ) {
                                    vm.selectedTask = task
                                }
                            }
                        }
                    }
                }
            }

            FloButton("Start Focus", icon: "play.fill") {
                withAnimation(FloAnimations.springDefault) {
                    vm.startSession()
                }
            }
        }
    }

    // MARK: - Active Timer

    private var activeTimerView: some View {
        VStack(spacing: 28) {
            FloTimerRing(
                progress: vm.progress,
                timeRemaining: vm.timeRemaining,
                size: 260
            )
            .animation(FloAnimations.easeFast, value: vm.timeRemaining)

            if let task = vm.selectedTask {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                    Text(task.title)
                        .font(FloTypography.footnote)
                }
                .foregroundStyle(FloColors.Hex.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FloColors.Hex.surface)
                .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                // Reset
                FloIconButton("stop.fill", size: 18, color: FloColors.Hex.textSecondary) {
                    withAnimation(FloAnimations.springDefault) {
                        vm.stopSession(context: context)
                    }
                }
                .frame(width: 56, height: 56)
                .background(FloColors.Hex.surface)
                .clipShape(Circle())

                // Play/Pause
                Button {
                    withAnimation(FloAnimations.springSnappy) {
                        if vm.isPaused {
                            vm.resumeSession()
                        } else {
                            vm.pauseSession()
                        }
                    }
                } label: {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(FloColors.Hex.accent)
                        .clipShape(Circle())
                        .shadow(color: FloColors.Hex.accent.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .bounceOnTap()
            }
        }
    }

    // MARK: - Today Stats

    private var todayStats: some View {
        FloCard {
            HStack(spacing: 16) {
                FloStatCard(
                    title: "Sessions",
                    value: "\(vm.sessionsToday)",
                    icon: "flame.fill",
                    color: FloColors.Hex.accent
                )
                FloStatCard(
                    title: "Focus Time",
                    value: "\(vm.sessionsToday * vm.selectedDuration.rawValue)m",
                    icon: "clock.fill",
                    color: FloColors.Hex.success
                )
            }
        }
    }
}

// MARK: - Focus Completed Sheet

struct FocusCompletedSheet: View {
    @Environment(\.dismiss) private var dismiss
    let duration: FocusDuration
    let sessionsToday: Int
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FloColors.Hex.success.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(FloColors.Hex.success)
                    .symbolEffect(.bounce, value: showConfetti)
            }
            .confetti(isActive: $showConfetti)

            VStack(spacing: 8) {
                Text("Well done!")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("You completed a \(duration.rawValue) minute focus session.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text("Session #\(sessionsToday) today")
                .font(FloTypography.footnote)
                .foregroundStyle(FloColors.Hex.textTertiary)

            Spacer()

            FloButton("Done", style: .primary) {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(FloColors.Hex.background.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}
