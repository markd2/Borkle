import XCTest
@testable import Borkle

class ScappleImporterTests: XCTestCase {
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
        let url = try urlFor(filename: "empty")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_import_single_bubble() throws {
        let url = try urlFor(filename: "bubble-with-text")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]
            XCTAssertEqual(bubble.text, "Snorgle")
            XCTAssertEqual(bubble.width, 50.0)
            XCTAssertEqual(bubble.position, CGPoint(x: 296.0, y: 221.0))
        } catch {
            XCTFail("\(error)")
        }
    }
}

extension ScappleImporterTests {
    func urlFor(filename: String) throws -> URL {
        let url = try XCTUnwrap(bundle.url(forResource: filename, withExtension: "scap"))
        return url
    }
}
