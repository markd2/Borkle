import Cocoa

/// Mouse handler for grab-hand scrolling
class MouseGrabHand: MouseHandler {
    private var support: MouseSupport

    var initialDragPoint: CGPoint!
    var scrollOrigin: CGPoint!

    var prefersWindowCoordinates: Bool { return true }
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        initialDragPoint = point
        scrollOrigin = support.currentScrollOffset
    }
    
    func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        let rawDelta = point - initialDragPoint
        let flippedX = CGPoint(x: rawDelta.x, y: -rawDelta.y)
        let newOrigin = scrollOrigin + flippedX

        support.scroll(to: newOrigin)
    }
    
    func finish(modifierFlags: NSEvent.ModifierFlags) {
    }
}
