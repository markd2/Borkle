import XCTest
@testable import Borkle

class MouseSpaceTests: XCTestCase {
    var mouser: MouseSpacer!
    private var testSupport: TestSupport!
    
    var invalCount = 0

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        mouser = MouseSpacer(withSupport: testSupport)
    }

    override func tearDown() {
        super.tearDown()
        mouser = nil
        testSupport = nil
    }

    func test_just_click_deselects_everything() {
        mouser.start(at: .zero)
        mouser.finish()

        XCTAssertTrue(testSupport.unselectAllCalled)
        XCTAssertNil(testSupport.selectArgument)
    }
}

private class TestSupport: MouseSupport {

    var hitTestBubbleArgument: CGPoint? = nil
    var hitTestBubbleReturn: Bubble? = nil
    func hitTestBubble(at: CGPoint) -> Bubble? {
        hitTestBubbleArgument = at
        return hitTestBubbleReturn
    }

    var areaTestBubblesArgument: CGRect? = nil
    var areaTestBubblesReturn: [Bubble]? = nil
    func areaTestBubbles(intersecting: CGRect) -> [Bubble]? {
        areaTestBubblesArgument = intersecting
        return areaTestBubblesReturn
    }

    var drawMarqueeArgument: CGRect? = nil
    func drawMarquee(around: CGRect) {
        drawMarqueeArgument = around
    }

    var unselectAllCalled = false
    func unselectAll() {
        unselectAllCalled = true
    }

    var selectArgument: [Bubble]? = nil
    func select(bubbles: [Bubble]) {
        selectArgument = bubbles
    }
}
