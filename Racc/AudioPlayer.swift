import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var engine: AVAudioEngine? // Reference to the engine it's part of

    init() {
        // Node is created, but not yet attached to an engine
    }

    func assignEngine(_ audioEngine: AVAudioEngine) {
        self.engine = audioEngine
        // AudioManager will be responsible for attaching this playerNode to the passed engine.
    }

    func loadFile(url: URL) {
        guard let assignedEngine = self.engine else {
            print("AudioPlayer: Engine not assigned. Cannot load file.")
            return
        }
        // Check if the playerNode is actually part of the assigned engine's graph
        guard playerNode.engine == assignedEngine else {
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
        playerNode.volume = max(0.0, min(1.0, volume))
    }

    func play() {
        guard audioFile != nil else {
            print("AudioPlayer: Cannot play. No audio file loaded.")
            return
        }
        guard let assignedEngine = self.engine, playerNode.engine == assignedEngine else {
            print("AudioPlayer: Cannot play. Node not attached to its assigned engine.")
            return
        }

        if !playerNode.isPlaying {
            do {
                if !assignedEngine.isRunning {
                    try assignedEngine.start()
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
        }
    }
}
