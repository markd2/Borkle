import XCTest
@testable import BorkleModels

class BarrierTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_rect_calculations() {
        let barrier = Barrier(ID: 23, label: "24", horizontalPosition: 30, width: 10)
        let area = CGRect(x: 0, y: 0, width: 300, height: 150)

        let (lineRect, textRect) = barrier.rects(in: area)

        // label is below the line
        XCTAssertTrue(textRect.minY <= lineRect.maxY)

        // total hight is a bit less, to account for padding
        XCTAssertTrue(textRect.height + lineRect.height < area.height)

        // line and text should be centered horizontally relative to each other.
        XCTAssertEqual(textRect.midX, lineRect.midX)
    }
    
    func test_hit_test_inside_line() {
        let barrier = Barrier(ID: 23, label: "24", horizontalPosition: 30, width: 10)
        let area = CGRect(x: 0, y: 0, width: 300, height: 150)

        XCTAssertTrue(barrier.hitTest(point:CGPoint(x: 28, y: 100), area: area))

        // too far left
        XCTAssertFalse(barrier.hitTest(point:CGPoint(x: 8, y: 100), area: area))

        // too far right
        XCTAssertFalse(barrier.hitTest(point:CGPoint(x: 58, y: 100), area: area))
    }

    func test_hit_test_inside_label() {
        let barrier = Barrier(ID: 23, label: "24", horizontalPosition: 30, width: 10)
        let area = CGRect(x: 0, y: 0, width: 300, height: 150)

        XCTAssertTrue(barrier.hitTest(point:CGPoint(x: 28, y: 140), area: area))

        // too far left
        XCTAssertFalse(barrier.hitTest(point:CGPoint(x: 8, y: 140), area: area))

        // too far right
        XCTAssertFalse(barrier.hitTest(point:CGPoint(x: 58, y: 140), area: area))
    }

    func test_add_to_sets() {
        let barrier = Barrier(ID: 23, label: "24", horizontalPosition: 25, width: 26)
        let set: Set<Barrier> = [barrier]
        XCTAssertTrue(set.contains(barrier))
    }
}

