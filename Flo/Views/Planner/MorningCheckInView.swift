import SwiftUI

struct MorningCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var energy: Double = 3
    @State private var mood = "😊"
    @State private var topPriority = ""

    private let moods = ["😴", "😔", "😐", "😊", "🔥"]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(FloColors.Hex.warning)

                        Text("Good Morning!")
                            .font(FloTypography.largeTitle)
                            .foregroundStyle(FloColors.Hex.textPrimary)

                        // Energy level
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy Level")
                                .font(FloTypography.headline)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            Slider(value: $energy, in: 1...5, step: 1)
                                .tint(FloColors.Hex.accent)
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Mood
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How are you feeling?")
                                .font(FloTypography.headline)
                                .foregroundStyle(FloColors.Hex.textPrimary)
                            HStack(spacing: 16) {
                                ForEach(moods, id: \.self) { m in
                                    Text(m)
                                        .font(.system(size: 32))
                                        .opacity(mood == m ? 1 : 0.4)
                                        .scaleEffect(mood == m ? 1.2 : 1)
                                        .onTapGesture { withAnimation { mood = m } }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .background(FloColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Top priority
                        FloTextField(placeholder: "Today's top priority", text: $topPriority, icon: "star.fill")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Morning Check-In")
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
