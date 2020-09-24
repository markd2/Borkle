import Cocoa

class MouseBubbler: MouseHandler {
    private var support: MouseSupport

    private var bubbleSoup: BubbleSoup
    private var selectedBubbles: Selection

    var prefersWindowCoordinates: Bool { return false }

    var initialDragPoint: CGPoint!
    var originalBubblePositions: [Bubble: CGPoint]!
    var originalBubblePosition: CGPoint!

    init(withSupport support: MouseSupport, 
         bubbleSoup: BubbleSoup, selectedBubbles: Selection) {
        self.support = support
        self.bubbleSoup = bubbleSoup
        self.selectedBubbles = selectedBubbles
    }

    func start(at point: CGPoint, modifierFlags: NSEvent.ModifierFlags) {
        // !!! still kind of split between canvas and here with bubble selection
        // !!! and stuff
        let hitBubble = support.hitTestBubble(at: point)

        initialDragPoint = point

        if let hitBubble = hitBubble {
            if selectedBubbles.isSelected(bubble: hitBubble) {
                // bubble already selected, so it's a drag of existing selection
            } else {
                // it's a fresh selection, no modifiers, could be a click-and-drag in one gesture
                // !!! scapple has click-drag 
                selectedBubbles.unselectAll()
                selectedBubbles.select(bubble: hitBubble)
                initialDragPoint = point
            }
        }

        // !!! Probably don't need to filter the _entire_ soup for this.
        bubbleSoup.forEachBubble {
            originalBubblePositions[$0] = $0.position
        }

        // we have a selected bubble. Drag it around.
        if let bubble = hitBubble {
            originalBubblePosition = bubble.position
        }
    }

    func drag(to point: CGPoint) {
    }

    func finish() {
    }
}
