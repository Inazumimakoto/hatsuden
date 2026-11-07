import CoreGraphics

enum FieldMotif: CaseIterable, Hashable {
    case hive, hamsterHouse, gardenFence, flowerPatch, railway, neighborhood
    case tokyo, fuji, liberty, rocket, moon, mars, ringedPlanet, comet, nebula, icePlanet
    case creek, windmill, foothill, sailboat, cloudBank, satellite
}

/// The strokes on one painting, in fixed world coordinates. An octave keeps
/// coordinates close to each mark's size even on a canvas this large.
struct FieldCanvas {
    private struct Placement: Equatable {
        let depth: Double
        let fromCorner: CGRect

        init(depth: Double, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
            self.depth = depth
            fromCorner = CGRect(x: 1 - x - width / 2, y: y - height / 2, width: width, height: height)
        }

        func frame(in viewport: CGSize, at worldDepth: Double) -> CGRect {
            let scale = FieldCamera.magnification(of: depth, at: worldDepth)
            return CGRect(x: viewport.width * (1 - fromCorner.maxX * scale),
                          y: viewport.height * fromCorner.minY * scale,
                          width: viewport.width * fromCorner.width * scale,
                          height: viewport.height * fromCorner.height * scale)
        }
    }

    struct Mark: Equatable {
        let motif: FieldMotif
        private let placement: Placement
        var depth: Double { placement.depth }

        init(_ motif: FieldMotif, _ depth: Double, _ x: CGFloat, _ y: CGFloat,
             _ width: CGFloat, _ height: CGFloat) {
            self.motif = motif
            placement = Placement(depth: depth, x: x, y: y, width: width, height: height)
        }

        func frame(in viewport: CGSize, at worldDepth: Double) -> CGRect {
            placement.frame(in: viewport, at: worldDepth)
        }
    }

    enum Artist {
        case room, earth, sky, extra
    }

    struct Detail: Equatable {
        let subject: CanvasSubject
        let artist: Artist
        private let placement: Placement
        var id: Int { subject.rawValue }
        var depth: Double { placement.depth }

        fileprivate init(_ artist: Artist, _ subject: CanvasSubject, _ depth: Double,
                         _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            self.artist = artist
            self.subject = subject
            placement = Placement(depth: depth, x: x, y: y, width: width, height: height)
        }

        func frame(in viewport: CGSize, at worldDepth: Double) -> CGRect {
            placement.frame(in: viewport, at: worldDepth)
        }
    }

    private typealias Composition = (subject: CanvasSubject, depth: Double,
                                     centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat)

    private static func paint(_ artist: Artist, _ composition: [Composition]) -> [Detail] {
        composition.map { subject, depth, x, y, width, height in
            Detail(artist, subject, depth, x, y, width, height)
        }
    }

