import Foundation

class ScappleImporter: NSObject {
    enum ImporterError: Error {
        case CouldNotInitializeParser
        case UnknownParserError
    }

    var bubbles: [Bubble] = []
    var currentBubble: Bubble = Bubble(ID: -1)
    var currentString: String = ""

    func importScapple(url: URL) throws -> [Bubble] {
        guard let parser = XMLParser(contentsOf: url) else {
            throw(ImporterError.CouldNotInitializeParser)
        }
        parser.delegate = self

        if parser.parse() {
            return []
        } else if let error = parser.parserError {
            throw error
        } else {
            throw ImporterError.UnknownParserError
        }
    }
}

extension ScappleImporter {
    func addNote(_ element: String, _ attributes: [String: String]) -> Bubble? {
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
}

extension CGFloat {
    init?(_ string: String) {
        if let double = Double(string) {
            self.init(double)
        } else {
            return nil
        }
    }
}

extension CGPoint {
    init?(_ string: String) {
        let components = string.split(separator: ",").map { String($0) }
        if components.count != 2 { return nil }
        
        if let x = CGFloat(components[0]), let y = CGFloat(components[1]) {
            self.init(x: x, y: y)
        } else {
            return nil
        }
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
            if let currentBubble = addNote(element, attributes) {
                self.currentBubble = currentBubble
            }
        case "String":
            currentString = ""
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
            Swift.print("BUBBLES! \(bubbles)")
        case "Note":
            bubbles.append(currentBubble)
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters: String) {
//        Swift.print("string! \(foundCharacters)")
        currentString += foundCharacters
    }

    func parserDidEndDocument(_ parser: XMLParser) {
//        Swift.print("all done")
    }
    
}
