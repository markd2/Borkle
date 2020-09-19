import Cocoa

class BubbleCanvas: NSView {
    static let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)

    var selectedBubbles = Set<Bubble>() {
        willSet {
            selectedBubbles.forEach { invalidateBubble($0) }
        }
        didSet {
            selectedBubbles.forEach { invalidateBubble($0) }
        }
    }
    
    var spaceDown: Bool = false
    var currentCursor: Cursor

    /// public API to select a chunka bubbles
    func selectBubbles(_ bubbles: Set<Bubble>) {
        selectedBubbles.forEach { invalidateBubble($0) }
        selectedBubbles = bubbles

        bubbles.forEach { invalidateBubble($0) }
    }

    /// Highlighted bubble, for mouse-motion indication.  Shown as a dashed line or something.
    var highlightedID: Int? = nil

    /// Where a click-drag originated.  nil if there's no active drag happening.
    /// might make enum with associated object when there's additional dragging behaviors.
    var initialDragPoint: CGPoint?

    var scrollOrigin: CGPoint?

    /// The bubble being dragged, original position, to calculate delta when dragging
    /// and eventually for undo.
    /// !!! Maybe copy the bubble, move it around, then on the completion it tells someone the move
    /// !!! delta for undo.
    var originalBubblePosition: CGPoint?
    var originalBubblePositions = [Bubble: CGPoint]()

    var bubbleMoveUndoCompletion: ((_ bubble: Bubble, _ originPoint: CGPoint, _ finalPoint: CGPoint) -> Void)?
    var keypressHandler: ((_ event: NSEvent) -> Void)?

    override var isFlipped: Bool { return true }

    /// On the way out.  Prefer bubble soup
    var bubbles: [Bubble] = [] {
        didSet {
            bubbles.forEach { $0._effectiveHeight = nil }
            needsDisplay = true
            resizeCanvas()
        }
    }

    var bubbleSoup: BubbleSoup!

    let extraPadding = CGSize(width: 80, height: 60)

    func resizeCanvas() {
        var union = CGRect.zero
        
        for bubble in bubbles {
            union = union.union(bubble.rect)
        }
        union = union + extraPadding

        if frame != union {
            frame = union
        }
    }

    required init?(coder: NSCoder) {
        currentCursor = .arrow
        super.init(coder: coder)
        addTrackingAreas()
    }
    
    override init(frame: CGRect) {
        currentCursor = .arrow
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
                if needsToDraw(rect) {
                    renderBubble($0, in: rect, 
                        selected: selectedBubbles.contains($0),
                        highlighted: $0.ID == (highlightedID ?? -666))
                }
            } else {
                Swift.print("unexpected not-rendering a bubble")
            }
        }
    }

    func allBorders(_ bubbles: [Bubble]) -> [Int: CGRect] {
        var idToRectMap: [Int: CGRect] = [:]

        for bubble in bubbles {
            let rect = bubble.rect
            idToRectMap[bubble.ID] = rect
        }
        return idToRectMap
    }

    private func drawConnections(_ map: [Int: CGRect]) {
        NSColor.darkGray.set()
        let bezierPath = NSBezierPath()
        let pattern: [CGFloat] = [3.0, 2.0]
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

        let textRect = rect.insetBy(dx: bubble.margin!, dy: bubble.margin!)
        nsstring.draw(in: textRect, withAttributes: nil)
        NSColor.gray.set()

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
            return
        }
        
        if !selectedBubbles.contains(bubble) {
            selectedBubbles.insert(bubble)
        }
    }

    func toggleBubble(_ bubble: Bubble?) {
        guard let bubble = bubble else { return }

        selectedBubbles.toggle(bubble)
        invalidateBubble(bubble)
    }

    func deselectAllBubbles() {
        selectedBubbles.removeAll()
    }

    func invalidateBubble(_ bubble: Bubble) {
        invalidateBubble(bubble.ID)
    }
    func invalidateBubble(_ bubbleID: Int) {
        guard let rect = idToRectMap[bubbleID] else { return }
        let rectWithPadding = rect.insetBy(dx: -5, dy: -5)
        setNeedsDisplay(rectWithPadding)
    }

    func highlightBubble(_ bubble: Bubble?) {
        guard let bubble = bubble else {
            if let highlightedID = highlightedID {
                invalidateBubble(highlightedID)

                self.highlightedID = nil
            }
            return
        }

        if highlightedID != bubble.ID {
            highlightedID = bubble.ID
            if let highlightedID = highlightedID {
                invalidateBubble(highlightedID)
            }
        }
    }
}

