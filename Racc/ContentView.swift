import SwiftUI
import Controls

struct ContentView: View {
    @State var crossfaderValue: Float = 0.5
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack {
            HStack {
                DeckView(deckName: "Deck A", layout: .left, audioPlayer: audioManager.playerA)
                DeckView(deckName: "Deck B", layout: .right, audioPlayer: audioManager.playerB)
            }

            Slider(value: $crossfaderValue, in: 0...1)
            .padding()
            .onChange(of: crossfaderValue) { _, newValue in
                audioManager.setCrossfader(value: newValue)
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
