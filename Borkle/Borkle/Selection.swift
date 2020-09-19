import Foundation

class Selection {
    var selection = Set<Bubble>()

    var bubbleCount: Int {
        return selection.count
    }
    
    func select(bubble: Bubble) {
        select(bubbles: [bubble])
    }
    
    func select(bubbles: [Bubble]) {
        let set = Set(bubbles)
        selection.formUnion(set)
    }

    func isSelected(bubble: Bubble) -> Bool {
        let selected = selection.contains(bubble)
        return selected
    }
    
    func toggle(bubble: Bubble) {
        if isSelected(bubble: bubble) {
            deselect(bubble: bubble)
        } else {
            select(bubble: bubble)
        }
    }
    
    func unselectAll() {
        selection.removeAll()
    }
    
    func deselect(bubble: Bubble) {
        selection.remove(bubble)
    }
}

