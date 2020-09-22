import Cocoa

class Barrier: Codable {
    var label = "Barrier"
    var horizontalPosition: CGFloat
    var width: CGFloat = 6.0

    init(label: String, horizontalPosition: CGFloat, width: CGFloat) {
        self.label = label
        self.horizontalPosition = horizontalPosition
        self.width = width
    }

    var lineRect: CGRect {
        let rect = CGRect(x: horizontalPosition - width / 2.0, y: 0,
                          width: width, height: .greatestFiniteMagnitude)
        return rect
    }

    func render(in area: CGRect) {
        var effectiveRect = area.intersection(lineRect)
        effectiveRect.size.height -= 20

        let text = label as NSString
        let textSize = text.size(withAttributes: nil)
        let textRect = CGRect(x: effectiveRect.midX - textSize.width / 2.0, y: effectiveRect.maxY,
            width: textSize.width, height: textSize.height)
        
        NSColor.orange.set()
        effectiveRect.frame()

        text.draw(in: textRect)
    }
}
