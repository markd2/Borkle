import Cocoa

protocol MouseHandler {
    func start(at: CGPoint, modifierFlags: NSEvent.ModifierFlags)
    func drag(to: CGPoint)
    func finish()

    var prefersWindowCoordinates: Bool { get }
}

protocol MouseSupport {
    func hitTestBubble(at: CGPoint) -> Bubble?
    func areaTestBubbles(intersecting: CGRect) -> [Bubble]?
    func drawMarquee(around: CGRect)

    func unselectAll()
    func select(bubbles: [Bubble])

    var currentScrollOffset: CGPoint { get }
    func scroll(to: CGPoint)

    func createNewBubble(at: CGPoint)

    func bubblesAffectedBy(barrier: Barrier) -> [Bubble]?
    func barriersAffectedBy(barrier: Barrier) -> [Barrier]?
    func move(bubble: Bubble, to: CGPoint)
    func move(barrier: Barrier, 
              affectedBubbles: [Bubble]?, affectedBarriers: [Barrier]?,
              to horizontalPosition: CGFloat)
}


extension MouseHandler {
    var prefersWindowCoordinates: Bool { return false }
}
