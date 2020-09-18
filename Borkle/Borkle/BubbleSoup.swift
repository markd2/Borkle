import Foundation

class BubbleSoup {
    private var bubbles: [Bubble] = []

    func add(bubbles: [Bubble]) {
        self.bubbles += bubbles
    }

    var bubbleCount: Int {
        return bubbles.count
    }
    
}
