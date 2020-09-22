import XCTest
@testable import Borkle

class BarrierSoupTests: XCTestCase {
    
    var soup: BarrierSoup!

    override func setUp() {
        super.setUp()
        soup = BarrierSoup()
    }

    override func tearDown() {
        soup = nil
        super.tearDown()
    }

    func test_complete_coverage() {
        _ = BarrierSoup(undoManager: UndoManager())
    }
}

