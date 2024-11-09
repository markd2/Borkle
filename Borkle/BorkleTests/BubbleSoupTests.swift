import Testing
import Foundation
@testable import Borkle

class BubbleSoupTests {
    private var soup: BubbleSoup
    private var undoManager: UndoManager

    var changeHookCount = 0

    init() {
        undoManager = UndoManager()
        // otherwise multiple undoable operations get coalesced and can't be popped
        // individually
        undoManager.groupsByEvent = false
        soup = BubbleSoup(undoManager: undoManager)
        soup.addChangeHook(bubbleSoupChangeHook)
    }
    
    func bubbleSoupChangeHook() {
        changeHookCount += 1
    }

    /// multiple undoable operations 
    @Test func sequentialUndo() {
        #expect(soup.bubbleCount == 0)

        let bubble1 = Bubble(ID: 234)
        soup.add(bubble: bubble1)
        #expect(soup.bubbleCount == 1)
        #expect(changeHookCount == 1)

        let bubbles = [Bubble(ID: 456), Bubble(ID: 457), Bubble(ID: 458)]
        soup.add(bubbles: bubbles)
        #expect(soup.bubbleCount == 4)
        #expect(changeHookCount == 2)

        let bubble = Bubble(ID: 789)
        soup.add(bubble: bubble)
        #expect(soup.bubbleCount == 5)
        #expect(changeHookCount == 3)

        soup.undoManager.undo()
        #expect(soup.bubbleCount == 4)
        #expect(changeHookCount == 4)

        soup.undoManager.undo()
        #expect(soup.bubbleCount == 1)
        #expect(changeHookCount == 5)

        soup.undoManager.undo()
        #expect(soup.bubbleCount == 0)
        #expect(changeHookCount == 6)
    }

    @Test func addBubble() {
        #expect(soup.bubbleCount == 0)

        let bubble = Bubble(ID: 234)
        soup.add(bubble: bubble)
        #expect(soup.bubbleCount == 1)

        soup.undoManager.undo()
        #expect(soup.bubbleCount == 0)
    }

}
