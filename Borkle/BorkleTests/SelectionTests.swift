import XCTest
@testable import Borkle

class SelectionTests: XCTestCase {
    var selection: Selection!
    
    var invalCount = 0

    override func setUp() {
        super.setUp()
        selection = Selection()
        selection.invalHook = { _ in self.invalCount += 1 }
    }

    override func tearDown() {
        selection = nil
        super.tearDown()
    }

    func test_select() {
        let bubble = Bubble(ID: 1)

        XCTAssertEqual(selection.bubbleCount, 0)

        // select something
        selection.select(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(invalCount, 1)

        // selecting it again shouldn't change anything
        selection.select(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 1)

        // Should not have issued a bogus invalidation.
        XCTAssertEqual(invalCount, 1)
    }

    func test_bulk_select() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)
        XCTAssertEqual(invalCount, 3)

        for bubble in bubbles {
            XCTAssertTrue(selection.isSelected(bubble: bubble))
        }
    }

    func test_is_selected() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        
        XCTAssertTrue(selection.isSelected(bubble: bubbles[0]))
        XCTAssertTrue(selection.isSelected(bubble: bubbles[1]))

        let bubble = Bubble(ID: 4)
        XCTAssertFalse(selection.isSelected(bubble: bubble))

        XCTAssertEqual(invalCount, 3)
    }
    
    func test_deselect() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)

        XCTAssertEqual(invalCount, 3)
        
        selection.deselect(bubble: bubbles[0])
        XCTAssertEqual(selection.bubbleCount, 2)
        XCTAssertEqual(invalCount, 4)

        selection.deselect(bubble: bubbles[1])
        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(invalCount, 5)

        // Removing same shouldn't affect anything
        selection.deselect(bubble: bubbles[1])
        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(invalCount, 6)
        
        // Remove the last one
        selection.deselect(bubble: bubbles[2])
        XCTAssertEqual(selection.bubbleCount, 0)
        XCTAssertEqual(invalCount, 7)
    }
    
    func test_unselect_all() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)
        XCTAssertEqual(invalCount, 3)

        selection.unselectAll()
        XCTAssertEqual(selection.bubbleCount, 0)
        XCTAssertEqual(invalCount, 6)
    }

    func test_toggle() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)
        XCTAssertEqual(invalCount, 3)

        let bubble = bubbles[1]
        
        selection.toggle(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 2)
        XCTAssertFalse(selection.isSelected(bubble: bubble))
        XCTAssertEqual(invalCount, 4)

        selection.toggle(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 3)
        XCTAssertTrue(selection.isSelected(bubble: bubble))
        XCTAssertEqual(invalCount, 5)
    }

}

