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

    func test_import_two_bubbles_with_connections() throws {
        let url = try urlFor(filename: "two-connected")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 2)
            let b1 = bubbles[0]
            let b2 = bubbles[1]

            XCTAssertEqual(b1.text, "oop")
            XCTAssertEqual(b2.text, "ack")
            XCTAssertEqual(b1.width, 29.0)
            XCTAssertEqual(b2.width, 27.0)
            XCTAssertEqual(b1.position, CGPoint(x: 179.0, y: 197.0))
            XCTAssertEqual(b2.position, CGPoint(x: 304.0, y: 280.0))

            XCTAssertTrue(b1.isConnectedTo(b2))
            XCTAssertTrue(b2.isConnectedTo(b1))
        } catch {
            XCTFail("\(error)")
        }
    }


    // What the corresponding XML looks like
    //   <String>I seem to be a verb</String>
    //   <Formatting>
    //       <FormatRange Italic="Yes">2,4</FormatRange>
    //       <FormatRange Bold="Yes">7,2</FormatRange>
    //       <FormatRange Underline="Yes">10,2</FormatRange>
    //       <FormatRange Struckthrough="Yes">13,1</FormatRange>
    //       <FormatRange Bold="Yes" Italic="Yes">15,4</FormatRange>
    //   </Formatting>
    func test_import_single_styled_bubble() throws {
        let url = try urlFor(filename: "single-formatted")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]
            XCTAssertEqual(bubble.text, "I seem to be a verb")

            XCTAssertEqual(bubble.formattingOptions.count, 5)
            
            let expectedOptions: [Bubble.FormattingOption] = [
              Bubble.FormattingOption([.italic], 2, 4),
              Bubble.FormattingOption([.bold], 7, 2),
              Bubble.FormattingOption([.underline], 10, 2),
              Bubble.FormattingOption([.strikethrough], 13, 1),
              Bubble.FormattingOption([.bold, .italic], 15, 4)
            ]
            XCTAssertEqual(bubble.formattingOptions, expectedOptions)
                               
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
