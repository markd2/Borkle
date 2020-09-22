import Cocoa

class BubbleCanvas: NSView {
    static let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)

    // move to soup
    var barriersChangedHook: (() -> Void)?

    var selectedBubbles = Selection()

    var currentMouseHandler: MouseHandler?

    let marqueeLineWidth: CGFloat = 2.0
    var marquee: CGRect? {
        willSet {
            if let blah = marquee {
                setNeedsDisplay(blah.insetBy(dx: -marqueeLineWidth, dy: -marqueeLineWidth))
            }

            if let blah = newValue {
                setNeedsDisplay(blah.insetBy(dx: -marqueeLineWidth, dy: -marqueeLineWidth))
            }
        }
    }

    var spaceDown: Bool = false
    var currentCursor: Cursor

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

    var keypressHandler: ((_ event: NSEvent) -> Void)?

    override var isFlipped: Bool { return true }
    var idToRectMap: [Int: CGRect] = [:]

    var bubbleSoup: BubbleSoup! {
        didSet {
            bubbleSoup.invalHook = invalidateBubbleFollowingConnections
            resizeCanvas()
        }
    }

    var barrierSoup: BarrierSoup! {
        didSet {
            barrierSoup.invalHook = invalidateBarrier
        }
    }

    var barriers: [Barrier] = [] {
        didSet {
            needsDisplay = true
        }
    }

    let extraPadding = CGSize(width: 80, height: 60)

    func resizeCanvas() {
        let union = bubbleSoup.enclosingRect + extraPadding

        if frame != union {
            frame = union
        }
    }

    required init?(coder: NSCoder) {
        currentCursor = .arrow
        super.init(coder: coder)
        addTrackingAreas()
        selectedBubbles.invalHook = invalidateBubbleFollowingConnections
    }
    
    override init(frame: CGRect) {
        currentCursor = .arrow
        super.init(frame: frame)
        addTrackingAreas()
        selectedBubbles.invalHook = invalidateBubbleFollowingConnections
    }
    var trackingArea: NSTrackingArea!

    func addTrackingAreas() {
        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }

    override func draw(_ areaToDrawPlzKthx: CGRect) {
        BubbleCanvas.background.set()
        bounds.fill()

        idToRectMap = allBorders()

        drawConnections(idToRectMap)

        bubbleSoup.forEachBubble {
            if let rect = idToRectMap[$0.ID] {
                if needsToDraw(rect) {
                    renderBubble($0, in: rect, 
                        selected: selectedBubbles.isSelected(bubble: $0),
                        highlighted: $0.ID == (highlightedID ?? -666))
                }
            } else {
                Swift.print("unexpected not-rendering a bubble")
            }
        }

        let viewRect = bounds
        for barrier in barriers {
            barrier.render(in: viewRect)
        }

        renderMarquee()
    }

    func renderMarquee() {
        if var marquee = marquee {

            if marquee.height <= 0 {
                marquee.size.height = 2
            }

            if marquee.width <= 0 {
                marquee.size.width = 2
            }

            NSColor.black.set()

            let bezierPath = NSBezierPath(rect: marquee)
            let pattern: [CGFloat] = [5.0, 5.0]
            bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)
            bezierPath.lineWidth = marqueeLineWidth
            bezierPath.stroke()
        }

    }

    func allBorders() -> [Int: CGRect] {

        bubbleSoup.forEachBubble {
            let rect = $0.rect
            idToRectMap[$0.ID] = rect
        }
        return idToRectMap
    }

    private func drawConnections(_ map: [Int: CGRect]) {
        NSColor.darkGray.set()
        let bezierPath = NSBezierPath()
        let pattern: [CGFloat] = [3.0, 2.0]
        bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)

        bubbleSoup.forEachBubble { bubble in
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

        let textRect = rect.insetBy(dx: Bubble.margin, dy: Bubble.margin)
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

    func invalidateBarrier(_ barrier: Barrier) {
        needsDisplay = true
    }

    func invalidateBubble(_ bubble: Bubble) {
        invalidateBubble(bubble.ID)
    }

    func invalidateBubble(_ bubbleID: Int) {
        guard let rect = idToRectMap[bubbleID] else { return }
        let rectWithPadding = rect.insetBy(dx: -5, dy: -5)
        setNeedsDisplay(rectWithPadding)
    }

    func invalidateBubbleFollowingConnections(_ bubble: Bubble) {
        var union = bubble.rect

        bubble.connections.forEach {
            if let connectedBubble = bubbleSoup.bubble(byID: $0) {
                union = union.union(connectedBubble.rect)
            }
        }
        let rectWithPadding = union.insetBy(dx: -10, dy: -10)
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
        let bubble = bubbleSoup.hitTestBubble(at: viewLocation)
        highlightBubble(bubble)
    }

    override func mouseDown(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)

        if spaceDown {
            setCursor(.closedHand)
            currentMouseHandler = MouseGrabHand(withSupport: self)
            currentMouseHandler?.start(at: locationInWindow)
            return
        }

        if event.clickCount == 2 {
            currentMouseHandler = MouseDoubleSpacer(withSupport: self)
            currentMouseHandler?.start(at: viewLocation)
            return
        }

        for barrier in barriers { // not a forEach because of the return
            if barrier.hitTest(point: viewLocation, area: bounds) {
                currentMouseHandler = MouseBarrier(withSupport: self, barrier: barrier)
                currentMouseHandler?.start(at: viewLocation)
                return
            }
        }

        let addToSelection = event.modifierFlags.contains(.shift)
        let toggleSelection = event.modifierFlags.contains(.command)

        let bubble = bubbleSoup.hitTestBubble(at: viewLocation)

        if bubble == nil {
            // space!
            if event.clickCount == 1 {
                currentMouseHandler = MouseSpacer(withSupport: self)
            } else if event.clickCount == 2 {
                currentMouseHandler = MouseDoubleSpacer(withSupport: self)
            } else {
                // do nothing
            }
            currentMouseHandler?.start(at: viewLocation)
            return
        }

        initialDragPoint = nil

        if addToSelection {
            if let bubble = bubble {
                selectedBubbles.select(bubble: bubble)
            }
        } else if toggleSelection {
            if let bubble = bubble {
                selectedBubbles.toggle(bubble: bubble)
            }

        } else {
            if let bubble = bubble {
                bubbleSoup.beginGrouping()

                if selectedBubbles.isSelected(bubble: bubble) {
                    // bubble already selected, so it's a drag of existing selection
                    initialDragPoint = viewLocation
                } else {
                    // it's a fresh selection, no modifiers, could be a click-and-drag in one gesture
                    // !!! scapple has click-drag 
                    selectedBubbles.unselectAll()
                    selectedBubbles.select(bubble: bubble)
                    initialDragPoint = viewLocation
                }
                    
                
            } else {
                // bubble is nil, so a click into open space, so deselect everything
                selectedBubbles.unselectAll()
            }
        }

        // All done if there's nothing to actually draga
        guard initialDragPoint != nil else { return }

        originalBubblePositions = [:]
        bubbleSoup.forEachBubble {
            originalBubblePositions[$0] = $0.position
        }

        // we have a selected bubble. Drag it around.
        if let bubble = bubble {
            originalBubblePosition = bubble.position
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil) as CGPoint

        if let handler = currentMouseHandler {
            if handler.prefersWindowCoordinates {
                handler.move(to: locationInWindow)
            } else {
                handler.move(to: viewLocation)
            }
            return
        }

        guard let initialDragPoint = initialDragPoint else { return }
        guard selectedBubbles.bubbleCount > 0 else { return }

        let delta = initialDragPoint - viewLocation
        selectedBubbles.forEachBubble { bubble in
            guard let originalPosition = originalBubblePositions[bubble] else {
                Swift.print("unexpectedly missing original bubble position")
                return
            }
            bubbleSoup.move(bubble: bubble, to: originalPosition + delta)
            
            // the area to redraw is kind of complex - like if there's connected 
            // bubbles need to make sure connecting lines are redrawn.
            setNeedsDisplay(bounds)
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            initialDragPoint = nil
            scrollOrigin = nil
            bubbleSoup.endGrouping()

            currentMouseHandler = nil
            marquee = nil
        }

        if spaceDown {
            setCursor(.openHand)
        }

        if let handler = currentMouseHandler {
            handler.finish()
            return
        }


        guard initialDragPoint != nil else { return }

        resizeCanvas()
    }

    override var acceptsFirstResponder: Bool { return true }

    // thank you peter! https://boredzo.org/blog/archives/2007-05-22/virtual-key-codes
    enum Keycodes: UInt16 {
        case spacebar = 49
        case delete = 51
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
        } else if event.keyCode == Keycodes.delete.rawValue {
            setCursor(.arrow)
            if !selectedBubbles.selectedBubbles.isEmpty {
                bubbleSoup.remove(bubbles: selectedBubbles.selectedBubbles)
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

extension BubbleCanvas: MouseSupport {
    func hitTestBubble(at point: CGPoint) -> Bubble? {
        let bubble = bubbleSoup.hitTestBubble(at: point)
        return bubble
    }

    func areaTestBubbles(intersecting area: CGRect) -> [Bubble]? {
        return bubbleSoup.areaTestBubbles(intersecting: area)
    }

    func drawMarquee(around rect: CGRect) {
        marquee = rect
    }

    func unselectAll() {
        selectedBubbles.unselectAll()
    }

    func select(bubbles: [Bubble]) {
        selectedBubbles.select(bubbles: bubbles)
    }

    var currentScrollOffset: CGPoint {
        guard let clipview = superview as? NSClipView else {
            Swift.print("no clip vieW?")
            return .zero
        }

        let origin = clipview.bounds.origin
        let viewCoordinates = origin

        return viewCoordinates
    }

    func scroll(to newOrigin: CGPoint) {
        scroll(newOrigin)
    }

    func createNewBubble(at point: CGPoint) {
        bubbleSoup.create(newBubbleAt: point)
    }

    func move(barrier: Barrier, to horizontalPosition: CGFloat) {
        barrier.horizontalPosition = horizontalPosition
        needsDisplay = true
        barriersChangedHook?()
    }
}
