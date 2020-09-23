import XCTest
@testable import Borkle

class MouseBarrierTests: XCTestCase {
    var mouser: MouseBarrier!
    var barrier: Barrier! // zero / empty-string values
    private var testSupport: TestSupport!

    var invalCount = 0

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        barrier = Barrier(ID: 0, label: "label", horizontalPosition: 0, width: 0)
        mouser = MouseBarrier(withSupport: testSupport, barrier: barrier)
    }

    override func tearDown() {
        testSupport = nil
        barrier = nil
        mouser = nil
        super.tearDown()
    }

    func test_window_coordinate_preference() {
        // We like view coordinates thank you very much
        XCTAssertFalse(mouser.prefersWindowCoordinates)
    }

    func test_just_click_moves_nothing() {
        mouser.start(at: .zero)
        mouser.finish()

        // it does ask first what dealios are affected
        XCTAssertNotNil(testSupport.bubblesAffectedByArgument)
        XCTAssertNotNil(testSupport.barriersAffectedByArgument)

        // Should not have attempted to move anything.
        XCTAssertNil(testSupport.moveBarrierArguments)
    }

    func test_drag_doesnt_move_nothing() {
        mouser.start(at: .zero)
        mouser.move(to: CGPoint(x: 10, y: -20))

        XCTAssertNil(testSupport.moveBarrierArguments)

        mouser.finish()
    }

    func test_empty_affected_arrays_als_do_nothing() {
        testSupport.bubblesAffectedByReturn = []
        testSupport.barriersAffectedByReturn = []

        mouser.start(at: .zero)
        mouser.move(to: CGPoint(x: 10, y: -20))

        XCTAssertNil(testSupport.moveBarrierArguments)

        mouser.finish()
    }
    
    func newBarrier(ID: Int) -> Barrier {
        let barrier = Barrier(ID: ID, label: "label", horizontalPosition: 0, width: 0)
        return barrier
    }

    func newBubble(ID: Int) -> Bubble {
        let bubble = Bubble(ID: ID)
        return bubble
    }

    func test_drag_uses_horizontal_component() {
        testSupport.barriersAffectedByReturn = [barrier]
        mouser.start(at: .zero)

        mouser.move(to: CGPoint(x: 10, y: -20))
        XCTAssertEqual(testSupport.moveBarrierArguments?.offset, 10)

        testSupport.reset()

        mouser.move(to: CGPoint(x: -666, y: 3.1415))
        XCTAssertEqual(testSupport.moveBarrierArguments?.offset, -666)

        mouser.finish()
    }

    func test_bubbles_but_no_barriers_trigger_move() {
        testSupport.bubblesAffectedByReturn = [newBubble(ID: 2)]
        mouser.start(at: .zero)

        mouser.move(to: CGPoint(x: 10, y: -20))
        XCTAssertEqual(testSupport.moveBarrierArguments?.offset, 10)

        mouser.finish()
    }

    func test_barriers_but_no_bubbles_trigger_move() {
        testSupport.barriersAffectedByReturn = [newBarrier(ID: 2)]
        mouser.start(at: .zero)

        mouser.move(to: CGPoint(x: 10, y: -20))
        XCTAssertEqual(testSupport.moveBarrierArguments?.offset, 10)

        mouser.finish()
    }

    func test_move_given_all_the_right_stuff() {
        let bubble = newBubble(ID: 2)
        let anotherBarrier = newBarrier(ID: 12)
        testSupport.bubblesAffectedByReturn = [bubble]
        testSupport.barriersAffectedByReturn = [anotherBarrier]
        mouser.start(at: .zero)

        mouser.move(to: CGPoint(x: -1.234, y: 666.0))

        let args = testSupport.moveBarrierArguments
        XCTAssertEqual(args!.barrier, self.barrier)
        XCTAssertEqual(args?.bubbles, [bubble])
        XCTAssertEqual(args?.barriers, [anotherBarrier])
        XCTAssertEqual(args?.offset, -1.234)

        mouser.finish()
    }
}

