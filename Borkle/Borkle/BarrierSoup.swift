import Foundation

class BarrierSoup {
    /// Hook that's called when a barrier position changes, so it can be invalidated
    var invalHook: ((Barrier) -> Void)?

    /// How many barriers we have.
    public var barrierCount: Int {
        return barriers.count
    }

    /// Something changed in the barriers - maybe resize the canvas?
    var barriersChangedHook: (() -> Void)?

    /// Array storage of barriers.  Might need to revisit this if array operations turn
    /// out to be annoying
    private var barriers: [Barrier] = []

    /// Iterate over each of the barriers in some kind of order
    /// I'm not smart enough to return some kind of sequence/iterator thing
    public func forEachBarrier(_ iterator: (Barrier) -> Void) {
        barriers.forEach { iterator($0) }
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
    public func barrier(byID: Int) -> Barrier? {
        let barrier = barriers.first(where: { $0.ID == byID } )
        return barrier
    }

    /// Add the barriers to the soup.  There's no intrinsic order to the barriers in the soup.
    /// (even though internally it is an array)
    public func add(barriers: [Barrier]) {
        add(barriersArray: barriers)

        barriers.forEach { invalHook?($0) }
    }

    /// Empty out the soup
    public func removeEverything() {
        removeLastBarriers(count: barriers.count)
    }


    public func move(barrier: Barrier, to newHorizontalPosition: CGFloat) {
        undoManager.beginUndoGrouping()

        let oldPosition = barrier.horizontalPosition
        barrier.horizontalPosition = newHorizontalPosition

        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.move(barrier: barrier, to: oldPosition)
        }
        barriersChangedHook?()
        invalHook?(barrier)
        undoManager.endUndoGrouping()
    }

    /// Given a rectangle, return all barriers that intersect the rect.
    public func areaTestBarriers(toTheRightOf horizontalPosition: CGFloat) -> [Barrier]? {
        let intersectingBarriers = barriers.filter { $0.horizontalPosition > horizontalPosition }
        let result = intersectingBarriers.count > 0 ? intersectingBarriers : nil
        return result
    }
}


extension BarrierSoup {
    /// Helper function for adding barriers to the soup, has undo support
    internal func add(barriersArray barriers: [Barrier]) {
        undoManager.beginUndoGrouping()
        self.barriers += barriers
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.removeLastBarriers(count: barriers.count)
        }
        undoManager.endUndoGrouping()
    }

    /// Helper function for removing barriers from the soup, has undo support
    /// It's the flip-side of `add(barriersArray:)`
    internal func removeLastBarriers(count: Int) {
        undoManager.beginUndoGrouping()
        let lastChunk = Array(self.barriers.suffix(count))
        lastChunk.forEach { invalHook?($0) }
        barriers.removeLast(count)
        undoManager.registerUndo(withTarget: self) { selfTarget in
            self.add(barriers: lastChunk)
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


