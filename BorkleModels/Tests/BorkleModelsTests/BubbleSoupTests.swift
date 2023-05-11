import XCTest
@testable import BorkleModels

class BubbleSoupTests: XCTestCase {
    
    var soup: BubbleSoup!
    var b1: Bubble!
    var b2: Bubble!
    var b3: Bubble!
    var b4: Bubble!

    var changeHookCallCount = 0

    override func setUp() {
        super.setUp()
        soup = BubbleSoup()

        b1 = Bubble(ID: 1)
        b2 = Bubble(ID: 2)
        b3 = Bubble(ID: 3)
        b4 = Bubble(ID: 4)

        soup.bubblesChangedHook = {
            self.changeHookCallCount += 1
        }
    }

    override func tearDown() {
        soup = nil
        super.tearDown()
        b1 = nil
        b2 = nil
        b3 = nil
        b4 = nil
    }

    func test_complete_coverage() {
        _ = BubbleSoup(undoManager: UndoManager())
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
        var invalCount = 0
        soup.invalHook = { _ in invalCount += 1 }

        let bubble = Bubble(ID: 23)
        bubble.position = CGPoint(x: 5, y: 10)
        soup.add(bubble: bubble)

        soup.move(bubble: bubble, to: CGPoint(x: 10, y: 20))
        let bubble1 = soup.bubble(byID: 23)!
        XCTAssertEqual(bubble1.position, CGPoint(x: 10, y: 20))
        XCTAssertEqual(invalCount, 1)

        soup.undo()
        XCTAssertEqual(bubble1.position, CGPoint(x: 5, y: 10))
        XCTAssertEqual(invalCount, 2)

        soup.redo()
        XCTAssertEqual(bubble1.position, CGPoint(x: 10, y: 20))
        XCTAssertEqual(invalCount, 3)
    }

    func test_select_area_returns_nil_when_no_bubbles() {
        let selection = soup.areaTestBubbles(intersecting: .zero)
        XCTAssertNil(selection) 
    }

    func test_select_area_returns_nil_when_no_intersections() {
        soup.add(bubble: Bubble(ID: 1, position: CGPoint(x: 10, y: 20), width: 90))
        soup.add(bubble: Bubble(ID: 2, position: CGPoint(x: 100, y: 200), width: 90))

        let selection = soup.areaTestBubbles(intersecting: CGRect(x: 500, y: 500, width: 100, height: 100))
        XCTAssertNil(selection)
    }

    func test_select_area_returns_intersections() {
        soup.add(bubble: Bubble(ID: 1, position: CGPoint(x: 10, y: 20), width: 90))
        soup.add(bubble: Bubble(ID: 2, position: CGPoint(x: 100, y: 200), width: 90))
        soup.add(bubble: Bubble(ID: 3, position: CGPoint(x: 1000, y: 2000), width: 90))

        let selection = soup.areaTestBubbles(intersecting: CGRect(x: 5, y: 10, width: 100, height: 200))!
        XCTAssertEqual(selection.count, 2)
        XCTAssertEqual(selection[0].ID, 1)
        XCTAssertEqual(selection[1].ID, 2)
    }

    func test_max_bubble_ID() {
        soup.add(bubbles: [Bubble(ID: 665), Bubble(ID: 23)])
        XCTAssertEqual(soup.maxBubbleID(), 665)
    }

    func test_create_bubble() {
        let point = CGPoint(x: 100, y: 200)
        _ = soup.create(newBubbleAt: point)
        XCTAssertEqual(soup.bubbleCount, 1)

        let bubble = soup.bubble(byID: 1)
        XCTAssertNotNil(bubble)

        // the actual position isn't 100% predictable due to font stuff,
        // so make sure the bubble contains the new bubble pointfor now.
        XCTAssertTrue(bubble!.rect.contains(point))
    }

    func test_create_bubble_undo() {
        let point = CGPoint(x: 100, y: 200)
        _ = soup.create(newBubbleAt: point)
        _ = soup.create(newBubbleAt: point)
        XCTAssertEqual(soup.bubbleCount, 2)

        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 1)

        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 0)

        soup.redo()
        XCTAssertEqual(soup.bubbleCount, 1)
    }

    func test_delete_bubble() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 5), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.remove(bubbles: [bubbles[1]]) // remove ID 5
        XCTAssertEqual(soup.bubbleCount, 2)

        XCTAssertNotNil(soup.bubble(byID: 1))
        XCTAssertNotNil(soup.bubble(byID: 3))
        XCTAssertNil(soup.bubble(byID: 5))
    }

    func test_delete_bubble_undo() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 5), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.remove(bubbles: [bubbles[1]]) // remove ID 5
        XCTAssertEqual(soup.bubbleCount, 2)

        soup.remove(bubbles: [bubbles[2]]) // remove ID 3
        XCTAssertEqual(soup.bubbleCount, 1)

        XCTAssertNotNil(soup.bubble(byID: 1))
        XCTAssertNil(soup.bubble(byID: 3))
        XCTAssertNil(soup.bubble(byID: 5))
        
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 2)
        XCTAssertNotNil(soup.bubble(byID: 1))
        XCTAssertNotNil(soup.bubble(byID: 3))
        XCTAssertNil(soup.bubble(byID: 5))
        
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 3)
        XCTAssertNotNil(soup.bubble(byID: 1))
        XCTAssertNotNil(soup.bubble(byID: 3))
        XCTAssertNotNil(soup.bubble(byID: 5))
    }

    func test_delete_bubble_removes_connection() {
        soup.add(bubbles: [b1, b2, b3])

        soup.connect(bubble: b2, to: b3)
        soup.remove(bubbles: [b3])
        XCTAssertTrue(b2.connections.count == 0)
    }
}

