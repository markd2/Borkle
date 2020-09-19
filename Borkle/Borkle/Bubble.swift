import Cocoa

class Bubble: Codable {
    let ID: Int
    var text: String = "" {
        didSet {
            _effectiveHeight = nil
        }
    }
    var position: CGPoint = .zero
    
    var width: CGFloat = 0 {
        didSet {
            _effectiveHeight = nil
        }
    }
    var connections = IndexSet()

    init(ID: Int) {
        self.ID = ID
    }

    var rect: CGRect {
        var rect = CGRect(x: position.x, y: position.y,
                          width: width, height: effectiveHeight)
        rect.size.height += 2 * Bubble.margin
        return rect
    }

    // optional as hacky way to opt out of Codable for this.
    static let margin: CGFloat = 3.0

    var _effectiveHeight: CGFloat?
    var effectiveHeight: CGFloat {
        if let height = _effectiveHeight {
            return height
        } else {
            _effectiveHeight = heightForStringDrawing()
            return _effectiveHeight!
        }
    }
}

extension Bubble: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Bubble(ID: \(ID), text: '\(text)'  at: \(position)  width: \(width))"
    }
}

extension Bubble: Equatable {
    static func == (thing1: Bubble, thing2: Bubble) -> Bool {
        return thing1.ID == thing2.ID
    }
}

extension Bubble: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }
}

extension Bubble {
    func heightForStringDrawing() -> CGFloat {
        let textStorage = NSTextStorage.init(string: text, attributes: nil)
        let insetWidth = width - (Bubble.margin * 2)
        let size = CGSize(width: insetWidth, height: .infinity)
        let textContainer = NSTextContainer.init(containerSize: size)
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // maybe need to add the font attribute textStorage.add
        textContainer.lineFragmentPadding = 0.0
        
        _ = layoutManager.glyphRange(for: textContainer)
        let height = layoutManager.usedRect(for: textContainer).height
        return height
    }
}
