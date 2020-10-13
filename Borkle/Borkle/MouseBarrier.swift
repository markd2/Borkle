import Cocoa

class MouseBarrier: MouseHandler {
    private var support: MouseSupport

    let barrier: Barrier
    let initialPosition: CGFloat!
    
    var initialPoint: CGPoint!

    var prefersWindowCoordinates: Bool { return false }

    var affectedBubbles: [Bubble]?
    var affectedBarriers: [Barrier]?

    init(withSupport support: MouseSupport, barrier: Barrier) {
        self.support = support
        self.barrier = barrier
        self.initialPosition = barrier.horizontalPosition
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        initialPoint = point
        affectedBubbles = support.bubblesAffectedBy(barrier: barrier)
        affectedBarriers = support.barriersAffectedBy(barrier: barrier)
    }
    
    func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        if affectedBubbles == nil && affectedBarriers == nil { return }

        guard affectedBubbles?.count ?? 0 > 0 || affectedBarriers?.count ?? 0 > 0 else { return }
        let horizontalDelta = point.x - initialPoint.x
        let newOffset = initialPosition + horizontalDelta
        support.move(barrier: barrier, affectedBubbles: affectedBubbles, affectedBarriers: affectedBarriers, to: newOffset)
    }
    
    func finish(at: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
    }
}
