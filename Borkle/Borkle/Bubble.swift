import Foundation

class Bubble {
    let ID: Int
    var text: String = ""
    var position: CGPoint = .zero
    var width: CGFloat = 0
    var connections = IndexSet()

    init(ID: Int) {
        self.ID = ID
    }
}



