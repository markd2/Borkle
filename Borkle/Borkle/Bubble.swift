import Cocoa

class Bubble: Codable {
    struct FormattingStyle: OptionSet, Codable {
        let rawValue: Int
        static let bold          = FormattingStyle(rawValue: 1 << 0)
        static let italic        = FormattingStyle(rawValue: 1 << 1)
        static let strikethrough = FormattingStyle(rawValue: 1 << 2)
        static let underline     = FormattingStyle(rawValue: 1 << 3)
    }

    let ID: Int
    var text: String = "" {
        didSet {
            _effectiveHeight = nil
        }
    }
    
    struct FormattingOption: Codable, Equatable {
        let options: FormattingStyle
        let rangeStart: Int 
        let rangeLength: Int 
        
        init(options: FormattingStyle, rangeStart: Int, rangeLength: Int) {
            self.options = options
            self.rangeStart = rangeStart
            self.rangeLength = rangeLength
        }

        // concise version for tests.
        init(_ options: FormattingStyle, _ rangeStart: Int, _ rangeLength: Int) {
            self.options = options
            self.rangeStart = rangeStart
            self.rangeLength = rangeLength
        }
    }

    var formattingOptions: [FormattingOption] = []

    var position: CGPoint = .zero
    
    var width: CGFloat = 0 {
        didSet {
            _effectiveHeight = nil
        }
    }
    var connections = IndexSet()

    init(ID: Int, position: CGPoint? = nil, width: CGFloat? = nil) {
        self.ID = ID
        if let position = position { self.position = position }
        if let width = width { self.width = width }
    }

    var rect: CGRect {
        var rect = CGRect(x: position.x, y: position.y,
                          width: width, height: effectiveHeight)
        rect.size.height += 2 * Bubble.margin
        return rect
    }

    func isConnectedTo(_ bubble: Bubble) -> Bool {
        let connected = connections.contains(bubble.ID)
        return connected
    }

    func connect(to bubble: Bubble) {
        connections.insert(bubble.ID)
        bubble.connections.insert(ID)
        print("connections are \(connections)")
    }

    func disconnect(bubble: Bubble) {
        connections.remove(bubble.ID)
        bubble.connections.remove(ID)
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
