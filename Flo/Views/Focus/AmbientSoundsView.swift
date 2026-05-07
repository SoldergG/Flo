import SwiftUI

struct AmbientSoundsView: View {
    @State private var sounds = AmbientSoundItem.allSounds
    @State private var masterVolume: Double = 0.7
    @State private var isAnyPlaying: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FloColors.Hex.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Now Playing / Status
                        nowPlayingBanner

                        // Sound Grid
                        soundGrid

                        // Master Volume
                        volumeControl
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Ambient Sounds")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(FloColors.Hex.textSecondary)
                }
            }
        }
    }

    // MARK: - Now Playing Banner

    private var nowPlayingBanner: some View {
        FloCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isAnyPlaying ? FloColors.Hex.accent.opacity(0.15) : FloColors.Hex.border.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: isAnyPlaying ? "waveform" : "speaker.slash.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isAnyPlaying ? FloColors.Hex.accent : FloColors.Hex.textTertiary)
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isAnyPlaying)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isAnyPlaying ? "Playing" : "No Sound")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    let playingSounds = sounds.filter(\.isPlaying).map(\.name)
                    Text(playingSounds.isEmpty ? "Tap a sound to start" : playingSounds.joined(separator: ", "))
                        .font(FloTypography.caption)
                        .foregroundStyle(FloColors.Hex.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isAnyPlaying {
                    Button {
                        withAnimation(FloAnimations.springSnappy) {
                            stopAll()
                        }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(FloColors.Hex.error)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sound Grid

    private var soundGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 14) {
            ForEach($sounds) { $sound in
                soundCard(sound: $sound)
            }
        }
    }

    private func soundCard(sound: Binding<AmbientSoundItem>) -> some View {
        let s = sound.wrappedValue

        return Button {
            withAnimation(FloAnimations.springBouncy) {
                sound.wrappedValue.isPlaying.toggle()
                updatePlayingState()
            }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(s.isPlaying ? Color(hex: s.colorHex).opacity(0.2) : FloColors.Hex.border.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: s.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(s.isPlaying ? Color(hex: s.colorHex) : FloColors.Hex.textTertiary)
                        .symbolEffect(.bounce, value: s.isPlaying)
                }

                Text(s.name)
                    .font(FloTypography.subheadline)
                    .foregroundStyle(s.isPlaying ? FloColors.Hex.textPrimary : FloColors.Hex.textSecondary)

                // Individual volume
                if s.isPlaying {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: s.colorHex))

                        Slider(value: sound.volume, in: 0...1)
                            .tint(Color(hex: s.colorHex))

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: s.colorHex))
                    }
                    .transition(FloAnimations.fadeScale)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(s.isPlaying ? Color(hex: s.colorHex).opacity(0.06) : FloColors.Hex.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        s.isPlaying ? Color(hex: s.colorHex).opacity(0.3) : FloColors.Hex.border.opacity(0.5),
                        lineWidth: s.isPlaying ? 2 : 1
                    )
            )
            .shadow(color: s.isPlaying ? Color(hex: s.colorHex).opacity(0.1) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .bounceOnTap()
    }

    // MARK: - Volume Control

    private var volumeControl: some View {
        FloCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Master Volume")
                        .font(FloTypography.headline)
                        .foregroundStyle(FloColors.Hex.textPrimary)

                    Spacer()

                    Text("\(Int(masterVolume * 100))%")
                        .font(FloTypography.badge)
                        .foregroundStyle(FloColors.Hex.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FloColors.Hex.accentSoft)
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FloColors.Hex.textTertiary)

                    Slider(value: $masterVolume, in: 0...1)
                        .tint(FloColors.Hex.accent)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(FloColors.Hex.textTertiary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func updatePlayingState() {
        isAnyPlaying = sounds.contains(where: \.isPlaying)
    }

    private func stopAll() {
        for i in sounds.indices {
            sounds[i].isPlaying = false
        }
        isAnyPlaying = false
    }
}

// MARK: - Ambient Sound Model

struct AmbientSoundItem: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var isPlaying: Bool = false
    var volume: Double = 0.7

    static let allSounds: [AmbientSoundItem] = [
        AmbientSoundItem(name: "Rain", icon: "cloud.rain.fill", colorHex: "4A90D9"),
        AmbientSoundItem(name: "Ocean", icon: "water.waves", colorHex: "34AADC"),
        AmbientSoundItem(name: "Forest", icon: "leaf.fill", colorHex: "5BA37C"),
        AmbientSoundItem(name: "Cafe", icon: "cup.and.saucer.fill", colorHex: "B8602E"),
        AmbientSoundItem(name: "Fireplace", icon: "flame.fill", colorHex: "D97757"),
        AmbientSoundItem(name: "White Noise", icon: "waveform", colorHex: "9B8E82"),
        AmbientSoundItem(name: "Lo-Fi", icon: "headphones", colorHex: "8B5CF6"),
        AmbientSoundItem(name: "Thunder", icon: "cloud.bolt.fill", colorHex: "6B5D52")
    ]
}
