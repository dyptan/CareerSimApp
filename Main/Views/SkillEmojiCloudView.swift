import SwiftUI

struct SkillEmojiCloudView: View {
    @ObservedObject var player: Player

    // Emoji size bounds
    var minFontSize: CGFloat = 16
    var maxFontSize: CGFloat = 64

    // Minimal padding added around each emoji (in points)
    var itemPadding: CGFloat = 2

    // Base ring spacing multiplier (extra space between rings)
    var ringSpacingFactor: CGFloat = 0.25

    // Animation
    var animation: Animation = .spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.2)

    struct SkillItem: Identifiable, Hashable {
        let id = UUID()
        let label: String
        let emoji: String
        let level: Int
        let baseFont: CGFloat
        let itemPadding: CGFloat

        var radius: CGFloat { baseFont / 2 } // approximate visual radius of the emoji glyph
        var paddedRadius: CGFloat { radius + itemPadding }
    }

    private var items: [SkillItem] {
        // Gather levels and map to proportional font sizes
        let pairs = SoftSkills.skillNames.map { (kp, label, emoji) in
            (label, emoji, player.softSkills[keyPath: kp])
        }

        // Avoid division by zero
        let total = max(pairs.map { max($0.2, 0) }.reduce(0, +), 1)

        return pairs.map { (label, emoji, level) in
            let clamped = max(level, 0)
            let weight = CGFloat(clamped) / CGFloat(total)
            // Non-linear mapping so small values stay visible; tweak exponent if desired
            let adjusted = pow(weight, 0.6)
            let font = minFontSize + adjusted * (maxFontSize - minFontSize)
            return SkillItem(label: label, emoji: emoji, level: clamped, baseFont: font, itemPadding: itemPadding)
        }
        .sorted { $0.baseFont > $1.baseFont }
    }

    var body: some View {
        GeometryReader { geo in
            let container = geo.size
            let positions = CircularPack.positions(
                for: items,
                in: container,
                ringSpacingFactor: ringSpacingFactor
            )

            ZStack {
                ForEach(Array(zip(items.indices, items)), id: \.1.id) { index, item in
                    let pos = positions[index]
                    Text(item.emoji)
                        .font(.system(size: item.baseFont))
                        .position(x: pos.x, y: pos.y)
                        .accessibilityLabel("\(item.label) level \(item.level)")
                        .transition(.scale.combined(with: .opacity))
                        .animation(animation, value: player.softSkills) // animate when skills change
                }
            }
            .frame(width: container.width, height: container.height)
        }
        // Do not force a size here; parent decides. Optionally provide a minimum ideal height.
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Circular packing helper
private enum CircularPack {
    // Compute positions where:
    // - Largest item is centered.
    // - Remaining items are placed on concentric rings around the center.
    // - On each ring, we space items by angle and then nudge outward if they collide with already placed ones.
    static func positions(for items: [SkillEmojiCloudView.SkillItem],
                          in container: CGSize,
                          ringSpacingFactor: CGFloat) -> [CGPoint] {

        guard !items.isEmpty else { return [] }

        let center = CGPoint(x: container.width / 2, y: container.height / 2)

        // Start with the largest item at center
        var positions: [CGPoint] = Array(repeating: center, count: items.count)
        positions[0] = center

        // If there’s only one item, we’re done.
        guard items.count > 1 else { return positions }

        // Initial ring radius: center item diameter plus spacing
        var ringIndex = 0
        var currentStartIndex = 1
        var currentRadius: CGFloat = max(items[0].baseFont * (1 + ringSpacingFactor), 24)

        // Place subsequent items ring-by-ring
        while currentStartIndex < items.count {
            let remaining = items.count - currentStartIndex

            // Estimate average padded diameter for the next few items
            let lookahead = min(remaining, 4)
            let avgPaddedDiameter = (0..<lookahead).map { i in
                items[currentStartIndex + i].paddedRadius * 2
            }.reduce(0, +) / CGFloat(lookahead)

            // Circumference available on this ring
            let circumference = 2 * .pi * currentRadius
            let requiredPerItem = max(avgPaddedDiameter, 1)
            let capacity = max(1, Int(floor(circumference / requiredPerItem)))

            let countOnRing = min(remaining, capacity)
            let angleStep = (2 * .pi) / CGFloat(countOnRing)
            let angleOffset = (ringIndex % 2 == 0) ? 0 : angleStep / 2

            // First pass: place by angle on the ring
            for i in 0..<countOnRing {
                let idx = currentStartIndex + i
                let angle = CGFloat(i) * angleStep + angleOffset
                let x = center.x + currentRadius * cos(angle)
                let y = center.y + currentRadius * sin(angle)
                positions[idx] = CGPoint(x: x, y: y)
            }

            // Second pass: nudge outward if colliding with already placed items
            for i in 0..<countOnRing {
                let idx = currentStartIndex + i
                var p = positions[idx]
                let r = items[idx].paddedRadius

                var attempts = 0
                let maxAttempts = 24
                var collided = true
                while collided && attempts < maxAttempts {
                    collided = false
                    for prev in 0..<idx {
                        let q = positions[prev]
                        let rq = items[prev].paddedRadius
                        let dx = p.x - q.x
                        let dy = p.y - q.y
                        let dist = sqrt(dx*dx + dy*dy)
                        let minDist = r + rq

                        if dist < minDist, dist > 0.0001 {
                            let overlap = minDist - dist
                            let ux = dx / dist
                            let uy = dy / dist
                            p.x += ux * overlap
                            p.y += uy * overlap
                            collided = true
                        } else if dist <= 0.0001 {
                            let dirX = p.x - center.x
                            let dirY = p.y - center.y
                            let len = max(sqrt(dirX*dirX + dirY*dirY), 0.0001)
                            p.x += (dirX / len) * (r * 0.5)
                            p.y += (dirY / len) * (r * 0.5)
                            collided = true
                        }
                    }
                    attempts += 1
                }

                positions[idx] = p
            }

            // Prepare next ring radius: add max item diameter of this ring plus spacing
            let maxDiaThisRing = (0..<countOnRing).map { i in
                items[currentStartIndex + i].paddedRadius * 2
            }.max() ?? avgPaddedDiameter

            currentRadius += maxDiaThisRing * (1 + ringSpacingFactor)
            currentStartIndex += countOnRing
            ringIndex += 1
        }

        // If any positions fall outside container, apply a uniform downscale around center
        let scale = fittingScale(positions: positions, items: items, in: container)
        if scale < 1.0 {
            return positions.map { p in
                CGPoint(x: center.x + (p.x - center.x) * scale,
                        y: center.y + (p.y - center.y) * scale)
            }
        } else {
            return positions
        }
    }

    private static func fittingScale(positions: [CGPoint],
                                     items: [SkillEmojiCloudView.SkillItem],
                                     in container: CGSize) -> CGFloat {
        guard positions.count == items.count, !items.isEmpty else { return 1.0 }

        // Compute bounding box considering item radius
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for (p, item) in zip(positions, items) {
            let r = item.paddedRadius
            minX = min(minX, p.x - r)
            maxX = max(maxX, p.x + r)
            minY = min(minY, p.y - r)
            maxY = max(maxY, p.y + r)
        }

        let contentW = maxX - minX
        let contentH = maxY - minY
        guard contentW > 0, contentH > 0 else { return 1.0 }

        let sx = container.width / contentW
        let sy = container.height / contentH
        return min(1.0, min(sx, sy))
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Skill Emoji Cloud")
            .font(.headline)
        SkillEmojiCloudView(player: Player(), minFontSize: 18, maxFontSize: 72, itemPadding: 3, ringSpacingFactor: 0.2)
            .frame(width: 340, height: 260) // Parent decides size here
            .border(.secondary)
            .padding()
    }
    .padding()
}
