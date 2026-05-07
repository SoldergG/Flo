import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Haptic Feedback Manager

enum HapticManager {
    enum HapticType {
        case light, medium, heavy
        case success, warning, error
        case selection
    }

    static func trigger(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }
}

// MARK: - View Extension for Haptic on Tap

extension View {
    func hapticOnTap(_ type: HapticManager.HapticType = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.trigger(type)
            }
        )
    }
}
