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
}


extension MouseHandler {
    var prefersWindowCoordinates: Bool { return false }
}
