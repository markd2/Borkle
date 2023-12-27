import Cocoa

class DumbButton: NSView {
    var color: NSColor! = .orange

    override func draw(_ areaToDrawPlzKthx: CGRect) {
        color.set()
        bounds.fill()

        NSColor.black.set()
        bounds.frame()
    }

    // too lazy to figure out how to get responder chain method selectors to not 
    // generate a warning.
    @objc func colorBubble(_ sender: DumbButton) { }

    override func mouseUp(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil) as CGPoint

        if bounds.contains(viewLocation) {
            NSApp.sendAction(#selector(colorBubbles(_:)), to: nil, from: self)
        }
    }
}
