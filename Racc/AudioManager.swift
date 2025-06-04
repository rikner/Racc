import AVFoundation

class AudioManager: ObservableObject {
    private let engine = AVAudioEngine()

    let playerA: AudioPlayer
    let playerB: AudioPlayer

    init() {
        playerA = AudioPlayer(attachTo: engine, toBus: 0)
        playerB = AudioPlayer(attachTo: engine, toBus: 1)
        
        engine.prepare()

        do {
            try engine.start()
            print("AudioManager: Audio engine started successfully.")
            setCrossfader(value: 0.5)
        } catch {
            print("AudioManager: Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func setCrossfader(value: Float) {
        let clampedValue = max(0.0, min(1.0, value))
        playerA.setVolume(1.0 - clampedValue)
        playerB.setVolume(clampedValue)
    }

    deinit {
        engine.stop()
        print("AudioManager: Audio engine stopped.")
    }
}
