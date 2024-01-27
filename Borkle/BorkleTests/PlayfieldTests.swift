import XCTest
@testable import Borkle

final class PlayfieldTests: XCTestCase {
    var playfield: Playfield!
    var soup: BubbleSoup!
    var undoManager: UndoManager!

    override func setUpWithError() throws {
        let undoManager = UndoManager()
        let soup = BubbleSoup(undoManager: undoManager)
        playfield = Playfield(soup: soup, undoManager: undoManager)
        setupDefaultSoup(soup: soup)
    }

    override func tearDownWithError() throws {
        playfield = nil
        soup = nil
        undoManager = nil
    }

    // ----------
    // Utilities

    private func setupDefaultSoup(soup: BubbleSoup) {
        let bubbleTexts = ["1", "2", "3", "4"]
        for text in bubbleTexts {
            let bubble = soup.createNewBubble()
            bubble.text = text
            print(bubble)
        }
    }

    // ----------
    // Tests

    func testBubbleByID() throws {
        let expectedBubble = playfield.bubble(byID: 1)
        XCTAssertNotNil(expectedBubble)

        let unexpectedBubble = playfield.bubble(byID: 0)
        XCTAssertNil(unexpectedBubble)
    }
}
