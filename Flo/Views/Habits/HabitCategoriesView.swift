import SwiftUI

struct HabitCategoriesView: View {
    @Environment(\.dismiss) private var dismiss

    private let categories: [(name: String, icon: String, color: Color)] = [
        ("Health", "heart.fill", FloColors.Hex.error),
        ("Fitness", "figure.run", FloColors.Hex.accent),
        ("Mindfulness", "brain.head.profile", Color(hex: "8B5CF6")),
        ("Learning", "book.fill", Color(hex: "4A90D9")),
        ("Productivity", "chart.bar.fill", FloColors.Hex.success),
        ("Social", "person.2.fill", FloColors.Hex.warning),
        ("Finance", "dollarsign.circle.fill", Color(hex: "5BA37C")),
        ("Creative", "paintbrush.fill", Color(hex: "EC4899")),
    ]

    var body: some View {
        ZStack {
            FloColors.Hex.background.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(categories, id: \.name) { category in
                        VStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(category.color)
                                .frame(width: 56, height: 56)
                                .background(category.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Text(category.name)
                                .font(FloTypography.subheadline.weight(.semibold))
                                .foregroundStyle(FloColors.Hex.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Categories")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
