import Foundation
import AVFoundation

// MARK: - Ambient Audio Manager (FIX #21: real audio playback via AVAudioEngine)

@MainActor @Observable
final class AmbientAudioManager {
    static let shared = AmbientAudioManager()

    private let engine = AVAudioEngine()
    private var players: [String: (node: AVAudioPlayerNode, buffer: AVAudioPCMBuffer)] = [:]
    private var volumes: [String: Float] = [:]
    var masterVolume: Float = 0.7 { didSet { applyMasterVolume() } }

    private init() { setupEngine() }

    // MARK: - Engine Setup

    private func setupEngine() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Play

    func play(_ name: String, type: SoundType, volume: Float = 0.7) {
        guard players[name] == nil else { return } // already playing

        let sampleRate = 44100.0
        let bufferLength = AVAudioFrameCount(sampleRate * 5) // 5-second loop
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferLength) else { return }
        buffer.frameLength = bufferLength

        // FIX #22: generate noise based on sound type
        fillBuffer(buffer, type: type, sampleRate: sampleRate)

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        if !engine.isRunning {
            try? engine.start()
        }

        players[name] = (node: player, buffer: buffer)
        volumes[name] = volume * masterVolume

        player.volume = volume * masterVolume
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
    }

    // MARK: - Stop

    func stop(_ name: String) {
        guard let entry = players[name] else { return }
        entry.node.stop()
        engine.detach(entry.node)
        players.removeValue(forKey: name)
        volumes.removeValue(forKey: name)

        if players.isEmpty {
            engine.pause()
        }
    }

    func stopAll() {
        for (name, _) in players { stop(name) }
    }

    // FIX #23: per-sound volume control
    func setVolume(_ volume: Float, for name: String) {
        volumes[name] = volume
        players[name]?.node.volume = volume * masterVolume
    }

    var isAnyPlaying: Bool { !players.isEmpty }

    func isPlaying(_ name: String) -> Bool { players[name] != nil }

    // MARK: - Master Volume

    private func applyMasterVolume() {
        for (name, entry) in players {
            let baseVolume = volumes[name] ?? 0.7
            entry.node.volume = baseVolume * masterVolume
        }
    }

    // MARK: - Buffer Generation (noise synthesis — no audio files needed)

    func fillBuffer(_ buffer: AVAudioPCMBuffer, type: SoundType, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameCapacity)

        switch type {
        case .whiteNoise:
            // Pure white noise
            for ch in 0..<Int(buffer.format.channelCount) {
                for i in 0..<frameCount {
                    channelData[ch][i] = Float.random(in: -0.3...0.3)
                }
            }

        case .pinkNoise:
            // Pink noise approximation (Voss-McCartney)
            var b: [Double] = Array(repeating: 0, count: 7)
            for ch in 0..<Int(buffer.format.channelCount) {
                for i in 0..<frameCount {
                    let white = Double.random(in: -1...1)
                    b[0] = 0.99886 * b[0] + white * 0.0555179
                    b[1] = 0.99332 * b[1] + white * 0.0750759
                    b[2] = 0.96900 * b[2] + white * 0.1538520
                    b[3] = 0.86650 * b[3] + white * 0.3104856
                    b[4] = 0.55000 * b[4] + white * 0.5329522
                    b[5] = -0.7616 * b[5] - white * 0.0168980
                    let pink = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362
                    b[6] = white * 0.115926
                    channelData[ch][i] = Float(pink * 0.11)
                }
            }

        case .brownNoise:
            // Brown noise (integrated white noise)
            var lastOut: Double = 0
            for ch in 0..<Int(buffer.format.channelCount) {
                for i in 0..<frameCount {
                    let white = Double.random(in: -1...1)
                    lastOut = (lastOut + 0.02 * white) / 1.02
                    channelData[ch][i] = Float(lastOut * 3.5)
                }
            }

        case .rain:
            // Rain = pink noise + occasional intensity bursts
            var b: [Double] = Array(repeating: 0, count: 7)
            for ch in 0..<Int(buffer.format.channelCount) {
                for i in 0..<frameCount {
                    let white = Double.random(in: -1...1)
                    b[0] = 0.99886 * b[0] + white * 0.0555179
                    b[1] = 0.99332 * b[1] + white * 0.0750759
                    b[2] = 0.96900 * b[2] + white * 0.1538520
                    b[3] = 0.86650 * b[3] + white * 0.3104856
                    b[4] = 0.55000 * b[4] + white * 0.5329522
                    b[5] = -0.7616 * b[5] - white * 0.0168980
                    let pink = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362
                    b[6] = white * 0.115926
                    // Add occasional splat drops
                    let drop = Double.random(in: 0...1) < 0.001 ? Double.random(in: 0.5...1.0) : 0
                    channelData[ch][i] = Float((pink * 0.08) + drop * 0.2)
                }
            }

        case .ocean:
            // Ocean = slow brown wave modulation
            var lastOut: Double = 0
            let waveFreq = 0.2 / sampleRate // very slow wave
            for ch in 0..<Int(buffer.format.channelCount) {
                for i in 0..<frameCount {
                    let white = Double.random(in: -1...1)
                    lastOut = (lastOut + 0.015 * white) / 1.015
                    let wave = sin(2 * Double.pi * waveFreq * Double(i)) * 0.5 + 0.5
                    channelData[ch][i] = Float(lastOut * 3.0 * wave)
                }
            }
        }
    }

    // MARK: - Sound Types

    enum SoundType {
        case whiteNoise, pinkNoise, brownNoise, rain, ocean
    }

    static func soundType(for name: String) -> SoundType {
        switch name.lowercased() {
        case "rain": return .rain
        case "ocean": return .ocean
        case "forest": return .pinkNoise
        case "thunderstorm", "thunder": return .brownNoise
        case "white noise": return .whiteNoise
        default: return .pinkNoise
        }
    }
}
