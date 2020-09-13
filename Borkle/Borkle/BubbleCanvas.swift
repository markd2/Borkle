import Cocoa

class BubbleCanvas: NSView {
    override var isFlipped: Bool { return true }
    var bubbles: [Bubble] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ areaToDrawPlzKthx: CGRect) {

        let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)
        background.set()
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
        
        NSColor.black.set()
        bounds.frame()
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
        NSColor.lightGray.set()
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
                NSBezierPath.strokeLine(from: thing1, to: thing2)
            }
        }
    }

    private func renderBubble(_ bubble: Bubble, in rect: CGRect) {
        NSColor.white.set()
        rect.fill()
        NSColor.black.set()
        rect.frame()

        let nsstring = "\(bubble.text)" as NSString
        nsstring.draw(in: rect, withAttributes: nil)
    }
}


extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
