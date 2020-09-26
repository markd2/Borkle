import Cocoa

class MouseBubbler: MouseHandler {
    private var support: MouseSupport

    private var selectedBubbles: Selection

    var prefersWindowCoordinates: Bool { return false }

    var initialDragPoint: CGPoint!
    var originalBubblePositions: [Bubble: CGPoint]!
    var originalBubblePosition: CGPoint!

    init(withSupport support: MouseSupport, selectedBubbles: Selection) {
        self.support = support
        self.selectedBubbles = selectedBubbles
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        let addToSelection = modifierFlags.contains(.shift)
        let toggleSelection = modifierFlags.contains(.command)

        let hitBubble = support.hitTestBubble(at: point)

        if addToSelection {
            if let hitBubble = hitBubble {
                selectedBubbles.select(bubble: hitBubble)
            }
        } else if toggleSelection {
            if let hitBubble = hitBubble {
                selectedBubbles.toggle(bubble: hitBubble)
            }
        } else {
            
            if let hitBubble = hitBubble {
                if selectedBubbles.isSelected(bubble: hitBubble) {
                    // dragging selection
                }  else {
                    // No other modifiers, so deselect all and drag
                    selectedBubbles.unselectAll()
                }

            } else {
                // !!! Probably should never get here, the spacer would get
                // !!! here.
                // bubble is nil, so a click into open space, so deselect everything
                print("SNORGLE OOPS BORK FLONGWAFFLE")
            }
        }

        // !!! still kind of split between canvas and here with bubble selection
        // !!! and stuff

        initialDragPoint = point

        if let hitBubble = hitBubble {
            if selectedBubbles.isSelected(bubble: hitBubble) {
                // bubble already selected, so it's a drag of existing selection
            } else {
                // it's a fresh selection, no modifiers, could be a click-and-drag in one gesture
                // !!! scapple has click-drag 
//                selectedBubbles.unselectAll()

                // if we toggled a selection, don't select
                if !toggleSelection {
                    selectedBubbles.select(bubble: hitBubble)
                }
                initialDragPoint = point
            }
        }

        // !!! Probably don't need to filter the _entire_ soup for this.
        // !!! also, use reduce.
        originalBubblePositions = [:]
        selectedBubbles.forEachBubble {
            originalBubblePositions[$0] = $0.position
        }

        // we have a selected bubble. Drag it around.
        if let bubble = hitBubble {
            originalBubblePosition = bubble.position
        }
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

    func finish(modifierFlags: NSEvent.ModifierFlags) {
    }
}
