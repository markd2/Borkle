import Foundation

class ScappleImporter: NSObject {
    enum ImporterError: Error {
        case CouldNotInitializeParser
        case UnknownParserError
    }

    var bubbles: [Bubble] = []
    var currentBubble: Bubble = Bubble(ID: -1)
    var currentString: String = ""
    var currentConnectedNoteString: String?

    func importScapple(url: URL) throws -> [Bubble] {
        guard let parser = XMLParser(contentsOf: url) else {
            throw(ImporterError.CouldNotInitializeParser)
        }
        parser.delegate = self

        if parser.parse() {
            return bubbles
        } else if let error = parser.parserError {
            throw error
        } else {
            throw ImporterError.UnknownParserError
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
        var connections = IndexSet()

        let components = connectionString.split(separator: ",").map { String($0).trimmed }

        for component in components {
            let innerComponents = component.split(separator: "-").map { String($0).trimmed }
            if innerComponents.count == 1 {
                if let value = Int(component) {
                    connections.update(with: value)
                }
            } else if innerComponents.count == 2 {
                if let firstValue = Int(innerComponents[0]),
                   let secondValue = Int(innerComponents[1]) {
                    connections.insert(integersIn: firstValue ... secondValue)
                }
            } else {
                Swift.print("Unexpected multiple (or zero) components from \(component)")
            }
        }

        // of the form "76, 78-79, 83, 91, 142-143, 162, 171"
        return connections
    }
}

extension String {
    var trimmed: String {
        let trimmedString = self.trimmingCharacters(in: .whitespaces)
        return trimmedString
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
            if let currentBubble = makeNote(element, attributes) {
                self.currentBubble = currentBubble
            }
        case "ConnectedNoteIDs":
            currentConnectedNoteString = ""
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
        case "ConnectedNoteIDs":
            if let connections = makeConnections(currentConnectedNoteString) {
                currentBubble.connections = connections
            }
            currentConnectedNoteString = nil
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters: String) {
//        Swift.print("string! \(foundCharacters)")
        if currentConnectedNoteString != nil {
            currentConnectedNoteString! += foundCharacters
        } else {
            currentString += foundCharacters
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
//        Swift.print("all done")
    }
    
}
