import Cocoa

public class Bubble: Codable {
    static let defaultFontName = "Helvetica"
    static let defaultFontSize: CGFloat = 12.0
    
    public struct FormattingStyle: OptionSet, Codable {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public let rawValue: Int
        static public let bold          = FormattingStyle(rawValue: 1 << 0)
        static public let italic        = FormattingStyle(rawValue: 1 << 1)
        static public let strikethrough = FormattingStyle(rawValue: 1 << 2)
        static public let underline     = FormattingStyle(rawValue: 1 << 3)
    }

    public var ID: Int
    public var text: String = "" {
        didSet {
            _effectiveHeight = nil
        }
    }

    public struct RGB: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        public init(red: CGFloat, green: CGFloat, blue: CGFloat) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        public init(string: String?) {
            guard let string = string else {
                // no string, be obnoxious green
                red = 0.0; green = 1.0; blue = 0.0
                return
            }

            let chunks: [CGFloat] = string
                .components(separatedBy: " ")
                .compactMap { CGFloat($0) }

            guard chunks.count >= 3 else {
                // not enough chunkage, be obnoxious green
                red = 0.0; green = 1.0; blue = 0.0
                return
            }
            red = chunks[0]
            green = chunks[1]
            blue = chunks[2]
        }
    }

    public var fillColorRGB: RGB?
    public var fillColor: NSColor? {
        get {
            guard let rgb = fillColorRGB else { return nil }
            return NSColor.colorFromRGB(rgb)
        }
        set(newColor) {
            if let newColor = newColor {
                fillColorRGB = newColor.rgbColor()
            } else {
                fillColorRGB = nil
            }
        }
    }
    public var borderColorRGB: RGB?
    public var borderColor: NSColor? {
        guard let rgb = borderColorRGB else { return nil }
        return NSColor.colorFromRGB(rgb)
    }
    public var borderThickness: Int?

    // Offsets ID values by a fixed amount
    // useful for importing so that imported stuff avoids clobbering existing bubbles.
    public func offset(by fixedAmount: Int) {
        ID += fixedAmount
        let renumberedConnections = connections.reduce(into: IndexSet()) { result, integer in
            result.insert(integer + fixedAmount)
        }
        connections = renumberedConnections
    }

    public func gronkulateAttributedString(_ attr: NSAttributedString) {
        formattingOptions = []

        let totalRange = NSMakeRange(0, attr.length)

        attr.enumerateAttributes(in: totalRange, options: []) { (attributes: [NSAttributedString.Key : Any], range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
            if let font = attributes[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits

                if traits.contains(.italic) && traits.contains(.bold) {
                    let foption = FormattingOption([.bold, .italic], range: range)
                    formattingOptions.append(foption)

                } else if traits.contains(.italic) {
                    let foption = FormattingOption([.italic], range: range)
                    formattingOptions.append(foption)
                    
                } else if traits.contains(.bold) {
                    let foption = FormattingOption([.bold], range: range)
                    formattingOptions.append(foption)
                }
            }
                
            if let _ = attributes[.strikethroughStyle] {
                let foption = FormattingOption([.strikethrough], range: range)
                formattingOptions.append(foption)
            }

            if let _ = attributes[.underlineStyle] {
                let foption = FormattingOption([.underline], range: range)
                formattingOptions.append(foption)
            }
        }
    }

    public var attributedString: NSAttributedString {
        let string = NSMutableAttributedString(string: text)

        let font = NSFont(name: Bubble.defaultFontName, size: Bubble.defaultFontSize)!
        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.bold)
        let boldFont = NSFont(descriptor: boldDescriptor, size: Bubble.defaultFontSize)!
        let italicDescriptor = font.fontDescriptor.withSymbolicTraits(.italic)
        let italicFont = NSFont(descriptor: italicDescriptor, size: Bubble.defaultFontSize)!
        let boldItalicDescriptor = font.fontDescriptor.withSymbolicTraits([.italic, .bold])
        let boldItalicFont = NSFont(descriptor: boldItalicDescriptor, size: Bubble.defaultFontSize)!

        formattingOptions.forEach { option in
            if option.options.contains(.bold) && option.options.contains(.italic) {
                string.addAttribute(.font,
                                    value: boldItalicFont,
                                    range: option.nsrange)
                
            } else if option.options.contains(.bold) {
                string.addAttribute(.font,
                                    value: boldFont,
                                    range: option.nsrange)
                
            } else if option.options.contains(.italic) {
                string.addAttribute(.font,
                                    value: italicFont,
                                    range: option.nsrange)
                
            }
            if option.options.contains(.strikethrough) {
                string.addAttribute(.strikethroughStyle,
                                    value: NSUnderlineStyle.single.rawValue,
                                    range: option.nsrange)
            }
            if option.options.contains(.underline) {
                string.addAttribute(.underlineStyle,
                                    value: NSUnderlineStyle.single.rawValue,
                                    range: option.nsrange)
            }
        }
        return string
    }

    public struct FormattingOption: Codable, Equatable {
        let options: FormattingStyle
        let rangeStart: Int 
        let rangeLength: Int 

        var nsrange: NSRange {
            NSRange(location: rangeStart, length: rangeLength)
        }
        
        public init(options: FormattingStyle, rangeStart: Int, rangeLength: Int) {
            self.options = options
            self.rangeStart = rangeStart
            self.rangeLength = rangeLength
        }

        // concise version for tests.
        public init(_ options: FormattingStyle, _ rangeStart: Int, _ rangeLength: Int) {
            self.options = options
            self.rangeStart = rangeStart
            self.rangeLength = rangeLength
        }

        public init(_ options: FormattingStyle, range: NSRange) {
            self.options = options
            self.rangeStart = range.location
            self.rangeLength = range.length
        }
    }

    public var formattingOptions: [FormattingOption] = []

    public var position: CGPoint = .zero
    
    public var width: CGFloat = 0 {
        didSet {
            _effectiveHeight = nil
        }
    }
    public var connections = IndexSet()

    public func forEachConnection(_ iterator: (Int) -> Void) {
        connections.forEach { iterator($0) }
    }

    public init(ID: Int, position: CGPoint? = nil, width: CGFloat? = nil) {
        self.ID = ID
        if let position = position { self.position = position }
        if let width = width { self.width = width }
    }

    public var rect: CGRect {
        var rect = CGRect(x: position.x, y: position.y,
                          width: width, height: effectiveHeight)
        rect.size.height += 2 * Bubble.margin
        return rect
    }

    public func isConnectedTo(_ bubble: Bubble) -> Bool {
        let connected = connections.contains(bubble.ID)
        return connected
    }

    public func connect(to bubble: Bubble) {
        connections.insert(bubble.ID)
        bubble.connections.insert(ID)
        print("connections are \(connections)")
    }

    public func disconnect(bubble: Bubble) {
        connections.remove(bubble.ID)
        bubble.connections.remove(ID)
    }

    // optional as hacky way to opt out of Codable for this.
    static public let margin: CGFloat = 3.0

    var _effectiveHeight: CGFloat?
    public var effectiveHeight: CGFloat {
        if let height = _effectiveHeight {
            return height
        } else {
            _effectiveHeight = heightForStringDrawing()
            return _effectiveHeight!
        }
    }
}

extension Bubble: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Bubble(ID: \(ID), text: '\(text)'  at: \(position)  width: \(width))"
    }
}

extension Bubble: Equatable {
    public static func == (thing1: Bubble, thing2: Bubble) -> Bool {
        return thing1.ID == thing2.ID
    }
}

extension Bubble: Hashable {
    public func hash(into hasher: inout Hasher) {
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

extension NSColor {
    static func colorFromRGB(_ rgb: Bubble.RGB) -> NSColor {
        NSColor.init(deviceRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)
    }

    func rgbColor() -> Bubble.RGB {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0

        getRed(&red, green: &green, blue: &blue, alpha: nil)
        return Bubble.RGB(red: red, green: green, blue: blue)
    }

}
