import Foundation

/// Mouse handler for clicks that start in space (blank canvas)
class MouseSpacer: MouseHandler {
    private var support: MouseSupport
    private var anchorPoint: CGPoint!
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    public func start(at point: CGPoint) {
        // this will need to go somewhere else when we support shift-dragging
        support.unselectAll()
        anchorPoint = point
    }

    public func move(to point: CGPoint) {
        let rect = CGRect(point1: point, point2: anchorPoint)
        support.drawMarquee(around: rect)

        support.unselectAll()
        let bubbles = support.areaTestBubbles(intersecting: rect)
        if let bubbles = bubbles {
            support.select(bubbles: bubbles)
        }
    }
    
    public func finish() {
    }
}


class MouseDoubleSpacer: MouseHandler {

    static let slopLimit: CGFloat = 3.0

    private var support: MouseSupport
    // cleared if a move happens, so don't create anything
    private var startPoint: CGPoint?
    
    init(withSupport support: MouseSupport) {
        self.support = support
    }

    public func start(at point: CGPoint) {
        // this will need to go somewhere else when we support shift-dragging
        support.unselectAll()
        startPoint = point
    }

    public func move(to point: CGPoint) {
        if let startPoint = startPoint {
            
            let delta = startPoint - point
            if abs(delta.x) > Self.slopLimit || abs(delta.y) > Self.slopLimit {
                // too far
                self.startPoint = nil
            }
        }
    }
    
    public func finish() {
        if let startPoint = startPoint {
            support.createNewBubble(at: startPoint)
        }
    }
}
