import XCTest
@testable import Borkle

class MouseGrabHandTests: XCTestCase {
    var mouser: MouseGrabHand!
    private var testSupport: TestSupport!

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        mouser = MouseGrabHand(withSupport: testSupport)
    }

    override func tearDown() {
        mouser = nil
        testSupport = nil
        super.tearDown()
    }

    func test_window_coordinate_preference() {
        // Need to have window coordinates - view coordinates when scrolling
        // become slippery
        XCTAssertTrue(mouser.prefersWindowCoordinates)
    }

}