/// These exercise adding and removing
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

/// These test UI jazz
extension BubbleSoupTests {

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

    func test_hit_test_overlapping_bubbles_are_back_to_front() {
        soup.add(bubble: Bubble(ID: 1, position: CGPoint(x: 10, y: 20), width: 90))
        soup.add(bubble: Bubble(ID: 2, position: CGPoint(x: 10, y: 20), width: 90))

        let bubble = soup.hitTestBubble(at: CGPoint(x: 12, y: 22))
        XCTAssertEqual(bubble?.ID, 2)
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

    func test_connect_1() {
        soup.add(bubbles: [b1, b2, b3])

        soup.connect(bubble: b1, to: b2)
        XCTAssertTrue(b1.isConnectedTo(b2))
        XCTAssertTrue(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b2))
    }

    func test_connect_1_undo() {
        soup.add(bubbles: [b1, b2, b3])

        // manually grouping because this is a helper function.
        soup.beginGrouping()
        soup.connect(bubble: b1, to: b2)
        soup.endGrouping()

        soup.undo()

        XCTAssertFalse(b1.isConnectedTo(b2))
        XCTAssertFalse(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
    }

    func test_disconnect_1() {
        soup.add(bubbles: [b1, b2, b3])
        soup.connect(bubbles: [b1], to: b2)

        soup.disconnect(bubble: b1, from: b2)

        XCTAssertFalse(b1.isConnectedTo(b2))
        XCTAssertFalse(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b2))
    }

    func test_disconnect_1_undo() {
        soup.add(bubbles: [b1, b2, b3])

        soup.beginGrouping()
        soup.connect(bubble: b1, to: b2)
        soup.endGrouping()

        soup.beginGrouping()
        soup.disconnect(bubble: b1, from: b2)
        soup.endGrouping()

        soup.undo()

        XCTAssertTrue(b1.isConnectedTo(b2))
        XCTAssertTrue(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
    }

    func test_connect_batch() {
        soup.add(bubbles: [b1, b2, b3, b4])
        soup.connect(bubble: b4, to: b1)

        soup.connect(bubbles: [b1, b2], to: b3)
        // make sure connections are made
        XCTAssertTrue(b1.isConnectedTo(b3))
        XCTAssertTrue(b2.isConnectedTo(b3))

        // existing connection is preserved
        XCTAssertTrue(b4.isConnectedTo(b1))

        // and other connection weren't made
        XCTAssertFalse(b3.isConnectedTo(b4))
    }

    func test_connect_batch_undo() {
        soup.add(bubbles: [b1, b2, b3, b4])
        soup.connect(bubble: b4, to: b1)

        soup.connect(bubbles: [b1, b2], to: b3)
        soup.undo()

        // make sure connections are no longer there
        XCTAssertFalse(b1.isConnectedTo(b3))
        XCTAssertFalse(b2.isConnectedTo(b3))

        // existing connection is preserved
        XCTAssertTrue(b4.isConnectedTo(b1))

        // and other connection wasn't made somehow
        XCTAssertFalse(b3.isConnectedTo(b4))
    }

    func test_disconnect_batch() {
        soup.add(bubbles: [b1, b2, b3, b4])
        soup.connect(bubbles: [b1], to: b2)

        soup.disconnect(bubbles: [b1], from: b2)

        XCTAssertFalse(b1.isConnectedTo(b2))
        XCTAssertFalse(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b2))
    }

    func test_disconnect_batch_undo() {
        soup.add(bubbles: [b1, b2, b3, b4])

        soup.connect(bubbles: [b1], to: b2)

        soup.disconnect(bubbles: [b1], from: b2)

        soup.undo()

        XCTAssertTrue(b1.isConnectedTo(b2))
        XCTAssertTrue(b2.isConnectedTo(b1))
        XCTAssertFalse(b3.isConnectedTo(b1))
    }

    func test_add_bubble_calls_change_hook() {
        soup.add(bubble: b1)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_add_bubbles_calls_change_hook() { 
        soup.add(bubbles: [b1, b2])
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_remove_bubbles_calls_change_hook() {
        // not caring if the remove actually removed stuff.
        // OK (currently 10/24/2020)
        soup.remove(bubbles: [b1])
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_create_bubble_calls_change_hook() {
        _ = soup.create(newBubbleAt: .zero)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_remove_everything_calls_change_hook() {
        soup.removeEverything()
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_move_bubble_calls_change_hook() {
        soup.move(bubble: b1, to: .zero)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_connect_calls_change_hook() {
        soup.connect(bubble: b1, to: b2)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_disconnect_calls_change_hook() {
        soup.disconnect(bubble: b1, from: b2)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_connect_plural_calls_change_hook() {
        soup.connect(bubbles: [b1, b2], to: b2)
        XCTAssertEqual(changeHookCallCount, 1)
    }

    func test_disconnect_plural_calls_change_hook() {
        b2.connect(to: b1)
        b2.connect(to: b3)
        soup.disconnect(bubbles: [b1, b2], from: b2)
        XCTAssertEqual(changeHookCallCount, 1)
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
