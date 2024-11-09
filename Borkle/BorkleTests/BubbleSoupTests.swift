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
    @Test(.tags(.undoRedo)) func sequentialUndo() {
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

        soup.undoManager.redo()
        #expect(soup.bubbleCount == 1)
        #expect(changeHookCount == 7)

        soup.undoManager.redo()
        #expect(soup.bubbleCount == 4)
        #expect(changeHookCount == 8)

        soup.undoManager.redo()
        #expect(soup.bubbleCount == 5)
        #expect(changeHookCount == 9)
    }

    @Test(.tags(.undoRedo)) func addBubble() {
        #expect(soup.bubbleCount == 0)

        let bubble = Bubble(ID: 234)
        soup.add(bubble: bubble)
        #expect(soup.bubbleCount == 1)
        #expect(changeHookCount == 1)

        soup.undoManager.undo()
        #expect(soup.bubbleCount == 0)
        #expect(changeHookCount == 2)

        soup.undoManager.redo()
        #expect(soup.bubbleCount == 1)
        #expect(changeHookCount == 3)
    }

    
    @Test(arguments: 0 ..< 10)
    func createBubbleChoosesID(count: Int) {
        #expect(soup.maxBubbleID() == 0)

        for i in 0 ..< count {
            let bubble = soup.createNewBubble()

            #expect(bubble.ID == i + 1)
            #expect(soup.bubbleCount == i + 1)
            #expect(changeHookCount == i + 1)
        }
    }

    @Test func bubbleIteration() {
        let count = 30
        for _ in 0 ..< count {
            _ = soup.createNewBubble()
        }

        #expect(soup.bubbleCount == count)
        #expect(changeHookCount == count)

        var bubbleCount = 0
        soup.forEachBubble { _ in
            bubbleCount += 1
        }
        #expect(count == bubbleCount)

        // change count shouldn't change
        #expect(changeHookCount == count)
    }

    @Test func getBubbleByID() throws {
        let count = 30
        for id in 0 ..< count {
            let bubble = Bubble(ID: id)
            soup.add(bubble: bubble)
        }

        #expect(soup.bubbleCount == count)
        #expect(changeHookCount == count)

        let bubbleFirst = try #require(soup.bubble(byID: 0))
        #expect(bubbleFirst.ID == 0)
        
        let bubbleMiddle = try #require(soup.bubble(byID: count / 2))
        #expect(bubbleMiddle.ID == count / 2)

        let bubbleLast = try #require(soup.bubble(byID: count - 1))
        #expect(bubbleLast.ID == count - 1)

        let bubbleFail = soup.bubble(byID: 666)
        #expect(bubbleFail == nil)

        // change count shouldn't change
        #expect(changeHookCount == count)
    }

    @Test(.tags(.undoRedo)) func removeBubbles() {
        let count = 30
        var evens: [Bubble] = []

        for id in 0 ..< count {
            let bubble = Bubble(ID: id)
            soup.add(bubble: bubble)

            if id.isMultiple(of: 2) {
                evens.append(bubble)
            }
        }

        #expect(soup.bubbleCount == count)
        let evensCount = count / 2
        #expect(evens.count == evensCount)
        #expect(changeHookCount == count)

        soup.remove(bubbles: evens)
        #expect(soup.bubbleCount == count - evensCount)
        #expect(changeHookCount == count + 1)

        undoManager.undo()
        #expect(soup.bubbleCount == count)
        #expect(changeHookCount == count + 2)

        undoManager.redo()
        #expect(soup.bubbleCount == count - evensCount)
        #expect(changeHookCount == count + 3)
    }
}
