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
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    public func start(at point: CGPoint) {
        print("Start \(point)")
        let rect = CGRect(at: point, width: 20, height: 30)
        support.drawMarquee(around: rect)
    }

    public func move(to point: CGPoint) {
        print("Move \(point)")
        let rect = CGRect(at: point, width: 20, height: 30)
        support.drawMarquee(around: rect)
    }
    
    public func finish() {
        print("finish")
    }
}

