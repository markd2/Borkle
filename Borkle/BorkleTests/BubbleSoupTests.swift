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

}


// These exercise internal helper methods
extension BubbleSoupTests {
    func test_remove_last_bubbles() {
        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.removeLastBubbles(count: 2)
        XCTAssertEqual(soup.bubbleCount, 1)

        // make sure the right bubble remains
        XCTAssertNotNil(soup.bubble(byID: 1))
    }
}
