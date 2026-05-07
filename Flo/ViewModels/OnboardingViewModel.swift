import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    // MARK: - Navigation

    var currentPage = 0
    let totalPages = 5  // Splash, Name, Highlights, Paywall, Ready

    // MARK: - User Info

    var userName: String = ""

    // MARK: - Project Setup (simplified)

    var projectName = ""
    var projectColor = "D97757"

    // MARK: - Persistence

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Computed

    var canProceed: Bool {
        switch currentPage {
        case 0: true           // Splash
        case 1: !userName.isEmpty // Name
        case 2: true           // Highlights
        case 3: true           // Paywall
        case 4: true           // Ready
        default: true
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.and.horizon.fill"
        case 17..<22: return "moon.stars.fill"
        default: return "moon.zzz.fill"
        }
    }

    var greetingColor: Color {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return FloColors.Hex.warning
        case 12..<17: return FloColors.Hex.accent
        case 17..<22: return Color(hex: "8B5CF6")
        default: return Color(hex: "4A90D9")
        }
    }

    // MARK: - Actions

    func nextPage() {
        guard currentPage < totalPages - 1 else { return }
        withAnimation(FloAnimations.springDefault) {
            currentPage += 1
        }
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        withAnimation(FloAnimations.springDefault) {
            currentPage -= 1
        }
    }

    func completeOnboarding() {
        if !userName.isEmpty {
            UserDefaults.standard.set(userName, forKey: "user_display_name")
        }
        hasCompletedOnboarding = true
    }

    let projectColors = [
        "D97757", "B8602E", "D94F4F", "E5A84B",
        "5BA37C", "4A90D9", "8B5CF6", "EC4899"
    ]
}