    // Coordinates describe a subject's place in the picture, including pieces
    // that cross the edge of its reference view. They do not reserve a slot.
    private static let scenery = paint(.room, [
        (.roomRug, 0, 0.53, 0.16, 0.76, 0.28),
        (.roomWindow, 0, 0.80, 0.80, 0.47, 0.34),
        (.pictureFrame, 0, 0.08, 0.70, 0.34, 0.22),
        (.slippers, 0, 0.90, 0.14, 0.29, 0.19),
        (.computer, 0.55, 0.24, 0.62, 0.73, 0.40),
        (.pencilCup, 0.62, 0.67, 0.65, 0.24, 0.20),
        (.deskLamp, 0.86, 0.31, 0.92, 0.43, 0.37),
        (.bookshelf, 1.15, 0.09, 0.54, 0.63, 0.51),
        (.wallClock, 1.32, 0.80, 0.99, 0.35, 0.29),
        (.toyTrain, 1.50, 0.37, 0.29, 0.53, 0.25),
        (.armchair, 1.68, 0.23, 0.63, 0.57, 0.43),
        (.radio, 1.91, 0.63, 0.87, 0.40, 0.27),
        (.teacup, 2.04, 0.44, 0.53, 0.26, 0.21),
        (.catBed, 2.21, 0.17, 0.28, 0.46, 0.30),
        (.kettle, 2.43, 0.57, 0.79, 0.42, 0.29),
        (.sewingMachine, 2.58, 0.06, 0.61, 0.64, 0.38),
        (.pottedCactus, 2.72, 0.82, 0.96, 0.34, 0.31),
        (.globe, 2.98, 0.25, 0.72, 0.41, 0.35),
        (.umbrellaStand, 3.23, 0.49, 0.42, 0.41, 0.38),
        (.doorway, 3.40, 0.43, 0.52, 0.69, 0.62)
    ]) + paint(.earth, [
        (.wheelbarrow, 4.4, 0.37, 0.58, 0.57, 0.30),
        (.roseArch, 5.0, 0.67, 0.94, 0.53, 0.38),
        (.vegetableRows, 5.8, 0.12, 0.38, 0.72, 0.49),
        (.fishPond, 6.6, 0.54, 0.57, 0.86, 0.43),
        (.gardenShed, 7.3, 0.13, 0.72, 0.60, 0.44),
        (.gardenWell, 8.4, 0.79, 0.84, 0.44, 0.36),
        (.cherryTree, 9.2, 0.39, 0.51, 0.69, 0.57),
        (.orchardTractor, 9.9, 0.25, 0.35, 0.61, 0.34),
        (.greenhouse, 10.7, 0.70, 0.71, 0.74, 0.43),
        (.bicycle, 11.8, 0.27, 0.37, 0.47, 0.28),
        (.bakery, 13.0, 0.70, 0.91, 0.60, 0.43),
        (.iceCreamTruck, 13.7, 0.50, 0.43, 0.66, 0.33),
        (.school, 14.3, 0.06, 0.53, 0.95, 0.52),
        (.postOffice, 15.5, 0.57, 0.66, 0.63, 0.42),
        (.cityBus, 17.0, 0.36, 0.35, 0.73, 0.29),
        (.tramStop, 18.2, 0.82, 0.66, 0.52, 0.34),
        (.waterTower, 18.9, 0.43, 0.96, 0.49, 0.44),
        (.fireStation, 19.5, 0.27, 0.68, 0.77, 0.50),
        (.hospital, 21.0, 0.72, 0.87, 0.74, 0.49),
        (.deliveryVan, 22.2, 0.20, 0.35, 0.52, 0.28),
        (.movieTheater, 22.8, 0.46, 0.70, 0.88, 0.56),
        (.constructionCrane, 23.5, 0.47, 0.80, 0.88, 0.55),
        (.library, 25.0, 0.54, 0.53, 0.76, 0.46),
        (.railStation, 26.8, 0.13, 0.66, 0.94, 0.45),
        (.pagoda, 27.6, 0.81, 0.93, 0.57, 0.59),
        (.torii, 28.3, 0.73, 0.72, 0.52, 0.38),
        (.waterfall, 30.2, 0.30, 0.57, 0.73, 0.62),
        (.stoneViaduct, 31.1, 0.18, 0.57, 1.12, 0.50),
        (.campsite, 32.0, 0.56, 0.83, 0.79, 0.40),
        (.castle, 33.1, 0.35, 0.90, 0.70, 0.54),
        (.cableCar, 34.8, 0.76, 0.77, 0.91, 0.40),
        (.alpineHut, 35.5, 0.77, 0.88, 0.61, 0.36),
        (.volcano, 37.4, 0.29, 0.70, 1.12, 0.76),
        (.skiLift, 39.4, 0.73, 0.52, 0.84, 0.42),
        (.hotSpring, 39.9, 0.09, 0.36, 0.88, 0.45),
        (.hydroDam, 41.4, 0.29, 0.56, 0.86, 0.47),
        (.craterLake, 42.6, 0.55, 0.79, 1.00, 0.47),
        (.observatory, 43.2, 0.61, 0.87, 0.62, 0.41),
        (.fishingPier, 45.5, 0.19, 0.48, 0.76, 0.39),
        (.lighthouse, 48.0, 0.80, 0.68, 0.50, 0.50),
        (.islandVillage, 48.9, 0.39, 0.85, 0.96, 0.50),
        (.suspensionBridge, 50.7, 0.38, 0.59, 1.17, 0.49),
        (.cargoShip, 53.2, 0.62, 0.38, 0.87, 0.39),
        (.coastGuardCutter, 53.9, 0.67, 0.79, 0.76, 0.48),
        (.ferrisWheel, 57.1, 0.31, 0.80, 0.70, 0.59),
        (.oilPlatform, 58.6, 0.14, 0.54, 0.86, 0.59),
        (.seaplane, 60.2, 0.76, 0.53, 0.68, 0.35),
        (.drawbridge, 61.1, 0.51, 0.79, 1.10, 0.42)
    ]) + paint(.sky, [
        (.sunriseFlock, 61.7, 0.29, 0.88, 0.78, 0.38),
        (.diamondKite, 63.3, 0.67, 0.57, 0.57, 0.46),
        (.hotAirBalloon, 64.9, 0.15, 0.72, 0.74, 0.53),
        (.rainbowArch, 66.1, 0.58, 0.87, 1.02, 0.47),
        (.paperGlider, 67.4, 0.76, 0.42, 0.58, 0.32),
        (.rescueHelicopter, 69.2, 0.27, 0.66, 0.78, 0.44),
        (.thunderhead, 70.65, 0.65, 0.72, 1.06, 0.58),
        (.propellerPlane, 72.7, 0.30, 0.47, 0.80, 0.40),
        (.hangGlider, 74.8, 0.56, 0.54, 0.69, 0.43),
        (.blimp, 76.3, 0.70, 0.91, 0.89, 0.37),
        (.earthFromOrbit, 78.4, 0.22, 0.47, 0.96, 0.70),
        (.weatherSatellite, 80.1, 0.75, 0.72, 0.66, 0.39),
        (.constellationMap, 82.1, 0.33, 0.86, 0.77, 0.47),
        (.spaceStation, 84.0, 0.19, 0.49, 0.84, 0.44),
        (.astronaut, 86.1, 0.70, 0.58, 0.56, 0.48),
        (.lunarRover, 87.6, 0.24, 0.38, 0.64, 0.36),
        (.radioTelescope, 90.7, 0.65, 0.82, 0.79, 0.49),
        (.meteorBelt, 93.1, 0.14, 0.59, 1.13, 0.67),
        (.flyingSaucer, 95.0, 0.67, 0.64, 0.69, 0.36),
        (.deepSpaceProbe, 99.0, 0.89, 0.43, 0.60, 0.36)
    ]) + paint(.extra, [
        (.steppingStones, 12.5, 0.45, 0.76, 0.99, 0.31),
        (.teaGarden, 24.1, 0.19, 0.42, 0.72, 0.43),
        (.cliffTrail, 46.6, 0.21, 0.68, 0.78, 0.48),
        (.weatherVane, 63.6, 0.22, 0.76, 0.53, 0.45),
        (.sunDog, 68.0, 0.66, 0.81, 0.82, 0.48),
        (.aurora, 75.5, 0.49, 0.81, 1.12, 0.45),
        (.spiralGalaxy, 80.6, 0.38, 0.68, 0.86, 0.56),
        (.ringDebris, 89.7, 0.70, 0.91, 0.99, 0.49)
    ])

