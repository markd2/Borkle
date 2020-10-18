import Foundation


/// BubbleSoup - a class that matains the storage miasma of Borkle.
///
/// It holds the bubbles, lines, and provides an API for updating the contents of
/// the soup (with undo support)
class BubbleSoup {

    let defaultWidth: CGFloat = 100
    let defaultHeight: CGFloat = 8

    /// Hook that's called when a bubble position changes, so it can be invalidated
    var invalHook: ((Bubble) -> Void)?

    /// Something changed in the bubbles - maybe resize the canvas?
    var bubblesChangedHook: (() -> Void)?

    /// How many bubbles we have.
    public var bubbleCount: Int {
        return bubbles.count
    }

    /// Array storage of bubbles.  Might need to revisit this if array operations turn
    /// out to be annoying
    private var bubbles: [Bubble] = []

    /// Iterate over each of the bubbles in some kind of order
    /// I'm not smart enough to return some kind of sequence/iterator thing
    public func forEachBubble(_ iterator: (Bubble) -> Void) {
        bubbles.forEach { iterator($0) }
    }

    /// Undo manager responsible for handling undo.  One will be provided if you don't
    /// give us one
    var undoManager: UndoManager

    public init(undoManager: UndoManager? = nil) {
        if let undoManager = undoManager {
            self.undoManager = undoManager
        } else {
            // most likely for tests, so turn off runloop grouping
            self.undoManager = UndoManager()
            undoManager?.groupsByEvent = false
        }
    }

    /// Unfortunatley, can't use undoManager's groupingLevel to decide if we're in a no-op
    /// undo situation.  In tests, a beginUndoGrouping goes to a level of two, so something
    /// is happening For Our Convenience™
    var  groupingLevel = 0

    /// When doing something that spans multiple spins of the event loop (like mouse
    /// tracking), start a grouping before, and end it afterwards
    func beginGrouping() {
        undoManager.beginUndoGrouping()
        groupingLevel += 1
    }

    /// Companion to `beginGrouping`. Call it first.
    /// Ok if called without a corresponding begin grouping - say when click-dragging in
    /// in empty space and doing nothing, so we don't want an empty undo grouping on the stack.
    /// (I am not terribly happy about this. ++md 9/19/2020)
    func endGrouping() {
        if groupingLevel > 0 {
            undoManager.endUndoGrouping()
            groupingLevel -= 1
        }
    }
    
    /// Looks up a bubble in the soup by its ID.  Returns nil if not found.
    public func bubble(byID: Int) -> Bubble? {
        let bubble = bubbles.first(where: { $0.ID == byID } )
        return bubble
    }

    /// Add the bubble to the soup.
    public func add(bubble: Bubble) {
        add(bubblesArray: [bubble])
    }

    /// Add the bubbles to the soup.  There's no intrinsic order to the bubbles in the soup.
    /// (even though internally it is an array)
    public func add(bubbles: [Bubble]) {
        add(bubblesArray: bubbles)

        bubbles.forEach { invalHook?($0) }
    }

    /// Remove a bunch of bubbles
    public func remove(bubbles: [Bubble]) {
        undoManager.beginUndoGrouping()
        bubbles.forEach { invalHook?($0) }

        let filtered = self.bubbles.filter { return !bubbles.contains($0) }
        self.bubbles = filtered

        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.add(bubbles: bubbles)
        }
        undoManager.endUndoGrouping()
    }

    // Make a new bubble centered at the given point.  ID is max + 1 of existing bubbles.
    public func create(newBubbleAt point: CGPoint) -> Bubble {
        let maxID = maxBubbleID()
        let bubble = Bubble(ID: maxID + 1)
        bubble.width = defaultWidth
        bubble.position = CGPoint(x: point.x - defaultWidth / 2.0, y: point.y - defaultHeight / 2.0)

        add(bubble: bubble)
        invalHook?(bubble)
        return bubble
    }

    /// Empty out the soup
    public func removeEverything() {
        removeLastBubbles(count: bubbles.count)
    }

    /// Move the bubble's location to a new place.
    public func move(bubble: Bubble, to newPosition: CGPoint) {
        undoManager.beginUndoGrouping()
        let oldPoint = bubble.position
        bubble.position = newPosition
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.move(bubble: bubble, to: oldPoint)
        }
        undoManager.endUndoGrouping()
        invalHook?(bubble)
        bubblesChangedHook?()
    }

    /// Given a point, find the first bubble that intersects it.
    /// Drawing happens front->back, so hit testing happens back->front
    public func hitTestBubble(at point: CGPoint) -> Bubble? {
        let bubble = bubbles.last(where: { $0.rect.contains(point) })
        return bubble
    }

    /// Given a rectangle, return all bubbles that intersect the rect.
    public func areaTestBubbles(intersecting rect: CGRect) -> [Bubble]? {
        let intersectingBubbles = bubbles.filter { $0.rect.intersects(rect) }
        let result = intersectingBubbles.count > 0 ? intersectingBubbles : nil
        return result
    }

    /// Calculate the rectangle that encloses all the bubbles, anchored at (0, 0)
    public var enclosingRect: CGRect {
        let union = bubbles.reduce(into: CGRect.zero) { union, bubble in
            union = union.union(bubble.rect)
        }
        return union
    }
    
    func connect(bubble: Bubble, to target: Bubble) {
        bubble.connect(to: target)
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.disconnect(bubble: bubble, from: target)
        }
    }

    func disconnect(bubble: Bubble, from target: Bubble) {
        bubble.disconnect(bubble: target)
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.connect(bubble: bubble, to: target)
        }
    }
    
    func connect(bubbles: [Bubble], to bubble: Bubble) {
        undoManager.beginUndoGrouping()
        bubbles.forEach { target in
            if !bubble.isConnectedTo(target) {
                connect(bubble: bubble, to: target)
            }
        }
        undoManager.endUndoGrouping()
    }

    func disconnect(bubbles: [Bubble], from bubble: Bubble) {
        undoManager.beginUndoGrouping()
        bubbles.forEach { target in
            if bubble.isConnectedTo(target) {
                disconnect(bubble: bubble, from: target)
            }
        }
        undoManager.endUndoGrouping()
    }

}

/// Helper Methods
extension BubbleSoup {
    /// Helper function for adding bubbles to the soup, has undo support
    internal func add(bubblesArray bubbles: [Bubble]) {
        undoManager.beginUndoGrouping()
        self.bubbles += bubbles
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.removeLastBubbles(count: bubbles.count)
        }
        undoManager.endUndoGrouping()
    }

    /// Helper function for removing bubbles from the soup, has undo support
    /// It's the flip-side of `add(bubblesArray:)`
    internal func removeLastBubbles(count: Int) {
        undoManager.beginUndoGrouping()
        let lastChunk = Array(self.bubbles.suffix(count))
        lastChunk.forEach { invalHook?($0) }
        bubbles.removeLast(count)
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.add(bubbles: lastChunk)
        }
        undoManager.endUndoGrouping()

    }

    /// Triggers undo. Mainly of use for tests. Presumably you're giving us the
    /// NSDocument UndoMangler.
    internal func undo() {
        undoManager.undoNestedGroup()
    }

    /// Triggers undo. Mainly of use for tests. Presumably you're giving us the
    /// NSDocument UndoMangler.
    internal func redo() {
        undoManager.redo()
    }

    /// Returns the largest bubble ID (so you can presumably create a new bubble)
    /// The IDs are not compact.
    internal func maxBubbleID() -> Int {
        var maxID = 0

        forEachBubble { bubble in
            maxID = max(maxID, bubble.ID)
        }
        return maxID
    }
}
