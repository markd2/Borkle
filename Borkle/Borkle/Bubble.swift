import Foundation

class Bubble: Codable {
    let ID: Int
    var text: String = ""
    var position: CGPoint = .zero
    var width: CGFloat = 0
    var connections = IndexSet()

    init(ID: Int) {
        self.ID = ID
    }
}

extension Bubble: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Bubble(ID: \(ID), text: '\(text)'  at: \(position)  width: \(width))"
    }
}



