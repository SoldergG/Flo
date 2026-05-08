import SwiftUI

// MARK: - Cross-Platform View Modifiers
// These wrappers allow iOS-specific modifiers to compile on macOS as no-ops,
// so every view works on both platforms without per-file #if guards.

extension View {

    /// navigationBarTitleDisplayMode is iOS-only; no-op on macOS.
    @ViewBuilder
    func floNavTitleMode(_ mode: NavigationBarMode) -> some View {
        #if os(iOS)
        switch mode {
        case .large:   self.navigationBarTitleDisplayMode(.large)
        case .inline:  self.navigationBarTitleDisplayMode(.inline)
        case .automatic: self.navigationBarTitleDisplayMode(.automatic)
        }
        #else
        self
        #endif
    }

    /// scrollDismissesKeyboard is iOS-only; no-op on macOS.
    @ViewBuilder
    func floScrollDismissesKeyboard() -> some View {
        #if os(iOS)
        self.scrollDismissesKeyboard(.interactively)
        #else
        self
        #endif
    }

    /// textInputAutocapitalization is iOS-only; no-op on macOS.
    @ViewBuilder
    func floAutocapitalization(_ cap: FloAutoCapitalization) -> some View {
        #if os(iOS)
        switch cap {
        case .never: self.textInputAutocapitalization(.never)
        case .words: self.textInputAutocapitalization(.words)
        case .sentences: self.textInputAutocapitalization(.sentences)
        }
        #else
        self
        #endif
    }

    /// Wraps in NavigationStack on iOS; on macOS the view is already inside the
    /// NavigationSplitView detail column, so no extra stack is needed.
    @ViewBuilder
    func floNavigationStack() -> some View {
        #if os(iOS)
        NavigationStack { self }
        #else
        self
        #endif
    }

    /// On macOS in the main detail pane, sheets are full views — no dimissable
    /// NavigationStack needed. Use this for views that live as detail pages on macOS.
    @ViewBuilder
    func floSheetNavigationStack() -> some View {
        #if os(iOS)
        NavigationStack { self }
        #else
        self
        #endif
    }

    /// Open a URL portably.
    func floOpenURL(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Enums for cross-platform options

enum NavigationBarMode { case large, inline, automatic }
enum FloAutoCapitalization { case never, words, sentences }
