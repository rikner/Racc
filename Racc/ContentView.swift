import SwiftUI
import Controls
import FilePicker

struct ContentView: View {
    
    @State var crossfaderValue: Float = 0.5
    
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        VStack {
            HStack {
                DeckView(deckName: "Deck A" , audioPlayer: audioManager.playerA)
                DeckView(deckName: "Deck B", audioPlayer: audioManager.playerB)
            }

            Slider(value: $crossfaderValue, in: 0...1) {
                Text("Crossfader")
            }
            .padding()
             .onChange(of: crossfaderValue) { newValue in
                 // Update volume of audioPlayerA and audioPlayerB based on newValue
                 audioManager.setCrossfader(value: newValue)
             }
        }
        .padding()
    }
}

struct DeckView: View {
    let deckName: String
    
    @ObservedObject var audioPlayer: AudioPlayer

    @State private var audioFileURL: URL?
    
    @State var modulation: Float = 0.5
    
    @State var isPlaying = false

    var body: some View {
        VStack {
            
            Text(deckName)
                .font(.headline)


            HStack {
                AudioFilePicker(selectedFileUrl: $audioFileURL, buttonText: "Load Track")

                PlayPauseButton(isPlaying: $isPlaying) {
                    if isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }// Add the PlayPauseButton
                    .padding(.top)

                // Example: Display selected file name
                if let url = audioFileURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                }
            }

            Equalizer() // You can have an EQ per deck

            ModWheel(value: $modulation)
                .foregroundColor(.black)
                .cornerRadius(10)
                .frame(width: 50)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
         .onChange(of: audioFileURL) { newURL in
             if let url = newURL {
                  audioPlayer.loadFile(url: url)
             }
         }
    }
}


struct AudioFilePicker: View {
    @Binding var selectedFileUrl: URL? // Changed to bind a single URL
    var buttonText: String = "Select File"

    @State private var filePickerOpen = false
    @State private var filePickerFiles: [URL] = [] // Still used by the .filePicker modifier

    var body: some View {
        VStack {
            Button(buttonText, systemImage: "square.and.arrow.down") {
                filePickerOpen.toggle()
            }
        }
        .padding()
        .filePicker(
            isPresented: $filePickerOpen,
            files: $filePickerFiles, // The modifier expects a binding to an array
            types: [.wav, .mp3, .aiff] // Added more common audio types
        )
        .onChange(of: filePickerFiles) { newFiles in
            if let firstFile = newFiles.first {
                selectedFileUrl = firstFile
                // If you only ever want one file, clear the array after selection
                // to allow re-selection of the same file if needed by the picker.
                // Or, ensure your picker logic handles single selection appropriately.
            }
        }
    }
}

struct PlayPauseButton: View {
    @Binding var isPlaying: Bool
    // You'll likely want an action to call when the button is tapped
     var action: () -> Void

    var body: some View {
        Button {
            action() // XXX: kind of brittle since we rely on order of commands here 
            isPlaying.toggle()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
        }
    }
}


struct Equalizer: View {
    @State var hi: Float = 0
    @State var mid: Float = 0
    @State var lo: Float = 0
    
    var body: some View {
        VStack {
            ArcKnob("Hi", value: $hi).foregroundColor(.black)
            ArcKnob("Mid", value: $mid).foregroundColor(.black)
            ArcKnob("Lo", value: $lo).foregroundColor(.black)
        }
    }
}

#Preview {
    ContentView()
}
