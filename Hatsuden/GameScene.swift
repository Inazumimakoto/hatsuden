import SpriteKit
import UIKit

/// Physics positions, painted scenery and the free pileCamera all share one world.
@MainActor
final class GameScene: SKScene {
    private let model: GameModel
    private let art = ArtProvider.shared
    private let wheelSizes: PileWheelSizes
    private let scenery: PileBackdrop
    private var world = PileWorld(bounds: GameScene.initialBounds)
    private var pileCamera = PileCamera(worldBounds: GameScene.initialBounds, viewport: CGSize(width: 1, height: 1))
    private let runners = SKNode()
    private let popups = SKNode()
    private let boxOutline = SKShapeNode()
    private var species: [SpeciesDisplay] = []
    private var runnerByID: [Int: RunnerDisplay] = [:]
    private var animatedRunners: [RunnerDisplay] = []
    private var displayedCounts: [Int] = []
    private var pending: [Arrival] = []
    private var arrivalElapsed: TimeInterval = 0
    private var arrivalDelay: TimeInterval = 0
    private var cameraMotion: CameraMotion?
    private var fieldInput = FieldTouchInput<ObjectIdentifier>()
    private var previousTime: TimeInterval?
    private var renderingActive = true
    private var isShopPresented = false
    private var runPhase: CGFloat = 0
    private var activityElapsed = 0.0
    private var motion = RunnerMotion.sleeping
    private var lastCamera: PileCamera?
    private var layoutDirty = false
    private var saveElapsed: TimeInterval = 0
    private var lastShake: TimeInterval = -.infinity
    private var shakeStrength: CGFloat = 1
    private var wavePool: [MoneyWave] = []
    private var waves: [MoneyWave] = []
    private var waveNumber = 0
    private var layoutRevision = 0
    private static let initialBounds = CGRect(x: -240, y: 0, width: 240, height: 400)
    private static let popupLifetime: TimeInterval = 0.72
    private static let popupHeight: CGFloat = 20
    private static let wakeDuration: TimeInterval = 0.16
    private static let runDelay: TimeInterval = 0.40

    private struct Arrival: Codable { let species: Int; let slot: Int }
    private struct LayoutSave: Codable {
        let artIndices: [Int]
        let snapshot: PileWorldSnapshot
        let pending: [Arrival]
    }
    private struct CameraMotion {
        let from: PileCamera
        let to: PileCamera
        var elapsed: TimeInterval = 0
        let duration: TimeInterval
    }

    #if DEBUG
    private var stressTapPeriod: TimeInterval?
    private var stressTapTime: TimeInterval = 0
    private var stressReportTime: TimeInterval = 0
    private var stressFrames = 0
    private var stressEmitted = 0
    private var lastWaveSize = 0
    var debugActiveWaveSizes: [Int] { waves.map { $0.sprites.count } }
    var debugLastWaveFirstTexture: SKTexture? { waves.last?.sprites.first?.texture }
    var debugCamera: PileCamera { pileCamera }
    var debugWorld: PileWorld { world }
    var debugBackdropMarks: [FieldMotif: CGRect] { scenery.markFrames }
    var debugCanvasDetails: [Int: CGRect] { scenery.detailFrames }
    var debugBackdropFrame: CGRect { scenery.referenceFrame }
    var debugPendingCount: Int { pending.count }
    func debugSetZoom(factor: CGFloat, at anchor: CGPoint? = nil) {
        synchronizeInventory()
        cameraMotion = nil
        pileCamera.magnify(by: factor, at: anchor ?? CGPoint(x: size.width / 2, y: size.height / 2))
        projectWorld()
    }
    func debugPan(by translation: CGPoint) {
        cameraMotion = nil
        pileCamera.pan(by: translation)
        projectWorld()
    }
    func debugRunnerFrame(species index: Int, slot: Int) -> CGRect? {
        guard species.indices.contains(index), species[index].members.indices.contains(slot) else { return nil }
        let runner = species[index].members[slot]
        guard let wheel = world.wheels.first(where: { $0.id == runner.worldID }) else { return nil }
        let center = pileCamera.screenPoint(fromWorld: wheel.position)
        let diameter = wheel.radius * 2 * pileCamera.scale
        return CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
    }
    func enableParticleStress(tapsPerSecond: Double = 10) {
        guard tapsPerSecond.isFinite, tapsPerSecond > 0 else { return }
        stressTapPeriod = 1 / tapsPerSecond
    }
    #endif

