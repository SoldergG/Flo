import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreKitManager.shared
    @State private var selectedPlan: FloPlan = .proYearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Animation states
    @State private var headerVisible = false
    @State private var featuresVisible = false
    @State private var plansVisible = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [FloColors.Hex.background, FloColors.Hex.accentSoft.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FloColors.Hex.textTertiary)
                                .frame(width: 32, height: 32)
                                .background(FloColors.Hex.surface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)

                    // Header
                    paywallHeader

                    // Features
                    featuresList

                    // Plan selector
                    planSelector

                    // CTA
                    ctaButton

                    // Footer
                    paywallFooter
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // Loading overlay
            if isPurchasing {
                purchaseOverlay
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(FloAnimations.springBouncy.delay(0.1)) { headerVisible = true }
            withAnimation(FloAnimations.springDefault.delay(0.3)) { featuresVisible = true }
            withAnimation(FloAnimations.springDefault.delay(0.5)) { plansVisible = true }
            Task { await store.loadProducts() }
        }
    }

    // MARK: - Header

    private var paywallHeader: some View {
        VStack(spacing: 16) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [FloColors.Hex.accent.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FloColors.Hex.accent, Color(hex: "E5A84B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: FloColors.Hex.accent.opacity(0.3), radius: 10, y: 5)
            }
            .scaleEffect(headerVisible ? 1.0 : 0.5)
            .opacity(headerVisible ? 1.0 : 0)

            VStack(spacing: 8) {
                Text("Unlock Flo Pro")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(FloColors.Hex.textPrimary)

                Text("Everything you need to be\nyour most productive self")
                    .font(FloTypography.body)
                    .foregroundStyle(FloColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .opacity(headerVisible ? 1.0 : 0)
            .offset(y: headerVisible ? 0 : 15)
        }
    }

    // MARK: - Features List

    private var featuresList: some View {
        VStack(spacing: 0) {
            ForEach(Array(paywallFeatures.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(feature.color)
                        .frame(width: 34, height: 34)
                        .background(feature.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(FloTypography.subheadline.weight(.semibold))
                            .foregroundStyle(FloColors.Hex.textPrimary)
                        Text(feature.subtitle)
                            .font(FloTypography.caption)
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(FloColors.Hex.success)
                }
                .padding(.vertical, 11)

                if index < paywallFeatures.count - 1 {
                    Divider().foregroundStyle(FloColors.Hex.border.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .opacity(featuresVisible ? 1 : 0)
        .offset(y: featuresVisible ? 0 : 20)
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            // Yearly plan
            planCard(
                plan: .proYearly,
                title: "Yearly",
                price: store.yearlyProduct?.displayPrice ?? "$29.99",
                subtitle: yearlySubtitle,
                badge: "Best Value",
                badgeColor: FloColors.Hex.success
            )

            // Monthly plan
            planCard(
                plan: .pro,
                title: "Monthly",
                price: store.monthlyProduct?.displayPrice ?? "$4.99",
                subtitle: "/month",
                badge: nil,
                badgeColor: .clear
            )
        }
        .opacity(plansVisible ? 1 : 0)
        .offset(y: plansVisible ? 0 : 20)
    }

    private var yearlySubtitle: String {
        if let yearly = store.yearlyProduct, let monthly = store.monthlyProduct {
            let monthlyTotal = monthly.price * 12
            let savings = monthlyTotal - yearly.price
            let savingsPercent = NSDecimalNumber(decimal: (savings / monthlyTotal) * 100).intValue
            return "/year · Save \(savingsPercent)%"
        }
        return "/year · Save 50%"
    }

    private func planCard(
        plan: FloPlan,
        title: String,
        price: String,
        subtitle: String,
        badge: String?,
        badgeColor: Color
    ) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(FloAnimations.springSnappy) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                // Radio button
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(FloColors.Hex.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(FloTypography.headline)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(FloTypography.badge)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }

                Spacer()

                // Price
                Text(price)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(FloColors.Hex.textPrimary)
            }
            .padding(16)
            .background(isSelected ? FloColors.Hex.accentSoft : FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await handlePurchase() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Start Free Trial")
                        .font(FloTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [FloColors.Hex.accent, FloColors.Hex.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: FloColors.Hex.accent.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .bounceOnTap()

            Text("3-day free trial, then auto-renews. Cancel anytime.")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textTertiary)
                .multilineTextAlignment(.center)
        }
        .opacity(plansVisible ? 1 : 0)
    }

    // MARK: - Footer

    private var paywallFooter: some View {
        VStack(spacing: 12) {
            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(FloTypography.footnote)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)

                Text("·")
                    .foregroundStyle(FloColors.Hex.textTertiary)

                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
        }
    }

    // MARK: - Purchase Overlay

    private var purchaseOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Processing...")
                    .font(FloTypography.callout)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .transition(.opacity)
    }

    // MARK: - Handle Purchase

    private func handlePurchase() async {
        let product: Product?
        switch selectedPlan {
        case .pro: product = store.monthlyProduct
        case .proYearly: product = store.yearlyProduct
        case .free: dismiss(); return
        }

        guard let product else {
            errorMessage = "Product not available. Please try again."
            showError = true
            return
        }

        isPurchasing = true
        do {
            let success = try await store.purchase(product)
            await MainActor.run {
                isPurchasing = false
                if success { dismiss() }
            }
        } catch {
            await MainActor.run {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Paywall Features Data

    private let paywallFeatures: [PaywallFeatureItem] = [
        PaywallFeatureItem(icon: "infinity", title: "Unlimited Everything", subtitle: "Tasks, habits, projects — no limits", color: FloColors.Hex.accent),
        PaywallFeatureItem(icon: "sparkles", title: "AI Assistant & Briefings", subtitle: "50 AI features to boost productivity", color: Color(hex: "8B5CF6")),
        PaywallFeatureItem(icon: "xmark.shield.fill", title: "No Ads", subtitle: "Clean, distraction-free experience", color: FloColors.Hex.success),
        PaywallFeatureItem(icon: "icloud.fill", title: "Cloud Sync", subtitle: "Access everywhere, automatic backup", color: Color(hex: "4A90D9")),
        PaywallFeatureItem(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", subtitle: "Deep insights into your productivity", color: FloColors.Hex.warning),
        PaywallFeatureItem(icon: "waveform", title: "All Ambient Sounds", subtitle: "8 focus sounds for the perfect environment", color: Color(hex: "EC4899")),
    ]
}

// MARK: - Paywall Feature Item

private struct PaywallFeatureItem {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Compact Paywall (for inline upsells)

struct CompactPaywallBanner: View {
    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FloColors.Hex.accent, Color(hex: "E5A84B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(FloTypography.subheadline.weight(.semibold))
                        .foregroundStyle(FloColors.Hex.textPrimary)
                    Text("Unlock all features & remove ads")
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FloColors.Hex.accent)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [FloColors.Hex.accentSoft, FloColors.Hex.surface],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(FloColors.Hex.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
