import SwiftUI
import Controls
import Waveform
import AVFoundation // TODO: refactor to remove this import

enum DeckLayout {
    case left, right
}

struct DeckView: View {
    let deckName: String
    let layout: DeckLayout
    
    @ObservedObject var audioPlayer: AudioPlayer
    
    @State private var samples: [Float]?

    @State private var audioFileURL: URL?
    @State private var sampleBuffer: SampleBuffer?
    @State var isPlaying = false
    @State var modWheelValue: Float = 0.5
    @State var lowEqKnobValue: Float = 0.5
    @State var midEqKnobValue: Float = 0.5
    @State var highEqKnobValue: Float = 0.5
    
    private var waveForm: some View {
        // Define the desired fixed height for the waveform area
        let waveformHeight: CGFloat = 100 // Adjust this value as needed

        return Group {
            if let sampleBuffer = sampleBuffer {
                Waveform(samples: sampleBuffer)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
            } else {
                // Use a view that will respect the frame to maintain size.
                // Color.clear will take up space but be invisible.
//                Color.clear
                // Alternatively, for a visual placeholder:
                 ZStack {
                     Rectangle().fill(Color.gray.opacity(0.1)) // Placeholder background
                     Text("No track loaded").foregroundColor(.gray)
                 }
            }
        }
        .frame(height: waveformHeight) // Apply the fixed height
        // You can also set a width or allow it to be flexible
        .frame(maxWidth: .infinity) // Example: make it take full available width
    }

    @ViewBuilder
    private var modWheelControl: some View {
        ModWheel(value: $modWheelValue)
            .foregroundColor(.black)
            .cornerRadius(10)
            .frame(width: 50)
            .onChange(of: modWheelValue) { audioPlayer.setModWheel(value: $1) }
    }

    @ViewBuilder
    private var equalizerControl: some View {
        Equalizer(hi: $highEqKnobValue, mid: $midEqKnobValue, lo: $lowEqKnobValue)
            .onChange(of: highEqKnobValue) { audioPlayer.setHighEQ(value: $1) }
            .onChange(of: midEqKnobValue) { audioPlayer.setMidEQ(value: $1) }
            .onChange(of: lowEqKnobValue) { audioPlayer.setLowEQ(value: $1) }
    }

    var body: some View {
        VStack {
            
            Text(deckName)
                .font(.headline)
            
            waveForm

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
        .onChange(of: audioFileURL) { _, newURL in
            if let url = newURL {
                audioPlayer.loadFile(url: url)
                if let audioFile = audioPlayer.audioFile, let samples: [[Float]] = audioFile.floatChannelData() {
                    sampleBuffer = SampleBuffer(samples: samples[0])
                }
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
