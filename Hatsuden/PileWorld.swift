import CoreGraphics
import Foundation

/// One owned animal and its wheel. Positions use SpriteKit's upward-positive axes.
/// The animal animation is independent of this body's resting state.
struct PileWheel: Identifiable {
    let id: Int
    let species: Int
    let slot: Int
    let radius: CGFloat
    var position: CGPoint
    var velocity: CGVector
    var angle: CGFloat
    var angularVelocity: CGFloat
    var isSleeping: Bool
    fileprivate var quietTime: TimeInterval = 0
    fileprivate var motionHeight: CGFloat = 0
    fileprivate var lastStepPosition: CGPoint = .zero
}

/// Saves the arrangement and motion, rather than recalculating the pile at every
/// launch. A wheel saved in midair resumes its fall instead of hovering forever.
struct PileWorldSnapshot: Codable {
    struct Wheel: Codable {
        let id: Int
        let species: Int
        let slot: Int
        let radius: Double
        let x: Double
        let y: Double
        let angle: Double
        let vx: Double?
        let vy: Double?
        let angularVelocity: Double?
        let isSleeping: Bool?
        let motionHeight: Double?
    }

    let version: Int
    let bounds: CGRect
    let wheels: [Wheel]
    let nextID: Int
    let randomState: UInt64
}

/// Circular pile simulation with an adaptive quadtree. Small wheels share only
/// nearby leaf buckets while giant wheels stay higher in the tree. Subpixel contacts are
/// approximate, while every owned wheel retains a separate position and ID.
struct PileWorld {
    private(set) var bounds: CGRect
    private(set) var wheels: [PileWheel] = []
    private(set) var movingCount = 0
    private(set) var totalArea: CGFloat = 0
    private(set) var largestRadius: CGFloat = 0
    private var nextID = 0
    private var randomState: UInt64 = 0xA076_1D64_78BD_642F
    private var shakeNumber = 0

    var isMoving: Bool { movingCount > 0 }

    init(bounds: CGRect) {
        self.bounds = Self.valid(bounds) ? bounds : CGRect(x: -240, y: 0, width: 240, height: 400)
    }

    /// Enlarging the box leaves existing positions untouched. In normal play
    /// maxX and minY stay fixed and only the upper and left walls move outward.
    mutating func expand(to proposed: CGRect) {
        guard Self.valid(proposed) else { return }
        bounds = bounds.union(proposed)
    }

    /// A purchase always enters in motion. A camera-aware caller can supply its
    /// visible upper-right position without changing the world's scale.
    @discardableResult
    mutating func add(species: Int, slot: Int, radius: CGFloat, at origin: CGPoint? = nil,
                      launchSize: CGSize? = nil) -> Int {
        guard radius.isFinite, radius > 0, species >= 0, slot >= 0, nextID < Int.max else { return -1 }
        ensureFits(radius: radius)
        let margin = min(bounds.width * 0.025, radius * 0.25)
        let start = origin ?? CGPoint(
            x: bounds.maxX - radius - margin - random() * bounds.width * 0.035,
            y: bounds.maxY - radius - margin
        )
        let position = contained(start, radius: radius)
        let requested = launchSize ?? bounds.size
        let launchWidth = requested.width.isFinite && requested.width > 0
            ? min(bounds.width, max(radius * 2.2, requested.width)) : bounds.width
        let launchHeight = requested.height.isFinite && requested.height > 0
            ? min(bounds.height, max(radius * 2.2, requested.height)) : bounds.height
        let velocity = CGVector(dx: -launchWidth * (0.18 + random() * 0.16),
                                dy: -launchHeight * 0.025)
        let body = PileWheel(id: nextID, species: species, slot: slot, radius: radius,
                             position: position, velocity: velocity, angle: random() * .pi * 2,
                             angularVelocity: min(12, abs(velocity.dx) / radius), isSleeping: false,
                             motionHeight: launchHeight)
        nextID += 1
        wheels.append(body)
        movingCount += 1
        totalArea += .pi * radius * radius
        largestRadius = max(largestRadius, radius)
        return body.id
    }

