import SwiftUI
import SwiftData
import StoreKit

// MARK: - Onboarding View (Clean, Direct, Professional)

struct OnboardingView: View {
    @State private var vm = OnboardingViewModel()
    @Environment(\.modelContext) private var context
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            OnboardingBackground(page: vm.currentPage)

            VStack(spacing: 0) {
                // Progress bar (pages 1+)
                if vm.currentPage > 0 {
                    OnboardingProgress(current: vm.currentPage, total: vm.totalPages)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Content
                TabView(selection: $vm.currentPage) {
                    SplashPage().tag(0)
                    NamePage(vm: vm).tag(1)
                    HighlightsPage().tag(2)
                    PaywallOnboardingPage(onContinue: { vm.nextPage() }).tag(3)
                    ReadyPage(vm: vm).tag(4)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(FloAnimations.springDefault, value: vm.currentPage)

                // Bottom actions (hidden on paywall page — it has its own CTA)
                if vm.currentPage != 3 {
                    bottomActions
                }
            }
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: 10) {
            if vm.currentPage == 0 {
                FloButton("Get Started", icon: "arrow.right") {
                    vm.nextPage()
                }
            } else if vm.currentPage == vm.totalPages - 1 {
                FloButton("Start Using Flo", icon: "checkmark") {
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
                }
            } else {
                FloButton("Continue", icon: "arrow.right") {
                    vm.nextPage()
                }
                .disabled(!vm.canProceed)
                .opacity(vm.canProceed ? 1 : 0.5)
            }

            if vm.currentPage > 0 && vm.currentPage < vm.totalPages - 1 && vm.currentPage != 3 {
                Button("Back") { vm.previousPage() }
                    .font(FloTypography.subheadline)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .animation(FloAnimations.springDefault, value: vm.currentPage)
    }
}

// MARK: - Background

private struct OnboardingBackground: View {
    let page: Int
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animate ? .topLeading : .topTrailing,
            endPoint: animate ? .bottomTrailing : .bottomLeading
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
        .animation(FloAnimations.easeSlow, value: page)
        .onAppear { animate = true }
    }

    private var gradientColors: [Color] {
        switch page {
        case 0: [FloColors.Hex.background, FloColors.Hex.accentSoft.opacity(0.6)]
        case 1: [FloColors.Hex.background, Color(hex: "FDF0E9").opacity(0.7)]
        case 2: [FloColors.Hex.background, Color(hex: "EDE9FE").opacity(0.5)]
        case 3: [FloColors.Hex.background, Color(hex: "FDF0E9").opacity(0.4)]
        case 4: [FloColors.Hex.background, Color(hex: "F0FDF4").opacity(0.5)]
        default: [FloColors.Hex.background, FloColors.Hex.accentSoft]
        }
    }
}

// MARK: - Progress

private struct OnboardingProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FloColors.Hex.border.opacity(0.3))
                    .frame(height: 3)

                Capsule()
                    .fill(FloColors.Hex.accent)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(total - 1), height: 3)
                    .animation(FloAnimations.springSmooth, value: current)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Page 0: Splash

private struct SplashPage: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FloColors.Hex.accent, FloColors.Hex.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: FloColors.Hex.accent.opacity(0.4), radius: 24, y: 12)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.white)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                Text("Flo")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Mindful productivity")
                    .font(FloTypography.title3)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(FloAnimations.springBouncy.delay(0.15)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(FloAnimations.easeSlow.delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Page 1: Name

private struct NamePage: View {
    @Bindable var vm: OnboardingViewModel
    @State private var visible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Greeting icon
                Image(systemName: vm.greetingIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(vm.greetingColor)
                    .symbolEffect(.pulse, options: .repeating)
                    .scaleEffect(visible ? 1 : 0.5)
                    .opacity(visible ? 1 : 0)

                VStack(spacing: 8) {
                    Text(vm.greeting + "!")
                        .font(FloTypography.largeTitle)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Text("What's your name?")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 15)

                // Name input
                VStack(spacing: 14) {
                    FloTextField(
                        placeholder: "Your name",
                        text: $vm.userName,
                        icon: "person.fill"
                    )

                    if !vm.userName.isEmpty {
                        Text("\(vm.greeting), \(vm.userName)!")
                            .font(FloTypography.title3)
                            .foregroundStyle(FloColors.Hex.accent)
                            .transition(FloAnimations.fadeScale)
                            .animation(FloAnimations.springDefault, value: vm.userName)
                    }
                }
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 20)
                .animation(FloAnimations.springDefault.delay(0.2), value: visible)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(FloAnimations.springBouncy.delay(0.1)) { visible = true }
        }
    }
}

