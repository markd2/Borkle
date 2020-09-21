import Foundation

/// Mouse handler for grab-hand scrolling
class MouseGrabHand: MouseHandler {
    private var support: MouseSupport

    var initialDragPoint: CGPoint!
    var scrollOrigin: CGPoint!

    var prefersWindowCoordinates: Bool { return true }
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    func start(at point: CGPoint) {
        initialDragPoint = point
        scrollOrigin = support.currentScrollOffset
    }
    
    func move(to point: CGPoint) {
        let rawDelta = point - initialDragPoint
        let flippedX = CGPoint(x: rawDelta.x, y: -rawDelta.y)
        let newOrigin = scrollOrigin + flippedX

        support.scroll(to: newOrigin)
    }
    
    func finish() {
    }
}
