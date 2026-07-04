import AVFoundation

@MainActor
final class SoundPlayer {
    private var player: AVAudioPlayer?

    /// Plays a bundled mp3 by resource name ("achievement", "firstblood").
    func play(_ resource: String) {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "mp3") else {
            NSLog("Cling: sound \(resource).mp3 missing from bundle")
            return
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
