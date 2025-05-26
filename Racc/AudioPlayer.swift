import AVFoundation

class AudioPlayer: ObservableObject {
    var audioFile: AVAudioFile?
    
    private var engine: AVAudioEngine
    private let playerNode = AVAudioPlayerNode()
    private let speedControl = AVAudioUnitVarispeed()
    private let equalizerNode = AVAudioUnitEQ(numberOfBands: 3)
    
    let mixerNode = AVAudioMixerNode()
    
    /// Configure EQ Bands (Low, Mid, High)
    private func configureEqualizer() {
        // Band 0: Low Shelf
        let lowBand = equalizerNode.bands[0]
        lowBand.filterType = .lowShelf
        lowBand.frequency = 120.0
        lowBand.gain = 0.0
        lowBand.bypass = false

        // Band 1: Mid Parametric/Peaking
        let midBand = equalizerNode.bands[1]
        midBand.filterType = .parametric
        midBand.frequency = 1000.0
        midBand.bandwidth = 1.0
        midBand.gain = 0.0
        midBand.bypass = false

        // Band 2: High Shelf
        let highBand = equalizerNode.bands[2]
        highBand.filterType = .highShelf
        highBand.frequency = 5000.0
        highBand.gain = 0.0
        highBand.bypass = false
    }
    

    init(attachTo engine: AVAudioEngine, toBus bus: AVAudioNodeBus) {
        self.engine = engine
        
        engine.attach(playerNode)
        engine.attach(mixerNode)
        engine.attach(speedControl)
        engine.attach(equalizerNode)
        
        configureEqualizer()

        // Connect nodes in the chain
        // Player -> SpeedControl
        let playerOutputFormat = playerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: speedControl, format: playerOutputFormat)
        
        // SpeedControl -> Equalizer
        let speedControlOutputFormat = speedControl.outputFormat(forBus: 0)
        engine.connect(speedControl, to: equalizerNode, format: speedControlOutputFormat)
        
        // Equalizer -> This player's MixerNode
        let equalizerOutputFormat = equalizerNode.outputFormat(forBus: 0)
        engine.connect(equalizerNode, to: mixerNode, format: equalizerOutputFormat)

        // This player's MixerNode -> Engine's MainMixerNode (or another upstream mixer) on the specified bus
        let mixerOutputFormat = mixerNode.outputFormat(forBus: 0)
        engine.connect(
            mixerNode,
            to: engine.mainMixerNode, // Assuming connection to mainMixerNode, adjust if it's a different target
            fromBus: 0,
            toBus: bus,
            format: mixerOutputFormat
        )
    }

    func loadFile(url: URL) {
        // Check if the playerNode is actually part of the assigned engine's graph
        guard playerNode.engine == engine else {
             print("AudioPlayer: PlayerNode not attached to the assigned engine. Cannot load file.")
             return
        }

        do {
            audioFile = try AVAudioFile(forReading: url)
            guard let audioFile = audioFile else {
                return
            }
            playerNode.stop()
            playerNode.scheduleFile(audioFile, at: nil, completionHandler: {
                print("AudioPlayer: \(url.lastPathComponent) finished playing.")
            })
            print("AudioPlayer: Loaded file \(url.lastPathComponent)")
        } catch {
            print("AudioPlayer: Error loading audio file \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    func setVolume(_ volume: Float) {
        mixerNode.volume = max(0.0, min(1.0, volume))
    }
    
    func setModWheel(value: Float) {
        let a: Float = 0.8
        let b: Float = 1.2
        speedControl.rate = a + (value * (b - a))
    }
    
    private func mapToDB(_ value: Float) -> Float {
        print("input value: \(value)")
        let minDB: Float = -24.0
        let maxDB: Float = 6.0
        // Ensure input value is clamped between 0.0 and 1.0
        let clampedValue = max(0.0, min(1.0, value))
        let a = minDB + (clampedValue * (maxDB - minDB))
        print("output value: \(a)")
        return a
    }

    // Gain is in decibels (dB). A common range for DJ EQs is -26dB (or -oo for kill EQs) to +6dB or +12dB.
    
    func setLowEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(0) else { return }
        equalizerNode.bands[0].gain = mapToDB(value)
        // print("AudioPlayer: Low EQ Gain set to \(gain) dB")
    }

    func setMidEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(1) else { return }
        equalizerNode.bands[1].gain = mapToDB(value)
        // print("AudioPlayer: Mid EQ Gain set to \(gain) dB")
    }

    func setHighEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(2) else { return }
        equalizerNode.bands[2].gain = mapToDB(value)
        // print("AudioPlayer: High EQ Gain set to \(gain) dB")
    }

    
    func play() {
        guard audioFile != nil else {
            print("AudioPlayer: Cannot play. No audio file loaded.")
            return
        }
        guard playerNode.engine == engine else {
            print("AudioPlayer: Cannot play. Node not attached to its assigned engine.")
            return
        }

        if !playerNode.isPlaying {
            do {
                if !engine.isRunning {
                    try engine.start()
                }
                playerNode.play()
                print("AudioPlayer: Play command issued.")
            } catch {
                print("AudioPlayer: Error playing audio: \(error.localizedDescription)")
            }
        }
    }

    func pause() {
        if playerNode.isPlaying {
            playerNode.pause()
            print("AudioPlayer: Pause command issued.")
        }
    }

    func stop() {
        if playerNode.isPlaying {
            playerNode.stop()
            print("AudioPlayer: Stop command issued.")
        }
    }
}
