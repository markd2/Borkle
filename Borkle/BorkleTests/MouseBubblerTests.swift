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
        mouser.finish(at: .zero, modifierFlags: [])

        XCTAssertEqual(selection.bubbleCount, 1)
        XCTAssertEqual(selection.selectedBubbles, [bubbles[3]])
    }

    func test_shift_click_adds_to_selection() {
        selection.select(bubbles: bubbles)
        selection.deselect(bubble: bubbles[3])

        testSupport.hitTestBubbleReturn = bubbles[3]
        mouser.start(at: .zero, modifierFlags: [.shift])
        mouser.finish(at: .zero, modifierFlags: [.shift])

        XCTAssertEqual(selection.bubbleCount, 4)
        XCTAssertEqual(Set(selection.selectedBubbles), Set(bubbles))
    }
    
    func test_command_click_toggles_selected() {
        selection.select(bubble: bubbles[1])
        selection.select(bubble: bubbles[2])

        testSupport.hitTestBubbleReturn = bubbles[2]
        mouser.start(at: .zero, modifierFlags: [.command])
        mouser.finish(at: .zero, modifierFlags: [.command])

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
        let expected = [BubblePoint(bubbles[1], CGPoint(x: 43, y: 53)),
                        BubblePoint(bubbles[2], CGPoint(x: 230, y: 240)),
                        BubblePoint(bubbles[1], CGPoint(x: 53, y: 73)),
                        BubblePoint(bubbles[2], CGPoint(x: 240, y: 260))].sorted(by: <)
        
        XCTAssertEqual(moved, expected)
        mouser.finish(at: .zero, modifierFlags: [])
    }

    // mainly for coverage
    func test_drag_called_with_no_selected_bubbles() {
        mouser.drag(to: .zero, modifierFlags: [])

        // make sure the subsequent code hasn't been called
        XCTAssertNil(testSupport.areaTestBubblesArgument)
    }

    // mainly for coverage
    func test_drag_with_no_original_position_bails_out() {
        selection.select(bubble: bubbles[1]) // ID 33
        mouser.originalBubblePositions = nil

        mouser.start(at: .zero, modifierFlags: [])
        mouser.drag(to: .zero, modifierFlags: [])

        XCTAssertNil(testSupport.moveBubbleArguments)
    }

    func test_drag_selected_bubbles_highlights_potential_drop_target() {
        selection.select(bubbles: [bubbles[0], bubbles[1]])

        // Start the drag.
        testSupport.hitTestBubbleReturn = bubbles[0]
        mouser.start(at: .zero, modifierFlags: [])

        // Drag "over" an existing bubble.
        testSupport.reset()
        testSupport.areaTestBubblesReturn = [bubbles[2], bubbles[0]] // IDs 22, 11

        mouser.drag(to: .zero, modifierFlags: [])

        // the code takes the last area test.  It should take out bubbles[0] (ID 11) first
        // because that's what is dragged under the mouse pointer.
        XCTAssertEqual(testSupport.highlightAsDropTargetArgument?.ID, 22)
    }

    func test_drag_selected_bubbles_turns_off_highlight_if_no_hit_test() {
        selection.select(bubbles: [bubbles[0], bubbles[1]])

        // Start the drag.
        testSupport.hitTestBubbleReturn = bubbles[0]
        mouser.start(at: .zero, modifierFlags: [])

        // Drag over no bubbles
        testSupport.reset()
        testSupport.areaTestBubblesReturn = nil

        mouser.drag(to: .zero, modifierFlags: [])

        // the code takes the last area test.  It should take out bubbles[0] (ID 11) first
        // because that's what is dragged under the mouse pointer.
        XCTAssertTrue(testSupport.highlightAsDropTargetCalled)
        XCTAssertNil(testSupport.highlightAsDropTargetArgument)
    }

    func test_drop_on_highlighted_bubble_makes_connections_and_resets_positions() {
    }

    func test_drop_on_highlighted_bubble_makes_disconnections_and_resets_positions() {
    }

    func test_drop_on_nothing_makes_no_connections_and_moves() {
        selection.select(bubbles: [bubbles[0], bubbles[1]])

        // Start the drag.
        testSupport.hitTestBubbleReturn = bubbles[0]
        mouser.start(at: .zero, modifierFlags: [])

        // Drag "over" no bubble, should move bubbles
        testSupport.reset()
        testSupport.areaTestBubblesReturn = nil

        mouser.drag(to: CGPoint(x: 100, y: 200), modifierFlags: [])
        // make sure it moved

        testSupport.moveBubbleArguments?.forEach {
            if $0.bubble.ID == bubbles[0].ID {
                XCTAssertEqual($0.to, CGPoint(x: 111, y: 211))
            } else if $0.bubble.ID == bubbles[1].ID {
                XCTAssertEqual($0.to, CGPoint(x: 133, y: 233))
            }
        }

        // release on nothing
        testSupport.reset()
        mouser.finish(at: CGPoint(x: 200, y: 300), modifierFlags: [])

        // make sure it still was moved, since this is a drag now.
        testSupport.moveBubbleArguments?.forEach {
            if $0.bubble.ID == bubbles[0].ID {
                XCTAssertEqual($0.to, CGPoint(x: 111, y: 211))
            } else if $0.bubble.ID == bubbles[1].ID {
                XCTAssertEqual($0.to, CGPoint(x: 133, y: 233))
            }
        }

        // Make sure no connections have been made
        XCTAssertFalse(bubbles[0].isConnectedTo(bubbles[1]))
        XCTAssertFalse(bubbles[0].isConnectedTo(bubbles[2]))
        XCTAssertFalse(bubbles[1].isConnectedTo(bubbles[2]))
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
        else if lhs.bubble.ID > rhs.bubble.ID { return false }
        else { // equal
            if lhs.point.x < rhs.point.x { return true }
            else if lhs.point.x > rhs.point.x {return false }
            else { // equal
                 if lhs.point.y < rhs.point.y { return true }
                else if lhs.point.y > rhs.point.y { return false }
                else { return false }
            }
        }
    }

}


class BubblerTestSupport: TestSupport {
    
    var moveAccumulator: [BubblePoint]! = []
    override func move(bubble: Bubble, to: CGPoint) {
        moveAccumulator.append(BubblePoint(bubble, to))
        super.move(bubble: bubble, to: to)
    }
    
}
