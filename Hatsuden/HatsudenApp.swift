import SpriteKit
import SwiftUI

@main
struct HatsudenApp: App {
    @State private var session = PlaySession()

    var body: some Scene {
        WindowGroup {
            GameScreen(session: session)
                .preferredColorScheme(.light)
        }
    }
}

@MainActor
final class PlaySession {
    let model: GameModel
    let scene: GameScene

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--stress-particles") {
            let model = GameModel.stressFixture()
            self.model = model
            scene = GameScene(model: model)
            scene.enableParticleStress()
            return
        }
#endif
        let model = GameModel()
        self.model = model
        scene = GameScene(model: model)
    }
}
