import SwiftUI
import UIKit

struct SharedCloudMascot: View {
    let scale: CGFloat
    @State private var cycleOffset = Double.random(in: 0..<SharedCloudMascot.animationCycleDuration)

    private static let assetFrameNames = [
        "wordy",
        "frame2",
        "frame3",
        "frame4",
        "frame5",
        "frame6"
    ]
    private static let frames = loadedFrames()
    private static let frameDuration = 0.14
    private static let idleDuration = 4.5
    private static let animationCycleDuration = (Double(assetFrameNames.count) * frameDuration) + idleDuration

    var body: some View {
        TimelineView(.periodic(from: .now, by: Self.frameDuration)) { context in
            Image(uiImage: Self.frames[frameIndex(for: context.date)])
                .resizable()
                .interpolation(.medium)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100 * scale, height: 100 * scale)
                .designSystemShadow(DesignTokens.shadow.light)
                .accessibilityLabel("Wolke mascot")
        }
    }

    private func frameIndex(for date: Date) -> Int {
        let cycleTime = (date.timeIntervalSinceReferenceDate + cycleOffset)
            .truncatingRemainder(dividingBy: Self.animationCycleDuration)

        if cycleTime >= Self.idleDuration {
            let animationTime = cycleTime - Self.idleDuration
            let animatedFrame = Int(animationTime / Self.frameDuration)
            return min(animatedFrame, Self.frames.count - 1)
        }

        return 0
    }

    private static func loadedFrames() -> [UIImage] {
        let assetImages = assetFrameNames.compactMap(UIImage.init(named:))
        if !assetImages.isEmpty {
            return assetImages
        }
        return [UIImage()]
    }
}

struct CrystalCloudMascot: View {
    @State private var showingMessage = false
    @State private var currentMessage = ""
    var wordDifficulty: Int = 1
    @State private var bubbleWidth: CGFloat = 0

    let easyMessages = [
        "Perfect starter word!",
        "You've got this one!",
        "Nice and simple!",
        "Building blocks of language!",
        "Easy peasy!",
        "Great foundation word!",
        "Smooth sailing ahead!",
        "You're cruising!",
        "Fundamental and useful!",
        "Building confidence!"
    ]

    let mediumMessages = [
        "Getting more interesting!",
        "Level up challenge!",
        "You're growing stronger!",
        "Embrace the challenge!",
        "Stepping up nicely!",
        "Perfect practice word!",
        "Your skills are growing!",
        "Rising to the occasion!",
        "Challenging but doable!",
        "You're improving!"
    ]

    let hardMessages = [
        "Wow, impressive word!",
        "You're a word master!",
        "That's advanced stuff!",
        "Challenging vocabulary!",
        "You're really leveling up!",
        "Expert level achieved!",
        "Sophisticated choice!",
        "Your mind is expanding!",
        "Academic excellence!",
        "Word wizard in training!"
    ]

    var body: some View {
        GeometryReader { proxy in
            let containerHalf = proxy.size.width / 2
            let spacing: CGFloat = 12
            let mascotWidth: CGFloat = 180 * 0.8 // SharedCloudMascot width at scale 0.8
            let desiredOffset = mascotWidth/2 + spacing + bubbleWidth/2
            let maxOffset = max(0, containerHalf - 16 - bubbleWidth/2) // keep 16pt margin
            let bubbleOffset = min(desiredOffset, maxOffset)

            ZStack {
                // Centered mascot
                SharedCloudMascot(scale: 0.8)

                // Bubble overlaid to the right, clamped to screen bounds
                if showingMessage {
                    CartoonSpeechBubble(text: currentMessage)
                        .font(DesignTokens.typography.footnote(weight: .semibold))
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: BubbleWidthKey.self, value: geo.size.width)
                            }
                        )
                        .onPreferenceChange(BubbleWidthKey.self) { bubbleWidth = $0 }
                        .offset(x: bubbleOffset)

                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 120) // reasonable tap area height
        .onTapGesture { showEncouragementMessage() }
    }

    private func showEncouragementMessage() {
        guard !showingMessage else { return }

        let messages: [String]
        switch wordDifficulty {
        case 1:
            messages = easyMessages
        case 2:
            messages = mediumMessages
        case 3:
            messages = hardMessages
        default:
            messages = easyMessages
        }

        currentMessage = messages.randomElement() ?? "Keep learning!"

        showingMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showingMessage = false
        }
    }
}

private struct CartoonSpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(DesignTokens.color.headingPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [DesignTokens.color.cardBackground, DesignTokens.color.cardBackground.opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DesignTokens.color.headingPrimary.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.color.primary.opacity(0.12), radius: 3, x: 0, y: 1)
            )
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 180, alignment: .leading)
    }
}

private struct BubbleWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
