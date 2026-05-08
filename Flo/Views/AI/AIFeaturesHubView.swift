import SwiftUI

// MARK: - AI Features Hub View

struct AIFeaturesHubView: View {
    @State private var selectedCategory: AIFeature.AIFeatureCategory?
    @State private var searchText = ""
    @State private var visible = false

    private var filteredFeatures: [AIFeature] {
        var features = FloAIService.allFeatures

        if let category = selectedCategory {
            features = features.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            features = features.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }

        return features
    }

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header stats
                    headerStats

                    // Search
                    FloTextField(placeholder: "Search features...", text: $searchText, icon: "magnifyingglass")
                        .padding(.horizontal, 4)

                    // Category filter
                    categoryFilter

                    // Features list
                    featuresList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("AI Features")
        .onAppear {
            withAnimation(FloAnimations.springDefault.delay(0.1)) {
                visible = true
            }
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("50")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.accent)
                Text("Features")
                    .font(FloTypography.caption2)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FloColors.Hex.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(spacing: 4) {
                Text("\(FloAIService.allFeatures.filter(\.isAvailableOffline).count)")
                    .font(FloTypography.title)
                    .foregroundStyle(FloColors.Hex.success)
                Text("Offline")
                    .font(FloTypography.caption2)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FloColors.Hex.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(spacing: 4) {
                Text("8")
                    .font(FloTypography.title)
                    .foregroundStyle(Color(hex: "8B5CF6"))
                Text("Categories")
                    .font(FloTypography.caption2)
                    .foregroundStyle(FloColors.Hex.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "8B5CF6").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .opacity(visible ? 1 : 0)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "All", category: nil)

                ForEach(AIFeature.AIFeatureCategory.allCases, id: \.rawValue) { cat in
                    categoryChip(label: cat.rawValue, category: cat, icon: cat.icon)
                }
            }
        }
    }

    private func categoryChip(label: String, category: AIFeature.AIFeatureCategory?, icon: String? = nil) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(FloAnimations.springSnappy) {
                selectedCategory = isSelected ? nil : category
            }
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(FloTypography.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? FloColors.Hex.accent : FloColors.Hex.surface)
            .foregroundStyle(isSelected ? .white : FloColors.Hex.textSecondary)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? FloColors.Hex.accent : FloColors.Hex.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Features List

    private var featuresList: some View {
        LazyVStack(spacing: 10) {
            ForEach(Array(filteredFeatures.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature: feature, index: index)
            }
        }
    }

    private func featureRow(feature: AIFeature, index: Int) -> some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 18))
                .foregroundStyle(feature.color)
                .frame(width: 40, height: 40)
                .background(feature.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(feature.title)
                        .font(FloTypography.subheadline.weight(.semibold))
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    if feature.isAvailableOffline {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 9))
                            .foregroundStyle(FloColors.Hex.textTertiary)
                    }
                }

                Text(feature.subtitle)
                    .font(FloTypography.caption)
                    .foregroundStyle(FloColors.Hex.textSecondary)
            }

            Spacer()

            // Category badge
            Text(feature.category.rawValue)
                .font(FloTypography.caption2)
                .foregroundStyle(feature.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(feature.color.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(FloColors.Hex.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 4, y: 2)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 10)
        .animation(FloAnimations.springDefault.delay(Double(min(index, 15)) * 0.03), value: visible)
    }
}

// AISettingsView is now in AISettingsView.swift — do not redeclare here.
