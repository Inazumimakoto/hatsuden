import SpriteKit
import UIKit

/// The painted ground at each point is fixed in the same world as the motifs.
@MainActor
final class CanvasPaper {
    let node: SKSpriteNode
    private let cameraDepth = SKUniform(name: "u_worldDepth", float: 0)

    init(texture: SKTexture? = nil) {
        node = SKSpriteNode(texture: texture ?? Self.whiteTexel())
        node.anchorPoint = .zero
        node.shader = SKShader(source: texture == nil ? Self.paint : Self.picture, uniforms: [cameraDepth])
    }

    func project(viewport: CGSize, worldDepth: Double) {
        if node.size != viewport { node.size = viewport }
        let depth = Float(worldDepth)
        if cameraDepth.floatValue != depth { cameraDepth.floatValue = depth }
    }

    private static func whiteTexel() -> SKTexture {
        // The texel supplies full-range UVs for the shader's painted canvas.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let texel = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { renderer in
            renderer.cgContext.setFillColor(UIColor.white.cgColor)
            renderer.cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return SKTexture(image: texel)
    }

    private static let picture = """
    void main() {
        float visible = exp2(min(u_worldDepth - 99.5, 0.0));
        vec2 point = vec2(1.0 - (1.0 - v_tex_coord.x) * visible, v_tex_coord.y * visible);
        gl_FragColor = texture2D(u_texture, point) * v_color_mix.a;
    }
    """