    init(model: GameModel) {
        self.model = model
        wheelSizes = PileWheelSizes(species: model.species)
        scenery = PileBackdrop(sizes: wheelSizes)
        super.init(size: CGSize(width: 1, height: 1))
        backgroundColor = FieldInk.paper
        scenery.node.zPosition = 0
        runners.zPosition = 3
        boxOutline.zPosition = 4
        popups.zPosition = 7
        boxOutline.strokeColor = FieldInk.dark.withAlphaComponent(0.8)
        boxOutline.lineWidth = 2.3
        boxOutline.fillColor = .clear
        addChild(scenery.node)
        addChild(runners)
        addChild(boxOutline)
        addChild(popups)
        scaleMode = .resizeFill
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("GameScene requires GameModel") }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = true
        fieldInput.reset()
        previousTime = nil
        pileCamera.resize(viewport: size)
        synchronizeInventory()
        projectWorld()
    }

    override func willMove(from view: SKView) {
        saveLayout()
        fieldInput.reset()
        previousTime = nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size != oldSize else { return }
        cameraMotion = nil
        pileCamera.resize(viewport: size)
        fieldInput.reset()
        projectWorld()
    }

    func setRenderingActive(_ active: Bool) {
        guard renderingActive != active else { return }
        renderingActive = active
        previousTime = nil
        if !active {
            saveLayout()
            fieldInput.reset()
            activityElapsed = 0
            renderRunners(motion: .sleeping, delta: 0)
            while let wave = waves.popLast() { recycle(wave) }
        }
    }

    func setShopPresented(_ presented: Bool) {
        guard isShopPresented != presented else { return }
        isShopPresented = presented
        fieldInput.reset()
        previousTime = nil
        if presented { saveLayout() }
        else { synchronizeInventory() }
    }

    // Purchases wait at the chute until the full-screen shop has closed.
    func synchronizeShopAdditions() {}

    func registerTap() { registerTaps(1) }

    private func registerTaps(_ count: Int) {
        guard renderingActive, !isShopPresented, count > 0 else { return }
        synchronizeInventory()
        for _ in 0..<count {
            for _ in 0..<model.tap() { emitMoney(multiplier: model.tapMultiplier) }
        }
    }

    func shake() {
        guard renderingActive, !isShopPresented else { return }
        synchronizeInventory()
        let now = ProcessInfo.processInfo.systemUptime
        shakeStrength = now - lastShake < 0.75 ? min(2.2, shakeStrength + 0.30) : 1
        lastShake = now
        world.shake(strength: shakeStrength)
        layoutDirty = true
        projectWorld()
    }

    func resetZoom() {
        var target = pileCamera
        target.reset()
        animateCamera(to: target, duration: 0.65)
    }

    override func update(_ currentTime: TimeInterval) {
        guard renderingActive else { return }
        let actualDelta = previousTime.map { max(0, currentTime - $0) } ?? 0
        let delta = min(0.067, actualDelta)
        previousTime = currentTime
        synchronizeInventory()
        if !isShopPresented {
            updateCamera(delta: delta)
            updateArrivals(delta: delta)
            let moving = world.isMoving
            world.advance(delta: delta, minimumCollisionRadius: 1.5 / pileCamera.scale)
            if moving { layoutDirty = true }
            if moving || lastCamera != pileCamera { projectWorld() }
            saveElapsed += actualDelta
            if saveElapsed >= 5 { saveLayout() }
        }
        model.update(delta: actualDelta)
        updateRunners(delta: delta)
        updateMoney(delta: actualDelta)
        #if DEBUG
        updateStress(delta: actualDelta)
        #endif
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard renderingActive, !isShopPresented, let time = event?.timestamp ?? touches.first?.timestamp else { return }
        fieldInput.began(locations(of: touches), at: time)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard renderingActive, !isShopPresented, let gesture = fieldInput.moved(locations(of: touches)) else { return }
        cameraMotion = nil
        pileCamera.gesture(from: gesture.previousCenter, to: gesture.center, factor: gesture.incrementalFactor)
        projectWorld()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let time = event?.timestamp ?? touches.first?.timestamp else { return }
        registerTaps(fieldInput.ended(locations(of: touches), at: time))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        fieldInput.cancelled(Set(touches.map(ObjectIdentifier.init)))
    }

    private func locations(of touches: Set<UITouch>) -> [ObjectIdentifier: CGPoint] {
        Dictionary(uniqueKeysWithValues: touches.map { (ObjectIdentifier($0), $0.location(in: self)) })
    }

    private func animateCamera(to target: PileCamera, duration: TimeInterval) {
        if UIAccessibility.isReduceMotionEnabled {
            pileCamera = target
            cameraMotion = nil
            projectWorld()
        } else if pileCamera != target {
            cameraMotion = CameraMotion(from: pileCamera, to: target, duration: duration)
        }
    }

    private func updateCamera(delta: TimeInterval) {
        guard var transition = cameraMotion else { return }
        transition.elapsed += delta
        let progress = min(1, CGFloat(transition.elapsed / transition.duration))
        let eased = progress * progress * (3 - 2 * progress)
        pileCamera = transition.from.interpolated(to: transition.to, progress: eased)
        cameraMotion = progress == 1 ? nil : transition
    }

    private func synchronizeInventory() {
        guard !isShopPresented else { return }
        let counts = Array(model.counts.prefix(model.highestOwned + 1))
        guard counts != displayedCounts else { return }
        let initial = displayedCounts.isEmpty
        var additions: [Arrival] = []
        for index in counts.indices {
            let animal = model.species[index]
            if index >= species.count {
                species.append(SpeciesDisplay(index: index,
                    regular: popupAppearance(index: index, amount: animal.income),
                    doubled: popupAppearance(index: index, amount: animal.income * 2)))
            }
            let display = species[index]
            for slot in display.members.count..<counts[index] {
                display.members.append(RunnerDisplay(artIndex: animal.artIndex, slot: slot))
                additions.append(Arrival(species: index, slot: slot))
            }
        }
        displayedCounts = counts
        let oldBounds = world.bounds
        expandForInventory()
        if initial {
            if !restoreLayout() {
                if counts.reduce(0, +) == 1 {
                    pending = additions
                    arrivalDelay = 0
                    arrivalElapsed = 0.2
                } else {
                    for arrival in additions.sorted(by: { wheelSizes[$0.species] > wheelSizes[$1.species] }) {
                        add(arrival, settled: true)
                    }
                }
            }
            pileCamera.updateWorldBounds(world.bounds, preserveView: false)
        } else {
            if pending.isEmpty { arrivalElapsed = 0.14 }
            pending.append(contentsOf: additions)
            pileCamera.updateWorldBounds(world.bounds)
            if world.bounds != oldBounds {
                var target = pileCamera
                target.reset()
                animateCamera(to: target, duration: 1.15)
                arrivalDelay = UIAccessibility.isReduceMotionEnabled ? 0 : 0.95
            }
        }
        layoutDirty = true
        projectWorld()
    }

    private func expandForInventory() {
        let aspect: CGFloat = 240 / 400
        var area: CGFloat = 0
        var largest: CGFloat = 0
        for index in displayedCounts.indices {
            let diameter = wheelSizes[index]
            largest = max(largest, diameter)
            area += CGFloat(displayedCounts[index]) * .pi * diameter * diameter / 4
        }
        let required = max(240, largest * 3.4, sqrt(area * aspect / 0.36))
        // Leave headroom. One tiny purchase in a crowded late-game box must not
        // cause a new pullback for a fractional change in its occupied area.
        guard required > world.bounds.width * 1.01 else { return }
        let width = max(required * 1.12, world.bounds.width * 1.18)
        world.expand(to: CGRect(x: -width, y: 0, width: width, height: width / aspect))
    }

    private func add(_ arrival: Arrival, settled: Bool) {
        let radius = wheelSizes[arrival.species] / 2
        let id: Int
        if settled {
            id = world.addSettled(species: arrival.species, slot: arrival.slot, radius: radius)
        } else {
            let visible = pileCamera.visibleWorldBounds.intersection(world.bounds)
            let start = CGPoint(x: visible.maxX - radius * 1.08,
                                y: visible.maxY - radius * 1.08)
            id = world.add(species: arrival.species, slot: arrival.slot, radius: radius,
                           at: start, launchSize: visible.size)
        }
        let runner = species[arrival.species].members[arrival.slot]
        runner.worldID = id
        runnerByID[id] = runner
    }

    private func updateArrivals(delta: TimeInterval) {
        guard !pending.isEmpty else { return }
        if arrivalDelay > 0 { arrivalDelay = max(0, arrivalDelay - delta); return }
        arrivalElapsed += delta
        if arrivalElapsed >= 0.14 {
            arrivalElapsed = 0
            add(pending.removeFirst(), settled: false)
            pileCamera.updateWorldBounds(world.bounds)
            layoutDirty = true
            projectWorld()
        }
    }

    private func saveLayout() {
        saveElapsed = 0
        guard layoutDirty, !world.wheels.isEmpty else { return }
        let save = LayoutSave(artIndices: Array(model.species.prefix(displayedCounts.count)).map(\.artIndex),
                              snapshot: world.snapshot, pending: pending)
        if let data = try? JSONEncoder().encode(save) { model.savePileLayout(data) }
        layoutDirty = false
    }

    private func restoreLayout() -> Bool {
        guard let data = model.loadPileLayout(), let save = try? JSONDecoder().decode(LayoutSave.self, from: data),
              save.artIndices.count <= displayedCounts.count,
              save.artIndices == model.species.prefix(save.artIndices.count).map(\.artIndex),
              save.snapshot.wheels.count + save.pending.count <= displayedCounts.reduce(0, +),
              save.pending.allSatisfy({ displayedCounts.indices.contains($0.species) && $0.slot >= 0 && $0.slot < displayedCounts[$0.species] }),
              save.snapshot.wheels.allSatisfy({
                  displayedCounts.indices.contains($0.species) && $0.slot >= 0 &&
                  $0.slot < displayedCounts[$0.species] &&
                  abs($0.radius * 2 - Double(wheelSizes[$0.species])) < 0.001
              }) else { return false }
        let allMembers = save.snapshot.wheels.map { "\($0.species):\($0.slot)" } + save.pending.map { "\($0.species):\($0.slot)" }
        guard Set(allMembers).count == allMembers.count, world.restore(save.snapshot) else { return false }
        expandForInventory()
        pending = save.pending
        let recorded = Set(allMembers)
        for index in displayedCounts.indices {
            for slot in 0..<displayedCounts[index] where !recorded.contains("\(index):\(slot)") {
                pending.append(Arrival(species: index, slot: slot))
            }
        }
        for wheel in world.wheels {
            let runner = species[wheel.species].members[wheel.slot]
            runner.worldID = wheel.id
            runnerByID[wheel.id] = runner
        }
        return true
    }

    private var pixelSize: CGFloat { 1 / max(1, view?.contentScaleFactor ?? 2) }

    private func projectWorld() {
        guard size.width > 1, size.height > 1 else { return }
        if lastCamera != pileCamera {
            scenery.project(camera: pileCamera)
            let p = CGMutablePath()
            let corners = [CGPoint(x: world.bounds.minX, y: world.bounds.minY),
                           CGPoint(x: world.bounds.maxX, y: world.bounds.minY),
                           CGPoint(x: world.bounds.maxX, y: world.bounds.maxY),
                           CGPoint(x: world.bounds.minX, y: world.bounds.maxY)]
            let points = corners.map { pileCamera.screenPoint(fromWorld: $0) }
            p.move(to: points[0])
            for index in points.indices {
                let start = points[index]
                let end = points[(index + 1) % points.count]
                p.addLine(to: CGPoint(x: start.x * 0.54 + end.x * 0.46 + (index.isMultiple(of: 2) ? 0 : 1.4),
                                      y: start.y * 0.54 + end.y * 0.46 + (index.isMultiple(of: 2) ? 1.2 : 0)))
                p.addLine(to: end)
            }
            p.closeSubpath()
            boxOutline.path = p
            lastCamera = pileCamera
        }
        animatedRunners.removeAll(keepingCapacity: true)
        let viewport = CGRect(origin: .zero, size: size)
        for wheel in world.wheels {
            guard let runner = runnerByID[wheel.id] else { continue }
            let center = pileCamera.screenPoint(fromWorld: wheel.position)
            let diameter = wheel.radius * 2 * pileCamera.scale
            runner.popupOrigin = CGPoint(x: center.x + diameter * 0.31, y: center.y + diameter * 0.14)
            let frame = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
            guard viewport.intersects(frame) else { runner.node.removeFromParent(); continue }
            if runner.node.parent == nil { runners.addChild(runner.node) }
            runner.node.position = center
            runner.diameter = diameter
            runner.rollAngle = wheel.angle
            if diameter <= pixelSize {
                let dot = runner.prepareDot()
                dot.size = CGSize(width: pixelSize, height: pixelSize)
                continue
            }
            let parts = runner.prepareArt(wheel: art.wheelTexture(),
                animal: art.animalTexture(index: runner.artIndex))
            parts.wheel.size = CGSize(width: diameter, height: diameter)
            parts.wheel.zRotation = runner.rollAngle + runner.spinAngle
            parts.animal.size = CGSize(width: diameter * 0.54, height: diameter * 0.54)
            parts.animal.position = CGPoint(x: diameter * 0.04, y: -diameter * 0.15)
            parts.animal.isHidden = diameter < 9
            if runner.pose == nil || motion == .sleeping { runner.setPose(.sleeping, using: art) }
            if diameter >= 9 { animatedRunners.append(runner) }
        }
        // A queued purchase already contributes income, so keep one popup origin
        // per owned animal even while it waits at the upper-right chute.
        for arrival in pending {
            species[arrival.species].members[arrival.slot].popupOrigin = CGPoint(x: size.width - 12, y: size.height - 12)
        }
        layoutRevision &+= 1
    }

    private func popupAppearance(index: Int, amount: Yen) -> PopupAppearance {
        let texture = art.moneyTexture(index: index, amount: amount)
        let textureSize = texture.size()
        return PopupAppearance(texture: texture, width: Self.popupHeight * textureSize.width / max(1, textureSize.height))
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
                runner.spinAngle = (runner.spinAngle - turn).truncatingRemainder(dividingBy: 2 * .pi)
            }
            parts.wheel.zRotation = runner.rollAngle + runner.spinAngle
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

                let anchor = runner.popupOrigin
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
        stressTapTime += min(delta, 0.1)
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
    }

    let artIndex: Int
    let slot: Int
    let node = SKNode()
    var art: Art?
    var diameter: CGFloat = 0
    var worldID = -1
    var rollAngle: CGFloat = 0
    var spinAngle: CGFloat = 0
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

    func prepareArt(wheel: SKTexture, animal: SKTexture) -> Art {
        dot?.removeFromParent()
        let currentArt: Art
        if let art {
            currentArt = art
        } else {
            currentArt = Art(wheel: SKSpriteNode(texture: wheel),
                             animal: SKSpriteNode(texture: animal))
            currentArt.wheel.zPosition = 1
            currentArt.animal.zPosition = 2
            art = currentArt
        }
        if currentArt.wheel.parent == nil {
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
