import SwiftUI

enum FloAnimations {
    // MARK: - Springs
    static let springDefault = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.35, dampingFraction: 0.6)
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.9)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    // MARK: - Ease
    static let easeDefault = Animation.easeInOut(duration: 0.3)
    static let easeSlow = Animation.easeInOut(duration: 0.5)
    static let easeFast = Animation.easeOut(duration: 0.2)

    // MARK: - Transitions
    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    static let slideIn = AnyTransition.move(edge: .trailing).combined(with: .opacity)
    static let fadeScale = AnyTransition.opacity.combined(with: .scale(scale: 0.9))
    static let popIn = AnyTransition.scale(scale: 0.5).combined(with: .opacity)
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - Bounce on Tap

struct BounceModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(FloAnimations.springSnappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Confetti

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
                .allowsHitTesting(false)
            )
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerConfetti()
                }
            }
    }

    private func triggerConfetti() {
        let colors: [Color] = [
            FloColors.Hex.accent,
            FloColors.Hex.success,
            FloColors.Hex.warning,
            FloColors.Hex.accentSoft,
            FloColors.Hex.accentSecondary
        ]

        particles = (0..<20).map { i in
            ConfettiParticle(
                id: i,
                x: 0, y: 0,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0
            )
        }

        for i in particles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...120)
            withAnimation(.easeOut(duration: Double.random(in: 0.6...1.2))) {
                particles[i].x = cos(angle) * distance
                particles[i].y = sin(angle) * distance - 30
                particles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isActive = false
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - View Extensions

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func bounceOnTap() -> some View {
        modifier(BounceModifier())
    }

    func confetti(isActive: Binding<Bool>) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }

    func floTransition(_ transition: AnyTransition = FloAnimations.fadeScale) -> some View {
        self.transition(transition)
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .contentTransition(.numericText(value: Double(displayValue)))
            .onAppear { displayValue = value }
            .onChange(of: value) { _, newValue in
                withAnimation(FloAnimations.springBouncy) {
                    displayValue = newValue
                }
            }
    }
}
