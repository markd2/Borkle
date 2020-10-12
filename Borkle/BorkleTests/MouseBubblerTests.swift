import XCTest
@testable import Borkle

class MouseBubblerTests: XCTestCase {
    var mouser: MouseBubbler!
    var testSupport: BubblerTestSupport!
    var selection: Selection! = Selection()
    var bubbles: [Bubble]!

    override func setUp() {
        super.setUp()
        testSupport = BubblerTestSupport()
        selection = Selection()
        mouser = MouseBubbler(withSupport: testSupport, selectedBubbles: selection)
        bubbles = [Bubble(ID: 11, position: CGPoint(x: 11, y: 11), width: 11),
                   Bubble(ID: 33, position: CGPoint(x: 33, y: 33), width: 33),
                   Bubble(ID: 22, position: CGPoint(x: 220, y: 220), width: 200),
                   Bubble(ID: 1, position: CGPoint(x: 100, y: 100), width: 42)]
    }

    override func tearDown() {
        mouser = nil
        testSupport = nil
        selection = nil
        bubbles = nil
        super.tearDown()
    }
    
    func test_window_coordinates() {
        XCTAssertFalse(mouser.prefersWindowCoordinates)
    }

    func test_click_in_bubble_unselects_others() {
        selection.select(bubbles: bubbles)
        selection.deselect(bubble: bubbles[3])

        testSupport.hitTestBubbleReturn = bubbles[3]
        mouser.start(at: .zero, modifierFlags: [])
        mouser.finish(modifierFlags: [])

        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(selection.selectedBubbles, [bubbles[3]])
    }

    func test_shift_click_adds_to_selection() {
        selection.select(bubbles: bubbles)
        selection.deselect(bubble: bubbles[3])

        testSupport.hitTestBubbleReturn = bubbles[3]
        mouser.start(at: .zero, modifierFlags: [.shift])
        mouser.finish(modifierFlags: [.shift])

        XCTAssertEqual(selection.bubbleCount, 4)
        XCTAssertEqual(Set(selection.selectedBubbles), Set(bubbles))
    }
    
    func test_command_click_toggles_selected() {
        selection.select(bubble: bubbles[1])
        selection.select(bubble: bubbles[2])

        testSupport.hitTestBubbleReturn = bubbles[2]
        mouser.start(at: .zero, modifierFlags: [.command])
        mouser.finish(modifierFlags: [.command])

        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(selection.selectedBubbles, [bubbles[1]])
    }

    func test_drag_in_selection_moves_it() {
        selection.select(bubble: bubbles[1]) // ID 33
        selection.select(bubble: bubbles[2]) // ID 22

        testSupport.hitTestBubbleReturn = bubbles[1]

        let p10_20 = CGPoint(x: 10, y: 20)
        let p20_40 = CGPoint(x: 20, y: 40)

        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: p10_20, modifierFlags: [])
        mouser.drag(to: p20_40, modifierFlags: [])
        
        let moved = testSupport.moveAccumulator.sorted(by: <)
        
        XCTAssertEqual(moved,
                       [BubblePoint(bubbles[1], CGPoint(x: 43, y: 53)),
                        BubblePoint(bubbles[2], CGPoint(x: 230, y: 240)),
                        BubblePoint(bubbles[1], CGPoint(x: 53, y: 73)),
                        BubblePoint(bubbles[2], CGPoint(x: 240, y: 260))].sorted(by: <) )
        mouser.finish(modifierFlags: [])
    }

    func test_click_in_unselected_bubble_and_drag_unselects_first_then_drag() {
    }
}

// Can't Equatable tuples :-(
struct BubblePoint: Equatable, Comparable {
    let bubble: Bubble
    let point: CGPoint
    
    init(_ bubble: Bubble, _ point: CGPoint) {
        self.bubble = bubble
        self.point = point
    }

    static func < (lhs: BubblePoint, rhs: BubblePoint) -> Bool {
        if lhs.bubble.ID < rhs.bubble.ID { return true }
        else if lhs.point.x < rhs.point.x { return true }
        else if lhs.point.y < rhs.point.y { return true }
        else { return false }
    }

}


class BubblerTestSupport: TestSupport {
    
    var moveAccumulator: [BubblePoint]! = []
    override func move(bubble: Bubble, to: CGPoint) {
        print("SNORGLE \(bubble.ID) to \(to)")
        moveAccumulator.append(BubblePoint(bubble, to))
    }
    
}
