import SpriteKit
import SwiftUI

@main
struct HatsudenApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = PlaySession()
    @State private var launchAds = AppOpenAds.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if launchAds.isShowingLaunchCover {
                    ZStack {
                        NotebookPaper(asset: "ui_paper", ruled: true)
                            .ignoresSafeArea()
                        SketchIcon(symbol: .bulbOn, size: 96)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("読み込み中")
                } else {
                    GameScreen(session: session)
                }
            }
            .preferredColorScheme(.light)
            .onChange(of: scenePhase == .active && !launchAds.isShowingLaunchCover, initial: true) { _, isInGame in
                GameMusic.shared.setInGame(isInGame)
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { session.model.setActive(true) }
                if phase == .background { session.model.setActive(false) }
                session.scene.setRenderingActive(phase == .active)
                if phase == .active { launchAds.start() }
                if phase == .background { launchAds.skipIfLoading() }
            }
        }
    }
}

@MainActor
final class PlaySession {
    let model: GameModel
    let scene: GameScene

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--pile-demo") {
            let model = GameModel.pileDemoFixture()
            self.model = model
            scene = GameScene(model: model)
            return
        }
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
