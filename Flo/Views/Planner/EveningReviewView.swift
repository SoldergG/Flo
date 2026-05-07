import SwiftUI

struct EveningReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gratitude = ""
    @State private var win = ""
    @State private var rating: Int = 3

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "8B5CF6"))

                        Text("Evening Review")
                            .font(FloTypography.largeTitle)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        // Day rating
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rate your day")
                                .font(FloTypography.headline)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 28))
                                        .foregroundStyle(star <= rating ? FloColors.Hex.warning : FloColors.Hex.border)
                                        .onTapGesture { withAnimation { rating = star } }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        FloTextField(placeholder: "Today's biggest win", text: $win, icon: "trophy.fill")
                        FloTextField(placeholder: "Something you're grateful for", text: $gratitude, icon: "heart.fill")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Evening Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FloColors.Hex.accent)
                }
            }
        }
    }
}
