import XCTest
@testable import Borkle

class BubbleSoupTests: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func test_add_bulk_bubbles_to_empty_soup() {
        let soup = BubbleSoup()
        let bubbles = [Bubble(ID: 1)]

        soup.add(bubbles: bubbles)
        XCTAssertEqual(soup.bubbleCount, 1)
    }

    func test_add_bulk_bubbles_to_soup() {
        let soup = BubbleSoup()

        let bubbles = [Bubble(ID: 1)]
        soup.add(bubbles: bubbles)

        let moreBubbles = [Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: moreBubbles)

        XCTAssertEqual(soup.bubbleCount, 3)
    }

    func test_remove_last_bubbles() {
        let soup = BubbleSoup()

        let bubbles = [Bubble(ID: 1), Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: bubbles)

        soup.removeLastBubbles(count: 2)
        XCTAssertEqual(soup.bubbleCount, 1)
    }

    func test_adding_bulk_bubbles_undo() {
        let soup = BubbleSoup()

        let bubbles = [Bubble(ID: 1)]
        soup.add(bubbles: bubbles)

        let moreBubbles = [Bubble(ID: 2), Bubble(ID: 3)]
        soup.add(bubbles: moreBubbles)

        XCTAssertEqual(soup.bubbleCount, 3)
        soup.undo()
        print("AFTER UNDO")
        XCTAssertEqual(soup.bubbleCount, 1)
        soup.undo()
        XCTAssertEqual(soup.bubbleCount, 0)
        print("AFTER UNDO")
    }

}


