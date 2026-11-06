import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    private let model: GameModel
    private let art = ArtProvider.shared
    private let fieldArt = FieldArtwork()
    private let field = SKNode()
    private let backdrop = SKSpriteNode()
    private let guides = SKNode()
    private let runners = SKNode()
    private let popups = SKNode()
    private let collapsedDot = SKSpriteNode(color: FieldInk.dark, size: .zero)
    private var guideNodes: [SKSpriteNode] = []
    private var guideCount = 0
    private var species: [SpeciesDisplay] = []
    private var animatedRunners: [RunnerDisplay] = []
    private var displayedCounts: [Int] = []
    private var displayedHighest = 0

    private var wavePool: [MoneyWave] = []
    private var waves: [MoneyWave] = []
    private var waveNumber = 0
    private var layoutRevision = 0
    private static let popupLifetime: TimeInterval = 0.72
    private static let popupHeight: CGFloat = 20
    private static let wakeDuration: TimeInterval = 0.16
    private static let runDelay: TimeInterval = 0.40

    private var layoutTopSpecies: Double
    private var unlockMotion: UnlockMotion?
    private var fieldZoom = FieldZoom.overview
    private var overviewMotion: (from: FieldZoom, elapsed: TimeInterval)?
    private var pinchStart = FieldZoom.overview
    private var pinchAnchor = CGPoint.zero
    private var previousTime: TimeInterval?
    private var renderingActive = true
    private var runPhase: CGFloat = 0
    private var activityElapsed = 0.0
    private var motion = RunnerMotion.sleeping
    private weak var gestureView: SKView?
    private var tapRecognizer: UITapGestureRecognizer?
    private var pinchRecognizer: UIPinchGestureRecognizer?

    #if DEBUG
    private var stressTapPeriod: TimeInterval?
    private var stressTapTime: TimeInterval = 0
    private var stressReportTime: TimeInterval = 0
    private var stressFrames = 0
    private var stressEmitted = 0
    private var lastWaveSize = 0
    var debugActiveWaveSizes: [Int] { waves.map { $0.sprites.count } }
    var debugLastWaveFirstTexture: SKTexture? { waves.last?.sprites.first?.texture }
    var debugHamstersAtCutoff: Int {
        guard !collapsedDot.isHidden,
              let rank = model.species.firstIndex(where: { $0.artIndex == 0 }),
              species.indices.contains(rank) else { return 0 }
        return species[rank].members.filter { $0.popupOrigin == collapsedDot.position }.count
    }

    func enableParticleStress(tapsPerSecond: Double = 10) {
        guard tapsPerSecond.isFinite, tapsPerSecond > 0 else { return }
        stressTapPeriod = 1 / tapsPerSecond
    }
    #endif

    init(model: GameModel) {
        self.model = model
        layoutTopSpecies = Double(model.highestOwned)
        super.init(size: CGSize(width: 1, height: 1))

        backgroundColor = FieldInk.paper
        backdrop.zPosition = 0
        backdrop.anchorPoint = .zero
        guides.zPosition = 1
        runners.zPosition = 3
        popups.zPosition = 7
        collapsedDot.zPosition = 2
        collapsedDot.isHidden = true
        addChild(field)
        field.addChild(backdrop)
        field.addChild(guides)
        field.addChild(runners)
        addChild(popups)
        runners.addChild(collapsedDot)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) {
        fatalError("GameScene is initialized with a GameModel.")
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = true
        removeRecognizers()

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.require(toFail: pinch)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(tap)
        gestureView = view
        tapRecognizer = tap
        pinchRecognizer = pinch
        previousTime = nil
        synchronizeInventory()
        layOutRunners()
    }

    override func willMove(from view: SKView) {
        removeRecognizers()
        previousTime = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size != oldSize else { return }
        applyZoom(fieldZoom.resized(from: oldSize, to: size))
        if let from = overviewMotion?.from {
            overviewMotion?.from = from.resized(from: oldSize, to: size)
        }
        layOutRunners()
    }

    func setRenderingActive(_ active: Bool) {
        guard renderingActive != active else { return }
        renderingActive = active
        previousTime = nil
        if !active {
            activityElapsed = 0
            renderRunners(motion: .sleeping, delta: 0)
            while let wave = waves.popLast() {
                recycle(wave)
            }
        }
    }

    func registerTap() {
        guard renderingActive else { return }
        synchronizeInventory()
        for _ in 0..<model.tap() {
            emitMoney(multiplier: model.tapMultiplier)
        }
    }

    func resetZoom() {
        guard fieldZoom != .overview else { return }
        overviewMotion = (from: fieldZoom, elapsed: 0)
    }

    override func update(_ currentTime: TimeInterval) {
        guard renderingActive else { return }
        let delta = previousTime.map { max(0, currentTime - $0) } ?? 0
        previousTime = currentTime

        synchronizeInventory()
        updateUnlock(delta: delta)
        updateOverview(delta: delta)
        model.update(delta: delta)
        updateRunners(delta: min(delta, 0.05))
        updateMoney(delta: delta)

        #if DEBUG
        updateStress(delta: delta)
        #endif
    }

    private func removeRecognizers() {
        if let tapRecognizer { gestureView?.removeGestureRecognizer(tapRecognizer) }
        if let pinchRecognizer { gestureView?.removeGestureRecognizer(pinchRecognizer) }
        gestureView = nil
        tapRecognizer = nil
        pinchRecognizer = nil
    }

    @objc private func handleTap() {
        registerTap()
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view, gesture.numberOfTouches >= 2 else { return }
        let center = convertPoint(fromView: gesture.location(in: view))
        switch gesture.state {
        case .began:
            overviewMotion = nil
            pinchStart = fieldZoom
            pinchAnchor = center
            gesture.scale = 1
        case .changed:
            applyZoom(pinchStart.magnified(by: gesture.scale, from: pinchAnchor, to: center, viewport: size))
        default:
            break
        }
    }

    private func applyZoom(_ zoom: FieldZoom) {
        guard zoom != fieldZoom else { return }
        fieldZoom = zoom
        field.position = zoom.offset
        field.setScale(zoom.scale)
        layoutRevision += 1
    }

    private func updateOverview(delta: TimeInterval) {
        guard var motion = overviewMotion else { return }
        motion.elapsed += delta
        let progress = min(1, CGFloat(motion.elapsed / 0.50))
        let eased = progress * progress * (3 - 2 * progress)
        applyZoom(motion.from.interpolatedToOverview(progress: eased))
        overviewMotion = progress == 1 ? nil : motion
    }

    private func updateUnlock(delta: TimeInterval) {
        guard var motion = unlockMotion else { return }
        motion.elapsed += delta
        let progress = min(1, motion.elapsed / 0.60)
        let eased = progress * progress * (3 - 2 * progress)
        layoutTopSpecies = progress == 1 ? motion.to : motion.from + (motion.to - motion.from) * eased
        unlockMotion = progress == 1 ? nil : motion
        layOutRunners()
    }

    private func synchronizeInventory() {
        let counts = model.counts
        guard displayedCounts != counts else { return }
        let highest = model.highestOwned
        let wasInitialized = !displayedCounts.isEmpty

        for index in 0...highest {
            let animal = model.species[index]
            if index >= species.count {
                let income = animal.income
                species.append(SpeciesDisplay(
                    index: index,
                    regular: popupAppearance(index: index, amount: income),
                    doubled: popupAppearance(index: index, amount: income * 2)
                ))
            }
            let display = species[index]
            for slot in display.members.count..<counts[index] {
                display.members.append(RunnerDisplay(artIndex: animal.artIndex, slot: slot))
            }
        }

        if wasInitialized && highest > displayedHighest {
            unlockMotion = UnlockMotion(from: layoutTopSpecies, to: Double(highest))
            resetZoom()
        }
        displayedHighest = highest
        displayedCounts = counts

        layOutRunners()
    }

    private func popupAppearance(index: Int, amount: Yen) -> PopupAppearance {
        let texture = art.moneyTexture(index: index, amount: amount)
        let size = texture.size()
        return PopupAppearance(texture: texture, width: Self.popupHeight * size.width / max(1, size.height))
    }

    private var pixelSize: CGFloat { 1 / max(1, view?.contentScaleFactor ?? 2) }

    private func layOutRunners() {
        guard size.width > 1, size.height > 1, !species.isEmpty else { return }
        let layout = StaircaseLayout(
            bounds: CGRect(origin: .zero, size: size),
            topSpeciesFloat: layoutTopSpecies,
            highestOwned: displayedHighest,
            pixelSize: pixelSize
        )
        let dot = scenePoint(layout.partition.dot)
        layOutBackdrop()
        layoutRevision += 1
        collapsedDot.size = CGSize(width: pixelSize, height: pixelSize)
        collapsedDot.position = dot
        collapsedDot.isHidden = true
        animatedRunners.removeAll(keepingCapacity: true)
        guideCount = 0

        for display in species {
            let index = display.index
            if layout.isCollapsed(index) {
                collapsedDot.isHidden = false
                for runner in display.members {
                    runner.popupOrigin = dot
                    runner.node.removeFromParent()
                }
                continue
            }

            // A newly purchased tier waits at the top edge until its tile enters.
            guard layout.partition.rect(for: index) != nil else {
                for runner in display.members {
                    runner.popupOrigin = CGPoint(x: min(25, size.width / 2), y: max(0, size.height - 8))
                    runner.node.removeFromParent()
                }
                continue
            }

            for slot in 0..<GameModel.maximumOwnedPerSpecies {
                guard let cell = layout.cell(for: index, slot: slot) else { continue }
                if slot < display.members.count {
                    position(display.members[slot], in: cell)
                } else if min(cell.width, cell.height) >= 27 {
                    showGuide(in: cell)
                }
            }
        }

        if guideCount < guideNodes.count {
            for index in guideCount..<guideNodes.count {
                guideNodes[index].isHidden = true
            }
        }
    }

    private func position(_ runner: RunnerDisplay, in cell: CGRect) {
        let center = scenePoint(CGPoint(x: cell.midX, y: cell.midY))
        let diameter = StaircaseLayout.wheelDiameter(in: cell)
        let usesDot = StaircaseLayout.usesPixelDot(in: cell, pixelSize: pixelSize)
        runner.node.position = !usesDot ? center : CGPoint(
            x: min(size.width - pixelSize / 2, max(pixelSize / 2, center.x)),
            y: min(size.height - pixelSize / 2, max(pixelSize / 2, center.y))
        )
        if runner.node.parent == nil { runners.addChild(runner.node) }
        if usesDot {
            let dot = runner.prepareDot()
            dot.size = CGSize(width: pixelSize, height: pixelSize)
            runner.popupOrigin = runner.node.position
            return
        }

        let pair = runner.prepareArt(
            wheel: art.wheelTexture(),
            animal: art.animalTexture(index: runner.artIndex),
            stand: fieldArt.stand
        )
        pair.wheel.size = CGSize(width: diameter, height: diameter)
        pair.animal.size = CGSize(width: diameter * 0.54, height: diameter * 0.54)
        pair.stand.size = CGSize(width: diameter * 0.77, height: diameter * 0.38)
        pair.stand.position = CGPoint(x: 0, y: -diameter * 0.34)
        runner.diameter = diameter
        pair.animal.position = CGPoint(x: diameter * 0.04, y: -diameter * 0.13)
        if motion == .sleeping {
            runner.setPose(.sleeping, using: art)
            pair.animal.position.y = -diameter * 0.15
            pair.animal.zRotation = 0
        } else if runner.pose == nil {
            runner.setPose(.awake, using: art)
        }
        runner.popupOrigin = CGPoint(x: center.x + diameter * 0.31, y: center.y + diameter * 0.14)
        animatedRunners.append(runner)
    }

    private func scenePoint(_ topLeftPoint: CGPoint) -> CGPoint {
        CGPoint(x: topLeftPoint.x, y: size.height - topLeftPoint.y)
    }

    private func layOutBackdrop() {
        if backdrop.texture == nil { backdrop.texture = fieldArt.background }
        let frame = FieldCamera.artworkFrame(
            in: CGRect(origin: .zero, size: size),
            topSpecies: layoutTopSpecies,
            lastSpecies: GameModel.catalog.count - 1
        )
        backdrop.size = frame.size
        backdrop.position = frame.origin
    }

    private func showGuide(in cell: CGRect) {
        if guideCount == guideNodes.count {
            let node = SKSpriteNode(texture: fieldArt.slot)
            guides.addChild(node)
            guideNodes.append(node)
        }
        let node = guideNodes[guideCount]
        guideCount += 1
        let side = min(cell.width, cell.height) * 0.84
        node.size = CGSize(width: side, height: side)
        node.position = scenePoint(CGPoint(x: cell.midX, y: cell.midY))
        node.isHidden = false
    }

    private func updateRunners(delta: TimeInterval) {
        let next: RunnerMotion
        if model.isReceivingTaps {
            activityElapsed += delta
            if activityElapsed < Self.wakeDuration {
                next = .waking
            } else if activityElapsed < Self.runDelay || !model.isLit {
                next = .stirring
            } else {
                next = .running
            }
        } else {
            activityElapsed = 0
            next = model.isBackgroundBoostActive ? .awake : .sleeping
        }

        guard next != .sleeping || motion != .sleeping else { return }
        renderRunners(motion: next, delta: delta)
    }

    private func renderRunners(motion next: RunnerMotion, delta: TimeInterval) {
        if next != motion {
            runPhase = 0
            motion = next
        }
        let turn = CGFloat(delta) * next.wheelSpeed
        runPhase = (runPhase + CGFloat(delta) * next.phaseSpeed)
            .truncatingRemainder(dividingBy: 2 * .pi)
        for runner in animatedRunners {
            guard let parts = runner.art else { continue }
            if turn > 0 {
                parts.wheel.zRotation = (parts.wheel.zRotation - turn).truncatingRemainder(dividingBy: 2 * .pi)
            }
            let phase = (runPhase + CGFloat(runner.slot) * 0.57)
                .truncatingRemainder(dividingBy: 2 * .pi)
            let size = runner.diameter
            var x: CGFloat = 0.04
            var y: CGFloat = -0.13
            var tilt: CGFloat = 0

            switch next {
            case .sleeping:
                runner.setPose(.sleeping, using: art)
                y = -0.15
            case .waking:
                runner.setPose(.awake, using: art)
                let hop = sin(CGFloat(activityElapsed / Self.wakeDuration) * .pi)
                y += hop * 0.045
                tilt = hop * -0.12
            case .awake:
                runner.setPose(.awake, using: art)
                y += sin(phase) * 0.008
            case .stirring, .running:
                runner.setPose(.running(Int(phase * 2 / .pi)), using: art)
                let stride = sin(phase)
                let amplitude: CGFloat = next == .running ? 1 : 0.38
                x += cos(phase) * 0.024 * amplitude
                y += stride * 0.044 * amplitude
                tilt = stride * 0.12 * amplitude
            }
            parts.animal.position = CGPoint(x: size * x, y: size * y)
            parts.animal.zRotation = tilt
        }
    }

    private func emitMoney(multiplier: Int) {
        guard !species.isEmpty else { return }
        let wave: MoneyWave
        if let pooled = wavePool.popLast() {
            wave = pooled
        } else {
            wave = MoneyWave(seed: waveNumber)
            waveNumber = (waveNumber + 1) % 8
        }
        configure(wave, multiplier: multiplier)
        wave.age = 0
        wave.root.alpha = 1
        for lane in wave.lanes {
            lane.position = .zero
        }

        popups.addChild(wave.root)
        waves.append(wave)

        #if DEBUG
        lastWaveSize = wave.sprites.count
        stressEmitted += lastWaveSize
        #endif
    }

    private func configure(_ wave: MoneyWave, multiplier: Int) {
        guard wave.layoutRevision != layoutRevision || wave.multiplier != multiplier else { return }
        let viewport = size
        let padding = pixelSize
        let popupHeight = Self.popupHeight
        var spriteIndex = 0

        // A detached wave owns its full SpriteKit subtree. When the board
        // stands still, tapping only attaches that subtree and resets time.
        for display in species {
            let appearance = multiplier == 2 ? display.doubled : display.regular
            let pad = min(viewport.width / 2, appearance.width / 2 + padding)
            for runner in display.members {
                if spriteIndex == wave.sprites.count {
                    wave.sprites.append(SKSpriteNode())
                }
                let sprite = wave.sprites[spriteIndex]
                spriteIndex += 1
                if sprite.texture !== appearance.texture {
                    sprite.texture = appearance.texture
                    sprite.size = CGSize(width: appearance.width, height: popupHeight)
                }
                sprite.zPosition = display.index == 0 ? 1 : 0

                let anchor = fieldZoom.point(runner.popupOrigin)
                let room = viewport.height - anchor.y - popupHeight / 2
                let band = room >= 77 ? 2 : (room >= 42 ? 1 : 0)
                let direction = anchor.x >= viewport.width / 2 ? 1 : 0
                let variation = (runner.slot + wave.seed + display.index * 3) % 8
                let index = band * 16 + direction * 8 + variation
                let lane = MoneyWave.trajectories[index]
                let x = max(pad, min(viewport.width - pad, anchor.x))
                let y = max(popupHeight / 2, min(viewport.height - popupHeight / 2 - lane.y, anchor.y))
                sprite.position = CGPoint(x: x, y: y)
                if sprite.parent !== wave.lanes[index] {
                    sprite.removeFromParent()
                    wave.lanes[index].addChild(sprite)
                }
            }
        }
        wave.layoutRevision = layoutRevision
        wave.multiplier = multiplier
    }

    private func updateMoney(delta: TimeInterval) {
        var index = 0
        while index < waves.count {
            let wave = waves[index]
            wave.age += delta
            if wave.age >= Self.popupLifetime {
                waves.swapAt(index, waves.count - 1)
                waves.removeLast()
                recycle(wave)
                continue
            }

            let time = CGFloat(wave.age / Self.popupLifetime)
            let eased = 1 - (1 - time) * (1 - time)
            wave.root.alpha = 1 - time * time
            for laneIndex in wave.lanes.indices {
                let trajectory = MoneyWave.trajectories[laneIndex]
                wave.lanes[laneIndex].position = CGPoint(x: trajectory.x * eased, y: trajectory.y * eased)
            }
            index += 1
        }
    }

    private func recycle(_ wave: MoneyWave) {
        wave.root.removeFromParent()
        wavePool.append(wave)
    }

    #if DEBUG
    private func updateStress(delta: TimeInterval) {
        guard let period = stressTapPeriod, delta > 0 else { return }
        stressTapTime += delta
        stressReportTime += delta
        stressFrames += 1
        while stressTapTime >= period {
            stressTapTime -= period
            registerTap()
        }
        if stressReportTime >= 3 {
            let fps = Double(stressFrames) / stressReportTime
            let active = waves.reduce(0) { $0 + $1.sprites.count }
            NSLog("Hatsuden particle stress: %.1f update fps, %d active, %d emitted, %d per wave",
                  fps, active, stressEmitted, lastWaveSize)
            stressFrames = 0
            stressReportTime = 0
        }
    }
    #endif
}

