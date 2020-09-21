import Foundation

/// Mouse handler for clicks that start in space (blank canvas)

protocol MouseHandler {
    func start(at: CGPoint)
    func move(to: CGPoint)
    func finish()
}

protocol MouseSupport {
    func hitTestBubble(at: CGPoint) -> Bubble?
    func areaTestBubbles(in: CGRect) -> [Bubble]?
    func drawMarquee(around: CGRect)
}

class MouseSpacer: MouseHandler {
    private var support: MouseSupport
    private var anchorPoint: CGPoint!
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    public func start(at point: CGPoint) {
        anchorPoint = point
    }

    public func move(to point: CGPoint) {
        let rect = CGRect(point1: point, point2: anchorPoint)
        support.drawMarquee(around: rect)
    }
    
    public func finish() {
    }
}

