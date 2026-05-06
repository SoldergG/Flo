import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    var currentPage = 0
    var selectedTools: Set<AppTab> = [.tasks, .focus]
    var projectName = ""
    var projectColor = "D97757"
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    let totalPages = 5

    var canProceed: Bool {
        switch currentPage {
        case 0: true
        case 1: selectedTools.count >= 2
        case 2: !projectName.isEmpty
        case 3: true
        case 4: true
        default: true
        }
    }

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
        hasCompletedOnboarding = true
    }

    let projectColors = [
        "D97757", "B8602E", "D94F4F", "E5A84B",
        "5BA37C", "4A90D9", "8B5CF6", "EC4899"
    ]

    let projectIcons = [
        "folder.fill", "briefcase.fill", "house.fill", "star.fill",
        "heart.fill", "book.fill", "desktopcomputer", "person.fill"
    ]
}
