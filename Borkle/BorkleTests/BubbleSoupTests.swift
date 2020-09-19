import XCTest
@testable import Borkle

class BubbleSoupTests: XCTestCase {
    
    var soup: BubbleSoup!

    override func setUp() {
        super.setUp()
        soup = BubbleSoup()
    }

    override func tearDown() {
        soup = nil
        super.tearDown()
    }

    func test_set_bubble_position() {
        let bubble = Bubble(ID: 23)
        bubble.position = CGPoint(x: 5, y: 10)
        soup.add(bubble: bubble)

        soup.move(bubble: bubble, to: CGPoint(x: 10, y: 20))
        let bubble1 = soup.bubble(byID: 23)!
        XCTAssertEqual(bubble1.position, CGPoint(x: 10, y: 20))
    }

    func test_set_bubble_position_undo() {
        let bubble = Bubble(ID: 23)
        bubble.position = CGPoint(x: 5, y: 10)
        soup.add(bubble: bubble)

        soup.move(bubble: bubble, to: CGPoint(x: 10, y: 20))
        let bubble1 = soup.bubble(byID: 23)!
        XCTAssertEqual(bubble1.position, CGPoint(x: 10, y: 20))

        soup.undo()
        XCTAssertEqual(bubble1.position, CGPoint(x: 5, y: 10))

        soup.redo()
        XCTAssertEqual(bubble1.position, CGPoint(x: 10, y: 20))
    }

}

/// These exercse adding and removing
extension BubbleSoupTests {
    func test_add_bubble() {
        let bubble = Bubble(ID: 23)
        soup.add(bubble: bubble)
        XCTAssertEqual(soup.bubbleCount, 1)
    }

    func test_add_bubble_undo() {
        let bubble = Bubble(ID: 23)
        soup.add(bubble: bubble)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 0)
    }

    func test_add_bulk_bubbles_to_empty_soup() {
        let bubbles = [Bubble(ID: 1)]

        soup.add(bubbles: bubbles)
        XCTAssertEqual(soup.bubbleCount, 1)
    }

    func test_add_bulk_bubbles_to_soup() {
        let bubbles = [Bubble(ID: 1)]
        soup.add(bubbles: bubbles)

        let moreBubbles = [Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: moreBubbles)

        XCTAssertEqual(soup.bubbleCount, 3)
    }

    func test_lookup_by_ID() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 5), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        XCTAssertEqual(soup.bubble(byID: 1)!.ID, 1)
        XCTAssertEqual(soup.bubble(byID: 3)!.ID, 3)
        XCTAssertNil(soup.bubble(byID: 666))
    }

    func test_adding_bulk_bubbles_undo() {
        let bubbles = [Bubble(ID: 1)]
        soup.add(bubbles: bubbles)

        let moreBubbles = [Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: moreBubbles)

        XCTAssertEqual(soup.bubbleCount, 3)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 1)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 0)
    }

    func test_remove_everything() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        XCTAssertEqual(soup.bubbleCount, 3)
        soup.removeEverything()

        XCTAssertEqual(soup.bubbleCount, 0)
    }

    func test_remove_everything_undo() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.removeEverything()
        XCTAssertEqual(soup.bubbleCount, 0)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 3)
    }

    func test_undo_grouping() {
        soup.beginGrouping()
        soup.add(bubble: Bubble(ID: 1))
        soup.add(bubble: Bubble(ID: 2))
        soup.add(bubble: Bubble(ID: 3))
        soup.endGrouping()
        
        XCTAssertEqual(soup.bubbleCount, 3)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 0)
    }
    
    func test_undo_latch() {
        soup.add(bubble: Bubble(ID: 1))
        soup.add(bubble: Bubble(ID: 2))
        soup.add(bubble: Bubble(ID: 3))
        soup.endGrouping()
        
        XCTAssertEqual(soup.bubbleCount, 3)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 2)
    }

    func test_hit_test_bubble() {
        soup.add(bubble: Bubble(ID: 1, position: CGPoint(x: 10, y: 20), width: 90))
        soup.add(bubble: Bubble(ID: 2, position: CGPoint(x: 100, y: 200), width: 90))

        // Should find bubbles
        let bubble1 = soup.hitTestBubble(at: CGPoint(x: 11, y: 21))
        XCTAssertEqual(bubble1?.ID, 1)
        let bubble2 = soup.hitTestBubble(at: CGPoint(x: 101, y: 201))
        XCTAssertEqual(bubble2?.ID, 2)

        // not inside any
        let bubble3 = soup.hitTestBubble(at: CGPoint(x: 666, y: 666))
        XCTAssertNil(bubble3)
    }

    func test_empty_enclosing_rect() {
        let rect = soup.enclosingRect
        XCTAssertEqual(rect, .zero)
    }

    func test_enclosing_rect() {
        let expectedRect = CGRect(x: 0, y: 0, width: 190, height: 220) // assuming 20 height
        soup.add(bubble: Bubble(ID: 1, position: CGPoint(x: 10, y: 20), width: 90))
        soup.add(bubble: Bubble(ID: 2, position: CGPoint(x: 100, y: 200), width: 90))
        let rect = soup.enclosingRect
        
        XCTAssertEqual(rect, expectedRect)
    }

    func test_bubble_iteration() {
        soup.add(bubble: Bubble(ID: 1))
        soup.add(bubble: Bubble(ID: 2))
        soup.add(bubble: Bubble(ID: 3))

        var count = 0
        var seenIDs = IndexSet()
        soup.forEachBubble {
            seenIDs.insert($0.ID)
            count += 1
        }
        
        XCTAssertEqual(count, 3)
        XCTAssertEqual(seenIDs, IndexSet(1...3))
    }

}

/// These exercise internal helper methods
extension BubbleSoupTests {
    func test_remove_last_bubbles() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.removeLastBubbles(count: 2)
        XCTAssertEqual(soup.bubbleCount, 1)

        // make sure the right bubble remains
        XCTAssertNotNil(soup.bubble(byID: 1))
    }

    func test_remove_last_bubbles_undo() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.removeLastBubbles(count: 2)
        XCTAssertEqual(soup.bubbleCount, 1)
        soup.undo()

        XCTAssertEqual(soup.bubbleCount, 3)
    }
}
