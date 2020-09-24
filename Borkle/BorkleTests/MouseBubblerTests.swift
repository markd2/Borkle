import XCTest
@testable import Borkle

class MouseBubblerTests: XCTestCase {
    var mouser: MouseBubbler!
    private var testSupport: TestSupport!

    override func setUp() {
        super.setUp()
        testSupport = TestSupport()
        mouser = MouseBubbler(withSupport: testSupport)
    }

    override func tearDown() {
        testSupport = nil
        mouser = nil
        super.tearDown()
    }

}
