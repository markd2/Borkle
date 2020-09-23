import Foundation

class MouseBarrier: MouseHandler {
    private var support: MouseSupport

    let barrier: Barrier
    let initialPosition: CGFloat!
    
    var initialPoint: CGPoint!

    var prefersWindowCoordinates: Bool { return false }

    var affectedBubbles: [Bubble]?

    init(withSupport support: MouseSupport, barrier: Barrier) {
        self.support = support
        self.barrier = barrier
        self.initialPosition = barrier.horizontalPosition
    }

    func start(at point: CGPoint) {
        initialPoint = point
        affectedBubbles = support.bubblesAffectedBy(barrier: barrier)
    }
    
    func move(to point: CGPoint) {
        let horizontalDelta = point.x - initialPoint.x
        let newOffset = initialPosition + horizontalDelta
        support.move(barrier: barrier, affectedBubbles: affectedBubbles, to: newOffset)
    }
    
    func finish() {
    }
}
