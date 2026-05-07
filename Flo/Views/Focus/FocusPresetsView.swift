import SwiftUI

struct FocusPresetsView: View {
    @State private var presets: [FocusPresetConfig] = FocusPresetConfig.defaults
    @State private var showingCreatePreset = false
    @State private var selectedPreset: FocusPresetConfig?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Quick start section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QUICK START")
                                .font(FloTypography.badge)
                                .foregroundStyle(FloColors.Hex.textTertiary)

                            ForEach(presets) { preset in
                                presetCard(preset)
                            }
                        }

                        FloButton("Create New Preset", icon: "plus.circle.fill", style: .secondary) {
                            showingCreatePreset = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Focus Presets")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
            .sheet(isPresented: $showingCreatePreset) {
                CreatePresetSheet(presets: $presets)
            }
        }
    }

    // MARK: - Preset Card

    private func presetCard(_ preset: FocusPresetConfig) -> some View {
        FloPressableCard(action: {
            selectedPreset = preset
        }) {
            HStack(spacing: 16) {
                // Icon ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: preset.colorHex).opacity(0.2), lineWidth: 4)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: Double(preset.duration) / 90.0)
                        .stroke(Color(hex: preset.colorHex), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text("\(preset.duration)")
                        .font(FloTypography.headline)
                        .foregroundStyle(Color(hex: preset.colorHex))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text("\(preset.duration) min")
                                .font(FloTypography.caption)
                        }
                        .foregroundStyle(FloColors.Hex.textSecondary)

                        if preset.breakDuration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "pause.circle")
                                    .font(.system(size: 10))
                                Text("\(preset.breakDuration) min break")
                                    .font(FloTypography.caption)
                            }
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        }

                        if let sound = preset.sound {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 10))
                                Text(sound)
                                    .font(FloTypography.caption)
                            }
                            .foregroundStyle(FloColors.Hex.textSecondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: preset.colorHex))
            }
        }
    }
}

// MARK: - Focus Preset

struct FocusPresetConfig: Identifiable {
    let id = UUID()
    var name: String
    var duration: Int
    var breakDuration: Int
    var sound: String?
    var colorHex: String

    static let defaults: [FocusPresetConfig] = [
        FocusPresetConfig(name: "Quick Focus", duration: 15, breakDuration: 3, sound: nil, colorHex: "5BA37C"),
        FocusPresetConfig(name: "Deep Work", duration: 90, breakDuration: 15, sound: "Rain", colorHex: "4A90D9"),
        FocusPresetConfig(name: "Pomodoro", duration: 25, breakDuration: 5, sound: "Lo-Fi", colorHex: "D97757")
    ]
}

// MARK: - Create Preset Sheet

struct CreatePresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var presets: [FocusPresetConfig]

    @State private var name = ""
    @State private var duration: Double = 25
    @State private var breakDuration: Double = 5
    @State private var selectedSound: String?
    @State private var colorHex = "D97757"

    private let sounds = ["Rain", "Ocean", "Forest", "Cafe", "Fireplace", "White Noise", "Lo-Fi", "Thunder"]
    private let colors = ["D97757", "B8602E", "D94F4F", "E5A84B", "5BA37C", "4A90D9", "8B5CF6", "EC4899"]

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        ZStack {
                            Circle()
                                .stroke(Color(hex: colorHex).opacity(0.2), lineWidth: 6)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: duration / 90.0)
                                .stroke(Color(hex: colorHex), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("\(Int(duration))")
                                    .font(FloTypography.title)
                                    .foregroundStyle(Color(hex: colorHex))
                                Text("min")
                                    .font(FloTypography.caption)
                                    .foregroundStyle(FloColors.Hex.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        FloTextField(placeholder: "Preset name", text: $name, icon: "tag")

                        // Duration slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(FloTypography.footnote)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                                Spacer()
                                Text("\(Int(duration)) min")
                                    .font(FloTypography.headline)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                            }

                            Slider(value: $duration, in: 5...120, step: 5)
                                .tint(Color(hex: colorHex))
                        }

                        // Break duration slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Break Duration")
                                    .font(FloTypography.footnote)
                                    .foregroundStyle(FloColors.Hex.textSecondary)
                                Spacer()
                                Text("\(Int(breakDuration)) min")
                                    .font(FloTypography.headline)
                                    .foregroundStyle(FloColors.Hex.textPrimary)
                            }

                            Slider(value: $breakDuration, in: 0...30, step: 1)
                                .tint(Color(hex: colorHex))
                        }

                        // Sound
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ambient Sound")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "None", isSelected: selectedSound == nil) {
                                        selectedSound = nil
                                    }
                                    ForEach(sounds, id: \.self) { sound in
                                        FilterChip(label: sound, isSelected: selectedSound == sound, color: Color(hex: colorHex)) {
                                            selectedSound = sound
                                        }
                                    }
                                }
                            }
                        }

                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(FloTypography.footnote)
                                .foregroundStyle(FloColors.Hex.textSecondary)

                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { c in
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: colorHex == c ? 3 : 0))
                                        .scaleEffect(colorHex == c ? 1.1 : 1.0)
                                        .animation(FloAnimations.springSnappy, value: colorHex)
                                        .onTapGesture { colorHex = c }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Preset")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let preset = FocusPresetConfig(
                            name: name,
                            duration: Int(duration),
                            breakDuration: Int(breakDuration),
                            sound: selectedSound,
                            colorHex: colorHex
                        )
                        presets.append(preset)
                        dismiss()
                    }
                    .foregroundStyle(FloColors.Hex.accent)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
