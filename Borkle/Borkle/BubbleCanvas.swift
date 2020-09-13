import Cocoa

class BubbleCanvas: NSView {
    override var isFlipped: Bool { return true }
    var bubbles: [Bubble] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ areaToDrawPlzKthx: CGRect) {
        NSColor.white.set()
        bounds.fill()

        bubbles.forEach { $0.render() }
        
        NSColor.black.set()
        bounds.frame()
    }
}

extension Bubble {
    func render() {
        let rect = CGRect(x: position.x, y: position.y, width: width, height: 20)
        NSColor.black.set()
        rect.frame()

        let nsstring = "\(ID)-\(text)" as NSString
        nsstring.draw(in: rect, withAttributes: nil)
    }
}
