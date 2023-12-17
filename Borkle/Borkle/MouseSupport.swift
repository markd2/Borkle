import Cocoa

protocol MouseHandler {
    func start(at: CGPoint, modifierFlags: NSEvent.ModifierFlags)
    func drag(to: CGPoint, modifierFlags: NSEvent.ModifierFlags)
    func finish(at: CGPoint, modifierFlags: NSEvent.ModifierFlags)

    var prefersWindowCoordinates: Bool { get }
}

protocol MouseSupport {
    var owningPlayfield: Playfield { get }
    func hitTestBubble(at: CGPoint) -> Bubble.Identifier?
    func areaTestBubbles(intersecting: CGRect) -> [Bubble.Identifier]?
    func drawMarquee(around: CGRect)

    func unselectAll()
    func select(bubbles: [Bubble.Identifier])
    
    // set to a selection to make them render less opaque, like for dragging.
    // set nil to revert to everyone fully opaque
    func makeTransparent(_ selection: Selection?)

    var currentScrollOffset: CGPoint { get }
    func scroll(to: CGPoint)

    func createNewBubble(at point: CGPoint, showEditor: Bool) -> Bubble.Identifier

    func connect(bubbles: [Bubble.Identifier], to: Bubble.Identifier)
    func disconnect(bubbles: [Bubble.Identifier], from: Bubble.Identifier)
    func highlightAsDropTarget(bubble: Bubble.Identifier?) // nil to remove highlight

    func bubblesAffectedBy(barrier: Barrier) -> [Bubble.Identifier]?
    func barriersAffectedBy(barrier: Barrier) -> [Barrier]?
    func move(bubble: Bubble.Identifier, to: CGPoint)
    func move(barrier: Barrier, 
              affectedBubbles: [Bubble.Identifier]?, affectedBarriers: [Barrier]?,
              to horizontalPosition: CGFloat)
}


extension MouseHandler {
    var prefersWindowCoordinates: Bool { return false }
}
