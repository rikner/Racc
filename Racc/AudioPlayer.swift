import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    private var audioFile: AVAudioFile?
    private var engine: AVAudioEngine
    private let playerNode = AVAudioPlayerNode()
    public let mixerNode = AVAudioMixerNode()

    init(attachTo engine: AVAudioEngine, toBus bus: AVAudioNodeBus) {
        self.engine = engine
        engine.attach(playerNode)
        engine.attach(mixerNode)
        
        let outputFormat = mixerNode.outputFormat(forBus: 0)
        
        engine.connect(playerNode, to: mixerNode, format: outputFormat)
        engine.connect(mixerNode, to: engine.mainMixerNode, fromBus: 0, toBus: bus, format: outputFormat)
    }

    func loadFile(url: URL) {
        // Check if the playerNode is actually part of the assigned engine's graph
        guard playerNode.engine == engine else {
             print("AudioPlayer: PlayerNode not attached to the assigned engine. Cannot load file.")
             return
        }

        do {
            audioFile = try AVAudioFile(forReading: url)
            guard let audioFile = audioFile else { return }

            if playerNode.isPlaying {
                playerNode.stop()
            }
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
