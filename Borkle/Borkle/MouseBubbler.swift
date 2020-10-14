import Cocoa

class MouseBubbler: MouseHandler {
    private var support: MouseSupport

    private var selectedBubbles: Selection

    var prefersWindowCoordinates: Bool { return false }

    var initialDragPoint: CGPoint!
    var originalBubblePositions: [Bubble: CGPoint]!
    var originalBubblePosition: CGPoint!
    var hitBubble: Bubble?

    init(withSupport support: MouseSupport, selectedBubbles: Selection) {
        self.support = support
        self.selectedBubbles = selectedBubbles
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        initialDragPoint = point

        let addToSelection = modifierFlags.contains(.shift)
        let toggleSelection = modifierFlags.contains(.command)
        
        guard let hitBubble = support.hitTestBubble(at: point) else {
            return
        }
        
        self.hitBubble = hitBubble

        if addToSelection {
            selectedBubbles.select(bubble: hitBubble)
        } else if toggleSelection {
            selectedBubbles.toggle(bubble: hitBubble)
        } else {
            if selectedBubbles.isSelected(bubble: hitBubble) {
                // dragging existing selection
            }  else {
                // No other modifiers, so deselect all and drag 
                selectedBubbles.unselectAll()
                selectedBubbles.select(bubble: hitBubble)
            }
        }

        originalBubblePositions = selectedBubbles.selectedBubbles.reduce(into: [:]) { dict, bubble in
            dict[bubble] = bubble.position
        }

        originalBubblePositions = [:]
        selectedBubbles.forEachBubble {
            originalBubblePositions[$0] = $0.position
        }

        originalBubblePosition = hitBubble.position
    }

    func drag(to point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        guard selectedBubbles.bubbleCount > 0 else { return }

        let delta = initialDragPoint - point
        selectedBubbles.forEachBubble { bubble in
            guard let originalPosition = originalBubblePositions[bubble] else {
                Swift.print("unexpectedly missing original bubble position")
                return
            }

            support.move(bubble: bubble, to: originalPosition + delta)
        }
    }

    func finish(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        guard let hitBubble = hitBubble else {
            return
        }
        
        let rect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        var hitBubbles = support.areaTestBubbles(intersecting: rect) ?? []
        hitBubbles.removeAll { $0.ID == hitBubble.ID }

        if hitBubbles.count >= 1, let targetBubble = hitBubbles.last  {
            let bubbles = selectedBubbles.selectedBubbles

            // if mouse-up inside of a bubble, connect or disconnect.
            if hitBubble.isConnectedTo(targetBubble) {
                print("DISCONNECT")
                support.disconnect(bubbles: bubbles, from: targetBubble)
            } else {
                support.connect(bubbles: bubbles, to: targetBubble)
            }

            originalBubblePositions.forEach { bubble, position in
                support.move(bubble: bubble, to: position)
            }
            
        } else {
            print("MOOOOOOOVE")
            // otherwise, do nothing and accept the movex
        }
    }
}
