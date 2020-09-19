import XCTest
@testable import Borkle

class SelectionTests: XCTestCase {
    var selection: Selection!

    override func setUp() {
        super.setUp()
        selection = Selection()
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

        // selecting it again shouldn't change anything
        selection.select(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 1)
    }

    func test_bulk_select() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)

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
    }
    
    func test_deselect() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        
        selection.deselect(bubble: bubbles[0])
        XCTAssertEqual(selection.bubbleCount, 2)

        selection.deselect(bubble: bubbles[1])
        XCTAssertEqual(selection.bubbleCount, 1)

        // Removing same shouldn't affect anything
        selection.deselect(bubble: bubbles[1])
        XCTAssertEqual(selection.bubbleCount, 1)
        
        // Remove the last one
        selection.deselect(bubble: bubbles[2])
        XCTAssertEqual(selection.bubbleCount, 0)
    }
    
    func test_unselect_all() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)

        selection.unselectAll()
        XCTAssertEqual(selection.bubbleCount, 0)
    }

    func test_toggle() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        selection.select(bubbles: bubbles)
        XCTAssertEqual(selection.bubbleCount, 3)

        let bubble = bubbles[1]
        
        selection.toggle(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 2)
        XCTAssertFalse(selection.isSelected(bubble: bubble))

        selection.toggle(bubble: bubble)
        XCTAssertEqual(selection.bubbleCount, 3)
        XCTAssertTrue(selection.isSelected(bubble: bubble))
    }

}

