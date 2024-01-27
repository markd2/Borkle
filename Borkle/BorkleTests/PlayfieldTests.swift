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
    }

    override func tearDownWithError() throws {
        playfield = nil
        soup = nil
        undoManager = nil
    }

    func testExample() throws {
        
    }
}
