import Cocoa

/// Mouse handler for clicks that start in space (blank canvas)
class MouseSpacer: MouseHandler {
    private var support: MouseSupport
    private var selection: Selection
    private var anchorPoint: CGPoint!
    private var originalSelection: [Bubble] = []
    
    
    init(withSupport support: MouseSupport, selection: Selection) {
        self.support = support
        self.selection = selection
    }

    /// !!! BORK - behavior is
    /// !!! if shift is down, preserve initial selection but do the exact same
    /// !!! stuff as before, just unioning in the prior selection.
    // !!! what's here now is kind of sticky
    public func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        // this will need to go somewhere else when we support shift-dragging

        if modifierFlags.contains(.shift) {
            originalSelection = selection.selectedBubbles
        } else {
            support.unselectAll()
            originalSelection = []
        }

        anchorPoint = point
    }

    public func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        let rect = CGRect(point1: point, point2: anchorPoint)
        support.drawMarquee(around: rect)

        support.unselectAll()
        var effectiveBubbles = originalSelection

        let bubbles = support.areaTestBubbles(intersecting: rect)
        if let bubbles = bubbles {
            effectiveBubbles += bubbles
        }
        support.select(bubbles: effectiveBubbles)

    }
    
    public func finish(at: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
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

    public func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        // this will need to go somewhere else when we support shift-dragging
        support.unselectAll()
        startPoint = point
    }

    public func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        if let startPoint = startPoint {
            
            let delta = startPoint - point
            if abs(delta.x) > Self.slopLimit || abs(delta.y) > Self.slopLimit {
                // too far
                self.startPoint = nil
            }
        }
    }
    
    public func finish(at: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        if let startPoint = startPoint {
            support.createNewBubble(at: startPoint)
        }
    }
}
