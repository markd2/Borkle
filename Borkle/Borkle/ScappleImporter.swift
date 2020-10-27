import Foundation

class ScappleImporter: NSObject {
    enum ImporterError: Error {
        case couldNotInitializeParser
        case unknownParserError
    }

    var bubbles: [Bubble] = []
    var currentBubble: Bubble = Bubble(ID: -1)
    var currentString: String = ""
    var currentConnectedNoteString: String?
    var formattingOptions: [Bubble.FormattingOption]?
    var currentFormattingOptionsString: String?
    var currentFormattingOptionsAttributes: [String: String]?

    func importScapple(url: URL) throws -> [Bubble] {
        guard let parser = XMLParser(contentsOf: url) else {
            throw(ImporterError.couldNotInitializeParser)
        }
        parser.delegate = self

        if parser.parse() {
            return bubbles
        } else if let error = parser.parserError {
            throw error
        } else {
            throw ImporterError.unknownParserError
        }
    }
}

extension ScappleImporter {
    func makeNote(_ element: String, _ attributes: [String: String]) -> Bubble? {
        guard let IDstring = attributes["ID"], let ID = Int(IDstring) else {
            return nil
        }
        let bubble = Bubble(ID: ID)

        if let widthString = attributes["Width"], let width = CGFloat(widthString) {
            bubble.width = width
        }

        if let positionString = attributes["Position"], let position = CGPoint(positionString) {
            bubble.position = position
        }

        return bubble
    }

    func makeConnections(_ connectionString: String?) -> IndexSet? {
        guard let connectionString = connectionString else { return nil }
        let connections = IndexSet(connectionString)

        // of the form "76, 78-79, 83, 91, 142-143, 162, 171"
        return connections
    }

    func makeFormatRange(_ attributes: [String: String]?, _ rangeString: String?) -> Bubble.FormattingOption? {
        guard let attributes = attributes, let rangeString = rangeString else { return nil }
        var options = Bubble.FormattingStyle()

        for (key, value) in attributes {
            if value == "Yes" {
                switch key { 
                case "Bold": options.insert(.bold)
                case "Italic": options.insert(.italic)
                case "Struckthrough": options.insert(.strikethrough)
                case "Underline": options.insert(.underline)
                default:
                    break
                }
            }
        }
        guard attributes.count > 0 else {
            print("Got no useful style attributes from \(attributes)")
            return nil
        }

        let ranges = rangeString.split(separator: ",")
        guard ranges.count == 2 else {
            print("unexpected number of items in range string \(rangeString)")
            return nil
        }

        guard let rangeStart = Int(ranges[0]), let rangeLength = Int(ranges[1]) else {
            print("unexpected Int processing from range string \(rangeString)")
            return nil
        }

        let formattingOption = Bubble.FormattingOption(options: options, 
                                                       rangeStart: rangeStart,
                                                       rangeLength: rangeLength)

        return formattingOption
    }
}

extension ScappleImporter: XMLParserDelegate {

    func parserDidStartDocument(_ parser: XMLParser) {
    }

    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, 
        qualifiedName: String?, attributes: [String: String]) {
        switch element {
        case "Notes":
            bubbles = []
        case "Note":
            if let currentBubble = makeNote(element, attributes) {
                self.currentBubble = currentBubble
            }
        case "ConnectedNoteIDs":
            currentConnectedNoteString = ""
        case "String":
            currentString = ""
        case "Formatting":
            formattingOptions = []
        case "FormatRange":
            currentFormattingOptionsString = ""
            currentFormattingOptionsAttributes = attributes
        case "Border":
            currentBorderColorString = ""
            if let weightString = attributes["Weight"],
               let weight = Int(weightString) {
                currentBubble.borderThickness = weight
            }
        default:
            break
        }
//        Swift.print("did start element \(element)  attributts \(attributes)")
    }

    func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
//        Swift.print("did end element \(element)")
        switch element {
        case "String":
            currentBubble.text = currentString
        case "Notes":
            break
            // Swift.print("BUBBLES! \(bubbles)")
        case "Note":
            bubbles.append(currentBubble)
        case "ConnectedNoteIDs":
            if let connections = makeConnections(currentConnectedNoteString) {
                currentBubble.connections = connections
            }
            currentConnectedNoteString = nil
        case "Formatting":
            currentBubble.formattingOptions = formattingOptions ?? [] // [] just to keep optionals happy
        case "FormatRange":
            if let formatRange = makeFormatRange(currentFormattingOptionsAttributes,
                                                 currentFormattingOptionsString),
               let formattingOptions = formattingOptions {
                self.formattingOptions = formattingOptions + [formatRange]
            }
            currentFormattingOptionsAttributes = nil
            currentFormattingOptionsString = nil

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters: String) {
//        Swift.print("string! \(foundCharacters)")
        if currentConnectedNoteString != nil {
            currentConnectedNoteString! += foundCharacters
        } else if currentFormattingOptionsString != nil {
            currentFormattingOptionsString! += foundCharacters
        } else {
            currentString += foundCharacters
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
//        Swift.print("all done")
    }
    
}