// MARK: - Page 2: Feature Highlights

private struct HighlightsPage: View {
    @State private var visible = false

    private let highlights: [(icon: String, title: String, color: Color)] = [
        ("checkmark.circle.fill", "Smart Tasks & Projects", FloColors.Hex.accent),
        ("flame.fill", "Habit Tracking with Streaks", FloColors.Hex.warning),
        ("timer", "Focus Timer & Ambient Sounds", Color(hex: "8B5CF6")),
        ("sparkles", "AI-Powered Productivity", Color(hex: "4A90D9")),
        ("chart.line.uptrend.xyaxis", "Analytics & Insights", FloColors.Hex.success),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Everything you need")
                        .font(FloTypography.largeTitle)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Text("One app for your entire workflow")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                .opacity(visible ? 1 : 0)

                VStack(spacing: 12) {
                    ForEach(Array(highlights.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(item.color)
                                .frame(width: 40, height: 40)
                                .background(item.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text(item.title)
                                .font(FloTypography.headline)
                                .foregroundStyle(FloColors.Hex.textPrimary)

                            Spacer()

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(FloColors.Hex.success)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(FloColors.Hex.surface.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .opacity(visible ? 1 : 0)
                        .offset(x: visible ? 0 : 30)
                        .animation(FloAnimations.springDefault.delay(Double(index) * 0.08 + 0.15), value: visible)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(FloAnimations.springDefault) { visible = true }
        }
    }
}

// MARK: - Page 3: Paywall (Onboarding)

private struct PaywallOnboardingPage: View {
    let onContinue: () -> Void
    @State private var store = StoreKitManager.shared
    @State private var selectedPlan: FloPlan = .proYearly
    @State private var isPurchasing = false
    @State private var visible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)

                // Header
                VStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [FloColors.Hex.accent, Color(hex: "E5A84B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(visible ? 1 : 0.5)
                        .opacity(visible ? 1 : 0)

                    Text("Unlock Full Power")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Text("Try Pro free for 3 days")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                .opacity(visible ? 1 : 0)

                // Comparison
                comparisonSection

                // Plan selection
                VStack(spacing: 8) {
                    planOption(.proYearly, label: "Yearly", price: store.yearlyProduct?.displayPrice ?? "$29.99", perMonth: "/year", badge: "Save 50%")
                    planOption(.pro, label: "Monthly", price: store.monthlyProduct?.displayPrice ?? "$4.99", perMonth: "/month", badge: nil)
                }
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 15)
                .animation(FloAnimations.springDefault.delay(0.3), value: visible)

                // CTA
                Button {
                    Task { await handlePurchase() }
                } label: {
                    HStack(spacing: 8) {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 15))
                        }
                        Text("Start Free Trial")
                            .font(FloTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [FloColors.Hex.accent, FloColors.Hex.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: FloColors.Hex.accent.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
                .bounceOnTap()

                // Skip
                Button {
                    onContinue()
                } label: {
                    Text("Continue with Free plan")
                        .font(FloTypography.subheadline)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
                .buttonStyle(.plain)

                // Legal
                HStack(spacing: 12) {
                    Button("Restore") {
                        Task { await store.restorePurchases() }
                    }
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .buttonStyle(.plain)

                    Text("·").foregroundStyle(FloColors.Hex.textTertiary)

                    Link("Terms", destination: URL(string: "https://example.com/terms")!)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)

                    Text("·").foregroundStyle(FloColors.Hex.textTertiary)

                    Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
                .padding(.top, 4)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(FloAnimations.springBouncy.delay(0.1)) { visible = true }
            Task { await store.loadProducts() }
        }
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        let rows: [(String, String, Bool, Bool)] = [
            ("checkmark.circle", "Tasks & Projects", true, true),
            ("flame", "Habits (up to 3)", true, true),
            ("timer", "Focus Timer", true, true),
            ("infinity", "Unlimited Everything", false, true),
            ("sparkles", "AI Assistant", false, true),
            ("xmark.shield", "Ad-Free", false, true),
            ("icloud", "Cloud Sync", false, true),
            ("chart.line.uptrend.xyaxis", "Advanced Analytics", false, true),
        ]

        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(FloTypography.caption.weight(.semibold))
                    .foregroundStyle(FloColors.Hex.textTertiary)
                    .frame(width: 50)
                Text("Pro")
                    .font(FloTypography.caption.weight(.bold))
                    .foregroundStyle(FloColors.Hex.accent)
                    .frame(width: 50)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: row.0)
                            .font(.system(size: 12))
                            .foregroundStyle(FloColors.Hex.textTertiary)
                            .frame(width: 18)
                        Text(row.1)
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Free
                    Group {
                        if row.2 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(FloColors.Hex.success)
                        } else {
                            Image(systemName: "xmark")
                                .foregroundStyle(FloColors.Hex.textTertiary.opacity(0.4))
                        }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 50)

                    // Pro
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(FloColors.Hex.accent)
                        .frame(width: 50)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
            }
        }
        .background(FloColors.Hex.surface.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 15)
        .animation(FloAnimations.springDefault.delay(0.2), value: visible)
    }

