import SwiftUI

#if canImport(GoogleMobileAds) && os(iOS)
import GoogleMobileAds
#endif

// MARK: - Ad Manager

@MainActor @Observable
final class AdManager {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs (Replace with your real IDs from AdMob)

    // Test IDs for development — replace with real ones before release
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"       // Test banner
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"  // Test interstitial
    static let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"        // Test native

    // MARK: - State

    var shouldShowAds: Bool {
        !StoreKitManager.shared.isPro
    }

    var isInterstitialReady = false
    private var interstitialCount = 0

    // MARK: - Init

    private init() {}

    // MARK: - Configure SDK

    func configure() {
        #if canImport(GoogleMobileAds) && os(iOS)
        MobileAds.shared.start()
        #endif
    }

    // MARK: - Track Interstitial Frequency

    /// Show interstitial every N actions (not too aggressive)
    func shouldShowInterstitial() -> Bool {
        guard shouldShowAds else { return false }
        interstitialCount += 1
        // Show every 5th action (e.g. completing a task, ending a focus session)
        return interstitialCount % 5 == 0
    }

    func resetInterstitialCounter() {
        interstitialCount = 0
    }
}

// MARK: - Banner Ad View (SwiftUI wrapper)

#if os(iOS)
struct FloBannerAdView: View {
    var body: some View {
        if AdManager.shared.shouldShowAds {
            BannerAdContent()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(FloColors.Hex.surface)
        }
    }
}

// When GoogleMobileAds is available, this uses real ads
// Otherwise it shows a placeholder that can be swapped later
private struct BannerAdContent: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        AdMobBannerRepresentable()
        #else
        // Placeholder — shown when GoogleMobileAds SDK is not linked yet
        BannerAdPlaceholder()
        #endif
    }
}

// MARK: - Placeholder Banner (before SDK integration)

private struct BannerAdPlaceholder: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 14))
                .foregroundStyle(FloColors.Hex.accent)

            Text("Upgrade to Pro to remove ads")
                .font(FloTypography.caption)
                .foregroundStyle(FloColors.Hex.textSecondary)

            Spacer()

            Text("Go Pro")
                .font(FloTypography.badge)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(FloColors.Hex.accent)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FloColors.Hex.surface)
        .overlay(
            Rectangle()
                .fill(FloColors.Hex.border.opacity(0.5))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

#if canImport(GoogleMobileAds)
import UIKit

// MARK: - UIKit AdMob Banner Wrapper

private struct AdMobBannerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = AdManager.bannerAdUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
#endif

#endif

// MARK: - Pro Gate Modifier

struct ProGateModifier: ViewModifier {
    let feature: ProFeature
    @State private var showPaywall = false
    private let store = StoreKitManager.shared

    func body(content: Content) -> some View {
        if store.hasAccess(to: feature) {
            content
        } else {
            content
                .overlay(proOverlay)
                .onTapGesture { showPaywall = true }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        }
    }

    private var proOverlay: some View {
        ZStack {
            Color.black.opacity(0.02)

            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(FloColors.Hex.accent)

                Text("PRO")
                    .font(FloTypography.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FloColors.Hex.accent)
                    .clipShape(Capsule())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func proGated(_ feature: ProFeature) -> some View {
        modifier(ProGateModifier(feature: feature))
    }
}
