import XCTest
@testable import Borkle

class MouseSpaceTests: XCTestCase {
    var mouser: MouseSpacer!
    private var testSupport: TestSupport!
    private var selection: Selection!
    
    var invalCount = 0

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        selection = Selection()
        mouser = MouseSpacer(withSupport: testSupport, selection: selection)
    }

    override func tearDown() {
        mouser = nil
        testSupport = nil
        selection = nil
        super.tearDown()
    }

    func test_window_coordinate_preference() {
        // We like view coordinates thank you very much
        XCTAssertFalse(mouser.prefersWindowCoordinates)
    }

    func test_just_click_deselects_everything() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])

        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertNil(testSupport.selectArgument)
    }

    func test_drag_in_emptyness_selectes_nothing() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: CGPoint(x: 10, y: 20), modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])

        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertEqual(testSupport.selectArgument, [])
    }

    func test_drag_encloses_two_points() {
        let start = CGPoint(x: 10, y: 20)
        let end = CGPoint(x: 110, y: 220)
        let rect = CGRect(point1: start, point2: end)

        mouser.start(at: start, modifierFlags: [])
        mouser.drag(to: end, modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])

        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertEqual(testSupport.areaTestBubblesArgument, rect)
        XCTAssertEqual(testSupport.drawMarqueeArgument, rect)
    }

    func test_drag_selects_multiples() {
        let bubbles = [Bubble(ID: 0), Bubble(ID: 1), Bubble(ID: 2)]
        testSupport.areaTestBubblesReturn = bubbles

        let point = CGPoint(x: 10, y: 20)
        let rect = CGRect(at: .zero, width: 10, height: 20)

        // click at origin, drag to 10,20.
        // we're going to say 3 things were selected, make sure those are passed to the selection
        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: point, modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])

        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertEqual(testSupport.areaTestBubblesArgument, rect)
        XCTAssertEqual(testSupport.selectArgument, bubbles)
        XCTAssertEqual(testSupport.drawMarqueeArgument, rect)
    }

    func test_expands_and_contracts_deselects() {
        let b1 = Bubble(ID: 0)
        let b2 = Bubble(ID: 1)
        let b3 = Bubble(ID: 2)

        mouser.start(at: .zero, modifierFlags: [])

        // Select 3
        testSupport.areaTestBubblesReturn = [b1, b2, b3]
        mouser.drag(to: .zero, modifierFlags: [])
        XCTAssertEqual(testSupport.selectArgument, [b1, b2, b3])

        // Now select two, make sure the selection count is 2
        testSupport.reset()
        testSupport.areaTestBubblesReturn = [b1, b2]
        mouser.drag(to: .zero, modifierFlags: [])
        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertEqual(testSupport.selectArgument, [b1, b2])
    }

    func test_shift_appends_to_selection() {
        let b1 = Bubble(ID: 0)
        let b2 = Bubble(ID: 1)
        let b3 = Bubble(ID: 2)

        selection.select(bubble: b1)

        mouser.start(at: .zero, modifierFlags: [.shift])

        // Select 2 more
        testSupport.areaTestBubblesReturn = [b2, b3]
        mouser.drag(to: .zero, modifierFlags: [])
        XCTAssertEqual(testSupport.selectArgument, [b1, b2, b3])

        // then "drag" away from the other two bubble,s the first one should stay selected
        testSupport.areaTestBubblesReturn = []
        mouser.drag(to: .zero, modifierFlags: [])
        XCTAssertEqual(testSupport.selectArgument, [b1])
    }
}

class MouseDoubleSpaceTests: XCTestCase {
    var mouser: MouseDoubleSpacer!
    private var testSupport: TestSupport!

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        mouser = MouseDoubleSpacer(withSupport: testSupport)
    }

    override func tearDown() {
        mouser = nil
        testSupport = nil
        super.tearDown()
    }
    
    func test_double_click_creates_bubble() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])
        XCTAssertEqual(testSupport.createNewBubbleArgument, CGPoint.zero)
    }

    func test_double_click_and_drag_short_distance_still_creates() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: CGPoint(x: MouseDoubleSpacer.slopLimit / 2.0,
                y: MouseDoubleSpacer.slopLimit / 2.0), modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])
        XCTAssertNotNil(testSupport.createNewBubbleArgument)
    }

    func test_double_click_and_drag_long_distance_doesnt_create() {
        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: CGPoint(x: MouseDoubleSpacer.slopLimit * 2.0,
                y: MouseDoubleSpacer.slopLimit * 2.0), modifierFlags: [])
        mouser.finish(at: .zero, modifierFlags: [])
        XCTAssertNil(testSupport.createNewBubbleArgument)
    }
}
