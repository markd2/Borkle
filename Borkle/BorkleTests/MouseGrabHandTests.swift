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

    func test_click_doesnt_scroll() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])
        XCTAssertNil(testSupport.scrollArgument)
    }

    func test_drag_scrolls_same_delta() {
        testSupport.currentScrollOffsetReturn = CGPoint(x: 100, y: 200)
        mouser.start(at: .zero, modifierFlags: [])

        // mouse drags down to the right
        mouser.drag(to: CGPoint(x: 10, y: 20), modifierFlags: []) // delta (10, 30)

        // scroll-to moves up and to the left the same amount.
        // y is flipped because #Cocoa
        XCTAssertEqual(testSupport.scrollArgument, CGPoint(x: 90, y: 220))
    }
}
