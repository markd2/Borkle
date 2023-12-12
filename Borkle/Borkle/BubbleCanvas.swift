import Cocoa

class BubbleCanvas: NSView {
    static let background = NSColor(red: 228.0 / 255.0, green: 232.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)

    // move to soup
    var barriersChangedHook: (() -> Void)?
    var playfield: Playfield!

    var selectedBubbles = Selection()
    var alphaBubbles: Selection?

    var currentMouseHandler: MouseHandler?

    var textEditor: NSTextView?
    var textEditingBubble: Bubble?

    var dropTargetBubble: Bubble?

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

    var scrollOrigin: CGPoint?

    /// for things like "hey paste at the last place the user clicked.
    var lastPoint: CGPoint?

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
        var union = playfield.enclosingRect + extraPadding

        // If bubbles are smaller than the useful area, 
        if let superBounds = superview?.superview?.bounds {
            union = union.union(superBounds)
        }

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

        playfield.forEachBubble { id in
            if let rect = idToRectMap[id] {
                if needsToDraw(rect) {
                    guard let bubble = bubbleSoup.bubble(byID: id) else {
                        fatalError("couldn't find bubble with expected id \(id)")
                    }
                    let transparent = alphaBubbles?.isSelected(bubble: bubble) ?? false
                    renderBubble(
                      bubble, in: rect, 
                      selected: selectedBubbles.isSelected(bubble: bubble),
                      highlighted: bubble.ID == (highlightedID ?? -666),
                      transparent: transparent,
                      dropTarget: bubble.ID == (dropTargetBubble?.ID ?? -666))
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
        playfield.forEachBubble { id in
            guard let bubble = bubbleSoup.bubble(byID: id) else {
                return
            }
            let rect = playfield.rectFor(bubbleID: id)
            idToRectMap[bubble.ID] = rect
        }
        return idToRectMap
    }

    private func drawConnections(_ map: [Int: CGRect]) {
        NSColor.darkGray.set()
        let bezierPath = NSBezierPath()
        let pattern: [CGFloat] = [3.0, 2.0]
        bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)

        playfield.forEachBubble { id in
            guard let bubble = bubbleSoup.bubble(byID: id) else {
                return
            }
            for index in bubble.connections {

                // both sides of the connection exist in bubble.  e.g. if 3 and 175 is connected,
                // only want to draw that once.  So wait until bubbles bigger than us to draw
                // the connection. We draw the ones less than us
                if index > bubble.ID {
                    continue
                }

                let thing1 = map[bubble.ID]!.center
                let thing2 = map[index]!.center

                let rect = CGRect(point1: thing1, point2: thing2)
                if needsToDraw(rect) {
                    bezierPath.removeAllPoints()
                    bezierPath.move(to: thing1)
                    bezierPath.line(to: thing2)
                    bezierPath.stroke()
                }
            }
        }
    }

    private func renderBubble(_ bubble: Bubble, in rect: CGRect, 
                              selected: Bool, highlighted: Bool, 
                              transparent: Bool, dropTarget: Bool) {
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        defer {
            context?.restoreGState()
        }

        if transparent {
            context?.setAlpha(0.5)
        }

        let bezierPath = NSBezierPath()
        bezierPath.appendRoundedRect(rect, xRadius: 8, yRadius: 8)
        if let fillColor = bubble.fillColor {
            fillColor.set()
        } else {
            NSColor.white.set()
        }
        bezierPath.fill()
        
        let attributedString = bubble.attributedString

        let textRect = rect.insetBy(dx: Bubble.margin, dy: Bubble.margin)
        attributedString.draw(in: textRect)
        NSColor.gray.set()

        if selected {
            NSColor.darkGray.set()
            let thickness = bubble.borderThickness ?? 4
            bezierPath.lineWidth = CGFloat(thickness)
        } else {
            let borderColor = bubble.borderColor ?? NSColor.darkGray
            borderColor.set()
            let thickness = bubble.borderThickness ?? 2
            bezierPath.lineWidth = CGFloat(thickness)
        }
        bezierPath.stroke()

        if highlighted {
            let pattern: [CGFloat] = [2.0, 2.0]
            bezierPath.setLineDash(pattern, count: pattern.count, phase: 0.0)
            bezierPath.lineWidth = 1.0

            NSColor.white.set()
            bezierPath.stroke()
        }

        if dropTarget {
            NSColor.orange.set()
            bezierPath.lineWidth = 3.0
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

    func invalidateSelection(_ selection: Selection?) {
        selection?.forEachBubble(invalidateBubble)
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

    func textEdit(bubble: Bubble) {
        if textEditor == nil {
            textEditor = NSTextView(frame: .zero)
        }
        guard let textEditor = textEditor else {
            Swift.print("uh... we just made the text editor")
            return
        }

        let rect = bubble.rect.insetBy(dx: 0, dy: 0)
        // !!! this logic is kind of duplicated around.
        let textRect = rect.insetBy(dx: Bubble.margin, dy: Bubble.margin)
        textEditor.frame = textRect

        textEditor.textStorage?.setAttributedString(bubble.attributedString)

        addSubview(textEditor)
        window?.makeFirstResponder(textEditor)
        textEditingBubble = bubble

        textEditor.textContainer?.lineFragmentPadding = 0
    }

    func commitEditing(bubble: Bubble) {
        guard let textEditor = textEditor else {
            Swift.print("uh.... we shouldn't get here without a text editor")
            return
        }
        bubble.text = textEditor.string
        
        if let attr = textEditor.textStorage?.attributedSubstring(from: NSMakeRange(0, bubble.text.count)) {
            bubble.gronkulateAttributedString(attr)
        }

        textEditor.removeFromSuperview()
        textEditor.string = ""
        
        needsDisplay = true
    }
}

// Mouse tracking
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
        lastPoint = viewLocation

        if let textEditingBubble = textEditingBubble {
            commitEditing(bubble: textEditingBubble)
            self.textEditingBubble = nil
            return
        }

        if spaceDown {
            setCursor(.closedHand)
            currentMouseHandler = MouseGrabHand(withSupport: self)
            currentMouseHandler?.start(at: locationInWindow, modifierFlags: event.modifierFlags)
            return
        }

        for barrier in barriers { // not a forEach because of the return
            if barrier.hitTest(point: viewLocation, area: bounds) {
                bubbleSoup.beginGrouping()
                barrierSoup.beginGrouping()
                currentMouseHandler = MouseBarrier(withSupport: self, barrier: barrier)
                currentMouseHandler?.start(at: viewLocation, modifierFlags: event.modifierFlags)
                return
            }
        }

        let bubble = bubbleSoup.hitTestBubble(at: viewLocation)

        if let bubble = bubble {
            if event.clickCount == 2 {
                textEdit(bubble: bubble)
            }
        } else {
            // space!
            if event.clickCount == 1 {
                currentMouseHandler = MouseSpacer(withSupport: self, selection: selectedBubbles)
            } else if event.clickCount == 2 {
                currentMouseHandler = MouseDoubleSpacer(withSupport: self)
                currentMouseHandler?.start(at: viewLocation, modifierFlags: event.modifierFlags)
                return
            } else {
                // do nothing
            }
            currentMouseHandler?.start(at: viewLocation, modifierFlags: event.modifierFlags)
            return
        }

        // Catch-all selecting and dragging.
        bubbleSoup.beginGrouping()
        currentMouseHandler = MouseBubbler(withSupport: self, 
                                           selectedBubbles: selectedBubbles)
        currentMouseHandler?.start(at: viewLocation,
                                   modifierFlags: event.modifierFlags)
    }

    override func mouseDragged(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil) as CGPoint
        lastPoint = viewLocation

        if let handler = currentMouseHandler {
            if handler.prefersWindowCoordinates {
                handler.drag(to: locationInWindow, modifierFlags: event.modifierFlags)
            } else {
                handler.drag(to: viewLocation, modifierFlags: event.modifierFlags)
            }
        }
    }

    override func mouseUp(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil) as CGPoint
        lastPoint = viewLocation

        defer {
            scrollOrigin = nil
            bubbleSoup.endGrouping()

            currentMouseHandler = nil
            marquee = nil

            bubbleSoup.endGrouping()
            barrierSoup.endGrouping()
        }

        if spaceDown {
            setCursor(.openHand)
        }

        if let handler = currentMouseHandler {
            handler.finish(at: viewLocation, modifierFlags: event.modifierFlags)
            return
        }

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

    func makeTransparent(_ selection: Selection?) {
        invalidateSelection(selection)
        invalidateSelection(alphaBubbles)
        alphaBubbles = selection
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
    
    func createNewBubble(at point: CGPoint, showEditor: Bool) -> Bubble {
        let bubble = bubbleSoup.create(newBubbleAt: point)
        if showEditor {
            textEdit(bubble: bubble)
        }
        return bubble
    }

    func move(bubble: Bubble, to point: CGPoint) {
        bubbleSoup.move(bubble: bubble, to: point)
            
        // the area to redraw is kind of complex - like if there's connected 
        // bubbles need to make sure connecting lines are redrawn.
        setNeedsDisplay(bounds)
    }

    func move(barrier: Barrier, affectedBubbles: [Bubble]?, affectedBarriers: [Barrier]?,
        to horizontalPosition: CGFloat) {
        moveAllTheThings(anchoredByBarrier: barrier, 
            affectedBubbles: affectedBubbles, affectedBarriers: affectedBarriers,
            to: horizontalPosition)
    }

    func connect(bubbles: [Bubble], to bubble: Bubble) {
        bubbleSoup.connect(bubbles: bubbles, to: bubble)
        needsDisplay = true
    }

    func disconnect(bubbles: [Bubble], from bubble: Bubble) {
        bubbleSoup.disconnect(bubbles: bubbles, from: bubble)
        needsDisplay = true
    }

    func highlightAsDropTarget(bubble: Bubble?) {
        var damageRects: [CGRect] = []

        if let dropTargetBubble = dropTargetBubble {
            damageRects += [dropTargetBubble.rect]
        }

        dropTargetBubble = bubble

        if let bubble = bubble {
            damageRects += [bubble.rect]
        }

        damageRects.forEach { setNeedsDisplay($0) }
    }

    func bubblesAffectedBy(barrier: Barrier) -> [Bubble]? {
        let affectedBubbles = bubbleSoup.areaTestBubbles(intersecting: barrier.horizontalPosition.rectToRight)
        return affectedBubbles
    }

    func barriersAffectedBy(barrier: Barrier) -> [Barrier]? {
        let affectedBarriers = barrierSoup.areaTestBarriers(toTheRightOf: barrier.horizontalPosition)
        return affectedBarriers
    }
}


// This stuff should move elsewhere since (hopefully) it's purely soup manipulations.
extension BubbleCanvas {
    func moveAllTheThings(anchoredByBarrier barrier: Barrier, 
        affectedBubbles: [Bubble]?, affectedBarriers: [Barrier]?, to horizontalPosition: CGFloat) {
        
        let delta = horizontalPosition - barrier.horizontalPosition
        barrierSoup.move(barrier: barrier, to: horizontalPosition)

        affectedBubbles?.forEach { bubble in
            let newPosition = CGPoint(x: bubble.position.x + delta, y: bubble.position.y)
            bubbleSoup.move(bubble: bubble, to: newPosition)
        }

        affectedBarriers?.forEach { barrier in
            let newPosition = barrier.horizontalPosition + delta
            barrierSoup.move(barrier: barrier, to: newPosition)
        }

        needsDisplay = true
    }
}


extension NSTextView {
    @IBAction func bk_strikethrough(_ sender: Any?) {
        print("SNORGLE")
    }
}
