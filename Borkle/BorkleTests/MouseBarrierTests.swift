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
    }
    
    func newBarrier(ID: Int) -> Barrier {
        barrier = Barrier(ID: ID, label: "label", horizontalPosition: 0, width: 0)
        return barrier
    }

    func test_drag_uses_horizontal_component() {
        mouser.start(at: .zero)

        testSupport.barriersAffectedByReturn = [barrier]
        mouser.move(to: CGPoint(x: 10, y: -20))

        XCTAssertEqual(testSupport.moveBarrierArguments?.offset, 10)
    }
}

