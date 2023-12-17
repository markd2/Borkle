import Cocoa

class MouseBarrier: MouseHandler {
    private var support: MouseSupport

    let barrier: Barrier
    let initialPosition: CGFloat!
    
    var initialPoint: CGPoint!

    var prefersWindowCoordinates: Bool { return false }

    var affectedBubbles: [Bubble.Identifier]?
    var affectedBarriers: [Barrier]?

    init(withSupport support: MouseSupport, barrier: Barrier) {
        self.support = support
        self.barrier = barrier
        self.initialPosition = barrier.horizontalPosition
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        initialPoint = point
        
        // option-drag to just move the selected barrier.
        // otherwise, move bubbles and barriers too.
        if modifierFlags.contains(.option) {
            affectedBubbles = nil
            affectedBarriers = nil
        } else {
            affectedBubbles = support.bubblesAffectedBy(barrier: barrier)
            affectedBarriers = support.barriersAffectedBy(barrier: barrier)
        }
    }
    
    func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        let horizontalDelta = point.x - initialPoint.x
        let newOffset = initialPosition + horizontalDelta
        support.move(barrier: barrier, affectedBubbles: affectedBubbles,
                     affectedBarriers: affectedBarriers, to: newOffset)
    }
    
    func finish(at: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
    }
}
