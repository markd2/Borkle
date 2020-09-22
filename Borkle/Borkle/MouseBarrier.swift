import Foundation

class MouseBarrier: MouseHandler {
    private var support: MouseSupport

    var prefersWindowCoordinates: Bool { return false }

    init(withSupport support: MouseSupport) {
        self.support = support
    }

    func start(at point: CGPoint) {
        print("START")
    }
    
    func move(to point: CGPoint) {
        print("MOVE")
    }
    
    func finish() {
        print("FINNISH")
    }
}
