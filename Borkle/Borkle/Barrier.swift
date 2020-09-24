import Cocoa

class Barrier: Codable {
    let ID: Int

    var label = "Barrier"
    var horizontalPosition: CGFloat
    var width: CGFloat = 6.0

    init(ID: Int) {
        self.ID = ID
        self.label = "label"
        self.horizontalPosition = 0.0
        self.width = 0.0
    }

    init(ID: Int, label: String, horizontalPosition: CGFloat, width: CGFloat) {
        self.ID = ID
        self.label = label
        self.horizontalPosition = horizontalPosition
        self.width = width
    }

    var lineRect: CGRect {
        let rect = CGRect(x: horizontalPosition - width / 2.0, y: 0,
                          width: width, height: .greatestFiniteMagnitude)
        return rect
    }

    func hitTest(point: CGPoint, area: CGRect) -> Bool {
        let (drawRect, textRect) = rects(in: area)
        
        if drawRect.contains(point) || textRect.contains(point) {
            return true
        }
        return false
    }

    func rects(in area: CGRect) -> (CGRect, CGRect) { // line rect, text rect
        var drawRect = effectiveRect(in: area)
        drawRect.size.height -= 20

        let text = label as NSString
        let textSize = text.size(withAttributes: nil)
        let textRect = CGRect(x: drawRect.midX - textSize.width / 2.0, y: drawRect.maxY,
            width: textSize.width, height: textSize.height)

        return (drawRect, textRect)
    }

    func effectiveRect(in area: CGRect) -> CGRect {
        let effectiveRect = area.intersection(lineRect)
        return effectiveRect
    }

    func render(in area: CGRect) {
        let (drawRect, textRect) = rects(in: area)

        NSColor.orange.set()
        drawRect.frame()

        let text = label as NSString
        text.draw(in: textRect)
    }
}


extension Barrier: Equatable {
    static func == (thing1: Barrier, thing2: Barrier) -> Bool {
        return thing1.ID == thing2.ID
    }
}

extension Barrier: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }
}
