import Foundation


/// BubbleSoup - a class that matains the storage miasma of all of Borkle's bubbles
///
/// It holds the bubbles, ~lines~, and provides an API for updating the contents of
/// the soup (with undo support)
///
/// Many visual stuffs are moving to playfields - so things like locations / area-hit-rect
/// will live there.
///
/// Playfield bubble arrays are a subset of the bubbles have, most likely a proper
/// subset when the documents get bigger
///
class BubbleSoup {

    static let defaultWidth: CGFloat = 160
    static let defaultHeight: CGFloat = 8

    /// Something changed in the bubbles - maybe resize the canvas?
    typealias BubbleChangeHook = () -> Void
    private var bubblesChangedHooks: [BubbleChangeHook] = []
    func addChangeHook(_ hook: @escaping BubbleChangeHook) {
        bubblesChangedHooks.append(hook)
    }

    /// How many bubbles we have.
    public var bubbleCount: Int {
        return bubbles.count
    }

    /// Array storage of bubbles.  Might need to revisit this if array operations turn
    /// out to be annoying
    var bubbles: [Bubble] = []

    /// Iterate over each of the bubbles in some kind of order
    /// I'm not smart enough to return some kind of sequence/iterator thing.
    /// Because this is soup-styles, this is every bubble in use in the entire
    /// application.
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
    
    /// Looks up a bubble in the soup by its ID.  Returns nil if not found.
    public func bubble(byID: Int) -> Bubble? {
        let bubble = bubbles.first(where: { $0.ID == byID } )
        if bubble == nil {
            print("should we really be getting nil bubbles if we have a presumably good ID?")
            return nil
        }
        return bubble
    }

    private func sanityCheckAdd(bubbles: [Bubble]) {
        bubbles.forEach {
            if let _ = bubble(byID: $0.ID) {
                print("CONFLICT WITH ID \($0.ID)")
            }
        }
    }

    public func bubbleChanged(_ bubbleID: Bubble.Identifier) {
        bubblesChangedHooks.forEach { $0() }
    }

    /// Add the bubble to the soup.
    public func add(bubble: Bubble) {
        add(bubblesArray: [bubble])
        bubblesChangedHooks.forEach { $0() }
    }

    /// Add the bubbles to the soup.  There's no intrinsic order to the bubbles in the soup.
    /// (even though internally it is an array)
    public func add(bubbles: [Bubble]) {
        sanityCheckAdd(bubbles: bubbles)

        add(bubblesArray: bubbles)

        bubblesChangedHooks.forEach { $0() }
    }

    /// Remove a bunch of bubbles permanently.
    /// Playfields should only remove bubbles they're dealing with, and then
    /// inform the soup that it got rid of the bubbles.
    /// TODO: some kind of reference counting or something for bubbles.  maybe tags.  12/15/2023
    public func remove(bubbles: [Bubble]) {
        undoManager.beginUndoGrouping()

        let filtered = self.bubbles.filter { return !bubbles.contains($0) }
        self.bubbles = filtered

        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.add(bubbles: bubbles)
        }
        undoManager.endUndoGrouping()
        bubblesChangedHooks.forEach { $0() }
    }

    // Make a new bubble.  ID is max + 1 of existing bubbles.
    public func createNewBubble() -> Bubble {
        let maxID = maxBubbleID()
        let bubble = Bubble(ID: maxID + 1)

        add(bubble: bubble)
        return bubble
    }

    /// Empty out the soup
    public func removeEverything() {
        removeLastBubbles(count: bubbles.count)
        bubblesChangedHooks.forEach { $0() }
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

    /// Returns the largest bubble ID (so you can presumably create a new bubble)
    /// The IDs are not compact.
    internal func maxBubbleID() -> Int {
        var maxID = 0

        maxID = bubbles.reduce(into: 0) { maxval, bubble in
            maxval = max(maxval, bubble.ID)
        }
        return maxID
    }
}