private struct UnlockMotion {
    let from: Double
    let to: Double
    var elapsed: TimeInterval = 0
}

private enum RunnerMotion {
    case sleeping, awake, waking, stirring, running

    var wheelSpeed: CGFloat {
        switch self {
        case .stirring: 1.8
        case .running: 8.2
        default: 0
        }
    }

    var phaseSpeed: CGFloat {
        switch self {
        case .awake: 2
        case .stirring: 7
        case .running: 18
        default: 0
        }
    }
}

private enum AnimalPose: Equatable {
    case sleeping, awake, running(Int)
}

private struct PopupAppearance {
    let texture: SKTexture
    let width: CGFloat
}

@MainActor
private final class SpeciesDisplay {
    let index: Int
    let regular: PopupAppearance
    let doubled: PopupAppearance
    var members: [RunnerDisplay] = []

    init(index: Int, regular: PopupAppearance, doubled: PopupAppearance) {
        self.index = index
        self.regular = regular
        self.doubled = doubled
    }
}

@MainActor
private final class RunnerDisplay {
    struct Art {
        let wheel: SKSpriteNode
        let animal: SKSpriteNode
        let stand: SKSpriteNode
    }

    let artIndex: Int
    let slot: Int
    let node = SKNode()
    var art: Art?
    var diameter: CGFloat = 0
    var popupOrigin = CGPoint.zero
    private(set) var pose: AnimalPose?
    private var dot: SKSpriteNode?

