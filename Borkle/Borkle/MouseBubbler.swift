import Foundation

class MouseBubbler: MouseHandler {
    private var support: MouseSupport

    var prefersWindowCoordinates: Bool { return false }

    init(withSupport support: MouseSupport) {
        self.support = support
    }

    func start(at point: CGPoint) {
    }

    func move(to point: CGPoint) {
    }

    func finish() {
    }
}
