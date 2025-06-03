import SwiftUI
import Controls
import Waveform

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
    @State var pitchFaderValue: Float = 0.5
    @State var lowEqKnobValue: Float = 0
    @State var midEqKnobValue: Float = 0
    @State var highEqKnobValue: Float = 0
    
    private var waveForm: some View {
        let waveformHeight: CGFloat = 100

        return Group {
            if let sampleBuffer = sampleBuffer {
                Waveform(samples: sampleBuffer)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
            } else {
                 ZStack {
                     Rectangle().fill(Color.gray.opacity(0.1))
                     Text("No track loaded").foregroundColor(.gray)
                 }
            }
        }
        .frame(height: waveformHeight)
        .frame(maxWidth: .infinity)
        .cornerRadius(10)
        .border(Color.gray, width: 2)
        .padding(.all)
    }

    @ViewBuilder
    private var pitchFader: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                
                let height = min(300, proxy.size.height)
                let width = height / 5
                
                ModWheel(value: $pitchFaderValue)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(width: width, height: height)
                    .onChange(of: pitchFaderValue) { audioPlayer.setModWheel(value: $1) }

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
                    pitchFader
                    equalizerControl
                } else {
                    equalizerControl
                    pitchFader
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
    
    let range: ClosedRange<Float> = -36 ... 12
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
