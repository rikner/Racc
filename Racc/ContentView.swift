import SwiftUI
import Controls

struct ContentView: View {
    @State var crossfaderValue: Float = 0.5
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                DeckView(
                    deckName: "Deck A",
                    layout: .left,
                    accent: Theme.deckA,
                    audioPlayer: audioManager.playerA
                )
                DeckView(
                    deckName: "Deck B",
                    layout: .right,
                    accent: Theme.deckB,
                    audioPlayer: audioManager.playerB
                )
            }

            crossfader
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }

    private var crossfader: some View {
        VStack(spacing: 6) {
            Text("Crossfader")
                .legendLabel()

            HStack(spacing: 12) {
                Text("A")
                    .font(.legend(12))
                    .foregroundStyle(Theme.deckA)

                Slider(value: $crossfaderValue, in: 0...1)
                    .tint(Theme.textSecondary)
                    .onChange(of: crossfaderValue) { _, newValue in
                        audioManager.setCrossfader(value: newValue)
                    }
                    .background(alignment: .center) {
                        // A→B gradient behind the track, with a centre detent mark.
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.deckA.opacity(0.35),
                                            Theme.stroke,
                                            Theme.deckB.opacity(0.35),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 4)

                            Rectangle()
                                .fill(Theme.textDim)
                                .frame(width: 1, height: 12)
                        }
                    }

                Text("B")
                    .font(.legend(12))
                    .foregroundStyle(Theme.deckB)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .wellStyle(cornerRadius: Theme.panelCorner)
        }
        .padding(.horizontal, 40)
    }
}


#Preview {
    ContentView()
        .environmentObject(AudioManager())
}
