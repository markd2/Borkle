import Foundation


class BubbleSoup {
    private var bubbles: [Bubble] = []
    private let undoManager: UndoManager
    
    public init(undoManager: UndoManager? = nil) {
        self.undoManager = undoManager ?? UndoManager()
        undoManager?.groupsByEvent = false
    }

    public func add(bubbles: [Bubble]) {
        add(bubblesArray: bubbles)
    }

    internal func add(bubblesArray bubbles: [Bubble]) {
        undoManager.beginUndoGrouping()
        self.bubbles += bubbles
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.removeLastBubbles(count: bubbles.count)
        }
        undoManager.endUndoGrouping()
    }

    internal func removeLastBubbles(count: Int) {
        undoManager.beginUndoGrouping()
        let lastChunk = Array(self.bubbles.suffix(count))
        bubbles.removeLast(count)
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.add(bubbles: lastChunk)
        }
        undoManager.endUndoGrouping()
    }

    public var bubbleCount: Int {
        return bubbles.count
    }

    internal func undo() {
        undoManager.undoNestedGroup()
    }
    
}
