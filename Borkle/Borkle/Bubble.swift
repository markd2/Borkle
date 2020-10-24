import Cocoa

class Bubble: Codable {
    static let defaultFontName = "Helvetica"
    static let defaultFontSize: CGFloat = 12.0

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

    func gronkulateAttributedString(_ attr: NSAttributedString) {
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

    var attributedString: NSAttributedString {
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

    struct FormattingOption: Codable, Equatable {
        let options: FormattingStyle
        let rangeStart: Int 
        let rangeLength: Int 

        var nsrange: NSRange {
            NSRange(location: rangeStart, length: rangeLength)
        }
        
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

        init(_ options: FormattingStyle, range: NSRange) {
            self.options = options
            self.rangeStart = range.location
            self.rangeLength = range.length
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