    /// Fast first-run/legacy-save packing. Hydrate larger wheels first. Each
    /// candidate rests on the circular surface beneath it, without hundreds of
    /// hidden physics frames. This one-time packing pass is deliberately separate
    /// from the spatially indexed per-frame simulation.
    @discardableResult
    mutating func addSettled(species: Int, slot: Int, radius: CGFloat) -> Int {
        guard radius.isFinite, radius > 0, species >= 0, slot >= 0, nextID < Int.max else { return -1 }
        ensureFits(radius: radius)
        let span = max(0, bounds.width - radius * 2)
        var best = CGPoint(x: bounds.minX + radius + span * random(), y: .greatestFiniteMagnitude)
        for candidate in 0..<7 {
            let fraction = candidate == 0 ? random() : (CGFloat(candidate) - 0.5 + random() * 0.8) / 6
            let x = bounds.minX + radius + span * min(1, max(0, fraction))
            var y = bounds.minY + radius
            for other in wheels {
                let reach = radius + other.radius
                let dx = x - other.position.x
                guard abs(dx) < reach else { continue }
                y = max(y, other.position.y + sqrt(max(0, reach * reach - dx * dx)))
            }
            if y < best.y { best = CGPoint(x: x, y: y) }
        }
        if best.y + radius > bounds.maxY {
            expand(to: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width,
                              height: best.y + radius * 1.1 - bounds.minY))
        }
        let id = add(species: species, slot: slot, radius: radius, at: best)
        guard id >= 0 else { return id }
        wheels[wheels.count - 1].position = best
        wheels[wheels.count - 1].velocity = .zero
        wheels[wheels.count - 1].angularVelocity = 0
        wheels[wheels.count - 1].isSleeping = true
        wheels[wheels.count - 1].quietTime = 0.5
        movingCount -= 1
        return id
    }

    /// Every press wakes all wheel bodies. Alternating lateral motion plus
    /// separate upward impulses prevents repeated presses from merely moving
    /// the pile as one rigid lump. This action does not call the economy model.
    mutating func shake(strength: CGFloat = 1) {
        guard strength.isFinite, strength > 0, !wheels.isEmpty else { return }
        let force = min(2.2, strength)
        shakeNumber &+= 1
        let direction: CGFloat = shakeNumber.isMultiple(of: 2) ? -1 : 1
        for index in wheels.indices {
            let horizontal = direction * 0.16 + (random() - 0.5) * 0.70
            let upward = 0.36 + random() * 0.47
            wheels[index].velocity = CGVector(
                dx: wheels[index].velocity.dx * 0.25 + bounds.width * horizontal * force,
                dy: max(0, wheels[index].velocity.dy) * 0.20 + bounds.height * upward * force
            )
            wheels[index].angularVelocity = (random() - 0.5) * 18 * force
            wheels[index].isSleeping = false
            wheels[index].quietTime = 0
            wheels[index].motionHeight = bounds.height
        }
        movingCount = wheels.count
    }

    /// Below the caller's visible radius threshold, bodies still move and hit
    /// the box and large wheels, but do not collide with other subpixel bodies.
    /// This preserves every animal while bounding physics work at deep pullback.
    mutating func advance(delta: TimeInterval, minimumCollisionRadius: CGFloat = 0) {
        guard isMoving, delta.isFinite, delta > 0 else { return }
        let minimumRadius = minimumCollisionRadius.isFinite ? max(0, minimumCollisionRadius) : 0
        // Limit catch-up after a busy rendering frame. Simulating six old steps
        // would delay the next frame again and create a self-sustaining slowdown.
        let elapsed = min(delta, 1.0 / 30)
        let steps = max(1, min(2, Int(ceil(elapsed * 60))))
        let step = CGFloat(elapsed / Double(steps))
        for _ in 0..<steps { integrate(step: step, minimumCollisionRadius: minimumRadius) }
    }

    var snapshot: PileWorldSnapshot {
        PileWorldSnapshot(version: 1, bounds: bounds, wheels: wheels.map {
            PileWorldSnapshot.Wheel(id: $0.id, species: $0.species, slot: $0.slot,
                                   radius: Double($0.radius), x: Double($0.position.x),
                                   y: Double($0.position.y), angle: Double($0.angle),
                                   vx: Double($0.velocity.dx), vy: Double($0.velocity.dy),
                                   angularVelocity: Double($0.angularVelocity),
                                   isSleeping: $0.isSleeping, motionHeight: Double($0.motionHeight))
        }, nextID: nextID, randomState: randomState)
    }

    @discardableResult
    mutating func restore(_ snapshot: PileWorldSnapshot) -> Bool {
        guard snapshot.version == 1, Self.valid(snapshot.bounds), snapshot.nextID >= 0,
              snapshot.wheels.allSatisfy({
                  $0.id >= 0 && $0.id < Int.max && $0.species >= 0 && $0.slot >= 0
                  && $0.radius.isFinite && $0.radius > 0 && $0.x.isFinite
                  && $0.y.isFinite && $0.angle.isFinite
                  && ($0.vx?.isFinite ?? true) && ($0.vy?.isFinite ?? true)
                  && ($0.angularVelocity?.isFinite ?? true)
                  && ($0.motionHeight?.isFinite ?? true) && ($0.motionHeight ?? 0) >= 0
                  && $0.radius * 2 <= Double(min(snapshot.bounds.width, snapshot.bounds.height)) * 1.001
              }) else { return false }
        var ids = Set<Int>()
        var members = Set<Member>()
        for wheel in snapshot.wheels {
            guard ids.insert(wheel.id).inserted,
                  members.insert(Member(species: wheel.species, slot: wheel.slot)).inserted else { return false }
        }
        bounds = snapshot.bounds
        randomState = snapshot.randomState
        nextID = max(snapshot.nextID, (snapshot.wheels.map(\.id).max() ?? -1) + 1)
        wheels = snapshot.wheels.map {
            let radius = CGFloat($0.radius)
            let sleeping = $0.isSleeping ?? true
            let savedHeight = CGFloat($0.motionHeight ?? 0)
            let motionHeight = savedHeight > 0 ? savedHeight : bounds.height
            return PileWheel(id: $0.id, species: $0.species, slot: $0.slot, radius: radius,
                             position: contained(CGPoint(x: $0.x, y: $0.y), radius: radius),
                             velocity: sleeping ? .zero : CGVector(dx: $0.vx ?? 0, dy: $0.vy ?? 0),
                             angle: CGFloat($0.angle),
                             angularVelocity: sleeping ? 0 : CGFloat($0.angularVelocity ?? 0),
                             isSleeping: sleeping, quietTime: sleeping ? 0.5 : 0,
                             motionHeight: motionHeight)
        }
        movingCount = wheels.filter { !$0.isSleeping }.count
        totalArea = wheels.reduce(0) { $0 + .pi * $1.radius * $1.radius }
        largestRadius = wheels.map(\.radius).max() ?? 0
        return true
    }

    private mutating func integrate(step: CGFloat, minimumCollisionRadius: CGFloat) {
        var supported = Array(repeating: false, count: wheels.count)
        let airDamping = exp(-0.14 * step)
        for index in wheels.indices where !wheels[index].isSleeping {
            var wheel = wheels[index]
            wheel.lastStepPosition = wheel.position
            let extent = wheel.motionHeight > 0 ? wheel.motionHeight : bounds.height
            let speedLimit = extent * 2.5
            wheel.velocity.dy -= extent * 1.6 * step
            wheel.velocity.dx *= airDamping
            wheel.velocity.dy = max(-speedLimit, min(speedLimit, wheel.velocity.dy))
            wheel.velocity.dx = max(-speedLimit, min(speedLimit, wheel.velocity.dx))
            wheel.position.x += wheel.velocity.dx * step
            wheel.position.y += wheel.velocity.dy * step
            wheel.angle = (wheel.angle + wheel.angularVelocity * step)
                .truncatingRemainder(dividingBy: .pi * 2)
            constrain(&wheel, supported: &supported[index])
            wheels[index] = wheel
        }

        // Two projection passes keep resting stacks stable while bounding the
        // work done after a large shake. Each pass rebuilds the tree because the
        // previous projection may have moved a body into another bucket.
        for pass in 0..<2 {
            let tree = SpatialTree(wheels, bounds: bounds, minimumRadius: minimumCollisionRadius)
            for index in wheels.indices {
                let tiny = wheels[index].radius < minimumCollisionRadius
                if tiny, pass > 0 { continue }
                for other in tree.candidates(for: index, wheels: wheels, outsideTree: tiny) {
                    guard !wheels[index].isSleeping || !wheels[other].isSleeping else { continue }
                    resolve(index, other, supported: &supported)
                }
            }
        }

        movingCount = 0
        let friction = exp(-4.5 * step)
        let angularFriction = exp(-4 * step)
        for index in wheels.indices where !wheels[index].isSleeping {
            var wheel = wheels[index]
            constrain(&wheel, supported: &supported[index])
            if supported[index] {
                wheel.velocity.dx *= friction
                wheel.angularVelocity *= angularFriction
            }
            let tiny = wheel.radius < minimumCollisionRadius
            // Positional correction may cancel a tiny body's gravity velocity
            // every frame. Sleep it based on the movement the player can see,
            // rather than that unobservable residual solver velocity.
            let speed = tiny
                ? hypot(wheel.position.x - wheel.lastStepPosition.x,
                        wheel.position.y - wheel.lastStepPosition.y) / step
                : hypot(wheel.velocity.dx, wheel.velocity.dy)
            let quietSpeed = max(wheel.radius * 0.45,
                                 minimumCollisionRadius > 0 ? minimumCollisionRadius * 6 : bounds.height * 0.0018)
            if supported[index], speed < quietSpeed, tiny || abs(wheel.angularVelocity) < 0.35 {
                wheel.quietTime += TimeInterval(step)
            } else {
                wheel.quietTime = 0
            }
            if wheel.quietTime >= 0.48 {
                wheel.isSleeping = true
                wheel.velocity = .zero
                wheel.angularVelocity = 0
                wheel.motionHeight = bounds.height
            } else {
                movingCount += 1
            }
            wheels[index] = wheel
        }
    }

    private func constrain(_ wheel: inout PileWheel, supported: inout Bool) {
        let left = bounds.minX + wheel.radius
        let right = bounds.maxX - wheel.radius
        let floor = bounds.minY + wheel.radius
        let ceiling = bounds.maxY - wheel.radius
        if wheel.position.x < left {
            wheel.position.x = left
            if wheel.velocity.dx < 0 { wheel.velocity.dx *= -0.28 }
        } else if wheel.position.x > right {
            wheel.position.x = right
            if wheel.velocity.dx > 0 { wheel.velocity.dx *= -0.28 }
        }
        if wheel.position.y <= floor {
            wheel.position.y = floor
            if wheel.velocity.dy < 0 { wheel.velocity.dy *= -0.18 }
            if abs(wheel.velocity.dy) < bounds.height * 0.004 { wheel.velocity.dy = 0 }
            supported = true
            let rolling = -wheel.velocity.dx / max(wheel.radius, bounds.height * 0.00001)
            wheel.angularVelocity = wheel.angularVelocity * 0.8 + min(12, max(-12, rolling)) * 0.2
        } else if wheel.position.y > ceiling {
            wheel.position.y = ceiling
            if wheel.velocity.dy > 0 { wheel.velocity.dy *= -0.22 }
        }
    }

    private mutating func resolve(_ first: Int, _ second: Int, supported: inout [Bool]) {
        var a = wheels[first]
        var b = wheels[second]
        let dx = b.position.x - a.position.x
        let dy = b.position.y - a.position.y
        let radii = a.radius + b.radius
        let slop = max(bounds.height * 0.000000001, min(a.radius, b.radius) * 0.001)
        let squared = dx * dx + dy * dy
        guard squared <= (radii + slop) * (radii + slop) else { return }
        let distance = sqrt(squared)
        let nx: CGFloat
        let ny: CGFloat
        if distance > slop * 0.1 {
            nx = dx / distance
            ny = dy / distance
        } else {
            let phase = CGFloat((a.id &* 73 &+ b.id &* 151) % 997) / 997 * .pi * 2
            nx = cos(phase)
            ny = sin(phase)
        }
        let approach = (b.velocity.dx - a.velocity.dx) * nx + (b.velocity.dy - a.velocity.dy) * ny
        let ratio = min(a.radius, b.radius) / max(a.radius, b.radius)
        let impactExtent = min(a.motionHeight > 0 ? a.motionHeight : bounds.height,
                               b.motionHeight > 0 ? b.motionHeight : bounds.height)
        if ratio > 0.08, approach < -impactExtent * 0.012 {
            if a.isSleeping { a.isSleeping = false; a.quietTime = 0; a.motionHeight = impactExtent }
            if b.isSleeping { b.isSleeping = false; b.quietTime = 0; b.motionHeight = impactExtent }
        }
        let invA: CGFloat = a.isSleeping ? 0 : 1 / (a.radius * a.radius)
        let invB: CGFloat = b.isSleeping ? 0 : 1 / (b.radius * b.radius)
        let total = invA + invB
        guard total > 0 else { return }
        let penetration = max(0, radii - distance - slop)
        if penetration > 0 {
            let adjustment = penetration / total * 0.98
            a.position.x -= nx * adjustment * invA
            a.position.y -= ny * adjustment * invA
            b.position.x += nx * adjustment * invB
            b.position.y += ny * adjustment * invB
        }
        if approach < 0 {
            let impulse = -(1.12 * approach) / total
            a.velocity.dx -= nx * impulse * invA
            a.velocity.dy -= ny * impulse * invA
            b.velocity.dx += nx * impulse * invB
            b.velocity.dy += ny * impulse * invB
            let tangent = (b.velocity.dx - a.velocity.dx) * -ny + (b.velocity.dy - a.velocity.dy) * nx
            let drag = tangent * 0.055 / total
            a.velocity.dx += -ny * drag * invA
            a.velocity.dy += nx * drag * invA
            b.velocity.dx -= -ny * drag * invB
            b.velocity.dy -= nx * drag * invB
        }
        if ny < -0.22 { supported[first] = true }
        if ny > 0.22 { supported[second] = true }
        wheels[first] = a
        wheels[second] = b
    }

    private mutating func ensureFits(radius: CGFloat) {
        let width = max(bounds.width, radius * 2.2)
        let height = max(bounds.height, radius * 2.2)
        bounds = CGRect(x: bounds.maxX - width, y: bounds.minY, width: width, height: height)
    }

    private func contained(_ point: CGPoint, radius: CGFloat) -> CGPoint {
        let x = point.x.isFinite ? point.x : bounds.maxX - radius
        let y = point.y.isFinite ? point.y : bounds.maxY - radius
        return CGPoint(x: min(bounds.maxX - radius, max(bounds.minX + radius, x)),
                       y: min(bounds.maxY - radius, max(bounds.minY + radius, y)))
    }

    private mutating func random() -> CGFloat {
        randomState = randomState &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(randomState >> 11) / 9_007_199_254_740_992
    }

    private static func valid(_ rect: CGRect) -> Bool {
        rect.minX.isFinite && rect.minY.isFinite && rect.width.isFinite && rect.height.isFinite
            && rect.width > 0 && rect.height > 0 && rect.maxX.isFinite && rect.maxY.isFinite
    }

    private struct Member: Hashable {
        let species: Int
        let slot: Int
    }

    private struct SpatialTree {
        private struct Node {
            let bounds: CGRect
            let members: [Int]
            let children: [Int]
            let awakeCount: Int
        }
        private let nodes: [Node]

        init(_ wheels: [PileWheel], bounds: CGRect, minimumRadius: CGFloat) {
            var nodes: [Node] = []
            nodes.reserveCapacity(max(1, wheels.count / 3))
            @discardableResult
            func build(_ indices: [Int], bounds: CGRect, depth: Int) -> Int {
                let nodeIndex = nodes.count
                let awake = indices.reduce(0) { $0 + (wheels[$1].isSleeping ? 0 : 1) }
                nodes.append(Node(bounds: bounds, members: [], children: [], awakeCount: awake))
                guard indices.count > 8, depth < 28, min(bounds.width, bounds.height) > 0.000000001 else {
                    nodes[nodeIndex] = Node(bounds: bounds, members: indices, children: [], awakeCount: awake)
                    return nodeIndex
                }
                var local: [Int] = []
                var buckets = Array(repeating: [Int](), count: 4)
                for index in indices {
                    let wheel = wheels[index]
                    let column = wheel.position.x + wheel.radius <= bounds.midX ? 0
                        : (wheel.position.x - wheel.radius >= bounds.midX ? 1 : -1)
                    let row = wheel.position.y + wheel.radius <= bounds.midY ? 0
                        : (wheel.position.y - wheel.radius >= bounds.midY ? 1 : -1)
                    if column >= 0, row >= 0 {
                        buckets[row * 2 + column].append(index)
                    } else {
                        local.append(index)
                    }
                }
                var children: [Int] = []
                for quadrant in 0..<4 where !buckets[quadrant].isEmpty {
                    let childBounds = CGRect(
                        x: quadrant % 2 == 0 ? bounds.minX : bounds.midX,
                        y: quadrant / 2 == 0 ? bounds.minY : bounds.midY,
                        width: bounds.width / 2, height: bounds.height / 2
                    )
                    children.append(build(buckets[quadrant], bounds: childBounds, depth: depth + 1))
                }
                nodes[nodeIndex] = Node(bounds: bounds, members: local, children: children, awakeCount: awake)
                return nodeIndex
            }
            build(wheels.indices.filter { wheels[$0].radius >= minimumRadius }, bounds: bounds, depth: 0)
            self.nodes = nodes
        }

        func candidates(for index: Int, wheels: [PileWheel], outsideTree: Bool) -> [Int] {
            let wheel = wheels[index]
            let region = CGRect(x: wheel.position.x - wheel.radius, y: wheel.position.y - wheel.radius,
                                width: wheel.radius * 2, height: wheel.radius * 2)
            let onlyAwake = wheel.isSleeping
            var result: [Int] = []
            func visit(_ nodeIndex: Int) {
                let node = nodes[nodeIndex]
                guard (!onlyAwake || node.awakeCount > 0), node.bounds.intersects(region) else { return }
                for other in node.members where (outsideTree || other > index) && (!onlyAwake || !wheels[other].isSleeping) {
                    result.append(other)
                }
                for child in node.children { visit(child) }
            }
            if !nodes.isEmpty { visit(0) }
            return result
        }
    }
}
