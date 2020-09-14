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

    var rect: CGRect {
        let rect = CGRect(x: position.x, y: position.y, width: width, height: 20)
        return rect
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