    private static let paint = """
    float pigment(vec2 cell, float seed) {
        vec2 n = fract((cell + seed * vec2(0.37, 0.61)) * vec2(0.1031, 0.1137));
        n += dot(n, n.yx + 19.19);
        return fract((n.x + n.y) * n.x);
    }

    float hatch(vec2 point, float octave) {
        vec2 grid = vec2(point.x + 0.19 * point.y, point.y + 0.23 * point.x)
                    * vec2(43.0, 180.0);
        vec2 cell = floor(grid);
        vec2 spot = fract(grid);
        float mark = pigment(cell, octave);
        float stripe = 1.0 - smoothstep(0.05, 0.24, abs(spot.y - mark));
        float ends = smoothstep(0.0, 0.18, spot.x) * (1.0 - smoothstep(0.71, 1.0, spot.x));
        return (mark - 0.42) * stripe * ends;
    }

    float rubbing(vec2 point, float octave) {
        vec2 grid = vec2(point.x + 0.34 * point.y, point.y + 0.30 * point.x) * vec2(11.0, 44.0);
        vec2 cell = floor(grid);
        vec2 spot = fract(grid);
        float mark = pigment(cell, octave + 37.0);
        float center = 0.19 + 0.61 * mark + 0.11 * (spot.x - 0.5) * (spot.x - 0.5);
        float stroke = 1.0 - smoothstep(0.03, 0.23, abs(spot.y - center));
        float ends = smoothstep(0.0, 0.29, spot.x) * (1.0 - smoothstep(0.62, 1.0, spot.x));
        return (mark - 0.53) * stroke * ends;
    }

    float stars(vec2 point, float octave) {
        vec2 grid = point * vec2(31.0, 54.0);
        vec2 cell = floor(grid);
        float mark = pigment(cell, octave + 83.0);
        vec2 center = vec2(0.25 + 0.5 * mark, 0.22 + 0.53 * pigment(cell, octave + 19.0));
        vec2 offset = abs(fract(grid) - center);
        float fleck = 1.0 - smoothstep(0.025, 0.10, offset.x + offset.y);
        float cross = (1.0 - smoothstep(0.02, 0.047, min(offset.x, offset.y)))
                      * (1.0 - smoothstep(0.05, 0.24, max(offset.x, offset.y)));
        return max(fleck, cross * step(0.965, mark)) * step(0.82, mark);
    }

    void main() {
        // Recover world coordinates without passing a 2^99-sized transform to the GPU.
        vec2 distanceFromCorner = vec2(1.0 - v_tex_coord.x, v_tex_coord.y);
        float radius = max(length(distanceFromCorner), 0.000001);
        float worldRadius = u_worldDepth + log2(radius);
        float worldHeight = u_worldDepth + log2(max(distanceFromCorner.y, 0.000001));
        float angle = distanceFromCorner.y
                      / max(distanceFromCorner.x + distanceFromCorner.y, 0.000001);
        float ripple = sin(worldRadius * 1.35 + angle * 16.0);
        float broad = sin(worldRadius * 0.31 - angle * 7.5);
        float horizon = smoothstep(0.49, 0.73, angle + 0.070 * ripple + 0.045 * broad);
        float yardHorizon = smoothstep(-0.36, -0.15, worldHeight + 0.10 * broad);
        horizon = mix(yardHorizon, horizon, smoothstep(0.55, 4.0, worldRadius));

        vec3 grass = mix(vec3(0.78, 0.81, 0.58), vec3(0.64, 0.72, 0.49),
                         0.5 + 0.5 * sin(worldRadius * 0.68 + angle * 12.0));
        float field = sin(worldRadius * 3.1 + angle * 19.0 + 1.7 * ripple);
        grass = mix(grass, vec3(0.61, 0.69, 0.40), smoothstep(0.17, 0.73, field) * 0.29);
        vec2 yard = min(distanceFromCorner * exp2(u_worldDepth), vec2(8.0));
        float pathCenter = 0.15 + 0.50 * yard.y + 0.065 * sin(yard.y * 10.0);
        float pathEdge = abs(yard.x - pathCenter) + 0.018 * ripple;
        float path = (1.0 - smoothstep(0.075, 0.12, pathEdge)) * (1.0 - smoothstep(0.53, 0.68, yard.y));
        grass = mix(grass, vec3(0.88, 0.73, 0.51), path * 0.70);
        vec3 garden = mix(grass, vec3(0.78, 0.87, 0.89), horizon);
        float grassEdge = 1.0 - smoothstep(0.03, 0.18, abs(worldHeight + 0.10 * broad + 0.27));
        garden = mix(garden, vec3(0.56, 0.67, 0.46), grassEdge * (1.0 - smoothstep(0.55, 4.0, worldRadius)) * 0.25);
        float ridge = smoothstep(0.31, 0.62, angle + 0.10 * ripple);
        vec3 mountains = mix(vec3(0.72, 0.76, 0.57), vec3(0.70, 0.76, 0.82), ridge);
        mountains = mix(mountains, vec3(0.80, 0.88, 0.91), horizon);
        float coastCurve = angle + broad * 0.15 + 0.045 * ripple;
        float shore = smoothstep(0.38, 0.58, coastCurve);
        vec3 coast = mix(vec3(0.62, 0.77, 0.72), vec3(0.50, 0.70, 0.79), shore);
        float sand = 1.0 - smoothstep(0.012, 0.065, abs(coastCurve - 0.44));
        coast = mix(coast, vec3(0.88, 0.77, 0.53), sand * 0.38);
        float waves = smoothstep(0.82, 0.99, sin(worldRadius * 13.0 + angle * 24.0 + ripple))
                    * smoothstep(-0.20, 0.80, sin(angle * 47.0 - worldRadius * 3.0));
        coast = mix(coast, vec3(0.89, 0.94, 0.92), waves * shore * 0.32);
        float cloud = smoothstep(0.13, 0.86, ripple * 0.64 + broad * 0.36);
        vec3 atmosphere = mix(vec3(0.58, 0.72, 0.84), vec3(0.89, 0.91, 0.92), cloud);
        vec3 color = mix(garden, mountains, smoothstep(12.0, 29.0, worldRadius));
        color = mix(color, coast, smoothstep(37.0, 52.0, worldRadius));
        color = mix(color, atmosphere, smoothstep(56.0, 70.0, worldRadius));

        // The original room occupies one small corner of the painting.
        // Its boards, wallpaper and walls have the same coordinates as the furniture.
        float wallX = yard.x + 0.11 * yard.y + 0.042 * sin(yard.y * 4.0);
        float wallY = yard.y - 0.10 * yard.x + 0.034 * sin(yard.x * 5.2);
        float room = (1.0 - smoothstep(5.76, 5.93, wallX)) * (1.0 - smoothstep(6.16, 6.32, wallY));
        float alongWall = max(0.0, yard.x - 1.0);
        float baseboard = yard.y - (0.36 + 0.013 * sin(yard.x * 8.4) + 0.065 * alongWall * alongWall);
        float wall = smoothstep(-0.024, 0.025, baseboard);
        float woodLine = 1.0 - smoothstep(0.03, 0.13, abs(sin((yard.x + 0.49 * yard.y) * 16.0
                                                                + 0.09 * sin(yard.y * 16.0))));
        float wallpaperLine = 1.0 - smoothstep(0.04, 0.22, abs(sin(yard.x * 15.7 + 0.04 * sin(yard.y * 16.0))));
        vec3 floorColor = mix(vec3(0.86, 0.69, 0.46), vec3(0.64, 0.44, 0.26), woodLine * 0.54);
        vec3 wallColor = mix(vec3(0.97, 0.90, 0.67), vec3(0.94, 0.73, 0.51), wallpaperLine * 0.33);
        vec3 interior = mix(floorColor, wallColor, wall);
        float trim = 1.0 - smoothstep(0.012, 0.029, abs(baseboard));
        float outsideTrim = max(1.0 - smoothstep(0.035, 0.13, abs(wallX - 5.71)),
                                1.0 - smoothstep(0.035, 0.13, abs(wallY - 6.11)));
        interior = mix(interior, vec3(0.64, 0.44, 0.29), max(trim * 0.76, outsideTrim * 0.68));
        color = mix(color, interior, room);

        float street = abs(angle - (0.41 + 0.14 * sin(worldRadius * 0.78 + 0.4 * ripple)));
        float town = smoothstep(8.0, 12.0, worldRadius) * (1.0 - smoothstep(23.0, 28.0, worldRadius));
        float road = 1.0 - smoothstep(0.018, 0.047, street);
        float stripe = (1.0 - smoothstep(0.001, 0.007, street))
                       * smoothstep(0.12, 0.54, sin(worldRadius * 16.0));
        color = mix(color, vec3(0.54, 0.54, 0.56), road * town * 0.55);
        color = mix(color, vec3(0.97, 0.90, 0.70), stripe * town * 0.58);

        float darkSky = smoothstep(72.0, 82.0, worldRadius);
        vec3 galaxy = mix(vec3(0.24, 0.29, 0.45), vec3(0.43, 0.37, 0.56),
                          0.5 + 0.5 * broad);
        color = mix(color, galaxy, darkSky);

        // Crossfade the scale of the grain at fixed world radii, never at camera cuts.
        float octave = floor(worldRadius);
        float fine = smoothstep(0.57, 1.0, fract(worldRadius));
        vec2 pigmentPoint = distanceFromCorner * exp2(u_worldDepth - octave);
        float wax = mix(hatch(pigmentPoint, octave), hatch(pigmentPoint * 0.5, octave + 1.0), fine);
        float smudge = mix(rubbing(pigmentPoint, octave), rubbing(pigmentPoint * 0.5, octave + 1.0), fine);
        color += vec3(wax * 0.14 + smudge * 0.21 + ripple * 0.013);
        if (darkSky > 0.0) {
            float spark = mix(stars(pigmentPoint, octave), stars(pigmentPoint * 0.5, octave + 1.0), fine);
            color = mix(color, vec3(0.96, 0.90, 0.70), spark * darkSky * 0.82);
        }

        gl_FragColor = vec4(color, 1.0) * v_color_mix.a;
    }
    """
}
