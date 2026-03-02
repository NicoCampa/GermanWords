import SwiftUI

// MARK: - Enhanced Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                Text(title)
                    .font(DesignTokens.typography.body(weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, DesignTokens.spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


struct AnimatedBackdrop: View {
    @State private var animationOffset1: CGFloat = 0
    @State private var animationOffset2: CGFloat = 0
    @State private var animationOffset3: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundGradientTop,
                    DesignTokens.color.backgroundMedium,
                    DesignTokens.color.backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.color.primary.opacity(0.1), DesignTokens.color.purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                        .offset(x: animationOffset1, y: animationOffset1 * 0.7)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.color.genderFeminine.opacity(0.08), DesignTokens.color.warning.opacity(0.04)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 150, height: 100)
                        .blur(radius: 25)
                        .rotationEffect(.degrees(rotation))
                        .offset(x: animationOffset2 * 0.5, y: -animationOffset2)
                        .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.7)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.color.info.opacity(0.12), DesignTokens.color.success.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                        .offset(x: -animationOffset3, y: animationOffset3 * 0.8)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animationOffset1 = 30
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animationOffset2 = 25
            }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animationOffset3 = 20
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .scaleEffect(isPressed ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)

                Text(title)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 36)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.9),
                                    color,
                                    color.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 28))

                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                }
            )
            .shadow(color: color.opacity(0.4), radius: 20, x: 0, y: 10)
            .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    isHovered = false
                }
                .onEnded { _ in
                    isPressed = false
                    isHovered = false
                }
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

