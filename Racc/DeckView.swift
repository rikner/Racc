import SwiftUI
import Controls


enum DeckLayout {
    case left, right
}

struct DeckView: View {
    let deckName: String
    let layout: DeckLayout
    
    @ObservedObject var audioPlayer: AudioPlayer

    @State private var audioFileURL: URL?
    
    @State var modWheelValue: Float = 0.5
    
    @State var isPlaying = false
    
    @State var lowEqKnobValue: Float = 0.5
    @State var midEqKnobValue: Float = 0.5
    @State var highEqKnobValue: Float = 0.5

    @ViewBuilder
    private var modWheelControl: some View {
        ModWheel(value: $modWheelValue)
            .foregroundColor(.black)
            .cornerRadius(10)
            .frame(width: 50)
            .onChange(of: modWheelValue) { newValue in
                 audioPlayer.setModWheel(value: newValue)
            }
    }

    @ViewBuilder
    private var equalizerControl: some View {
        Equalizer(hi: $highEqKnobValue, mid: $midEqKnobValue, lo: $lowEqKnobValue)
            .onChange(of: highEqKnobValue, perform: audioPlayer.setHighEQ)
            .onChange(of: midEqKnobValue, perform: audioPlayer.setMidEQ)
            .onChange(of: lowEqKnobValue, perform: audioPlayer.setLowEQ)
    }

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
                }
                .padding(.top)


                if let url = audioFileURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                }
            }
            
            HStack {
                if layout == .left {
                    modWheelControl
                    Spacer()
                    equalizerControl
                } else {
                    equalizerControl
                    Spacer()
                    modWheelControl
                }
            }


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


struct Equalizer: View {
    @Binding var hi: Float
    @Binding var mid: Float
    @Binding var lo: Float
    
    let range: ClosedRange<Float> = 0 ... 1
    
    var body: some View {
        VStack {
            ArcKnob("Hi", value: $hi, range: range).foregroundColor(.black)
            ArcKnob("Mid", value: $mid, range: range).foregroundColor(.black)
            ArcKnob("Lo", value: $lo, range: range).foregroundColor(.black)
        }.frame(maxHeight: 300)
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
