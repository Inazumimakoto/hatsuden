import CoreGraphics
import Foundation

struct FieldTouchInput<TouchID: Hashable> {
    struct Pinch {
        let factor: CGFloat
        let began: Bool
    }

    private struct Contact {
        let origin: CGPoint
        let beganAt: TimeInterval
        var location: CGPoint
        var canTap = true
    }

    private struct Pair {
        let first: TouchID
        let second: TouchID
        let initialDistance: CGFloat
        var isPinching = false
    }

    private var contacts: [TouchID: Contact] = [:]
    private var pair: Pair?

    private static var tapTravelLimit: CGFloat { 14 }
    private static var tapDurationLimit: TimeInterval { 0.35 }
    private static var pinchTravelThreshold: CGFloat { 12 }

    mutating func began(_ locations: [TouchID: CGPoint], at time: TimeInterval) {
        for (id, location) in locations where contacts[id] == nil {
            contacts[id] = Contact(origin: location, beganAt: time, location: location)
        }
        updatePair()
    }

    mutating func moved(_ locations: [TouchID: CGPoint]) -> Pinch? {
        for (id, location) in locations {
            guard var contact = contacts[id] else { continue }
            contact.location = location
            contact.canTap = contact.canTap && Self.distance(contact.origin, location) <= Self.tapTravelLimit
            contacts[id] = contact
        }

        guard contacts.count == 2, var pair,
              let first = contacts[pair.first], let second = contacts[pair.second] else { return nil }
        let distance = Self.distance(first.location, second.location)
        let began = !pair.isPinching
        if began {
            guard abs(distance - pair.initialDistance) >= Self.pinchTravelThreshold else { return nil }
            pair.isPinching = true
            self.pair = pair
            contacts[pair.first]?.canTap = false
            contacts[pair.second]?.canTap = false
        }
        return Pinch(factor: max(1, distance) / pair.initialDistance, began: began)
    }

    mutating func ended(_ locations: [TouchID: CGPoint], at time: TimeInterval) -> Int {
        var taps = 0
        for (id, location) in locations {
            guard let contact = contacts.removeValue(forKey: id), contact.canTap,
                  (0...Self.tapDurationLimit).contains(time - contact.beganAt),
                  Self.distance(contact.origin, location) <= Self.tapTravelLimit else { continue }
            taps += 1
        }
        updatePair()
        return taps
    }

    mutating func cancelled(_ ids: Set<TouchID>) {
        for id in ids {
            contacts.removeValue(forKey: id)
        }
        updatePair()
    }

    mutating func reset() {
        contacts.removeAll(keepingCapacity: true)
        pair = nil
    }

    private mutating func updatePair() {
        // Keep an active pinch's original fingers while an extra touch is present.
        if let pair, contacts[pair.first] != nil, contacts[pair.second] != nil,
           pair.isPinching || contacts.count == 2 {
            return
        }
        pair = nil
        guard contacts.count == 2 else { return }
        var iterator = contacts.makeIterator()
        guard let first = iterator.next(), let second = iterator.next() else { return }
        let distance = Self.distance(first.value.location, second.value.location)
        guard distance >= Self.pinchTravelThreshold else { return }
        pair = Pair(first: first.key, second: second.key, initialDistance: distance)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }
}
