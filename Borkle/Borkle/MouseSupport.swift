import Foundation

protocol MouseHandler {
    func start(at: CGPoint)
    func move(to: CGPoint)
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
    func move(barrier: Barrier, affectedBubbles: [Bubble]?, to horizontalPosition: CGFloat)
}


extension MouseHandler {
    var prefersWindowCoordinates: Bool { return false }
}
