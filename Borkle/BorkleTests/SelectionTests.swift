import XCTest
@testable import Borkle

class SelectionTests: XCTestCase {
    var selection: Selection!

    override func setUp() {
        super.setUp()
        selection = Selection()
    }

    override func tearDown() {
        selection = nil
        super.tearDown()
    }

}

