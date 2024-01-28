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
            playfield.addBubble(bubble)
            print(bubble)
        }
    }

    // ----------
    // Tests

    func testBubbleByID() {
        let expectedBubble = playfield.bubble(byID: 1)
        XCTAssertNotNil(expectedBubble)

// need to see if we want to support this - right now this fatal errors if you ask a playfield
// for a bubble ID it doesn't have.
//        let unexpectedBubble = playfield.bubble(byID: 0)
//        XCTAssertNil(unexpectedBubble)
    }

    func testConnections() {
        // nothing should be connected
        for id in playfield.bubbleIdentifiers {
            let connectedIndexes = playfield.connectionsForBubble(id: id)
            XCTAssertEqual(connectedIndexes, IndexSet())
        }

        // connect two bubbles
        playfield.addConnectionsBetween(bubbleIDs: [2], to: 1)
        XCTAssertTrue(playfield.isBubble(1, connectedTo: 2))
        XCTAssertTrue(playfield.isBubble(2, connectedTo: 1))

        // make sure extras not connected
        for id1 in playfield.bubbleIdentifiers {
            for id2 in playfield.bubbleIdentifiers {
                if (id1 == 1 && id2 == 2) || (id1 == 2 && id2 == 1) {
                    continue
                }
                XCTAssertFalse(playfield.isBubble(id1, connectedTo: id2))
                XCTAssertFalse(playfield.isBubble(id2, connectedTo: id1))
            }
        }

        // disconnect them
        playfield.disconnect(bubbleIDs: [1], from: 2)

        // nothing should be connected now
        for id in playfield.bubbleIdentifiers {
            let connectedIndexes = playfield.connectionsForBubble(id: id)
            XCTAssertEqual(connectedIndexes, IndexSet())
        }
    }
}