// mouse and tracking area foobage.
extension BubbleCanvas {
    override func updateTrackingAreas() {
        if spaceDown { return }

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
            self.trackingArea = nil
        }
        addTrackingAreas()
    }

    override func mouseMoved(with event: NSEvent) {
        if spaceDown { return }

        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)
        let bubble = hitTestBubble(at: viewLocation)
        highlightBubble(bubble)
    }

    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)

        if spaceDown {
            guard let clipview = superview as? NSClipView else {
                Swift.print("no clip vieW?")
                return
            }
            setCursor(.closedHand)
            initialDragPoint = locationInWindow
            scrollOrigin = clipview.bounds.origin
            return
        }

        let addToSelection = event.modifierFlags.contains(.shift)
        let toggleSelection = event.modifierFlags.contains(.command)

        let bubble = hitTestBubble(at: viewLocation)
        initialDragPoint = nil

        // !!! ponder enum/switch for this
        if addToSelection {
            selectBubble(bubble)

        } else if toggleSelection {
            toggleBubble(bubble)

        } else {

            if let bubble = bubble {
                if selectedBubbles.contains(bubble) {
                    // bubble already selected, so it's a drag of existing selection
                    initialDragPoint = viewLocation
                } else {
                    // it's a fresh selection, no modifiers, could be a click-and-drag in one gesture
                    // !!! scapple has click-drag 
                    deselectAllBubbles()
                    selectBubble(bubble)
                    initialDragPoint = viewLocation
                }
                    
                
            } else {
                // bubble is nil, so a click into open space, so deselect everything
                deselectAllBubbles()
            }
        }

        // All done if there's nothing to actually draga
        guard initialDragPoint != nil else { return }

        originalBubblePositions = selectedBubbles.reduce(into: [:]) { positions, bubble in
            positions[bubble] = bubble.position
        }

        // we have a selected bubble. Drag it around.
        if let bubble = bubble {
            originalBubblePosition = bubble.position
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil) as CGPoint

        if spaceDown {
            guard let initialDragPoint = initialDragPoint, let scrollOrigin = scrollOrigin  else { return }
            let rawDelta = locationInWindow - initialDragPoint
            let flippedX = CGPoint(x: rawDelta.x, y: -rawDelta.y)
            let newOrigin = scrollOrigin + flippedX
            scroll(newOrigin)
            return
        }

        guard let initialDragPoint = initialDragPoint else { return }
        guard selectedBubbles.count > 0 else { return }

        let delta = initialDragPoint - viewLocation
        selectedBubbles.forEach { bubble in
            guard let originalPosition = originalBubblePositions[bubble] else {
                Swift.print("unexpectedly missing original bubble position")
                return
            }
            bubble.position = originalPosition + delta
            
            // the area to redraw is kind of complex - like if there's connected 
            // bubbles need to make sure connecting lines are redrawn.
            setNeedsDisplay(bounds)
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            initialDragPoint = nil
            scrollOrigin = nil
        }

        if spaceDown {
            setCursor(.openHand)

            return
        }

        guard initialDragPoint != nil else { return }

        selectedBubbles.forEach { bubble in
            guard let originalPosition = originalBubblePositions[bubble] else {
                Swift.print("unexpectedly missing bubble position in mouse up")
                return
            }
            bubbleMoveUndoCompletion?(bubble, bubble.position, originalPosition)
        }
        resizeCanvas()
    }

    override var acceptsFirstResponder: Bool { return true }

    // thank you peter! https://boredzo.org/blog/archives/2007-05-22/virtual-key-codes
    enum Keycodes: UInt16 {
        case spacebar = 49
    }

    enum Cursor {
        case arrow
        case openHand
        case closedHand

        var nscursor: NSCursor {
            switch self {
            case .arrow: return NSCursor.arrow
            case .openHand: return NSCursor.openHand
            case .closedHand: return NSCursor.closedHand
            }
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: currentCursor.nscursor)
    }

    func setCursor(_ cursor: Cursor) {
        currentCursor = cursor
        cursor.nscursor.set()
        window?.invalidateCursorRects(for: self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == Keycodes.spacebar.rawValue {
            if !spaceDown {
                spaceDown = true
                setCursor(.openHand)
            }
        } else {
            setCursor(.arrow)
            keypressHandler?(event)
            spaceDown = false
        }
    }
    
    override func keyUp(with event: NSEvent) {
        if event.keyCode == Keycodes.spacebar.rawValue {
            spaceDown = false
            setCursor(.arrow)
        } else {
            keypressHandler?(event)
        }
    }
}

