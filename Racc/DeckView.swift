import SwiftUI
import Controls
import Waveform

enum DeckLayout {
    case left, right
}

struct DeckView: View {
    let deckName: String
    let layout: DeckLayout
    let accent: Color

    @ObservedObject var audioPlayer: AudioPlayer

    @State private var samples: [Float]?

    @State private var isLoadingFile = false
    @State private var loadingError: Error?

    @State private var audioFileURL: URL?
    @State private var sampleBuffer: SampleBuffer?
    @State var isPlaying = false
    @State var pitchFaderValue: Float = 0.5
    @State var lowEqKnobValue: Float = 0
    @State var midEqKnobValue: Float = 0
    @State var highEqKnobValue: Float = 0

    private var header: some View {
        HStack(spacing: 10) {
            StatusLED(color: accent, isOn: audioPlayer.isPlaying)

            Text(deckName.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(accent)

            Spacer()

            AudioFilePicker(selectedFileUrl: $audioFileURL)

            PlayPauseButton(isPlaying: .init(
                get: { audioPlayer.isPlaying },
                set: { newValue in
                    if newValue {
                        audioPlayer.play()
                    } else {
                        audioPlayer.pause()
                    }
                }
            ), disabled: audioFileURL == nil, accent: accent)
        }
        .buttonStyle(DeckButtonStyle(accent: accent))
    }

    private var trackTitle: some View {
        Text(audioFileURL?.lastPathComponent ?? "— no track loaded —")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(audioFileURL == nil ? Theme.textDim : Theme.textSecondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var waveForm: some View {
        let waveformHeight: CGFloat = 100

        return Group {
            if isLoadingFile {
                ProgressView("Loading waveform...")
                    .font(.legend())
                    .tint(accent)
                    .foregroundStyle(Theme.textSecondary)
            } else if let sampleBuffer = sampleBuffer {
                Waveform(samples: sampleBuffer)
                    .foregroundColor(accent)
                    .overlay(alignment: .center) {
                        // Centre line, so quiet passages still read as a signal.
                        Rectangle()
                            .fill(accent.opacity(0.35))
                            .frame(height: 1)
                    }
            } else if let error = loadingError {
                Text(error.localizedDescription)
                    .font(.legend())
                    .foregroundStyle(Theme.danger)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: waveformHeight)
        .wellStyle()
    }

    @ViewBuilder
    private var pitchFader: some View {
        VStack(spacing: 8) {
            Text("Pitch")
                .legendLabel()

            GeometryReader { proxy in
                let height = min(280, proxy.size.height)
                let width = max(28, height / 6)

                VStack {
                    Spacer(minLength: 0)

                    ModWheel(value: $pitchFaderValue)
                        .backgroundColor(Theme.well)
                        .foregroundColor(accent)
                        .cornerRadius(Theme.controlCorner)
                        .frame(width: width, height: height)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlCorner)
                                .strokeBorder(Theme.stroke, lineWidth: 1)
                        )
                        .onChange(of: pitchFaderValue) { audioPlayer.setModWheel(value: $1) }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var equalizerControl: some View {
        VStack(spacing: 8) {
            Text("EQ")
                .legendLabel()

            Equalizer(
                hi: $highEqKnobValue,
                mid: $midEqKnobValue,
                lo: $lowEqKnobValue,
                accent: accent
            )
            .onChange(of: highEqKnobValue) { audioPlayer.setHighEQ(value: $1) }
            .onChange(of: midEqKnobValue) { audioPlayer.setMidEQ(value: $1) }
            .onChange(of: lowEqKnobValue) { audioPlayer.setLowEQ(value: $1) }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            waveForm

            trackTitle

            HStack(spacing: 16) {
                if layout == .left {
                    pitchFader
                    equalizerControl
                } else {
                    equalizerControl
                    pitchFader
                }
            }
        }
        .padding(16)
        .panelStyle(accent: accent)
        .onChange(of: audioFileURL) { _, newURL in
            if let url = newURL {
                isLoadingFile = true
                loadingError = nil

                audioPlayer.loadFile(url: url)

                Task.detached(priority: .userInitiated) {
                    if let audioFile = await audioPlayer.audioFile,
                       let samples: [[Float]] = audioFile.floatChannelData()
                    {
                        await MainActor.run {
                            sampleBuffer = SampleBuffer(samples: samples[0])
                            isLoadingFile = false
                        }
                    }
                }
            } else {
                audioPlayer.stop()
                sampleBuffer = nil
                isLoadingFile = false
                loadingError = nil
            }
        }
    }
}


struct Equalizer: View {
    @Binding var hi: Float
    @Binding var mid: Float
    @Binding var lo: Float
    var accent: Color = Theme.deckA

    let range: ClosedRange<Float> = -36 ... 12
    private let maxHeight : CGFloat = 80

    var body: some View {
        VStack {
            knob("Hi", value: $hi)
            knob("Mid", value: $mid)
            knob("Lo", value: $lo)
        }
    }

    private func knob(_ label: String, value: Binding<Float>) -> some View {
        ArcKnob(label, value: value, range: range)
            .backgroundColor(Theme.controlTrack)
            .foregroundColor(accent)
            .frame(maxHeight: maxHeight)
    }
}


struct PlayPauseButton: View {
    @Binding var isPlaying: Bool
    var disabled: Bool
    var accent: Color = Theme.deckA

    var body: some View {
        Button {
            isPlaying.toggle()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .frame(width: 44, height: 16)
        }
        .buttonStyle(DeckButtonStyle(accent: accent, isActive: isPlaying))
        .disabled(disabled)
    }
}
