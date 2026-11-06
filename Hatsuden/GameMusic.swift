import AVFAudio
import Foundation
import Observation

@MainActor
@Observable
final class GameMusic {
    static let shared = GameMusic()

    private static let muteKey = "hatsuden.musicMuted"
    private(set) var isMuted = UserDefaults.standard.bool(forKey: GameMusic.muteKey)
    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var isInGame = false
    @ObservationIgnored private var isShowingReward = false

    private init() {}

    func toggleMute() {
        isMuted.toggle()
        UserDefaults.standard.set(isMuted, forKey: Self.muteKey)
        updatePlayback()
    }

    func setInGame(_ isInGame: Bool) {
        self.isInGame = isInGame
        updatePlayback()
    }

    func setShowingReward(_ isShowingReward: Bool) {
        self.isShowingReward = isShowingReward
        updatePlayback()
    }

    private func updatePlayback() {
        guard isInGame, !isShowingReward, !isMuted else {
            player?.pause()
            return
        }

        if player == nil {
            guard let url = Bundle.main.url(forResource: "CozyPuzzle", withExtension: "m4a"),
                  let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
            newPlayer.volume = 0.20
            newPlayer.numberOfLoops = -1
            player = newPlayer
        }

        guard let player, !player.isPlaying else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            player.play()
        } catch {
            // Playback can be retried the next time the game becomes active.
        }
    }
}
