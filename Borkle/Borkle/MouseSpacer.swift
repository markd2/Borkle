import Foundation

/// Mouse handler for clicks that start in space (blank canvas)

protocol MouseHandler {
    func start(at: CGPoint)
    func move(to: CGPoint)
    func finish()

}

class MouseSpacer: MouseHandler {
    public func start(at point: CGPoint) {
        print("Start \(point)")
    }

    public func move(to point: CGPoint) {
        print("Move \(point)")
    }
    
    public func finish() {
        print("finish")
    }
}

