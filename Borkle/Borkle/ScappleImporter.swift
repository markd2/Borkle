import Foundation

class ScappleImporter: NSObject {
    enum ImporterError: Error {
        case CouldNotInitializeParser
        case UnknownParserError
    }

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

extension ScappleImporter: XMLParserDelegate {
    
}
