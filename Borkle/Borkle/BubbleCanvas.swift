import Cocoa

class BubbleCanvas: NSView {
    static let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)

    /// Selected bubble.  Eventually needs to become a set of bubbles for multi-selection
    var selectedID: Int? = nil

    /// Highlighted bubble, for mouse-motion indication.  Shown as a dashed line or something.
    var highlightedID: Int? = nil

    override var isFlipped: Bool { return true }
    var bubbles: [Bubble] = [] {
        didSet {
            needsDisplay = true
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTrackingAreas()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTrackingAreas()
    }
    var trackingArea: NSTrackingArea!

    func addTrackingAreas() {
        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }

    var idToRectMap: [Int: CGRect] = [:]
    
    override func draw(_ areaToDrawPlzKthx: CGRect) {
        BubbleCanvas.background.set()
        bounds.fill()

        idToRectMap = allBorders(bubbles)

        drawConnections(idToRectMap)

        bubbles.forEach {
            if let rect = idToRectMap[$0.ID] {
                renderBubble($0, in: rect, 
                    selected: $0.ID == (selectedID ?? -666), 
                    highlighted: $0.ID == (highlightedID ?? -666))
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
                bezierPath.removeAllPoints()
                bezierPath.move(to: thing1)
                bezierPath.line(to: thing2)
                bezierPath.stroke()
            }
        }
    }

    private func renderBubble(_ bubble: Bubble, in rect: CGRect, selected: Bool, highlighted: Bool) {
        let bezierPath = NSBezierPath()
        bezierPath.appendRoundedRect(rect, xRadius: 8, yRadius: 8)
        NSColor.white.set()
        bezierPath.fill()

        let nsstring = "\(bubble.text)" as NSString
        nsstring.draw(in: rect, withAttributes: nil)

        if selected {
            NSColor.darkGray.set()
            bezierPath.lineWidth = 4.0
        } else {
            NSColor.darkGray.set()
            bezierPath.lineWidth = 2.0
        }
        bezierPath.stroke()

        if highlighted {
            let pattern: [CGFloat] = [2.0, 2.0]
            bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)
            bezierPath.lineWidth = 1.0

            NSColor.white.set()
            bezierPath.stroke()
        }
    }

    func hitTestBubble(at point: CGPoint) -> Bubble? {
        for bubble in bubbles {
            if let rect = idToRectMap[bubble.ID] {
                if rect.contains(point) {
                    return bubble
                }
            }
        }
        return nil
    }

    func selectBubble(_ bubble: Bubble?) {
        guard let bubble = bubble else {
            selectedID = nil
            needsDisplay = true
            return
        }

        if selectedID != bubble.ID {
            selectedID = bubble.ID
            needsDisplay = true
        }
    }

    func highlightBubble(_ bubble: Bubble?) {
        guard let bubble = bubble else {
            highlightedID = nil
            needsDisplay = true
            return
        }

        if highlightedID != bubble.ID {
            highlightedID = bubble.ID
            needsDisplay = true
        }
    }
}

// mouse and tracking area foobage.
extension BubbleCanvas {
    override func updateTrackingAreas() {
        Swift.print("SNORGLE update tracking areas")
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
            self.trackingArea = nil
        }
        addTrackingAreas()
    }

    override func mouseMoved(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)
        let bubble = hitTestBubble(at: viewLocation)
        highlightBubble(bubble)
    }

    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)
        let bubble = hitTestBubble(at: viewLocation)
        selectBubble(bubble)
    }
}
