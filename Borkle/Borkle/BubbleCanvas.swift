import Cocoa

class BubbleCanvas: NSView {
    static let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)

    override var isFlipped: Bool { return true }
    var bubbles: [Bubble] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ areaToDrawPlzKthx: CGRect) {
        BubbleCanvas.background.set()
        bounds.fill()

        let idToRectMap = allBorders(bubbles)

        drawConnections(idToRectMap)

        bubbles.forEach {
            if let rect = idToRectMap[$0.ID] {
                renderBubble($0, in: rect)
            } else {
                Swift.print("unexpected not-rendering a bubble")
            }
        }
    }

    func allBorders(_ bubbles: [Bubble]) -> [Int: CGRect] {
        var idToRectMap: [Int: CGRect] = [:]

        for bubble in bubbles {
            let rect = CGRect(x: bubble.position.x, y: bubble.position.y, width: bubble.width, height: 20)
            idToRectMap[bubble.ID] = rect
        }
        return idToRectMap
    }

    private func drawConnections(_ map: [Int: CGRect]) {
        NSColor.darkGray.set()
        let bezierPath = NSBezierPath()
        let pattern: [CGFloat] = [2.0, 1.0]
        bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)

        for bubble in bubbles {
            for index in bubble.connections {

                // both sides of the connection exist in bubble.  e.g. if 3 and 175 is connected,
                // only want to draw that once.  So wait until bubbles bigger than us to draw
                // the connection. We draw the ones less than us
                if index > bubble.ID {
                    continue
                }

                let thing1 = map[bubble.ID]!.center
                let thing2 = map[index]!.center
                Swift.print("pairing \(thing1)->\(thing2)")
                bezierPath.removeAllPoints()
                bezierPath.move(to: thing1)
                bezierPath.line(to: thing2)
                bezierPath.stroke()
            }
        }
    }

    private func renderBubble(_ bubble: Bubble, in rect: CGRect) {
        let bezierPath = NSBezierPath()
        bezierPath.appendRoundedRect(rect, xRadius: 8, yRadius: 8)
        NSColor.white.set()
        bezierPath.fill()

        let nsstring = "\(bubble.text)" as NSString
        nsstring.draw(in: rect, withAttributes: nil)

        NSColor.black.set()
        bezierPath.stroke()
    }
}
