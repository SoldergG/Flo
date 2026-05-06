import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<vm.totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= vm.currentPage ? FloColors.Hex.accent : FloColors.Hex.border)
                            .frame(width: index == vm.currentPage ? 24 : 8, height: 8)
                            .animation(FloAnimations.springDefault, value: vm.currentPage)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $vm.currentPage) {
                    WelcomePage().tag(0)
                    ToolPickerPage(vm: vm).tag(1)
                    ProjectSetupPage(vm: vm).tag(2)
                    NotificationsPage().tag(3)
                    SyncPage().tag(4)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(FloAnimations.springDefault, value: vm.currentPage)

                // Bottom buttons
                VStack(spacing: 12) {
                    FloButton(
                        vm.currentPage == vm.totalPages - 1 ? "Get Started" : "Continue",
                        icon: vm.currentPage == vm.totalPages - 1 ? "arrow.right" : nil,
                        style: .primary
                    ) {
                        if vm.currentPage == vm.totalPages - 1 {
                            if !vm.projectName.isEmpty {
                                let project = Project(
                                    name: vm.projectName,
                                    colorHex: vm.projectColor,
                                    icon: "folder.fill"
                                )
                                context.insert(project)
                                try? context.save()
                            }
                            vm.completeOnboarding()
                            onComplete()
                        } else {
                            vm.nextPage()
                        }
                    }
                    .disabled(!vm.canProceed)
                    .opacity(vm.canProceed ? 1 : 0.5)

                    if vm.currentPage > 0 {
                        Button("Back") {
                            vm.previousPage()
                        }
                        .font(FloTypography.subheadline)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated logo
            ZStack {
                Circle()
                    .fill(FloColors.Hex.accentSoft)
                    .frame(width: 120, height: 120)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FloColors.Hex.accent)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            VStack(spacing: 12) {
                Text("Welcome to Flō")
                    .font(FloTypography.largeTitle)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Focus on what matters.\nA calm space for your productivity.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(FloAnimations.springBouncy.delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(FloAnimations.easeSlow.delay(0.5)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Tool Picker Page

private struct ToolPickerPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Pick your tools")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Choose at least 2 to get started")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppTab.allCases) { tab in
                    let isSelected = vm.selectedTools.contains(tab)

                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            if isSelected {
                                vm.selectedTools.remove(tab)
                            } else {
                                vm.selectedTools.insert(tab)
                            }
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(isSelected ? FloColors.Hex.accent : FloColors.Hex.textSecondary)
                                .symbolEffect(.bounce, value: isSelected)

                            Text(tab.label)
                                .font(FloTypography.callout)
                                .foregroundStyle(isSelected ? FloColors.Hex.textPrimary : FloColors.Hex.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(isSelected ? FloColors.Hex.accentSoft : FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Project Setup Page

private struct ProjectSetupPage: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Create your first project")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("A project groups related tasks together")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            VStack(spacing: 20) {
                // Project preview
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: vm.projectColor))
                        .frame(width: 48, height: 48)
                        .background(Color(hex: vm.projectColor).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.projectName.isEmpty ? "Project Name" : vm.projectName)
                            .font(FloTypography.headline)
                            .foregroundStyle(vm.projectName.isEmpty ? FloColors.Hex.textTertiary : FloColors.Hex.textPrimary)
                        Text("0 tasks")
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(FloColors.Hex.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                FloTextField(placeholder: "e.g. Work, Personal, Side Project", text: $vm.projectName, icon: "pencil")

                // Color picker
                HStack(spacing: 10) {
                    ForEach(vm.projectColors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white, lineWidth: vm.projectColor == color ? 3 : 0)
                            )
                            .shadow(color: Color(hex: color).opacity(0.4), radius: vm.projectColor == color ? 4 : 0)
                            .scaleEffect(vm.projectColor == color ? 1.1 : 1.0)
                            .animation(FloAnimations.springSnappy, value: vm.projectColor)
                            .onTapGesture {
                                vm.projectColor = color
                            }
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Notifications Page

private struct NotificationsPage: View {
    @State private var bellBounce = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FloColors.Hex.accentSoft)
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FloColors.Hex.accent)
                    .symbolEffect(.bounce, value: bellBounce)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bellBounce = true
                }
            }

            VStack(spacing: 12) {
                Text("Stay on track")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Gentle reminders help you maintain focus and keep your habits going.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Sync Page

private struct SyncPage: View {
    @State private var cloudAnimate = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FloColors.Hex.accentSoft)
                    .frame(width: 120, height: 120)

                Image(systemName: "icloud.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FloColors.Hex.accent)
                    .offset(y: cloudAnimate ? -4 : 4)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: cloudAnimate)
            }
            .onAppear { cloudAnimate = true }

            VStack(spacing: 12) {
                Text("Synced everywhere")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Your data syncs automatically via iCloud across all your devices. No account needed.")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HStack(spacing: 20) {
                ForEach(["iphone", "ipad.landscape", "macbook"], id: \.self) { device in
                    VStack(spacing: 6) {
                        Image(systemName: device)
                            .font(.system(size: 28))
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FloColors.Hex.success)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