    let details = scenery

    let marks = [
            Mark(.nebula, 97.8, 0.43, 0.49, 0.81, 0.33),
            Mark(.hamsterHouse, 0, 0.58, 0.46, 0.72, 0.42),
            Mark(.gardenFence, 4.0, 0.54, 0.67, 1.10, 0.15),
            Mark(.flowerPatch, 4.3, 0.58, 0.35, 0.93, 0.42),
            Mark(.hive, 4.6, 0.69, 0.50, 0.36, 0.20),
            Mark(.creek, 6.0, 0.29, 0.36, 1.05, 0.42),
            Mark(.neighborhood, 8, 0.53, 0.55, 0.84, 0.15),
            Mark(.railway, 12, 0.50, 0.49, 0.94, 0.17),
            Mark(.windmill, 16, 0.57, 0.49, 0.88, 0.34),
            Mark(.tokyo, 20, 0.51, 0.49, 0.92, 0.63),
            Mark(.foothill, 27, 0.48, 0.50, 0.91, 0.35),
            Mark(.fuji, 34, 0.51, 0.52, 0.87, 0.38),
            Mark(.sailboat, 45, 0.53, 0.46, 0.84, 0.32),
            Mark(.liberty, 56, 0.48, 0.49, 0.76, 0.48),
            Mark(.cloudBank, 65, 0.53, 0.55, 0.90, 0.34),
            Mark(.rocket, 73, 0.46, 0.60, 0.53, 0.30),
            Mark(.moon, 82, 0.51, 0.56, 0.46, 0.25),
            Mark(.mars, 89, 0.50, 0.54, 0.74, 0.38),
            Mark(.satellite, 93, 0.53, 0.52, 0.83, 0.32),
            Mark(.comet, 96, 0.42, 0.47, 0.72, 0.31),
            Mark(.icePlanet, 98.1, 0.75, 0.34, 0.34, 0.19),
            Mark(.ringedPlanet, 99.5, 0.50, 0.65, 0.77, 0.27)
    ]
}