    // MARK: - Plan Option

    private func planOption(_ plan: FloPlan, label: String, price: String, perMonth: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(FloAnimations.springSnappy) { selectedPlan = plan }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle().fill(FloColors.Hex.accent).frame(width: 10, height: 10)
                    }
                }

                Text(label)
                    .font(FloTypography.subheadline.weight(.semibold))
                    .foregroundStyle(FloColors.Hex.textPrimary)

                if let badge {
                    Text(badge)
                        .font(FloTypography.badge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(FloColors.Hex.success)
                        .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 2) {
                    Text(price)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(perMonth)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
                .foregroundStyle(FloColors.Hex.textPrimary)
            }
            .padding(14)
            .background(isSelected ? FloColors.Hex.accentSoft : FloColors.Hex.surface.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border.opacity(0.4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase

    private func handlePurchase() async {
        let product: Product?
        switch selectedPlan {
        case .pro: product = store.monthlyProduct
        case .proYearly: product = store.yearlyProduct
        case .free: onContinue(); return
        }

        guard let product else { return }

        isPurchasing = true
        do {
            let success = try await store.purchase(product)
            await MainActor.run {
                isPurchasing = false
                if success { onContinue() }
            }
        } catch {
            await MainActor.run { isPurchasing = false }
        }
    }
}

// MARK: - Page 4: Ready

struct ReadyPage: View {
    @Bindable var vm: OnboardingViewModel
    @State private var checkVisible = false
    @State private var textVisible = false
    @State private var ringProgress: CGFloat = 0
    @State private var confettiActive = false

    var store = StoreKitManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Success ring
                ZStack {
                    Circle()
                        .strokeBorder(FloColors.Hex.border.opacity(0.2), lineWidth: 5)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [FloColors.Hex.accent, FloColors.Hex.success],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(FloColors.Hex.success)
                        .scaleEffect(checkVisible ? 1 : 0)
                }
                .confetti(isActive: $confettiActive)

                VStack(spacing: 8) {
                    if vm.userName.isEmpty {
                        Text("You're all set!")
                            .font(FloTypography.largeTitle)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                    } else {
                        Text("Let's go, \(vm.userName)!")
                            .font(FloTypography.largeTitle)
                            .foregroundStyle(FloColors.Hex.textPrimary)
                    }

                    Text("Flo is ready to help you\nachieve more every day.")
                        .font(FloTypography.body)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(textVisible ? 1 : 0)
                .offset(y: textVisible ? 0 : 15)

                // Plan badge
                if store.isPro {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(FloColors.Hex.accent)
                        Text("Pro Plan Active")
                            .font(FloTypography.footnote.weight(.semibold))
                            .foregroundStyle(FloColors.Hex.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(FloColors.Hex.accentSoft)
                    .clipShape(Capsule())
                    .transition(FloAnimations.fadeScale)
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) { ringProgress = 1.0 }
            withAnimation(FloAnimations.springBouncy.delay(0.6)) { checkVisible = true }
            withAnimation(FloAnimations.easeSlow.delay(0.8)) { textVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { confettiActive = true }
        }
    }
}
