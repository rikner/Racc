import AVFoundation
import Combine

class AudioManager: ObservableObject {
    let engine = AVAudioEngine()

    // Keep references to your simplified AudioPlayer objects
    public let playerA = AudioPlayer()
    public let playerB = AudioPlayer()

    init() {
        // Assign engine to players
        playerA.assignEngine(engine)
        playerB.assignEngine(engine)

        // Attach nodes to the engine
        // Player nodes are attached within assignEngine or here explicitly
        engine.attach(playerA.playerNode)
        engine.attach(playerB.playerNode)
    
        // Connect player nodes to the crossfader mixer
        // It's crucial to use a compatible format for connections.
        // Using the player's output format for its connection to the mixer is a common approach.
        let playerAOutputFormat = playerA.playerNode.outputFormat(forBus: 0)
        let playerBOutputFormat = playerB.playerNode.outputFormat(forBus: 0)

        engine.connect(playerA.playerNode, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: playerAOutputFormat)
        engine.connect(playerB.playerNode, to: engine.mainMixerNode, fromBus: 0, toBus: 1, format: playerBOutputFormat)
        
        // Prepare the engine
        engine.prepare()

        do {
            try engine.start()
            print("AudioManager: Audio engine started successfully.")
            // Set initial crossfader position (e.g., center)
            setCrossfader(value: 0.5)
        } catch {
            print("AudioManager: Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func setCrossfader(value: Float) {
        let clampedValue = max(0.0, min(1.0, value)) // Ensure value is between 0 and 1
        // Volume for Player A (connected to bus 0 of crossfaderMixer)
        playerA.setVolume(1.0 - clampedValue)
        // Volume for Player B (connected to bus 1 of crossfaderMixer)
        playerB.setVolume(clampedValue)
        // print("AudioManager: Crossfader set. Bus 0 (A): \(1.0 - clampedValue), Bus 1 (B): \(clampedValue)")
    }

    // Optional: Add cleanup
    deinit {
        engine.stop()
        print("AudioManager: Audio engine stopped.")
    }
}
