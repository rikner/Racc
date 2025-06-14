import AVFoundation

class AudioPlayer: ObservableObject {
    var audioFile: AVAudioFile?
    
    private var engine: AVAudioEngine
    private let playerNode = AVAudioPlayerNode()
    private let speedControl = AVAudioUnitVarispeed()
    private let equalizerNode = AVAudioUnitEQ(numberOfBands: 3)
    
    let mixerNode = AVAudioMixerNode()

    @Published private(set) var isPlaying: Bool = false
    
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
            to: engine.mainMixerNode,
            fromBus: 0,
            toBus: bus,
            format: mixerOutputFormat
        )
    }

    func loadFile(url: URL) {
        guard playerNode.engine == engine else {
             return print("AudioPlayer: PlayerNode not attached to the assigned engine. Cannot load file.")
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
        let minDB: Float = -24.0
        let maxDB: Float = 6.0
        // Ensure input value is clamped between 0.0 and 1.0
        let clampedValue = max(0.0, min(1.0, value))
        let a = minDB + (clampedValue * (maxDB - minDB))
        return a
    }

    func setLowEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(0) else { return }
        equalizerNode.bands[0].gain = value //mapToDB(value)
    }

    func setMidEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(1) else { return }
        equalizerNode.bands[1].gain = value //mapToDB(value)
    }

    func setHighEQ(value: Float) {
        guard equalizerNode.bands.indices.contains(2) else { return }
        equalizerNode.bands[2].gain = value //mapToDB(value)
    }

    func play() {
        guard audioFile != nil else {
            return print("AudioPlayer: Cannot play. No audio file loaded.")
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
                isPlaying = playerNode.isPlaying
                print("AudioPlayer: Play command issued.")
            } catch {
                print("AudioPlayer: Error playing audio: \(error.localizedDescription)")
            }
        }
    }

    func pause() {
        if playerNode.isPlaying {
            playerNode.pause()
            isPlaying = playerNode.isPlaying
        }
    }

    func stop() {
        if playerNode.isPlaying {
            playerNode.stop()
            isPlaying = playerNode.isPlaying
        }
    }
}