    init(artIndex: Int, slot: Int) {
        self.artIndex = artIndex
        self.slot = slot
    }

    func setPose(_ newPose: AnimalPose, using provider: ArtProvider) {
        guard pose != newPose, let art else { return }
        switch newPose {
        case .sleeping:
            art.animal.texture = provider.sleepingTexture(index: artIndex)
        case .awake:
            art.animal.texture = provider.animalTexture(index: artIndex)
        case let .running(frame):
            art.animal.texture = provider.runningTexture(index: artIndex, frame: frame)
        }
        pose = newPose
    }

    func prepareDot() -> SKSpriteNode {
        if let art, art.wheel.parent != nil {
            node.removeAllChildren()
        }
        let sprite = dot ?? SKSpriteNode(color: FieldInk.dark, size: .zero)
        dot = sprite
        if sprite.parent == nil { node.addChild(sprite) }
        return sprite
    }

    func prepareArt(wheel: SKTexture, animal: SKTexture, stand: SKTexture) -> Art {
        dot?.removeFromParent()
        let currentArt: Art
        if let art {
            currentArt = art
        } else {
            currentArt = Art(wheel: SKSpriteNode(texture: wheel),
                             animal: SKSpriteNode(texture: animal),
                             stand: SKSpriteNode(texture: stand))
            currentArt.wheel.zPosition = 1
            currentArt.animal.zPosition = 2
            art = currentArt
        }
        if currentArt.wheel.parent == nil {
            node.addChild(currentArt.stand)
            node.addChild(currentArt.wheel)
            node.addChild(currentArt.animal)
        }
        return currentArt
    }
}

@MainActor
private final class MoneyWave {
    // Each lane moves all of its sprites together. Even at the maximum
    // inventory there are only 48 transforms and one alpha change per wave.
    static let trajectories: [CGPoint] = (0..<48).map { index in
        let verticalBand = index / 16
        let direction: CGFloat = (index / 8).isMultiple(of: 2) ? 1 : -1
        let variation = CGFloat(index % 8)
        return CGPoint(x: direction * (4 + variation * 4.4),
                       y: [12.0, 28.0, 50.0][verticalBand] + variation * (verticalBand == 0 ? 1.6 : 3.2))
    }

    let root = SKNode()
    let lanes: [SKNode]
    let seed: Int
    var sprites: [SKSpriteNode] = []
    var age: TimeInterval = 0
    var layoutRevision = -1
    var multiplier = 0

    init(seed: Int) {
        self.seed = seed
        lanes = Self.trajectories.map { _ in SKNode() }
        for lane in lanes {
            root.addChild(lane)
        }
    }
}
