import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Plan

enum FloPlan: String, CaseIterable, Identifiable {
    case free = "free"
    case pro = "com.solderg.flo.pro.monthly"
    case proYearly = "com.solderg.flo.pro.yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro Monthly"
        case .proYearly: return "Pro Yearly"
        }
    }

    var badge: String {
        switch self {
        case .free: return "Basic"
        case .pro: return "PRO"
        case .proYearly: return "PRO"
        }
    }

    var icon: String {
        switch self {
        case .free: return "leaf"
        case .pro: return "crown.fill"
        case .proYearly: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .free: return FloColors.Hex.textSecondary
        case .pro: return FloColors.Hex.accent
        case .proYearly: return Color(hex: "8B5CF6")
        }
    }
}

// MARK: - Feature Gate

enum ProFeature: String, CaseIterable {
    case unlimitedTasks
    case unlimitedHabits
    case aiAssistant
    case aiDailyBriefing
    case smartLists
    case advancedAnalytics
    case customThemes
    case cloudSync
    case focusAmbientSounds
    case kanbanBoard
    case eisenhowerMatrix
    case taskTemplates
    case journaling
    case dataExport
    case noAds

    var displayName: String {
        switch self {
        case .unlimitedTasks: return "Unlimited Tasks"
        case .unlimitedHabits: return "Unlimited Habits"
        case .aiAssistant: return "AI Assistant"
        case .aiDailyBriefing: return "AI Daily Briefing"
        case .smartLists: return "Smart Lists"
        case .advancedAnalytics: return "Advanced Analytics"
        case .customThemes: return "Custom Themes"
        case .cloudSync: return "Cloud Sync"
        case .focusAmbientSounds: return "All Ambient Sounds"
        case .kanbanBoard: return "Kanban Board"
        case .eisenhowerMatrix: return "Eisenhower Matrix"
        case .taskTemplates: return "Task Templates"
        case .journaling: return "Journal & Mood"
        case .dataExport: return "Data Export"
        case .noAds: return "No Ads"
        }
    }

    var icon: String {
        switch self {
        case .unlimitedTasks: return "checkmark.circle.fill"
        case .unlimitedHabits: return "flame.fill"
        case .aiAssistant: return "sparkles"
        case .aiDailyBriefing: return "sun.max.fill"
        case .smartLists: return "wand.and.stars"
        case .advancedAnalytics: return "chart.line.uptrend.xyaxis"
        case .customThemes: return "paintpalette.fill"
        case .cloudSync: return "icloud.fill"
        case .focusAmbientSounds: return "waveform"
        case .kanbanBoard: return "rectangle.split.3x1"
        case .eisenhowerMatrix: return "square.grid.2x2.fill"
        case .taskTemplates: return "doc.on.doc.fill"
        case .journaling: return "book.fill"
        case .dataExport: return "square.and.arrow.up"
        case .noAds: return "xmark.shield.fill"
        }
    }

    /// Features available on the free plan
    static let freeFeatures: Set<ProFeature> = [
        .unlimitedTasks,  // Limited to 10 in free but let's be generous
    ]

    /// Free plan limits
    static let freeTaskLimit = 15
    static let freeHabitLimit = 3
    static let freeAmbientSounds = 2  // Only rain + lofi free
}

// MARK: - StoreKit Manager

@MainActor @Observable
final class StoreKitManager {
    static let shared = StoreKitManager()

    // MARK: - State

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed

    var isPro: Bool {
        purchasedProductIDs.contains(FloPlan.pro.rawValue) ||
        purchasedProductIDs.contains(FloPlan.proYearly.rawValue)
    }

    var currentPlan: FloPlan {
        if purchasedProductIDs.contains(FloPlan.proYearly.rawValue) { return .proYearly }
        if purchasedProductIDs.contains(FloPlan.pro.rawValue) { return .pro }
        return .free
    }

    var monthlyProduct: Product? {
        products.first { $0.id == FloPlan.pro.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == FloPlan.proYearly.rawValue }
    }

    // MARK: - Product IDs

    private let productIDs: Set<String> = [
        FloPlan.pro.rawValue,
        FloPlan.proYearly.rawValue
    ]

    // MARK: - Init

    private init() {
        Task { await loadProducts() }
        Task { await listenForTransactions() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            self.errorMessage = error.localizedDescription
        }

        await updatePurchasedProducts()
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Check Feature Access

    func hasAccess(to feature: ProFeature) -> Bool {
        if isPro { return true }
        return ProFeature.freeFeatures.contains(feature)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await updatePurchasedProducts()
                await transaction.finish()
            } catch {
                // Transaction verification failed
            }
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var newPurchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    newPurchased.insert(transaction.productID)
                }
            } catch {
                // Skip invalid transactions
            }
        }

        self.purchasedProductIDs = newPurchased
    }

    // MARK: - Verify Transaction

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Error

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
