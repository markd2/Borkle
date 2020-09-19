import Foundation

class Selection {
    private var selection = Set<Bubble>()
    var invalHook: ((Bubble) -> Void)?

    /// Iterate over each of the bubbles in some kind of order
    /// I'm not smart enough to return some kind of sequence/iterator thing
    public func forEachBubble(_ iterator: (Bubble) -> Void) {
        selection.forEach { iterator($0) }
    }

    public var bubbleCount: Int {
        return selection.count
    }
    
    public func select(bubble: Bubble) {
        select(bubbles: [bubble])
    }
    
    public func select(bubbles: [Bubble]) {
        let set = Set(bubbles)

        // only inval hook changes.
        let changed = Set(bubbles).subtracting(selection)

        selection.formUnion(set)

        changed.forEach { invalHook?($0) }
    }

    public func isSelected(bubble: Bubble) -> Bool {
        let selected = selection.contains(bubble)
        return selected
    }
    
    public func toggle(bubble: Bubble) {
        if isSelected(bubble: bubble) {
            deselect(bubble: bubble)
        } else {
            select(bubble: bubble)
        }
    }
    
    public func unselectAll() {
        selection.forEach { invalHook?($0) }
        selection.removeAll()
    }
    
    public func deselect(bubble: Bubble) {
        selection.remove(bubble)
        invalHook?(bubble)
    }
}

