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
                 ZStack {
                     Rectangle().fill(Color.gray.opacity(0.1)) // Placeholder background
                     Text("No track loaded").foregroundColor(.gray)
                 }
            }
        }
        .frame(height: waveformHeight) // Apply the fixed height
        .frame(maxWidth: .infinity)
        .cornerRadius(10)
        .border(.bar, width: 2)
        .padding(.all)
    }

    @ViewBuilder
    private var modWheelControl: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                
                let height = min(300, proxy.size.height)
                let width = proxy.size.height / 5
                
                ModWheel(value: $modWheelValue)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(width: width, height: height)
                    .onChange(of: modWheelValue) { audioPlayer.setModWheel(value: $1)
                    }


                Spacer()
            }
            .frame(maxWidth: .infinity)
        }

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
            HStack {
                Text(deckName).font(.headline)
                
                AudioFilePicker(selectedFileUrl: $audioFileURL)
                
                PlayPauseButton(isPlaying: $isPlaying, disabled: audioFileURL == nil) {
                    if isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }
            }
            
            waveForm

            if let url = audioFileURL {
                Text(url.lastPathComponent)
                    .font(.caption)
            }        
            
            HStack {
                if layout == .left {
                    modWheelControl
                    equalizerControl
                } else {
                    equalizerControl
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
    private let maxHeight : CGFloat = 80
    
    var body: some View {
        VStack {
            ArcKnob("Hi", value: $hi, range: range)
                .foregroundColor(.black)
                .frame(maxHeight: maxHeight)
            ArcKnob("Mid", value: $mid, range: range)
                .foregroundColor(.black)
                .frame(maxHeight: maxHeight)
            ArcKnob("Lo", value: $lo, range: range)
                .foregroundColor(.black)
                .frame(maxHeight: maxHeight)
        }
    }
}


struct PlayPauseButton: View {
    @Binding var isPlaying: Bool
    var disabled: Bool
    // You'll likely want an action to call when the button is tapped
     var action: () -> Void

    var body: some View {
        Button {
            action() // XXX: kind of brittle since we rely on order of commands here
            isPlaying.toggle()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .frame(width: 64, height: 24)
        }
        .disabled(disabled)
    }
}
