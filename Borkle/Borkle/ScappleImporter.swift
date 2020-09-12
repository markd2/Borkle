import Foundation

class ScappleImporter {
    enum ImporterError: Error {
        case CouldNotInitializeParser
    }

    func importScapple(url: URL) throws -> [Bubble] {
        guard let parser = XMLParser(contentsOf: url) 
    }
}
