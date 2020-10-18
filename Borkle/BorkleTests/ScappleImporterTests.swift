import XCTest
@testable import Borkle

class ScappleImporterTests: XCTestCase {
    let scap = "scap"

    var importer: ScappleImporter!
    var bundle: Bundle!
    
    override func setUp() {
        super.setUp()
        importer = ScappleImporter()
        bundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        importer = nil
        bundle = nil
        super.tearDown()
    }

    func test_import_empty_document() throws {
        let url = try XCTUnwrap(bundle.url(forResource: "empty", withExtension: scap))

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 0)
        } catch {
            XCTFail("\(error)")
        }

    }
}
