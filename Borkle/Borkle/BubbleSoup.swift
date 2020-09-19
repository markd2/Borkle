import Foundation


/// BubbleSoup - a class that matains the storage miasma of Borkle.
///
/// It holds the bubbles, lines, and provides an API for updating the contents of
/// the soup (with undo support)
class BubbleSoup {

    /// How many bubbles we have.
    public var bubbleCount: Int {
        return bubbles.count
    }

    /// Array storage of bubbles.  Might need to revisit this if array operations turn
    /// out to be annoying
    private var bubbles: [Bubble] = []

    /// Undo manager responsible for handling undo.  One will be provided if you don't
    /// give us one
    private let undoManager: UndoManager
    
    public init(undoManager: UndoManager? = nil) {
        self.undoManager = undoManager ?? UndoManager()
        undoManager?.groupsByEvent = false
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

}
